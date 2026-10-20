#!/usr/bin/env python3
"""Offline checks for the paid-generation gate (art/pipeline/budget.py). No network, no spend.

    python3 -I art/pipeline/test_budget.py

Builds a throwaway batch at art/factory/zz_gate_test/ and removes it afterwards.
"""
import json
import multiprocessing as mp
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import budget  # noqa: E402

D = ROOT / "art/factory/zz_gate_test"
BATCH = """[batch]
id = "zz_gate_test"
theme = "gate test"
budget_credits = 200
budget_usd_cap = 10.0
candidates_dir = "{cand}"

[asset.rock]
route = "meshy"
category = "kit_prop"
dims_m = [1.0, 1.0, 1.0]
tri_budget = 600
max_materials = 1
max_texture_px = 512
licence = "test"
{est}
generator = {{ ai_model = "meshy-t2.5", model_type = "smart-topology", should_texture = true }}

[asset.log]
route = "tripo"
category = "kit_prop"
dims_m = [1.0, 1.0, 1.0]
tri_budget = 600
max_materials = 1
max_texture_px = 512
licence = "test"
est_credits = 30
"""
checks = []


def check(name, ok):
    checks.append((name, bool(ok)))
    print(("PASS " if ok else "FAIL ") + name)


def write(est="est_credits = 15", cand="assets/candidates/zz_gate_test", approval=None, ledger=()):
    D.mkdir(parents=True, exist_ok=True)
    (D / "batch.toml").write_text(BATCH.format(est=est, cand=cand))
    (D / "APPROVAL.toml").unlink(missing_ok=True)
    if approval is not None:
        (D / "APPROVAL.toml").write_text(approval)
    (D / "ledger.jsonl").write_text("".join(json.dumps(r) + "\n" for r in ledger))


def refused(fn):
    try:
        fn()
        return False
    except (PermissionError, ValueError, SystemExit):
        return True


def load():
    return budget.load_batch(Path("art/factory/zz_gate_test/batch.toml"))


def _race(_):
    b, d = load()
    try:
        budget.reserve(b, d, "rock")
        return 1
    except PermissionError:
        return 0


OK = 'approved_by = "test"\ncredits = 15\nmeshy_plan = "paid"\n'


def main():
    try:
        write()
        check("no APPROVAL.toml → refused", refused(lambda: budget.reserve(*load(), "rock")))
        write(approval='approved_by = "t"\ncredits = 15\n')
        check("missing meshy_plan → refused", refused(lambda: budget.reserve(*load(), "rock")))
        write(approval='approved_by = "t"\ncredits = nan\nmeshy_plan = "paid"\n')
        check("credits = nan → refused", refused(lambda: budget.reserve(*load(), "rock")))
        write(approval='approved_by = "t"\ncredits = 500\nmeshy_plan = "paid"\n')
        check("credits over batch budget → refused", refused(lambda: budget.reserve(*load(), "rock")))
        write(est="", approval=OK)
        check("missing est_credits → refused", refused(lambda: budget.reserve(*load(), "rock")))
        write(est="est_credits = 5", approval=OK)
        check("est below verified cost (t2.5 textured = 15) → refused", refused(lambda: budget.reserve(*load(), "rock")))
        write(cand="assets/models", approval=OK)
        check("candidates_dir = assets/models → refused", refused(load))

        write(approval=OK)
        with mp.Pool(6) as pool:
            wins = sum(pool.map(_race, range(6)))
        check(f"6 concurrent reserves against 15 credits → exactly 1 admitted (got {wins})", wins == 1)
        b, d = load()
        att = next(iter(budget.state(d)))
        check("open reservation counts at its estimate", budget.committed(d) == 15)
        check("a reservation that may still send cannot be resolved away", refused(lambda: budget.resolve(d, att, None)))
        budget.record(d, att, "post_error", error="timeout")
        check("post_error keeps the attempt open and blocks the asset", refused(lambda: budget.reserve(b, d, "rock")))
        budget.resolve(d, att, None)
        check("resolve --not-created (after post_error) releases the reservation", budget.committed(d) == 0)
        check("reservation snapshots the plan for the licence", budget.state(d)[att]["meta"].get("meshy_plan") == "paid")

        write(approval=OK, ledger=[{"attempt": "x", "event": "reserved", "asset": "rock", "est": 15},
                                   {"attempt": "x", "event": "terminal", "status": "SUCCEEDED", "credits": -100}])
        check("negative charge is treated as unknown (estimate kept)", budget.committed(D) == 15)
        (D / "ledger.jsonl").write_text('{"attempt": "x", "event": "reserved", "asset": "rock", "est": 15}\n'
                                        '{"attempt": "x", "event": "terminal", "status": "SUCCEEDED", "credits": NaN}\n')
        check("NaN in the ledger → refuse to read it", refused(lambda: budget.reserve(*load(), "rock")))
        write(approval=OK + "assets = []\n")
        check("assets = [] approves nothing", refused(lambda: budget.reserve(*load(), "rock")))
        write(approval=OK + 'assets = "rock_and_more"\n')
        check("assets as a string → refused", refused(lambda: budget.reserve(*load(), "rock")))
        write()
        link = ROOT / "assets/candidates/zz_gate_test"
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to(ROOT / "assets/models")
        try:
            check("candidates_dir symlinked to assets/models → refused", refused(load))
        finally:
            link.unlink()

        write(approval='approved_by = "t"\ncredits = 30\nmeshy_plan = "paid"\n')
        b, d = load()
        a1 = budget.reserve(b, d, "rock")
        budget.record(d, a1, "created", task_id="T1")
        budget.record(d, a1, "terminal", status="FAILED", credits=None)
        check("terminal with unknown credits keeps the estimate committed", budget.committed(d) == 15)
        a2 = budget.reserve(b, d, "rock")
        budget.record(d, a2, "created", task_id="T2")
        budget.record(d, a2, "terminal", status="SUCCEEDED", credits=15)
        check("30 approved: 15 unknown + 15 confirmed = 30 committed", budget.committed(d) == 30)
        check("third attempt over the approval → refused", refused(lambda: budget.reserve(b, d, "rock")))

        write(approval=OK)
        r = subprocess.run([sys.executable, "-I", "art/pipeline/meshy.py", "rock", "art/runs/af01-concepts/af01_laterite_boulder-E-gpt-1.jpg",
                            "--batch", "art/factory/zz_gate_test/batch.toml", "--approved"], cwd=ROOT, capture_output=True, text=True,
                           env={"PATH": "/usr/bin:/bin"})
        check("meshy.py --approved without a key: exits before reserving", r.returncode == 2 and budget.committed(D) == 0)
        r = subprocess.run([sys.executable, "-I", "art/pipeline/factory.py", "gen", "zz_gate_test", "--only", "log"],
                           cwd=ROOT, capture_output=True, text=True)
        check("tripo route has no gated adapter → refused", r.returncode != 0 and "refused" in r.stderr)
    finally:
        shutil.rmtree(D, ignore_errors=True)
    failed = [n for n, ok in checks if not ok]
    print(f"{len(checks)} checks, {len(failed)} failures")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
