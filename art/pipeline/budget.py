"""Paid-generation gate and credit ledger for Asset Factory batches.

Every paid attempt follows reserve → created → terminal, all appended to the
batch's ledger.jsonl under an exclusive file lock:

  reserved  {attempt, asset, est}       written BEFORE the request is sent
  created   {attempt, task_id}          the generator accepted it
  post_error{attempt, error}            unknown whether a task exists: the attempt
                                        stays open (counted at est) until resolved
  terminal  {attempt, status, credits}  credits = null when the API did not say
  resolved  {attempt, task_id|None}     a human reconciled an ambiguous attempt

Committed spend = confirmed credits of finished attempts + est for every attempt
whose charge is not confirmed. An asset with an open attempt cannot start
another (Meshy: a timed-out create may still have been charged).
"""
import fcntl
import hashlib
import json
import math
import os
import re
import time
import tomllib
import uuid
from contextlib import contextmanager
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ID = re.compile(r"^[a-z][a-z0-9_]*$")

# Credits per image→3D attempt by (ai_model, textured), from docs.meshy.ai/en/api/pricing
# (2026-10-20). est_credits in batch.toml must be at least this.
MESHY_COST = {
    ("meshy-t2.5", True): 15, ("meshy-t2.5", False): 5,
    ("meshy-t2", True): 15, ("meshy-t2", False): 5,
    ("meshy-6-lite", True): 15, ("meshy-6-lite", False): 5,
    ("meshy-6", True): 30, ("meshy-6", False): 20,
    ("meshy-7.1", True): 30, ("meshy-7.1", False): 20,
    ("latest", True): 30, ("latest", False): 20,
}


def load_batch(batch_toml: Path) -> tuple[dict, Path]:
    """Registry + its directory, with the isolation rules checked."""
    path = (ROOT / batch_toml).resolve()
    b = tomllib.loads(path.read_text())
    d = path.parent
    bid = b["batch"]["id"]
    if d.name != bid or d.parent != ROOT / "art/factory":
        raise SystemExit(f"batch id {bid!r} must match its directory art/factory/{bid}/")
    base = ROOT / "assets/candidates"
    if base.is_symlink() or (base.exists() and base.resolve() != base):
        raise SystemExit("assets/candidates must be a real directory, not a link (isolation from assets/models)")
    cand = ROOT / b["batch"]["candidates_dir"]
    if b["batch"]["candidates_dir"] != f"assets/candidates/{bid}" or cand.is_symlink() or \
            (cand.exists() and cand.resolve() != (ROOT / "assets/candidates").resolve() / bid):
        raise SystemExit(f"candidates_dir must be the real directory assets/candidates/{bid} (never production paths)")
    builds = [x["build"] for x in b["asset"].values() if x.get("build")]
    if any(not x.startswith("art/pipeline/blender/factory/build_") for x in builds):
        raise SystemExit("factory builds must be art/pipeline/blender/factory/build_*.py (production builders write assets/models/)")
    bad = [i for i in b["asset"] if not ID.match(i)]
    if bad:
        raise SystemExit(f"asset ids must match {ID.pattern}: {bad}")
    return b, d


def _num(v, name: str, positive=True) -> float:
    if not isinstance(v, (int, float)) or isinstance(v, bool) or not math.isfinite(v) or v < 0 or (positive and v == 0):
        raise ValueError(f"{name} must be a finite {'positive' if positive else 'non-negative'} number, got {v!r}")
    return float(v)


@contextmanager
def _locked(d: Path):
    with (d / "ledger.lock").open("a") as lk:
        fcntl.flock(lk, fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lk, fcntl.LOCK_UN)


def _rows(d: Path) -> list:
    p = d / "ledger.jsonl"
    def bad_constant(c):
        raise ValueError(f"ledger contains {c}: refusing to read it")
    rows = [json.loads(l, parse_constant=bad_constant) for l in p.read_text().splitlines() if l.strip()] if p.exists() else []
    if any("attempt" not in r for r in rows):
        raise ValueError(f"{p} has rows without an attempt id (pre-7dda567 format): reconcile it by hand before use")
    return rows


def _append(d: Path, row: dict) -> None:
    """Append and fsync (file and, when new, the directory) before returning: a reservation
    must survive a host crash that happens after the request it covers was sent."""
    p = d / "ledger.jsonl"
    new = not p.exists()
    with p.open("a") as f:
        f.write(json.dumps({"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), **row}, allow_nan=False) + "\n")
        f.flush()
        os.fsync(f.fileno())
    if new:
        fd = os.open(d, os.O_RDONLY)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)


def _credits(v):
    """A confirmed charge is a finite, non-negative number; anything else is unknown (None)."""
    return float(v) if isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v) and v >= 0 else None


def state(d: Path) -> dict:
    """attempt id → {asset, est, task_id, status, credits, open, post_error, meta}."""
    att = {}
    for r in _rows(d):
        a = att.setdefault(r["attempt"], {"asset": r.get("asset"), "est": 0.0, "task_id": None, "status": None,
                                          "credits": None, "open": True, "post_error": False, "meta": {}})
        ev = r["event"]
        if ev == "reserved":
            a.update(asset=r["asset"], est=_num(r["est"], "ledger est"), meta=r.get("meta", {}))
        elif ev == "created":
            a["task_id"] = r["task_id"]
        elif ev == "post_error":
            a["post_error"] = True
        elif ev == "terminal":
            c = _credits(r.get("credits"))
            if a["credits"] is not None and (c is None or c < a["credits"]):
                c = a["credits"]  # a later, vaguer observation never lowers a confirmed charge
            a.update(status=r["status"], credits=c, open=False)
        elif ev == "resolved":
            a["task_id"] = r.get("task_id")
            if r.get("task_id") is None:  # confirmed: no task was created, nothing charged
                a.update(status="not_created", credits=0, open=False)
    return att


def committed(d: Path) -> float:
    return sum(a["credits"] if (not a["open"] and a["credits"] is not None) else a["est"] for a in state(d).values())


def approval(b: dict, d: Path) -> dict:
    p = d / "APPROVAL.toml"
    if not p.exists():
        raise PermissionError(f"no {p.relative_to(ROOT)} (paid generation needs the Owner's approval)")
    appr = tomllib.loads(p.read_text())
    if not appr.get("approved_by"):
        raise PermissionError("APPROVAL.toml needs approved_by")
    credits = _num(appr.get("credits"), "APPROVAL credits")
    if credits > _num(b["batch"]["budget_credits"], "budget_credits"):
        raise PermissionError("APPROVAL credits exceed the batch budget_credits")
    if appr.get("meshy_plan") not in ("paid", "free"):
        raise PermissionError("APPROVAL.toml needs meshy_plan = \"paid\" | \"free\" (it decides the licence)")
    if "assets" in appr and not (isinstance(appr["assets"], list) and all(isinstance(x, str) for x in appr["assets"])):
        raise PermissionError("APPROVAL assets must be a list of asset ids (omit it to approve every asset)")
    return appr


def cost_floor(spec: dict) -> float:
    g = spec.get("generator", {})
    key = (g.get("ai_model", "meshy-t2.5"), bool(g.get("should_texture", True)))
    if key not in MESHY_COST:
        raise ValueError(f"no verified cost for {key}; add it to budget.MESHY_COST first")
    return MESHY_COST[key]


def reserve(b: dict, d: Path, asset: str) -> str:
    """Check approval + budget and durably reserve one attempt. Raises PermissionError/ValueError."""
    spec = b["asset"][asset]
    est = _num(spec.get("est_credits"), f"{asset}.est_credits")
    if est < cost_floor(spec):
        raise ValueError(f"{asset}.est_credits {est} is below the verified cost {cost_floor(spec)} for its generator options")
    with _locked(d):
        appr = approval(b, d)
        if "assets" in appr and asset not in appr["assets"]:  # [] approves nothing
            raise PermissionError(f"{asset} is not in the approved asset list")
        pending = [k for k, a in state(d).items() if a["asset"] == asset and a["open"]]
        if pending:
            raise PermissionError(f"{asset} has an unresolved attempt {pending[-1]}: resume it (meshy.py --resume) "
                                  f"or reconcile it (factory.py resolve) before generating again")
        spent = committed(d)
        if spent + est > appr["credits"]:
            raise PermissionError(f"committed {spent} + est {est} > approved {appr['credits']}")
        attempt = uuid.uuid4().hex[:12]
        # Snapshot what the licence and audit depend on, so a later APPROVAL edit cannot rewrite history.
        meta = {"approved_by": appr["approved_by"], "meshy_plan": appr["meshy_plan"],
                "approval_sha256": hashlib.sha256((d / "APPROVAL.toml").read_bytes()).hexdigest(),
                "generator": spec.get("generator", {})}
        _append(d, {"attempt": attempt, "event": "reserved", "asset": asset, "est": est, "meta": meta})
        return attempt


def record(d: Path, attempt: str, event: str, **fields) -> None:
    with _locked(d):
        _append(d, {"attempt": attempt, "event": event, **fields})


def resolve(d: Path, attempt: str, task_id: str | None) -> None:
    """Reconcile an attempt whose POST failed ambiguously. Under the lock, and only for an
    open attempt that recorded post_error and has no task: a reservation without post_error
    may still be about to send, so it can never be released."""
    with _locked(d):
        a = state(d).get(attempt)
        if not a or not a["open"]:
            raise PermissionError(f"no open attempt {attempt}")
        if a["task_id"] or not a["post_error"]:
            raise PermissionError(f"attempt {attempt} is not an ambiguous POST failure (task={a['task_id']}, "
                                  f"post_error={a['post_error']}); resume it instead")
        _append(d, {"attempt": attempt, "event": "resolved", "task_id": task_id})


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()
