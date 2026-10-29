#!/usr/bin/env python3
"""Asset Factory: one command per stage for a batch of candidate assets.

    python3 art/pipeline/factory.py plan     af01          # routes, stage status, budget, open attempts
    python3 art/pipeline/factory.py concept  af01 [--only a,b]   # GPT concepts for image→3D routes (gen.py)
    python3 art/pipeline/factory.py build    af01 [--only ...]   # Blender procedural routes
    python3 art/pipeline/factory.py gen      af01 --only a       # PAID: Meshy, gated (art/pipeline/budget.py)
    python3 art/pipeline/factory.py resolve  af01 <attempt> --task <id> | --not-created   # reconcile an ambiguous attempt
    python3 art/pipeline/factory.py ingest   af01 [--only ...]   # raw generated mesh → spec'd candidate GLB
    python3 art/pipeline/factory.py validate af01                # G2 against the batch registry
    python3 art/pipeline/factory.py preview  af01                # Godot import + G3 lookdev per asset + contact sheet
    python3 art/pipeline/factory.py qa       af01                # in-game QA in the real scene (tests/factory_qa.gd)
    python3 art/pipeline/factory.py report   af01                # STATUS.json + LICENCES.md + yield table
    python3 art/pipeline/factory.py all      af01                # build → validate → preview → qa → report (free routes)

The batch registry is art/factory/<batch>/batch.toml (same schema as
art/assets.toml plus route/licence/cost fields). Candidates are written only to
assets/candidates/<batch>/ (budget.load_batch enforces it); promotion into
assets/models/ is an Owner decision (art/factory/README.md).

Paid generation: the request is sent only after budget.reserve() has checked
APPROVAL.toml (approved_by, finite credits ≤ budget_credits, meshy_plan,
optional assets list) and durably reserved the attempt's estimate in
ledger.jsonl under a file lock. Unconfirmed charges stay committed.

Every stage fails closed: stale outputs are removed before a stage runs, a
non-zero tool exit is a failure, and `all` stops at the first failing stage.
"""
import argparse
import glob
import json
import os
import shutil
import subprocess
import sys
import time
import tomllib
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import budget  # noqa: E402

BLENDER = os.environ.get("BLENDER", "blender")
GODOT = os.environ.get("GODOT", "godot")
GEN_ROUTES = ("meshy", "tripo")
PAID_READY = ("meshy",)  # tripo.py does not implement the reserve/ledger contract yet


def load(batch: str) -> tuple[dict, Path]:
    return budget.load_batch(Path(f"art/factory/{batch}/batch.toml"))


def ids(b: dict, only: str, routes=None) -> list[str]:
    want = [s for s in only.split(",") if s] if only else list(b["asset"])
    bad = [i for i in want if i not in b["asset"]]
    if bad:
        sys.exit(f"unknown asset(s): {bad}")
    return [i for i in want if routes is None or b["asset"][i]["route"] in routes]


def run(cmd: list[str], log: Path | None = None) -> tuple[int, float]:
    t0 = time.time()
    with (log.open("w") if log else open(os.devnull, "w")) as f:
        p = subprocess.run(cmd, cwd=ROOT, stdout=f, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL)
    return p.returncode, round(time.time() - t0, 1)


def rel(p: Path) -> str:
    return str(p.relative_to(ROOT))


def glb(b: dict, i: str) -> Path:
    return ROOT / b["batch"]["candidates_dir"] / f"{i}.glb"


def concept_for(b: dict, i: str) -> Path | None:
    hits = sorted(glob.glob(str(ROOT / f"art/runs/{b['batch']['id']}-concepts/{b['batch']['id']}_{i}-*.jpg")))
    pick = b["asset"][i].get("concept")
    return ROOT / pick if pick else (Path(hits[-1]) if hits else None)


def stamp(receipt: Path, b: dict, ids_: list[str]) -> None:
    """A stage's success receipt: which candidate content (sha256) its evidence describes."""
    receipt.write_text(json.dumps({i: budget.sha256(glb(b, i)) for i in ids_}, indent=2))


def fresh(receipt: Path, i: str, b: dict) -> bool:
    """Evidence counts only if its stage succeeded for exactly the current candidate content."""
    if not (receipt.exists() and glb(b, i).exists()):
        return False
    return json.loads(receipt.read_text()).get(i) == budget.sha256(glb(b, i))


# ------------------------------------------------------------------ stages (return failure count)

def plan(b, d, a):
    appr = d / "APPROVAL.toml"
    approved = tomllib.loads(appr.read_text()).get("credits", 0) if appr.exists() else 0
    est = sum(x.get("est_credits", 0) for x in b["asset"].values())
    print(f"batch {b['batch']['id']}: {len(b['asset'])} assets — {b['batch']['theme']}")
    print(f"budget cap {b['batch']['budget_credits']} credits (≤ ${b['batch']['budget_usd_cap']}); "
          f"approved {approved}; committed {budget.committed(d)}; one attempt each = {est}")
    for k, att in budget.state(d).items():
        if att["open"]:
            print(f"  OPEN attempt {k}: {att['asset']} task={att['task_id']} est={att['est']}")
    print(f"{'asset':24} {'route':19} {'cr':>3}  concept raw glb g2")
    for i, x in b["asset"].items():
        g2 = d / "g2" / f"{i}.g2.json"
        g2s = ("PASS" if json.loads(g2.read_text())["pass"] else "FAIL") if fresh(d / "g2" / f"{i}.receipt.json", i, b) else "-"
        gen_route = x["route"] in GEN_ROUTES
        raw = bool(glob.glob(str(ROOT / f"art/sources/{x['route']}/{i}/*.glb"))) if gen_route else None
        c = concept_for(b, i) if gen_route else None
        print(f"{i:24} {x['route']:19} {x.get('est_credits', 0):>3}  "
              f"{('yes' if c else 'no') if gen_route else 'n/a':7} "
              f"{('yes' if raw else 'no') if gen_route else 'n/a':3} {'yes' if glb(b, i).exists() else 'no':3} {g2s}")
    return 0


def concept(b, d, a):
    todo = ids(b, a.only, GEN_ROUTES)
    procs = []
    for i in todo:  # ≤3 parallel Codex image jobs (art/PIPELINE.md tool status)
        while len([p for p in procs if p.poll() is None]) >= 3:
            time.sleep(2)
        procs.append(subprocess.Popen([sys.executable, "art/pipeline/gen.py", "--run", f"{b['batch']['id']}-concepts",
                                       "--styles", a.style, "--subject", f"{b['batch']['id']}_{i}", "--gens", "gpt", "--n", "1"],
                                      cwd=ROOT, stdout=(d / "logs" / f"concept-{i}.log").open("w"),
                                      stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL))
    codes = [p.wait() for p in procs]
    for i, c in zip(todo, codes):
        print(f"concept {i}: {'ok' if c == 0 else f'FAIL ({c})'} {concept_for(b, i) or ''}")
    return sum(c != 0 for c in codes)


def _models_snapshot() -> dict:
    return {f.name: budget.sha256(f) for f in (ROOT / "assets/models").glob("*.glb")}


def build(b, d, a):
    fails = 0
    before = _models_snapshot()  # belt and braces: no factory build may touch production models
    for i in ids(b, a.only, ("blender_procedural",)):
        glb(b, i).unlink(missing_ok=True)  # a failed build must not leave the previous GLB looking current
        code, s = run([BLENDER, "-b", "--factory-startup", "-P", b["asset"][i]["build"]], d / "logs" / f"build-{i}.log")
        ok = code == 0 and glb(b, i).exists()
        fails += not ok
        print(f"build {i}: {'ok' if ok else 'FAIL'} ({s}s)")
        if _models_snapshot() != before:
            sys.exit(f"ABORT: build {i} changed assets/models/ — restore it from git (`git checkout -- assets/models`)")
    return fails


def gen(b, d, a):
    for i in ids(b, a.only, GEN_ROUTES):
        x = b["asset"][i]
        if x["route"] not in PAID_READY:
            sys.exit(f"refused {i}: route {x['route']} has no gated adapter yet (tripo.py lacks budget.reserve)")
        c = concept_for(b, i)
        if not c:
            sys.exit(f"refused {i}: no concept image (run `factory.py concept {b['batch']['id']} --only {i}`)")
        # meshy.py reserves the credits itself (lock + ledger) before sending anything.
        code, s = run([sys.executable, "art/pipeline/meshy.py", i, rel(c), "--batch", rel(d / "batch.toml"), "--approved"],
                      d / "logs" / f"gen-{i}.log")
        print(f"gen {i}: {'ok' if code == 0 else f'FAIL ({code})'} ({s}s); committed {budget.committed(d)} credits")
        if code != 0:  # stop: never carry on spending after a refusal, error or ambiguous create
            print((d / "logs" / f"gen-{i}.log").read_text()[-600:])
            return 1
    return 0


def resolve(b, d, a):
    if bool(a.task) == a.not_created:
        sys.exit("give exactly one of --task <id> (then `meshy.py --resume`) or --not-created")
    try:
        budget.resolve(d, a.attempt, a.task or None)
    except PermissionError as e:
        sys.exit(f"refused: {e}")
    print(f"attempt {a.attempt}: " + (f"task {a.task}; resume with meshy.py --resume {a.attempt}" if a.task
                                      else "confirmed not created; reservation released"))
    return 0


def ingest(b, d, a):
    fails = 0
    for i in ids(b, a.only, GEN_ROUTES):
        raws = sorted(glob.glob(str(ROOT / f"art/sources/{b['asset'][i]['route']}/{i}/*.glb")), key=os.path.getmtime)
        src = Path(a.raw) if a.raw else (Path(raws[-1]) if raws else None)
        if not src:
            print(f"ingest {i}: no raw mesh yet")
            continue
        glb(b, i).unlink(missing_ok=True)
        (d / "g2" / f"{i}.ingest.json").unlink(missing_ok=True)  # provenance must never outlive its GLB
        code, s = run([BLENDER, "-b", "--factory-startup", "-P", "art/pipeline/blender/ingest.py", "--", str(src), i,
                       "--registry", rel(d / "batch.toml"), "--export", rel(glb(b, i)), "--out", rel(d / "g2")],
                      d / "logs" / f"ingest-{i}.log")
        ok = code == 0 and glb(b, i).exists()
        fails += not ok
        print(f"ingest {i}: {'ok' if ok else 'FAIL'} ({s}s)")
    return fails


def validate(b, d, a):
    passed, fails = 0, 0
    for i in ids(b, a.only):
        rep_path = d / "g2" / f"{i}.g2.json"
        rep_path.unlink(missing_ok=True)
        (d / "g2" / f"{i}.receipt.json").unlink(missing_ok=True)
        if not glb(b, i).exists():
            print(f"G2 {i}: no candidate")
            continue
        code, _ = run([BLENDER, "-b", "--factory-startup", "-P", "art/pipeline/blender/validate.py", "--",
                       rel(glb(b, i)), i, "--registry", rel(d / "batch.toml"), "--out", rel(d / "g2")],
                      d / "logs" / f"g2-{i}.log")
        if code not in (0, 1) or not rep_path.exists():  # 1 = ran and found failures; anything else = did not run
            fails += 1
            print(f"G2 {i}: ERROR (exit {code}, see logs/g2-{i}.log)")
            continue
        rep = json.loads(rep_path.read_text())
        bad = [k for k, c in rep["checks"].items() if not c["ok"]]
        passed += rep["pass"]
        fails += not rep["pass"]  # a G2 failure is a gate failure: `all` stops here
        stamp(d / "g2" / f"{i}.receipt.json", b, [i])
        print(f"G2 {i}: {'PASS' if rep['pass'] else 'FAIL ' + ','.join(bad)} ({rep['checks']['triangles']['value']} tris)")
    print(f"G2 passed: {passed}")
    return fails


def godot_import() -> int:
    code, s = run([GODOT, "--headless", "--path", ".", "--import"], None)
    print(f"godot import: {'ok' if code == 0 else f'exit {code}'} ({s}s)")
    return int(code != 0)


def preview(b, d, a):
    if godot_import():
        return 1  # no receipts from an un-imported project
    res_dir = "res://" + b["batch"]["candidates_dir"]
    shots = []
    for i in ids(b, a.only):
        out = d / "g3" / i
        shutil.rmtree(out, ignore_errors=True)
        if not glb(b, i).exists():
            continue
        code, s = run([GODOT, "--path", ".", "--always-on-top", "res://scenes/lookdev.tscn", "--",
                       f"--capture={out}", f"--assets={i}", f"--models={res_dir}"], d / "logs" / f"g3-{i}.log")
        tq = out / "lookdev_three_quarter.png"
        ok = code == 0 and tq.exists()
        fails += not ok
        print(f"G3 {i}: {'ok' if ok else 'FAIL'} ({s}s)")
        if ok:
            shots.append((i, tq))
            stamp(out / "receipt.json", b, [i])
    _sheet(shots, d / "contact-g3.jpg")
    return fails


def _sheet(shots, path: Path, cols=5, w=384):
    if not shots:
        return
    from PIL import Image, ImageDraw
    ims = [(i, Image.open(p).convert("RGB")) for i, p in shots]
    h = round(w * ims[0][1].height / ims[0][1].width)
    sheet = Image.new("RGB", (cols * w, -(-len(ims) // cols) * (h + 22)), (24, 24, 24))
    dr = ImageDraw.Draw(sheet)
    for n, (i, im) in enumerate(ims):
        x, y = (n % cols) * w, (n // cols) * (h + 22)
        sheet.paste(im.resize((w, h)), (x, y + 22))
        dr.text((x + 6, y + 5), i, fill=(235, 230, 215))
    sheet.save(path, quality=86)
    print("contact sheet", rel(path))


def qa(b, d, a):
    if godot_import():
        return 1
    fails = 0
    res_dir = "res://" + b["batch"]["candidates_dir"] + "/"
    assets = []
    for i, x in b["asset"].items():
        if not glb(b, i).exists():
            continue
        assets.append({"id": i, "glb": res_dir + f"{i}.glb", "pos": x["qa"][0], "yaw": x["qa"][1],
                       "light": x.get("qa_light", "prep_early"), "on": x.get("qa_on", ""),
                       "lean": x.get("qa_lean_deg", 0), "eye": x.get("qa_eye", [])})
    manifest = {"batch": b["batch"]["id"], "assets": assets, "views": b["batch"].get("qa_views", [])}
    (d / "qa_manifest.json").write_text(json.dumps(manifest, indent=2))
    out = d / "qa"
    shutil.rmtree(out, ignore_errors=True)
    code, s = run([GODOT, "--path", ".", "--always-on-top", "--", f"--factory-qa={rel(out)}",
                   f"--qa-manifest={rel(d / 'qa_manifest.json')}", "--seed=7"], d / "logs" / "qa.log")
    ok = code == 0 and (out / "qa.json").exists()
    print(f"in-game QA: {'ok' if ok else f'FAIL (exit {code}; captures kept for diagnosis)'} ({s}s) → {rel(out)}")
    if not ok:
        return fails + 1
    rep = json.loads((out / "qa.json").read_text())
    stamp(out / "receipt.json", b, [r["id"] for r in rep["assets"] if "screenshot" in r])
    _sheet([(r["id"], out / r["screenshot"]) for r in rep["assets"] if "screenshot" in r], d / "contact-ingame.jpg")
    _sheet([(r["id"], out / f"{r['id']}-detail.png") for r in rep["assets"] if "screenshot" in r], d / "contact-ingame-detail.jpg")
    _sheet([(f"{v['view']} {s}", out / f"view-{v['view']}-{s}.png") for v in rep["views"] for s in ("without", "with")],
           d / "contact-views.jpg", cols=2, w=640)
    return fails + sum(1 for r in rep["assets"] if r.get("missing"))


def _licence_source(b, d, i) -> str:
    """The exact source behind the current candidate: build script, or the receipt of the ingested task."""
    x = b["asset"][i]
    if x["route"] not in GEN_ROUTES:
        return x.get("build", "?")
    ing = d / "g2" / f"{i}.ingest.json"
    if not ing.exists():
        return "not generated"
    ingr = json.loads(ing.read_text())
    if not glb(b, i).exists() or ingr.get("glb_sha256") != budget.sha256(glb(b, i)):
        return "UNTRACED: ingest receipt does not match the current candidate (not promotable)"
    receipt = (ROOT / ingr["raw"]).with_suffix(".json")
    if not receipt.exists():
        return f"UNTRACED raw {json.loads(ing.read_text())['raw']} (no receipt: not promotable)"
    r = json.loads(receipt.read_text())
    return f"{rel(receipt)} — task {r['task_id']}, plan {r.get('meshy_plan', '?')}: {r.get('licence', '?')}"


def report(b, d, a):
    review = tomllib.loads((d / "review.toml").read_text()) if (d / "review.toml").exists() else {}
    status, lic = [], ["# Licences: batch " + b["batch"]["id"], "",
                       "| asset | route | licence policy | exact source |", "|---|---|---|---|"]
    for i, x in b["asset"].items():
        g2 = d / "g2" / f"{i}.g2.json"
        g2r = json.loads(g2.read_text()) if fresh(d / "g2" / f"{i}.receipt.json", i, b) else None
        r = review.get(i, {})
        verdict = r.get("verdict", "pending")
        if "glb_sha256" in r and (not glb(b, i).exists() or r["glb_sha256"] != budget.sha256(glb(b, i))):
            verdict = "stale_review"  # the review judged different content
        status.append({"id": i, "route": x["route"], "candidate": glb(b, i).exists(),
                       "g2": None if g2r is None else g2r["pass"],
                       "triangles": g2r["checks"]["triangles"]["value"] if g2r else None,
                       "g3": fresh(d / "g3" / i / "receipt.json", i, b),
                       "ingame": fresh(d / "qa" / "receipt.json", i, b),
                       "verdict": verdict, "score": r.get("score"), "note": r.get("note", "")})
        lic.append(f"| {i} | {x['route']} | {x['licence']} | `{_licence_source(b, d, i)}` |")
    usable = [s for s in status if s["verdict"] in ("usable", "usable_with_fixes")]
    summary = {"batch": b["batch"]["id"], "generated_at": datetime.now().astimezone().isoformat(timespec="seconds"),
               "assets": len(status), "candidates": sum(s["candidate"] for s in status),
               "g2_pass": sum(bool(s["g2"]) for s in status), "ingame_shots": sum(s["ingame"] for s in status),
               "usable": len(usable),
               "verdicts": {v: sum(s["verdict"] == v for s in status) for v in sorted({s["verdict"] for s in status})},
               "credits_committed": budget.committed(d), "attempts": len(budget.state(d)), "status": status}
    (d / "STATUS.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False))
    (d / "LICENCES.md").write_text("\n".join(lic) + "\n")
    print(json.dumps({k: v for k, v in summary.items() if k != "status"}, indent=2))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["plan", "concept", "build", "gen", "resolve", "ingest", "validate", "preview",
                                      "qa", "report", "all"])
    ap.add_argument("batch")
    ap.add_argument("attempt", nargs="?", default="", help="resolve: the open attempt id")
    ap.add_argument("--only", default="")
    ap.add_argument("--style", default="E_diorama_plate_grade", help="concept style (art/prompts/e1919/styles.toml)")
    ap.add_argument("--raw", default="", help="ingest: explicit raw mesh path (one asset)")
    ap.add_argument("--task", default="", help="resolve: the Meshy task id that the attempt did create")
    ap.add_argument("--not-created", action="store_true", help="resolve: Meshy shows no task for the attempt")
    a = ap.parse_args()
    b, d = load(a.batch)
    (d / "logs").mkdir(exist_ok=True)
    stages = ["build", "validate", "preview", "qa", "report"] if a.stage == "all" else [a.stage]
    for s in stages:
        if globals()[s](b, d, a):
            sys.exit(f"stage {s}: failures (see art/factory/{a.batch}/logs/)")


if __name__ == "__main__":
    main()
