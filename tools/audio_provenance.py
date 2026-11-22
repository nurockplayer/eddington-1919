#!/usr/bin/env python3
"""Audit audio provenance: every sound the release ships against docs/audio/SOURCES.md.

Shipped audio files are found the way Godot's export finds them for each preset
in export_presets.cfg (all resources, then include_filter, then exclude_filter).
Runtime synthesis is found in the shipped GDScript: every function that turns
computed samples into an AudioStreamWAV, or feeds an AudioStreamGenerator.

    python3 -I tools/audio_provenance.py [--root DIR] [--sources FILE]

Prints the audit (one line per file and per synthesis entry point) and exits 1
with a FAIL line for each file or entry point missing from SOURCES.md, each
hash mismatch, and each SOURCES.md row with nothing shipped behind it.
"""

import argparse
import hashlib
import os
import re
import sys
from pathlib import Path

AUDIO_EXTENSIONS = {".ogg", ".wav", ".mp3"}
FILE_COLUMNS = ["File", "Source", "Author", "Licence class", "SHA-256"]
GENERATOR_COLUMNS = ["Generator", "Sounds", "Author", "Licence class"]
CC0_CLASSES = {"CC0 1.0", "Original + CC0 1.0 samples"}
NON_CC0 = "Public domain, not CC0"
LICENCE_CLASSES = CC0_CLASSES | {"Original", NON_CC0}


def presets(root):
    """Name, export_filter, include_filter and exclude_filter of every [preset.N]."""
    found, current = [], None
    for line in (root / "export_presets.cfg").read_text(encoding="utf-8").splitlines():
        section = re.fullmatch(r"\[(.+)\]", line.strip())
        if section:
            current = {} if re.fullmatch(r"preset\.\d+", section.group(1)) else None
            if current is not None:
                found.append(current)
            continue
        value = re.fullmatch(r'(name|export_filter|include_filter|exclude_filter)="(.*)"', line.strip())
        if current is not None and value:
            current[value.group(1)] = value.group(2)
    return found


def project_files(root):
    """Paths Godot's file system sees: no hidden entries, no .gdignore or nested project folders."""
    for folder, dirs, files in os.walk(root):
        dirs[:] = sorted(
            d for d in dirs
            if not d.startswith(".")
            and not (Path(folder, d) / ".gdignore").exists()
            and not (Path(folder, d) / "project.godot").exists()
        )
        for name in sorted(files):
            if not name.startswith("."):
                yield Path(folder, name).relative_to(root).as_posix()


def matches(path, patterns):
    """Godot's String.matchn against the path with and without res://: * and ? only, any case."""
    for pattern in (p.strip() for p in patterns.split(",")):
        if not pattern:
            continue
        regex = "".join(".*" if c == "*" else "." if c == "?" else re.escape(c) for c in pattern)
        if any(re.fullmatch(regex, p, re.IGNORECASE | re.DOTALL) for p in (path, "res://" + path)):
            return True
    return False


def shipped(root):
    """{path: [preset names]} for every file some preset exports, plus any error."""
    files = list(project_files(root))
    result, errors = {}, []
    for preset in presets(root):
        name = preset.get("name", "?")
        if preset.get("export_filter") != "all_resources":
            errors.append(f'preset "{name}": export_filter "{preset.get("export_filter")}" is not '
                          "all_resources; the audit only models that mode")
            continue
        for path in files:
            # all_resources exports every resource; only audio and scripts matter here.
            resource = Path(path).suffix.lower() in AUDIO_EXTENSIONS or path.endswith(".gd")
            if (resource or matches(path, preset.get("include_filter", ""))) \
                    and not matches(path, preset.get("exclude_filter", "")):
                result.setdefault(path, []).append(name)
    return result, errors


def code(line):
    """A GDScript line without string contents or comment."""
    line = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', '""', line)
    return line.split("#", 1)[0]


def functions(text):
    """(name, parameter names, body lines) for every func in a GDScript source."""
    lines = [code(line).expandtabs(4) for line in text.splitlines()]
    found = []
    for i, line in enumerate(lines):
        head = re.match(r"( *)(?:static\s+)?func\s+(\w+)\s*\(([^)]*)", line)
        if not head:
            continue
        indent = len(head.group(1))
        params = [re.match(r"\s*(\w*)", p).group(1) for p in head.group(3).split(",")]
        body = []
        for next_line in lines[i + 1:]:
            if next_line.strip() and len(next_line) - len(next_line.lstrip()) <= indent:
                break
            body.append(next_line)
        found.append((head.group(2), [p for p in params if p], body))
    return found


def first_arguments(body, names):
    """(callee, first argument text) for each call to one of names in body."""
    calls = []
    joined = "\n".join(body)
    for call in re.finditer(r"(?<!\w)(" + "|".join(map(re.escape, names)) + r")\s*\(", joined):
        depth, start = 0, call.end()
        for j in range(start, len(joined)):
            c = joined[j]
            if c in "([{":
                depth += 1
            elif c in ")]}" and depth:
                depth -= 1
            elif c in ",)" and not depth:
                calls.append((call.group(1), joined[start:j].strip()))
                break
    return calls


def generators(root, scripts):
    """Sorted "script::function" for every function that synthesises sound.

    A converter makes an AudioStreamWAV from a sample-array parameter; a wrapper
    forwards a parameter to a converter. Direct WAV synthesis, other callers of
    converters, and AudioStreamGenerator users are synthesis entry points.
    """
    funcs = {}
    for script in scripts:
        for name, params, body in functions((root / script).read_text(encoding="utf-8")):
            funcs[(script, name)] = (params, body)
    direct = {key for key, (_, body) in funcs.items() if re.search(r"AudioStreamWAV\s*\.\s*new\s*\(", "\n".join(body))}
    makers = {
        key for key in direct
        if re.search(r"func\s+" + re.escape(key[1]) + r"\s*\(\s*\w+\s*:\s*Packed(?:Float32|Byte)Array",
                     (root / key[0]).read_text(encoding="utf-8"))
    }
    while True:
        names = {name for _, name in makers}
        wrappers = {
            key for key, (params, body) in funcs.items()
            if key not in makers and any(arg in params for _, arg in first_arguments(body, names))
        }
        if not wrappers:
            break
        makers |= wrappers
    names = {name for _, name in makers}
    return sorted(
        f"{script}::{name}" for (script, name), (_, body) in funcs.items()
        if (script, name) not in makers
        and ((script, name) in direct or first_arguments(body, names) or "AudioStreamGenerator" in "\n".join(body))
    )


def records(text):
    """File and Generator rows of SOURCES.md, each with its ## section."""
    rows, section, header = [], "", None
    for line in text.splitlines():
        if line.startswith("## "):
            section = line[3:].strip()
        if not line.startswith("|"):
            header = None
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            header = cells
        elif not set(line) <= set("|-: ") and header[0] in ("File", "Generator"):
            row = dict(zip(header, cells))
            row["section"] = section
            row["kind"] = header[0]
            rows.append(row)
    return rows


def audit(root, sources):
    """(report lines, error lines) for the project at root against the SOURCES.md at sources."""
    root = Path(root)
    report = []
    files, errors = shipped(root)
    audio = {path: names for path, names in files.items() if Path(path).suffix.lower() in AUDIO_EXTENSIONS}
    synth = generators(root, [path for path in files if path.endswith(".gd")])
    rows = records(Path(sources).read_text(encoding="utf-8"))
    recorded = {}
    for row in rows:
        key = row[row["kind"]].strip("`")
        if key in recorded:
            errors.append(f"{key}: recorded twice in {sources}")
        recorded[key] = row
        columns = FILE_COLUMNS if row["kind"] == "File" else GENERATOR_COLUMNS
        for column in columns:
            if not row.get(column):
                errors.append(f'{key}: empty or missing "{column}" in {sources}')
        if row.get("Licence class") and row["Licence class"] not in LICENCE_CLASSES:
            errors.append(f'{key}: unknown licence class "{row["Licence class"]}" '
                          f"(one of: {', '.join(sorted(LICENCE_CLASSES))})")
    classes = {}
    for row in rows:
        classes.setdefault(row["section"], set()).add(row.get("Licence class"))
    for section, found in classes.items():
        if NON_CC0 in found and found & CC0_CLASSES:
            errors.append(f'section "{section}" lists CC0 and non-CC0 sounds together; keep them apart')

    for path in sorted(audio):
        row = recorded.get(path)
        if row is None:
            errors.append(f"{path}: shipped by {', '.join(audio[path])} but has no File row in {sources}")
            continue
        digest = hashlib.sha256((root / path).read_bytes()).hexdigest()
        if digest != row.get("SHA-256", "").strip("`"):
            errors.append(f"{path}: SHA-256 is {digest}, {sources} records {row.get('SHA-256')}")
        report.append(f"file   {path}  sha256 {digest}  [{row.get('Licence class')}]  {row.get('Author')}")
    for entry in synth:
        row = recorded.get(entry)
        if row is None:
            errors.append(f"{entry}: synthesises sound at runtime but has no Generator row in {sources}")
            continue
        report.append(f"synth  {entry}  [{row.get('Licence class')}]  {row.get('Sounds')}")
    for key, row in sorted(recorded.items()):
        if row["kind"] == "File" and key not in audio:
            errors.append(f"{key}: recorded in {sources} but no export preset ships it")
        if row["kind"] == "Generator" and key not in synth:
            errors.append(f"{key}: recorded in {sources} but no shipped script synthesises sound there")
    report.append(f"{len(audio)} shipped audio files, {len(synth)} synthesis entry points")
    return report, errors


def main(argv):
    root_default = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=root_default, help="Godot project folder")
    parser.add_argument("--sources", type=Path, help="provenance record (default ROOT/docs/audio/SOURCES.md)")
    args = parser.parse_args(argv)
    report, errors = audit(args.root, args.sources or args.root / "docs/audio/SOURCES.md")
    print("\n".join(report))
    for error in errors:
        print("FAIL: " + error, file=sys.stderr)
    print("audio provenance: " + ("FAILED" if errors else "OK"))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
