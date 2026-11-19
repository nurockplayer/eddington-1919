#!/bin/bash
# One run (from the worktree root):
# job-run --id sa-row2 -- tachi-run --heavy --host -- tools/style_motion.sh <out>/day day [--style-set=line_px=5,wash=0.35]
# Use a fresh output folder and job id for another run; state is day or totality.
# 960 unscaled frames: 10 s at WALK, then a 6 s clockwise turn; fixed 60 Hz.
# Pixel change: any RGB channel differs by >10% of full scale (alpha ignored).
# sim_s is the end of each 1/60 s interval. Wind stays live; totality cloud time
# starts at 215 and advances at play's TIME_SCALE; daytime starts at -150, 1x.
set -euo pipefail
out=$1
state=$2
shift 2
case "$state" in day|totality) ;; *) echo 'state must be day or totality' >&2; exit 2 ;; esac
# Never overwrite a prior capture.
mkdir "$out"
out=$(cd "$out" && pwd)
exec > >(tee "$out/run.log") 2>&1
export TZ=Asia/Tokyo
printf 'START %s\n' "$(date '+%F %T %Z')"
printf 'COMMAND tools/style_motion.sh %q %q' "$out" "$state"
printf ' %q' "$@"
printf '\n'
# Keep logs and transient files inside the capture folder; disable user shader
# cache writes for this invocation, without changing the project's defaults.
mkdir -p "$out/runtime" "$out/runtime/tmp"
[ ! -e override.cfg ] || { echo 'override.cfg already exists; preserve it' >&2; exit 1; }
printf '[rendering]\nshader_compiler/shader_cache/enabled=false\n' > override.cfg
trap 'rm -f override.cfg; rm -r "$out/runtime"; printf "END %s\\n" "$(date "+%F %T %Z")"' EXIT
export TMPDIR="$out/runtime/tmp"
lighting=prep_early
[ "$state" != totality ] || lighting=totality
godot --path . --resolution 1280x720 --fixed-fps 60 --always-on-top --log-file "$out/runtime/godot.log" -- \
  --benchmark="$out" --bench-motion="$lighting" --bench-size=1280x720 --bench-cloud-t=215 --seed=7 "$@"
python3 -I tools/style_motion_stats.py "$out"
if command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -nostdin -hide_banner -loglevel warning -framerate 60 -start_number 1 -i "$out/f_%05d.png" \
    -frames:v 960 -c:v libx264 -preset slow -crf 10 -pix_fmt yuv420p -movflags +faststart "$out/motion.mp4"
else
  echo 'ffmpeg not installed; motion.mp4 omitted; nothing installed'
fi
magick identify "$out/f_00001.png" "$out/f_00960.png"
magick "$out/f_00001.png" "$out/f_00960.png" -format 'nonblack mean=%[fx:mean] maximum=%[fx:maxima]\n' info:
if rg -n 'SHADER ERROR|SCRIPT ERROR|STYLE ERROR' "$out/runtime/godot.log"; then exit 1; fi
