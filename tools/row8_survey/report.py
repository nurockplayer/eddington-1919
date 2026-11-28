import collections
import csv
import json
import math
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw

from contrast import measure

out = Path(sys.argv[1])
capture_sha = sys.argv[2] if len(sys.argv) > 2 else out.name
commands = dict(line.split("\t", 1) for line in (out / "commands.tsv").read_text().splitlines())
files = sorted(out.glob("receipts-*.jsonl"))
rows = [json.loads(line) for f in files for line in f.read_text().splitlines()]


def contrast(fg, bg, repeat, bounds):
    x0, y0, x1, y1 = bounds
    box = max(x0, 0), max(y0, 0), min(x1, fg.width), min(y1, fg.height)
    if box[2] <= box[0] or box[3] <= box[1]:
        return None
    rasters = [image.crop(box).get_flattened_data() for image in (fg, bg, repeat)]
    sample = measure(*rasters, box[2] - box[0])
    if sample is None:
        return None
    ratio, ink, paper, (x, y), count = sample
    return ratio, ink, paper, (x + box[0], y + box[1]), count


def prefix(r):
    return f'{r["config"]} {r["state"]} {r["case"]}'


def clean(s):
    return str(s).replace("|", "&#124;").replace("\n", " ").replace("\r", " ")


def link(r, field="frame", label="frame"):
    return f'[{label}]({r[field]})' if r.get(field) else "—"


frames = [r["frame"] for r in rows if r.get("frame")]
if len(set(frames)) != len(frames):
    raise SystemExit("Duplicate whole-frame paths in receipts")
for r in rows:
    if r.get("frame"):
        for key in ("frame", "crop", "background", "repeat"):
            if r.get(key) and not (out / r[key]).is_file():
                raise SystemExit(f"Missing {key} file: {r[key]}")
        r["command"] = commands.get(r["config"], "")
        r["sha"] = capture_sha

minima = {}
numeric_fails = []
contrast_fails = []
additional_gaps = []
with (out / "contrast.tsv").open("w", newline="") as report:
    writer = csv.writer(report, delimiter="\t")
    writer.writerow(["config","state","case","frame","surface","ratio","ink_rgb","paper_rgb","xy","components","node","text"])
    for r in rows:
        by_surface = collections.defaultdict(list)
        if r.get("background"):
            fg = Image.open(out/r["frame"]).convert("RGB")
            bg = Image.open(out/r["background"]).convert("RGB")
            repeat = Image.open(out/r["repeat"]).convert("RGB")
            for t in r["text"]:
                sample = contrast(fg,bg,repeat,t["rect"])
                writer.writerow([r["config"],r["state"],r["case"],r["frame"],t["surface"],
                                 *((sample or ("","","","",""))),t["node"],t["text"]])
                if sample is not None:
                    by_surface[t["surface"]].append(sample)
                    if sample[0] < 4.5:
                        excerpt = " ".join(t["text"].split())
                        if len(excerpt) > 90:
                            excerpt = excerpt[:87] + "..."
                        contrast_fails.append(
                            f'{prefix(r)} / {t["surface"]} / {excerpt} ({sample[0]:.3f}:1) {link(r)}'
                        )
        r["minima"] = {s:min(samples) for s,samples in by_surface.items()}
        for surface, sample in r["minima"].items():
            key = r["config"],r["state"],surface
            if key not in minima or sample[0] < minima[key][0]:
                minima[key] = sample[0],r
        for surface in {t["surface"] for t in r.get("text", [])} - r["minima"].keys():
            additional_gaps.append(f"{prefix(r)} / {surface}: no differing glyph pixels in the visible bounds.")
        if r["clause"] == "text" and r.get("frame") and not r.get("text"):
            additional_gaps.append(f"{prefix(r)}: no visible text controls for pixel measurement.")
        if r["clause"] == "interactables" and r.get("frame") and abs(r["distance_m"]-3.0) > .01:
            numeric_fails.append(f'{prefix(r)} ({r["distance_m"]:.3f} m)')
        if r["clause"] == "faces" and r.get("frame") and not r.get("crop"):
            additional_gaps.append(f"{prefix(r)}: face crop fell outside the frame.")

with (out / "receipts.jsonl").open("w") as f:
    for r in rows:
        f.write(json.dumps(r,ensure_ascii=False)+"\n")


def sheet_pages(clause, source):
    paths = []
    columns, per_page, w, h = 4, 20, 384, 216
    for offset in range(0,len(source),per_page):
        page = source[offset:offset+per_page]
        im = Image.new("RGB",(w*columns,(h+26)*math.ceil(len(page)/columns)),"#eee6d4")
        draw = ImageDraw.Draw(im)
        for i,r in enumerate(page):
            x,y = i%columns*w,i//columns*(h+26)
            with Image.open(out/r["frame"]) as frame:
                im.paste(frame.convert("RGB").resize((w,h),Image.Resampling.LANCZOS),(x,y+26))
            draw.text((x+5,y+6),prefix(r),fill="#211d17")
        filename = f"sheets/{clause}-{offset//per_page+1:02d}.jpg"
        im.save(out/filename,quality=89)
        paths.append(f"[{offset//per_page+1}]({filename})")
    return " ".join(paths)


no_portraits = collections.defaultdict(set)
speakers = set()
audited = set()
for f in sorted(out.glob("dialogue-*.jsonl")):
    for line in f.read_text().splitlines():
        r = json.loads(line)
        speakers.add(r["speaker"])
        audit_case = r["speaker"],r["source"],r["line"],r["body"]
        audited.add(audit_case)
        if not r["portrait"]:
            no_portraits[audit_case].add(r["state"])

gaps = collections.defaultdict(list)
for r in rows:
    if r.get("gap"):
        gaps[r["case"],r["state"],r["gap"]].append(r["config"])
        if r.get("nearer_m"):
            numeric_fails.append(f'{prefix(r)} (3 m pose unavailable, closer ray at {r["nearer_m"]:.3f} m)')
completed_file = out / ".work/completed.txt"
completed = completed_file.read_text().splitlines() if completed_file.exists() else []
for config in sorted({"720-100","1080-100","720-120"} - set(completed)):
    additional_gaps.append(f"{config}: render process did not reach its completion marker. See the per-configuration log.")
for speaker in speakers - {r["speaker"] for r in rows if r.get("speaker") and r.get("frame")}:
    additional_gaps.append(f"{speaker}: appeared in audited dialogue but has no whole portrait-case frame.")

lines = [
    "# Slice row 8 survey",
    "",
    f"Frames captured at `{capture_sha}`. Seed 7, English, windowed, reduced motion off, journey flag off.",
    f"Report generated {datetime.now().astimezone().strftime('%Y-%m-%d %H:%M %Z')}.",
    f"Report command from the worktree: `nice -n 15 {sys.executable} tools/row8_survey/report.py {out} {capture_sha}`.",
    "",
    "## Text rows below 4.5:1",
    "",
]
lines += [f"- {item}" for item in contrast_fails] or ["- No measured text row fell below 4.5:1."]
lines += [
    "",
    "## Cases outside the 3 m threshold",
    "",
]
lines += [f"- {item}" for item in numeric_fails] or ["- No measured case fell outside the distance threshold."]
lines += ["", f"Portraits are absent on {len(no_portraits)} rendered line variants listed below.", "", "## Cases without the requested evidence", ""]
lines += [f"- {case} / {state} / {', '.join(configs)}. {reason}" for (case,state,reason),configs in gaps.items()]
lines += [f"- {item}" for item in additional_gaps]
lines += ["",
          "The totality strip and hold bar contain graphical marks without text. Their presence is recorded in the frame receipts.",
          "The nearest-face search sampled grounded capsule poses every 2.5° and 0.025 m across the front of the face. Distances are to the iris mesh landmark. Poses are collision-checked placements. A walking route to each one was not exercised.",
          f"Portrait audit checked {len(audited)} rendered sequence entries and branches. Alternate dialogue variants outside the staged sequences were not exhaustively enumerated.",
          "The 1.2 configuration repeats text surfaces. Standalone Príncipe is staged with completed Departure state for the loupe, workbook and coda. Menus and papers follow the game's own phase palette.",
          "",
          "Contrast uses rendered RGB and the [WCAG 2.2 formula](https://www.w3.org/TR/WCAG22/#dfn-contrast-ratio). The text-hidden frame supplies the local paper color. When hiding text removes the flat color covering at least two thirds of both text-on crops, the sampler uses that color from the visible frame. The restored frame rejects temporal changes. Each connected component contributes its strongest pixel pair. The report uses the lowest area-weighted lower quartile across the control and its word-sized runs, separated by gaps in the visible glyphs. This retains a short dim run in an otherwise stronger caption. Changing or nonuniform backgrounds can affect the estimate. Sample colors and coordinates are in [contrast.tsv](contrast.tsv).",
          "",
          "Camera, target, distance, phase, size, settings, rays and exact launch commands are in [receipts.jsonl](receipts.jsonl). Original PNGs are full frames. Crops are native pixels.",
          ""]
for clause,title in [("interactables","Interactables at 3 m"),("text","Text surfaces"),("drawn","Signs, Sun crescents and fireflies"),("faces","Closest face views"),("dialogue","Dialogue portraits")]:
    entries = [r for r in rows if r["clause"]==clause]
    source = [r for r in entries if r.get("frame")]
    lines += [f"## {title}", "", f'Contact sheets {sheet_pages(clause,source) or "—"}.', "",
              "| Case | Frame | Measured value | Status |", "|---|---|---|---|"]
    for r in entries:
        value, status = "—", "Art review"
        if r.get("gap"):
            value, status = r["gap"], "Unavailable"
            if r.get("nearer_m"):
                value += f' {r["nearer_m"]:.3f} m.'
        elif clause == "interactables":
            value = f'{r["distance_m"]:.3f} m, ray {r["ray_id"]}, prompt visible'
            status = "3 m pass, identifiability awaits art review" if abs(r["distance_m"]-3)<.011 else "3 m fail"
        elif clause == "text":
            value = ", ".join(f"{s} {m[0]:.3f}:1" for s,m in r["minima"].items()) or "No paired pixels"
            status = ("Pass" if min(m[0] for m in r["minima"].values()) >= 4.5 else "Fail") if r["minima"] else "Unmeasured"
            if r.get("strip_marker"):
                value += f'; strip {r["strip_marker"]}'
            if r.get("hold_visible"):
                value += f'; hold {r["hold_progress"]:.2f}'
        elif clause == "faces":
            value = f'{r["distance_m"]:.3f} m {link(r,"crop","native crop")}'
        elif clause == "dialogue":
            value = f'{r["speaker"]}, portrait {"visible" if r["portrait"] else "absent"}'
            status = "Art review" if r["portrait"] else "Fail"
        lines.append(f"| {prefix(r)} | {link(r)} | {clean(value)} | {status} |")
    if clause == "text":
        lines += ["", "### Lowest contrast per surface", "",
                  "| Configuration and state | Surface | Frame | Ratio | Status |","|---|---|---|---:|---|"]
        for (config,state,surface),(ratio,r) in sorted(minima.items()):
            lines.append(f'| {config} {state} | {surface} | {link(r)} | {ratio:.3f}:1 | {"Pass" if ratio >= 4.5 else "Fail"} |')
    lines.append("")
lines += ["### Authored line sites with no portrait mapping", "",
          "This source inventory covers conditional entries and templates that are absent from the rendered sample. The portrait lookup has no mapping for these speaker keys.", "",
          "| Source | Speaker key | Entry or template |", "|---|---|---|"]
sources = [
    Path("scripts/main.gd"), Path("scripts/content.gd"), Path("scripts/content_coda.gd"),
    Path("scripts/cambridge/content_departure.gd"),
]
unmapped_sites = 0
for path in sources:
    source = subprocess.check_output(
        ["git", "show", f"{capture_sha}:{path.as_posix()}"], text=True
    )
    for number, contents in enumerate(source.splitlines(), 1):
        if path.name == "content_departure.gd" and number < 174:
            continue
        match = re.search(r'\{"s": (.*?), "t": (.*)', contents)
        if match and match[1] not in {"E", "C", "Content.E", "Content.C"}:
            unmapped_sites += 1
            lines.append(f"| {path}:{number} | {clean(match[1])} | {clean(match[2])} |")
lines += ["", f"{unmapped_sites} source entries with no mapping.", "",
          "### Rendered lines with no engraved portrait", "",
          "| State | Speaker | Sequence and line | Text |", "|---|---|---|---|"]
for (speaker,source,line,body),states in sorted(no_portraits.items()):
    lines.append(f'| {", ".join(sorted(states))} | {clean(speaker)} | {source} {line} | {clean(body)} |')
(out / "index.md").write_text("\n".join(lines)+"\n")
print(f"Row 8 survey: {sum(bool(r.get('frame')) for r in rows)} whole frames, {len(contrast_fails)} text rows below 4.5:1, {len(numeric_fails)} distance failures, {len(no_portraits)} audited lines without portraits, {len(completed)}/3 render configurations complete.",flush=True)
if len(completed) != 3:
    sys.exit(1)
(out / ".archive-ready").touch()
