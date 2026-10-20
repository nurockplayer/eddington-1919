#!/usr/bin/env python3
"""Image → 3D through the Meshy REST API (stage S3a, Asset Factory route `meshy`).

    MESHY_API_KEY=... python3 art/pipeline/meshy.py <asset> <concept.jpg> \
        --batch art/factory/af01/batch.toml [--dry-run]

The scripted twin of the Meshy MCP server (`meshy_image_to_3d`): same endpoint
and options, but reproducible from the command line and bound to the batch
budget. Never call it directly for paid work; `factory.py gen` checks the
Owner's approval file and the credit ledger first and passes --approved.

Writes art/sources/meshy/<asset>/<task_id>.glb (git-ignored raw source) and a
receipt <task_id>.json (options, task id, consumed credits, seconds), and
appends the spend to art/factory/<batch>/ledger.jsonl.

Contract checked against https://docs.meshy.ai/en/api/image-to-3d (2026-10-20):
POST /openapi/v1/image-to-3d {image_url (data URI ok), ai_model, model_type,
target_polycount, should_texture, target_formats} → {result: <task id>};
GET /openapi/v1/image-to-3d/<id> → status, model_urls.glb, consumed_credits.
"""
import argparse
import base64
import json
import os
import sys
import time
import tomllib
import urllib.request
from pathlib import Path

API = os.environ.get("MESHY_API_BASE", "https://api.meshy.ai/openapi/v1")
ROOT = Path(__file__).resolve().parents[2]


def _req(method: str, path: str, body: dict | None = None) -> dict:
    req = urllib.request.Request(API + path, data=json.dumps(body).encode() if body else None, method=method,
                                 headers={"Authorization": f"Bearer {os.environ['MESHY_API_KEY']}",
                                          "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)


def options(spec: dict, image: Path) -> dict:
    g = spec.get("generator", {})
    mime = "image/png" if image.suffix.lower() == ".png" else "image/jpeg"
    return {
        "image_url": f"data:{mime};base64," + base64.b64encode(image.read_bytes()).decode(),
        "ai_model": g.get("ai_model", "meshy-t2.5"),
        "model_type": g.get("model_type", "smart-topology"),
        "target_polycount": g.get("target_polycount", spec["tri_budget"]),
        "should_texture": g.get("should_texture", True),
        "target_formats": ["glb"],
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("asset")
    ap.add_argument("image", type=Path)
    ap.add_argument("--batch", type=Path, required=True)
    ap.add_argument("--dry-run", action="store_true", help="print the request (image elided) and exit")
    ap.add_argument("--approved", action="store_true", help="set by factory.py after the budget gate")
    a = ap.parse_args()
    batch = tomllib.loads((ROOT / a.batch).read_text())
    spec = batch["asset"][a.asset]
    opts = options(spec, ROOT / a.image)
    shown = {**opts, "image_url": f"<{a.image} base64, {len(opts['image_url'])} chars>"}
    if a.dry_run or not a.approved:
        print(json.dumps(shown, indent=2))
        if not a.dry_run:
            print("refusing: paid generation runs only through `factory.py gen` (budget + approval gate)", file=sys.stderr)
        return 0 if a.dry_run else 3
    if "MESHY_API_KEY" not in os.environ:
        print("MESHY_API_KEY is not set.", file=sys.stderr)
        return 2
    t0 = time.time()
    task = _req("POST", "/image-to-3d", opts)["result"]
    ledger = ROOT / "art/factory" / batch["batch"]["id"] / "ledger.jsonl"
    # Record the task before polling: if this process dies, the spend is still visible.
    with ledger.open("a") as f:
        f.write(json.dumps({"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "asset": a.asset, "route": "meshy",
                            "task_id": task, "event": "created", "est_credits": spec.get("est_credits", 0)}) + "\n")
    while True:
        time.sleep(8)
        t = _req("GET", f"/image-to-3d/{task}")
        if t["status"] in ("SUCCEEDED", "FAILED", "CANCELED"):
            break
    with ledger.open("a") as f:
        f.write(json.dumps({"ts": time.strftime("%Y-%m-%dT%H:%M:%S"), "asset": a.asset, "route": "meshy",
                            "task_id": task, "event": t["status"].lower(),
                            "credits": t.get("consumed_credits", 0)}) + "\n")
    if t["status"] != "SUCCEEDED":
        print(json.dumps(t.get("task_error", t), indent=2), file=sys.stderr)
        return 1
    out = ROOT / "art/sources/meshy" / a.asset / f"{task}.glb"
    out.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(t["model_urls"]["glb"], out)
    receipt = {"asset": a.asset, "image": str(a.image), "options": shown, "task_id": task,
               "credits": t.get("consumed_credits"), "seconds": round(time.time() - t0, 1),
               "glb": str(out.relative_to(ROOT)), "thumbnail_url": t.get("thumbnail_url")}
    out.with_suffix(".json").write_text(json.dumps(receipt, indent=2))
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
