#!/usr/bin/env python3
"""Image → 3D through the Tripo API (stage S3 in art/PIPELINE.md).

    TRIPO_API_KEY=... python3 art/pipeline/tripo.py coelostat art/runs/r03-assets/coelostat-B-gpt-1.jpg \
        [--face-limit 8000] [--model v3.1-20260211]

Uploads the concept image, starts an image-to-model task, polls it, and saves the
GLB as art/sources/tripo/<asset>/<task_id>.glb plus a JSON receipt (inputs,
options, task id, timings). The raw GLB then goes through
art/pipeline/blender/ingest.py like any other source mesh.

STATUS: written against the v3 docs (https://developers.tripo3d.com/llms.txt,
read 2026-10-19). NOT YET EXERCISED: this machine has no TRIPO_API_KEY. The
first real run must confirm the field names flagged "verify" below.
"""
import argparse
import json
import os
import sys
import time
import urllib.request
import uuid
from pathlib import Path

API = os.environ.get("TRIPO_API_BASE", "https://openapi.tripo3d.com/v3")
ART = Path(__file__).resolve().parents[1]


def _req(method: str, path: str, body: bytes | None = None, ctype: str = "application/json") -> dict:
    req = urllib.request.Request(API + path, data=body, method=method, headers={
        "Authorization": f"Bearer {os.environ['TRIPO_API_KEY']}", "Content-Type": ctype})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)


def upload(img: Path) -> str:
    boundary = uuid.uuid4().hex
    mime = "image/png" if img.suffix.lower() == ".png" else "image/jpeg"
    body = (f"--{boundary}\r\nContent-Disposition: form-data; name=\"file\"; filename=\"{img.name}\"\r\n"
            f"Content-Type: {mime}\r\n\r\n").encode() + img.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    data = _req("POST", "/files", body, f"multipart/form-data; boundary={boundary}")
    return data["data"]["file_token"]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("asset")
    ap.add_argument("image", type=Path)
    ap.add_argument("--model", default="v3.1-20260211")
    ap.add_argument("--face-limit", type=int, default=8000)
    a = ap.parse_args()
    if "TRIPO_API_KEY" not in os.environ:
        print("TRIPO_API_KEY is not set; use the Blender procedural path (S3b) instead.", file=sys.stderr)
        return 2
    t0 = time.time()
    token = upload(a.image)
    opts = {"input": token, "model": a.model,  # verify: older docs call this model_version
            "face_limit": a.face_limit, "texture": True, "pbr": False,
            "auto_size": True, "delight": True}  # delight: keep baked light out of albedo (BIBLE §5)
    task = _req("POST", "/generation/image-to-model", json.dumps(opts).encode())["data"]["task_id"]
    while True:
        time.sleep(4)
        t = _req("GET", f"/tasks/{task}")["data"]
        if t["status"] in ("success", "failed", "cancelled"):
            break
    if t["status"] != "success":
        print(json.dumps(t, indent=2), file=sys.stderr)
        return 1
    url = t["output"]["model_url"]  # verify: signed URL, expires after ~24 h
    out = ART / "sources/tripo" / a.asset / f"{task}.glb"
    out.parent.mkdir(parents=True, exist_ok=True)
    urllib.request.urlretrieve(url, out)
    receipt = {"asset": a.asset, "image": str(a.image), "options": {**opts, "input": "<file_token>"},
               "task_id": task, "seconds": round(time.time() - t0, 1), "glb": str(out.relative_to(ART.parent))}
    out.with_suffix(".json").write_text(json.dumps(receipt, indent=2))
    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
