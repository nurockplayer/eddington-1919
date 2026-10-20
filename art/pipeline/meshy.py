#!/usr/bin/env python3
"""Image → 3D through the Meshy REST API (stage S3a, Asset Factory route `meshy`).

    MESHY_API_KEY=... python3 art/pipeline/meshy.py <asset> <concept.jpg> \
        --batch art/factory/af01/batch.toml [--dry-run | --approved | --resume <attempt>]

The scripted twin of the Meshy MCP server (`meshy_image_to_3d`): same endpoint
and options, but reproducible from the command line and bound to the batch
budget. Paid work goes through `factory.py gen`; whichever way it is called,
the request is sent only after budget.reserve() has checked the Owner's
APPROVAL.toml and durably reserved the credits under a lock (art/pipeline/budget.py).

Writes art/sources/meshy/<asset>/<task_id>.glb (git-ignored raw source) and a
receipt <task_id>.json (options, attempt, task id, credits, plan → licence).

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
import urllib.request
from pathlib import Path

API = os.environ.get("MESHY_API_BASE", "https://api.meshy.ai/openapi/v1")
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import budget  # noqa: E402


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


def _poll(task: str) -> dict:
    while True:
        t = _req("GET", f"/image-to-3d/{task}")
        if t["status"] in ("SUCCEEDED", "FAILED", "CANCELED"):
            return t
        time.sleep(8)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("asset")
    ap.add_argument("image", type=Path)
    ap.add_argument("--batch", type=Path, required=True)
    ap.add_argument("--dry-run", action="store_true", help="print the request (image elided) and exit")
    ap.add_argument("--approved", action="store_true", help="send it (still subject to budget.reserve)")
    ap.add_argument("--resume", default="", help="attempt id: poll/download its existing task, no new spend")
    a = ap.parse_args()
    batch, d = budget.load_batch(a.batch)
    spec = batch["asset"][a.asset]
    opts = options(spec, ROOT / a.image)
    shown = {**opts, "image_url": f"<{a.image} base64, {len(opts['image_url'])} chars>"}
    if a.dry_run or not (a.approved or a.resume):
        print(json.dumps(shown, indent=2))
        return 0 if a.dry_run else 3
    if "MESHY_API_KEY" not in os.environ:  # checked before reserving, so no reservation is left dangling
        print("MESHY_API_KEY is not set.", file=sys.stderr)
        return 2
    t0 = time.time()
    if a.resume:
        att = budget.state(d).get(a.resume)
        if not att or att["asset"] != a.asset or not att["task_id"] or not att["open"]:
            print(f"attempt {a.resume} is not an open attempt with a known task for {a.asset}", file=sys.stderr)
            return 4
        attempt, task = a.resume, att["task_id"]
    else:
        try:
            attempt = budget.reserve(batch, d, a.asset)
        except (PermissionError, ValueError) as e:
            print(f"refused: {e}", file=sys.stderr)
            return 3
        try:
            task = _req("POST", "/image-to-3d", opts)["result"]
        except Exception as e:  # the task may exist and be billed: keep the attempt open
            budget.record(d, attempt, "post_error", error=repr(e)[:300])
            print(f"POST failed ({e!r}); attempt {attempt} stays reserved. Check meshy_list_tasks, then "
                  f"`factory.py resolve {batch['batch']['id']} {attempt} --task <id>|--not-created`", file=sys.stderr)
            return 4
        budget.record(d, attempt, "created", task_id=task)
    t = _poll(task)
    credits = budget._credits(t.get("consumed_credits"))  # None = unknown/invalid: the estimate stays committed
    budget.record(d, attempt, "terminal", status=t["status"], credits=credits)
    if t["status"] != "SUCCEEDED":
        print(json.dumps(t.get("task_error", t), indent=2), file=sys.stderr)
        return 1
    out = ROOT / "art/sources/meshy" / a.asset / f"{task}.glb"
    out.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(t["model_urls"]["glb"], out)
    meta = budget.state(d)[attempt]["meta"]  # the approval as it was when the credits were reserved
    plan = meta["meshy_plan"]
    receipt = {"asset": a.asset, "image": str(a.image), "options": shown, "attempt": attempt, "task_id": task,
               "credits": credits, "seconds": round(time.time() - t0, 1), "glb": str(out.relative_to(ROOT)),
               "thumbnail_url": t.get("thumbnail_url"), "meshy_plan": plan, "approved_by": meta["approved_by"],
               "approval_sha256": meta["approval_sha256"], "glb_sha256": budget.sha256(out),
               "licence": "user-owned, no attribution (Meshy paid plan)" if plan == "paid"
                          else "CC BY 4.0, credit Meshy (free plan)",
               "terms_source": "https://intercom.help/meshy/en/articles/16102098-can-i-use-meshy-assets-commercially (read 2026-10-20)"}
    out.with_suffix(".json").write_text(json.dumps(receipt, indent=2))
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
