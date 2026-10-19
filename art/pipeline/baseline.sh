#!/bin/sh
# Capture the in-game benchmark (G4) for any git ref, e.g. the last release, so a
# change can be compared against it with art/pipeline/compare.py.
#   art/pipeline/baseline.sh <git-ref> art/validation/<name> [seed]
# Uses a detached temporary worktree, copies the CURRENT tests/benchmark.gd into
# it (so both runs use identical bookmarks), and injects the --benchmark hook if
# that ref predates it. Captures into a fresh temp dir and only replaces <out>
# after the run produced benchmark.json; exits non-zero otherwise.
set -eu
REF=$1; SEED=${3:-7}
ROOT=$(git rev-parse --show-toplevel)
case "$2" in
  art/validation/?*) OUT="$ROOT/$2" ;;
  *) echo "out dir must be art/validation/<name> (relative to the repo root)" >&2; exit 2 ;;
esac
case "$2" in *..*) echo "no '..' in out dir" >&2; exit 2 ;; esac
TMP=$(mktemp -d)
WT=$TMP/wt
git -C "$ROOT" worktree add -q --detach "$WT" "$REF"
trap 'git -C "$ROOT" worktree remove --force "$WT"; rm -rf "$TMP"' EXIT
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
assert '\tif args.has("autoplay"):' in s, "unexpected main.gd at this ref"
p.write_text(s.replace('\tif args.has("autoplay"):', hook + '\tif args.has("autoplay"):', 1))
PY
fi
godot --headless --path "$WT" --import >"$TMP/import.log" 2>&1 || { cat "$TMP/import.log" >&2; exit 1; }
godot --path "$WT" --always-on-top -- --benchmark="$TMP/out" --seed="$SEED" >"$TMP/bench.log" 2>&1 || true
if [ ! -s "$TMP/out/benchmark.json" ]; then
  echo "benchmark produced no benchmark.json; log:" >&2; tail -20 "$TMP/bench.log" >&2; exit 1
fi
rm -rf "$OUT"
mkdir -p "$(dirname "$OUT")"
mv "$TMP/out" "$OUT"
echo "baseline for $REF -> $OUT"
