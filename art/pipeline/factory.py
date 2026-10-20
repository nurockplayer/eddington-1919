#!/usr/bin/env python3
"""Asset Factory: one command per stage for a batch of candidate assets.

    python3 art/pipeline/factory.py plan     af01          # routes, stage status, budget
    python3 art/pipeline/factory.py concept  af01 [--only a,b]   # GPT concepts for image→3D routes (gen.py)
    python3 art/pipeline/factory.py build    af01 [--only ...]   # Blender procedural routes
    python3 art/pipeline/factory.py gen      af01 --only a       # PAID: Meshy/Tripo, gated (see below)
    python3 art/pipeline/factory.py ingest   af01 [--only ...]   # raw generated mesh → spec'd candidate GLB
    python3 art/pipeline/factory.py validate af01                # G2 against the batch registry
    python3 art/pipeline/factory.py preview  af01                # Godot import + G3 lookdev per asset + contact sheet
    python3 art/pipeline/factory.py qa       af01                # in-game QA in the real scene (tests/factory_qa.gd)
    python3 art/pipeline/factory.py report   af01                # STATUS.json + LICENCES.md + yield table
    python3 art/pipeline/factory.py all      af01                # build → validate → preview → qa → report (free routes)

The batch registry is art/factory/<batch>/batch.toml (same schema as
art/assets.toml plus route/licence/cost fields). Candidates are written to the
batch's candidates_dir and never to assets/models/: promotion is an Owner
decision (art/factory/README.md).

Paid generation gate: `gen` refuses unless art/factory/<batch>/APPROVAL.toml
exists with `approved_by`, `credits` (≤ batch budget_credits) and optionally
`assets`; and spent + this attempt's est_credits ≤ approved credits, where
spent is read from the append-only ledger.jsonl (created-but-unfinished tasks
count at their estimate).
"""
import argparse
import glob
import json
import os
import subprocess
import sys
import time
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BLENDER = os.environ.get("BLENDER", "blender")
GODOT = os.environ.get("GODOT", "godot")
GEN_ROUTES = ("meshy", "tripo")


def load(batch: str) -> tuple[dict, Path]:
    d = ROOT / "art/factory" / batch
    return tomllib.loads((d / "batch.toml").read_text()), d


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


def glb(b: dict, i: str) -> Path:
    return ROOT / b["batch"]["candidates_dir"] / f"{i}.glb"


def concept_for(b: dict, i: str) -> Path | None:
    hits = sorted(glob.glob(str(ROOT / f"art/runs/{b['batch']['id']}-concepts/{b['batch']['id']}_{i}-*.jpg")))
    pick = b["asset"][i].get("concept")
    return ROOT / pick if pick else (Path(hits[-1]) if hits else None)


def ledger(d: Path) -> tuple[float, list]:
    rows = [json.loads(l) for l in (d / "ledger.jsonl").read_text().splitlines() if l.strip()] if (d / "ledger.jsonl").exists() else []
    spent, open_ = 0.0, {}
    for r in rows:
        if r["event"] == "created":
            open_[r["task_id"]] = r.get("est_credits", 0)
        else:
            open_.pop(r["task_id"], None)
            spent += r.get("credits", 0) or 0
    return spent + sum(open_.values()), rows


# ------------------------------------------------------------------ stages

def plan(b, d, a):
    spent, _ = ledger(d)
    appr = d / "APPROVAL.toml"
    approved = tomllib.loads(appr.read_text()).get("credits", 0) if appr.exists() else 0
    est = sum(x.get("est_credits", 0) for x in b["asset"].values())
    print(f"batch {b['batch']['id']}: {len(b['asset'])} assets — {b['batch']['theme']}")
    print(f"budget cap {b['batch']['budget_credits']} credits (≤ ${b['batch']['budget_usd_cap']}); "
          f"approved {approved}; spent/committed {spent}; one attempt each = {est}")
    print(f"{'asset':24} {'route':19} {'cr':>3}  concept raw glb g2")
    for i, x in b["asset"].items():
        g2 = d / "g2" / f"{i}.g2.json"
        g2s = ("PASS" if json.loads(g2.read_text())["pass"] else "FAIL") if g2.exists() else "-"
        raw = bool(glob.glob(str(ROOT / f"art/sources/{x['route']}/{i}/*.glb"))) if x["route"] in GEN_ROUTES else None
        c = concept_for(b, i) if x["route"] in GEN_ROUTES else None
        print(f"{i:24} {x['route']:19} {x.get('est_credits', 0):>3}  "
              f"{('yes' if c else 'no') if x['route'] in GEN_ROUTES else 'n/a':7} "
              f"{('yes' if raw else 'no') if raw is not None else 'n/a':3} {'yes' if glb(b, i).exists() else 'no':3} {g2s}")


def concept(b, d, a):
    todo = ids(b, a.only, GEN_ROUTES)
    procs = []
    for i in todo:  # ≤3 parallel Codex image jobs (art/PIPELINE.md tool status)
        while len([p for p in procs if p.poll() is None]) >= 3:
            time.sleep(2)
        log = d / "logs" / f"concept-{i}.log"
        log.parent.mkdir(exist_ok=True)
        procs.append(subprocess.Popen([sys.executable, "art/pipeline/gen.py", "--run", f"{b['batch']['id']}-concepts",
                                       "--styles", a.style, "--subject", f"{b['batch']['id']}_{i}", "--gens", "gpt", "--n", "1"],
                                      cwd=ROOT, stdout=log.open("w"), stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL))
    codes = [p.wait() for p in procs]
    for i, c in zip(todo, codes):
        print(f"concept {i}: {'ok' if c == 0 else f'FAIL ({c})'} {concept_for(b, i) or ''}")


def build(b, d, a):
    for i in ids(b, a.only, ("blender_procedural",)):
        code, s = run([BLENDER, "-b", "--factory-startup", "-P", b["asset"][i]["build"]], d / "logs" / f"build-{i}.log")
        print(f"build {i}: {'ok' if code == 0 and glb(b, i).exists() else 'FAIL'} ({s}s)")


def gen(b, d, a):
    appr_path = d / "APPROVAL.toml"
    if not appr_path.exists():
        sys.exit(f"refused: no {appr_path.relative_to(ROOT)} (paid generation needs the Owner's approval)")
    appr = tomllib.loads(appr_path.read_text())
    if not appr.get("approved_by") or appr.get("credits", 0) > b["batch"]["budget_credits"]:
        sys.exit("refused: APPROVAL.toml needs approved_by and credits ≤ the batch budget_credits")
    for i in ids(b, a.only, GEN_ROUTES):
        x = b["asset"][i]
        if appr.get("assets") and i not in appr["assets"]:
            print(f"skip {i}: not in the approved asset list")
            continue
        spent, _ = ledger(d)
        if spent + x.get("est_credits", 0) > appr["credits"]:
            sys.exit(f"refused {i}: spent {spent} + est {x.get('est_credits', 0)} > approved {appr['credits']}")
        c = concept_for(b, i)
        if not c:
            sys.exit(f"refused {i}: no concept image (run `factory.py concept {b['batch']['id']} --only {i}`)")
        tool = {"meshy": "art/pipeline/meshy.py", "tripo": "art/pipeline/tripo.py"}[x["route"]]
        cmd = [sys.executable, tool, i, str(c.relative_to(ROOT)), "--batch", str((d / "batch.toml").relative_to(ROOT)), "--approved"]
        code, s = run(cmd, d / "logs" / f"gen-{i}.log")
        print(f"gen {i} via {x['route']}: {'ok' if code == 0 else f'FAIL ({code})'} ({s}s); ledger now {ledger(d)[0]} credits")


def ingest(b, d, a):
    for i in ids(b, a.only, GEN_ROUTES):
        raws = sorted(glob.glob(str(ROOT / f"art/sources/{b['asset'][i]['route']}/{i}/*.glb")), key=os.path.getmtime)
        src = Path(a.raw) if a.raw else (Path(raws[-1]) if raws else None)
        if not src:
            print(f"ingest {i}: no raw mesh yet")
            continue
        code, s = run([BLENDER, "-b", "--factory-startup", "-P", "art/pipeline/blender/ingest.py", "--", str(src), i,
                       "--registry", str((d / "batch.toml").relative_to(ROOT)),
                       "--export", str(glb(b, i).relative_to(ROOT)), "--out", str((d / "g2").relative_to(ROOT))],
                      d / "logs" / f"ingest-{i}.log")
        print(f"ingest {i}: {'ok' if code == 0 else 'FAIL'} ({s}s)")


def validate(b, d, a):
    passed = 0
    for i in ids(b, a.only):
        if not glb(b, i).exists():
            print(f"G2 {i}: no candidate")
            continue
        code, _ = run([BLENDER, "-b", "--factory-startup", "-P", "art/pipeline/blender/validate.py", "--",
                       str(glb(b, i).relative_to(ROOT)), i, "--registry", str((d / "batch.toml").relative_to(ROOT)),
                       "--out", str((d / "g2").relative_to(ROOT))], d / "logs" / f"g2-{i}.log")
        rep = json.loads((d / "g2" / f"{i}.g2.json").read_text())
        fails = [k for k, c in rep["checks"].items() if not c["ok"]]
        passed += rep["pass"]
        print(f"G2 {i}: {'PASS' if rep['pass'] else 'FAIL ' + ','.join(fails)} ({rep['checks']['triangles']['value']} tris)")
    print(f"G2 passed: {passed}")


def godot_import():
    code, s = run([GODOT, "--headless", "--path", ".", "--import"], None)
    print(f"godot import: {'ok' if code == 0 else f'exit {code}'} ({s}s)")


def preview(b, d, a):
    godot_import()
    res_dir = "res://" + b["batch"]["candidates_dir"]
    shots = []
    for i in ids(b, a.only):
        if not glb(b, i).exists():
            continue
        out = d / "g3" / i
        code, s = run([GODOT, "--path", ".", "--always-on-top", "res://scenes/lookdev.tscn", "--",
                       f"--capture={out}", f"--assets={i}", f"--models={res_dir}"], d / "logs" / f"g3-{i}.log")
        tq = out / "lookdev_three_quarter.png"
        print(f"G3 {i}: {'ok' if tq.exists() else 'FAIL'} ({s}s)")
        if tq.exists():
            shots.append((i, tq))
    _sheet(shots, d / "contact-g3.jpg")


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
    print("contact sheet", path.relative_to(ROOT))


def qa(b, d, a):
    godot_import()
    res_dir = "res://" + b["batch"]["candidates_dir"] + "/"
    assets = []
    for i, x in b["asset"].items():
        if not glb(b, i).exists():
            continue
        assets.append({"id": i, "glb": res_dir + f"{i}.glb", "pos": x["qa"][0], "yaw": x["qa"][1],
                       "light": x.get("qa_light", "prep_early"), "on": x.get("qa_on", ""), "lean": x.get("qa_lean_deg", 0), "eye": x.get("qa_eye", [])})
    manifest = {"batch": b["batch"]["id"], "assets": assets, "views": b["batch"].get("qa_views", [])}
    (d / "qa_manifest.json").write_text(json.dumps(manifest, indent=2))
    out = d / "qa"
    code, s = run([GODOT, "--path", ".", "--always-on-top", "--", f"--factory-qa={out.relative_to(ROOT)}",
                   f"--qa-manifest={(d / 'qa_manifest.json').relative_to(ROOT)}", "--seed=7"], d / "logs" / "qa.log")
    print(f"in-game QA: {'ok' if (out / 'qa.json').exists() else 'FAIL'} ({s}s) → {out.relative_to(ROOT)}")
    if (out / "qa.json").exists():
        rep = json.loads((out / "qa.json").read_text())
        _sheet([(r["id"], out / r["screenshot"]) for r in rep["assets"] if "screenshot" in r], d / "contact-ingame.jpg")
        _sheet([(r["id"], out / f"{r['id']}-detail.png") for r in rep["assets"] if "screenshot" in r], d / "contact-ingame-detail.jpg")
        _sheet([(f"{v['view']} {s}", out / f"view-{v['view']}-{s}.png") for v in rep["views"] for s in ("without", "with")],
               d / "contact-views.jpg", cols=2, w=640)


def report(b, d, a):
    review = tomllib.loads((d / "review.toml").read_text()) if (d / "review.toml").exists() else {}
    spent, rows = ledger(d)
    status, lic = [], ["# Licences: batch " + b["batch"]["id"], "",
                       "| asset | route | licence | source / receipt |", "|---|---|---|---|"]
    for i, x in b["asset"].items():
        g2 = d / "g2" / f"{i}.g2.json"
        g2r = json.loads(g2.read_text()) if g2.exists() else None
        r = review.get(i, {})
        status.append({"id": i, "route": x["route"], "candidate": glb(b, i).exists(),
                       "g2": None if g2r is None else g2r["pass"],
                       "triangles": g2r["checks"]["triangles"]["value"] if g2r else None,
                       "g3": (d / "g3" / i / "lookdev_three_quarter.png").exists(),
                       "ingame": (d / "qa" / f"{i}.png").exists(),
                       "verdict": r.get("verdict", "pending"), "score": r.get("score"), "note": r.get("note", "")})
        receipts = sorted(glob.glob(str(ROOT / f"art/sources/{x['route']}/{i}/*.json")))
        src = Path(receipts[-1]).relative_to(ROOT) if receipts else (x.get("build") or "not generated")
        lic.append(f"| {i} | {x['route']} | {x['licence']} | `{src}` |")
    usable = [s for s in status if s["verdict"] in ("usable", "usable_with_fixes")]
    summary = {"batch": b["batch"]["id"], "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S"),
               "assets": len(status), "candidates": sum(s["candidate"] for s in status),
               "g2_pass": sum(bool(s["g2"]) for s in status), "ingame_shots": sum(s["ingame"] for s in status),
               "usable": len(usable),
               "verdicts": {v: sum(s["verdict"] == v for s in status) for v in sorted({s["verdict"] for s in status})},
               "credits_spent": spent, "ledger_rows": len(rows), "status": status}
    (d / "STATUS.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False))
    (d / "LICENCES.md").write_text("\n".join(lic) + "\n")
    print(json.dumps({k: v for k, v in summary.items() if k != "status"}, indent=2))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["plan", "concept", "build", "gen", "ingest", "validate", "preview", "qa", "report", "all"])
    ap.add_argument("batch")
    ap.add_argument("--only", default="")
    ap.add_argument("--style", default="E_diorama_plate_grade", help="concept style (art/prompts/e1919/styles.toml)")
    ap.add_argument("--raw", default="", help="ingest: explicit raw mesh path (one asset)")
    a = ap.parse_args()
    b, d = load(a.batch)
    (d / "logs").mkdir(exist_ok=True)
    stages = ["build", "validate", "preview", "qa", "report"] if a.stage == "all" else [a.stage]
    for s in stages:
        globals()[s](b, d, a)


if __name__ == "__main__":
    main()
