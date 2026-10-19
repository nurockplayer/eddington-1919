#!/bin/sh
# Capture the in-game benchmark (G4) for any git ref, e.g. the last release, so a
# change can be compared against it with art/pipeline/compare.py.
#   art/pipeline/baseline.sh <git-ref> <out-dir> [seed]
# Uses a detached temporary worktree, copies the CURRENT tests/benchmark.gd into
# it (so both runs use identical bookmarks), and injects the --benchmark hook if
# that ref predates it.
set -eu
REF=$1; OUT=$(cd "$(dirname "$2")" && pwd)/$(basename "$2"); SEED=${3:-7}
ROOT=$(git rev-parse --show-toplevel)
WT=$(mktemp -d)/wt
git -C "$ROOT" worktree add -q --detach "$WT" "$REF"
trap 'git -C "$ROOT" worktree remove --force "$WT"' EXIT
cp "$ROOT/tests/benchmark.gd" "$WT/tests/benchmark.gd"
if ! grep -q 'has("benchmark")' "$WT/scripts/main.gd"; then
  python3 - "$WT/scripts/main.gd" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1]); s = p.read_text()
hook = '''	if args.has("benchmark"):
		var bench: Node = load("res://tests/benchmark.gd").new()
		bench.main = self
		bench.out_dir = args.benchmark
		add_child(bench)
		return
'''
p.write_text(s.replace('\tif args.has("autoplay"):', hook + '\tif args.has("autoplay"):', 1))
PY
fi
godot --headless --path "$WT" --import >/dev/null 2>&1 || true
rm -rf "$OUT"
godot --path "$WT" --always-on-top -- --benchmark="$OUT" --seed="$SEED" 2>&1 | grep -E '\[BENCH\] done|ERROR' || true
