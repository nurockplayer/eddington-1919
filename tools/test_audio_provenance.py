#!/usr/bin/env python3
"""audio_provenance passes on this repo and fails on a lost row or changed bytes:
python3 -I tools/test_audio_provenance.py (works on temp copies; touches nothing tracked)"""
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCES = ROOT / "docs/audio/SOURCES.md"
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "tools"))
import audio_provenance


def errors(root=ROOT, sources=SOURCES):
    return audio_provenance.audit(root, sources)[1]


# Exercise the actual command on the head as well as the audit API below.
started = time.monotonic()
head = subprocess.run([sys.executable, "-I", str(ROOT / "tools/audio_provenance.py")],
                      capture_output=True, text=True)
assert head.returncode == 0, head.stdout + head.stderr
print(head.stdout, end="")

with tempfile.TemporaryDirectory() as folder:
    scratch = Path(folder)

    # A SOURCES.md without one File row, or without one Generator row, fails on that key.
    text = SOURCES.read_text(encoding="utf-8")
    for key in ("assets/sfx/bed_surf.ogg", "scripts/player.gd::_synth_step"):
        lines = text.splitlines(keepends=True)
        kept = [line for line in lines if not line.startswith(f"| `{key}` |")]
        assert len(kept) == len(lines) - 1, key
        cut = scratch / "SOURCES.md"
        cut.write_text("".join(kept), encoding="utf-8")
        found = errors(sources=cut)
        assert len(found) == 1 and found[0].startswith(key + ":") and "has no" in found[0], found

    # A copy of every shipped file passes until one audio file's bytes change.
    project = scratch / "project"
    shipped, _ = audio_provenance.shipped(ROOT)
    for path in [*shipped, "export_presets.cfg"]:
        (project / path).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ROOT / path, project / path)
    assert errors(project) == [], errors(project)
    changed = project / "assets/music/departure_motif.ogg"
    data = bytearray(changed.read_bytes())
    data[len(data) // 2] ^= 1
    changed.write_bytes(bytes(data))
    found = errors(project)
    assert len(found) == 1 and found[0].startswith("assets/music/departure_motif.ogg: SHA-256 is"), found
    shutil.copyfile(ROOT / "assets/music/departure_motif.ogg", changed)

    # The export filters decide what ships: an unrecorded file under the excluded
    # tests/ passes, the same file under assets/ fails, and excluding assets/sfx/
    # leaves its three rows with nothing shipped behind them.
    stray = project / "tests/stray.wav"
    stray.parent.mkdir()
    shutil.copyfile(ROOT / "assets/sfx/bed_surf.ogg", stray)
    assert errors(project) == [], errors(project)
    stray.rename(project / "assets/stray.wav")
    found = errors(project)
    assert len(found) == 1 and found[0].startswith("assets/stray.wav: shipped by macOS"), found
    (project / "assets/stray.wav").unlink()
    presets = project / "export_presets.cfg"
    presets.write_text(presets.read_text(encoding="utf-8").replace(
        'exclude_filter="tests/*,', 'exclude_filter="assets/sfx/*, tests/*,'), encoding="utf-8")
    found = errors(project)
    assert sorted(found) == [f"assets/sfx/bed_{name}.ogg: recorded in {SOURCES} but no export preset ships it"
                             for name in ("birds", "insects", "surf")], found

    # A newly added direct synthesiser also needs a Generator row.
    synth = project / "scripts/new_sound.gd"
    synth.write_text("extends Node\nfunc beep():\n\tvar wav = AudioStreamWAV.new()\n"
                     "\twav.data = PackedByteArray([0, 1])\n\treturn wav\n", encoding="utf-8")
    found = errors(project)
    assert any(error.startswith("scripts/new_sound.gd::beep: synthesises sound at runtime") for error in found), found

print(f"test_audio_provenance: OK (8 cases, {time.monotonic() - started:.2f}s)")
