#!/usr/bin/env python3
"""Generate concept images from the versioned prompt library.

    python3 art/pipeline/gen.py --run r01-directions \
        --styles A_silver_plate,B_painted_diorama --subject key_station \
        --gens gemini,gpt [--n 1] [--ref art/refs/x.jpg ...] [--extra "..."]

Prompt = series/base.toml (framing, identity, avoid) + <era>/styles.toml[style]
+ <era>/subjects.toml[subject] (+ --extra). Every image is logged to
art/runs/<run>/manifest.jsonl with the exact prompt text, block versions,
generator/model and timing, so any image can be regenerated or audited later.

Generators
  gemini  Google Gemini image model over REST (needs GEMINI_API_KEY with a paid
          image quota; the free tier has 0 image requests, see art/PIPELINE.md).
  gpt     OpenAI image generation through `codex exec` (Codex CLI, logged in).

Raw PNGs go to art/runs/<run>/_raw/ (git-ignored); a 1280px JPEG copy that is
committed sits next to the manifest.
"""
import argparse
import base64
import datetime as dt
import hashlib
import json
import os
import subprocess
import sys
import time
import tomllib
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ART = Path(__file__).resolve().parents[1]
GEMINI_MODEL = os.environ.get("E1919_GEMINI_MODEL", "gemini-3.1-flash-image")
GPT_MODEL = os.environ.get("E1919_CODEX_MODEL", "gpt-6-astra")


def load(path: Path) -> dict:
    with open(path, "rb") as f:
        return tomllib.load(f)


def compose(era: str, style_key: str, subject_key: str, extra: str) -> tuple[str, dict]:
    base = load(ART / "prompts/series/base.toml")
    styles = load(ART / f"prompts/{era}/styles.toml")
    subjects = load(ART / f"prompts/{era}/subjects.toml")
    st, sj = styles[style_key], subjects[subject_key]
    # Order matters: r01 put the subject first and every style collapsed into the
    # same photoreal render (see art/runs/r01-directions/REVIEW.md). Medium first.
    parts = [st["style"], base["identity"], "Subject: " + sj["text"].strip()]
    if sj.get("kind") == "keyframe":
        parts.append(base["framing"])
    parts.append("Reminder of the medium: " + st["style"].strip().split(".")[0] + ".")
    if extra:
        parts.append(extra)
    parts.append(base["avoid"])
    prompt = "\n".join(p.strip() for p in parts)
    versions = {"series": base["version"], "style": st["version"], "subject": sj["version"]}
    return prompt, versions


def gen_gemini(prompt: str, refs: list[Path], aspect: str, out: Path) -> str:
    parts = [{"text": prompt}]
    for r in refs:
        mime = "image/png" if r.suffix.lower() == ".png" else "image/jpeg"
        parts.append({"inline_data": {"mime_type": mime, "data": base64.b64encode(r.read_bytes()).decode()}})
    body = {
        "contents": [{"parts": parts}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": aspect}},
    }
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent",
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json", "x-goog-api-key": os.environ["GEMINI_API_KEY"]},
    )
    with urllib.request.urlopen(req, timeout=300) as resp:
        data = json.load(resp)
    for cand in data.get("candidates", []):
        for p in cand.get("content", {}).get("parts", []):
            blob = p.get("inline_data") or p.get("inlineData")
            if blob:
                out.write_bytes(base64.b64decode(blob["data"]))
                return GEMINI_MODEL
    raise RuntimeError(f"gemini returned no image: {json.dumps(data)[:400]}")


def gen_gpt(prompt: str, refs: list[Path], aspect: str, out: Path) -> str:
    shape = "landscape (wide)" if aspect == "16:9" else "square"
    instr = (
        "Use your image generation tool exactly once to create ONE "
        f"{shape} image from the prompt between the markers. Do not rewrite or embellish the prompt. "
        + ("Use the attached image(s) only as style reference. " if refs else "")
        + f"Then copy the generated file to {out}. Your final reply must be ONLY the exact prompt text "
        "you passed to the image tool, verbatim, so it can be audited.\n"
        "<<<PROMPT\n" + prompt + "\nPROMPT>>>"
    )
    last = out.with_suffix(".tool_prompt.txt")
    cmd = ["codex", "exec", "--skip-git-repo-check", "-m", GPT_MODEL, "-c", "model_reasoning_effort=low",
           "-C", str(out.parent), "-o", str(last)]
    cmd.append(instr)  # prompt BEFORE -i: `-i <FILE>...` is variadic and would swallow it
    for r in refs:
        cmd += ["-i", str(r)]
    for attempt in range(3):  # parallel codex sessions occasionally fail transiently
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=600, stdin=subprocess.DEVNULL)
        if r.returncode == 0 and out.exists():
            break
        time.sleep(5 + 10 * attempt)
    else:
        raise RuntimeError(f"codex exit {r.returncode}: {(r.stderr or r.stdout)[-400:]}")
    return f"codex:{GPT_MODEL}/image_generation"


def to_jpeg(src: Path, dst: Path) -> None:
    from PIL import Image

    im = Image.open(src).convert("RGB")
    im.thumbnail((1280, 1280))
    im.save(dst, "JPEG", quality=85, optimize=True)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", required=True)
    ap.add_argument("--era", default="e1919")
    ap.add_argument("--styles", required=True)
    ap.add_argument("--subject", required=True)
    ap.add_argument("--gens", default="gemini,gpt")
    ap.add_argument("--n", type=int, default=1)
    ap.add_argument("--ref", action="append", default=[])
    ap.add_argument("--extra", default="")
    ap.add_argument("--tag", default="", help="suffix for image ids, e.g. a prompt-revision label")
    ap.add_argument("--reuse-raw", action="store_true", help="re-log existing _raw PNGs instead of regenerating")
    a = ap.parse_args()

    run = ART / "runs" / a.run
    raw = run / "_raw"
    raw.mkdir(parents=True, exist_ok=True)
    refs = [Path(r).resolve() for r in a.ref]
    subjects = load(ART / f"prompts/{a.era}/subjects.toml")
    aspect = "16:9" if subjects[a.subject].get("kind") == "keyframe" else "1:1"

    jobs = []
    for style in a.styles.split(","):
        prompt, versions = compose(a.era, style, a.subject, a.extra)
        for g in a.gens.split(","):
            for i in range(a.n):
                iid = f"{a.subject}-{style.split('_')[0]}-{g}-{i + 1}{('-' + a.tag) if a.tag else ''}"
                jobs.append((iid, style, g, prompt, versions))

    def work(job):
        iid, style, g, prompt, versions = job
        png = raw / f"{iid}.png"
        t0 = time.time()
        try:
            reused = a.reuse_raw and png.exists()
            if reused:
                model = GEMINI_MODEL if g == "gemini" else f"codex:{GPT_MODEL}/image_generation"
            else:
                model = (gen_gemini if g == "gemini" else gen_gpt)(prompt, refs, aspect, png)
            to_jpeg(png, run / f"{iid}.jpg")
        except Exception as e:  # keep the batch going; failures are logged too
            body = e.read()[:300].decode(errors="replace") if hasattr(e, "read") else ""
            return {"id": iid, "ok": False, "error": (str(e) + " " + body)[:500], "generator": g, "style": style}
        return {
            "id": iid, "ok": True, "file": f"{iid}.jpg", "generator": g, "model": model,
            "era": a.era, "style": style, "subject": a.subject, "versions": versions,
            "refs": [str(r.relative_to(ART.parent)) if r.is_relative_to(ART.parent) else r.name for r in refs],
            "extra": a.extra, "aspect": aspect, "prompt": prompt,
            # What the Codex agent actually sent to the image tool (r01 finding: it may paraphrase).
            "tool_prompt": (png.with_suffix(".tool_prompt.txt").read_text().strip()
                            if png.with_suffix(".tool_prompt.txt").exists() else None),
            "seconds": None if reused else round(time.time() - t0, 1),
            "raw_sha256": hashlib.sha256(png.read_bytes()).hexdigest(),
            "created": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        }

    with ThreadPoolExecutor(max_workers=int(os.environ.get("E1919_GEN_WORKERS", "4"))) as ex:
        results = list(ex.map(work, jobs))
    with open(run / "manifest.jsonl", "a") as f:
        for r in results:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
            print(("OK  " if r["ok"] else "ERR ") + r["id"] + (f"  {r.get('seconds')}s" if r["ok"] else f"  {r['error']}"))
    return 0 if all(r["ok"] for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
