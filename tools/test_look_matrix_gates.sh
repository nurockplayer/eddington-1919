#!/bin/sh
# Exercise the real runner with PATH stubs; no windowed Godot is launched.
set -eu
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir "$scratch/bin"
export MATRIX_EVENTS="$scratch/events"
export PATH="$scratch/bin:$PATH"
# An inherited override must not bypass the per-variant gate.
export WINDOWED_OK=1

cat > "$scratch/bin/heavy-window" <<'SH'
#!/bin/sh
echo gate >> "$MATRIX_EVENTS"
if [ "$(grep -c '^gate$' "$MATRIX_EVENTS")" -gt "$GATE_LIMIT" ]; then
  echo 'owner present'
  exit 1
fi
SH
cat > "$scratch/bin/godot" <<'SH'
#!/bin/sh
for arg do
  case "$arg" in
    --headless) exit 0 ;;
    --benchmark=*) out=${arg#--benchmark=} ;;
  esac
done
echo "run:${out##*/}" >> "$MATRIX_EVENTS"
mkdir -p "$out"
printf '%s\n' '{"bookmarks": [{"bookmark": "first"}]}' > "$out/benchmark.json"
if [ "${out##*/}" = failed ]; then exit 1; fi
SH
chmod +x "$scratch/bin/heavy-window" "$scratch/bin/godot"
sh -n "$scratch/bin/heavy-window"
sh -n "$scratch/bin/godot"
printf 'alpha\t\nbeta\t\n' > "$scratch/variants.tsv"
export GATE_LIMIT=1
if bash tools/look_matrix.sh "$scratch/closed" "$scratch/variants.tsv" > "$scratch/closed.log" 2>&1; then
  echo 'FAIL: a closed gate returned success' >&2
  exit 1
fi
printf 'gate\nrun:alpha\ngate\n' > "$scratch/expected"
cmp "$scratch/expected" "$MATRIX_EVENTS"
grep -q 'heavy gate closed before beta: owner present' "$scratch/closed.log"
test -f "$scratch/closed/alpha/benchmark.json"
test ! -e "$scratch/closed/beta"
grep -q '^alpha' "$scratch/closed/stats.tsv"

# Reuse must fail before any invocation, preserving the old result.
if bash tools/look_matrix.sh "$scratch/closed" "$scratch/variants.tsv" > "$scratch/reuse.log" 2>&1; then
  echo 'FAIL: an existing output directory was accepted' >&2
  exit 1
fi
grep -q 'output path already exists' "$scratch/reuse.log"
cmp "$scratch/expected" "$MATRIX_EVENTS"
test -f "$scratch/closed/alpha/benchmark.json"

# A failed variant can leave JSON behind; it must stay out of stats.
: > "$MATRIX_EVENTS"
export GATE_LIMIT=3
printf 'alpha\t\nfailed\t\nbeta\t\n' > "$scratch/variants.tsv"
if bash tools/look_matrix.sh "$scratch/mixed" "$scratch/variants.tsv" > "$scratch/mixed.log" 2>&1; then
  echo 'FAIL: a failed variant returned success' >&2
  exit 1
fi
printf 'gate\nrun:alpha\ngate\nrun:failed\ngate\nrun:beta\n' > "$scratch/expected"
cmp "$scratch/expected" "$MATRIX_EVENTS"
test -f "$scratch/mixed/failed/benchmark.json"
grep -q '^alpha' "$scratch/mixed/stats.tsv"
grep -q '^beta' "$scratch/mixed/stats.tsv"
if grep -q '^failed' "$scratch/mixed/stats.tsv"; then
  echo 'FAIL: failed variant included in stats' >&2
  exit 1
fi
echo 'look matrix gates: PASS'
