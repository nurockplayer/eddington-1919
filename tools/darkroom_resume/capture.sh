#!/bin/sh
set -eu
# Invoke only via job-run + tachi-run --heavy --host.
sha=$(rtk git rev-parse HEAD)
out="/Volumes/KIOXIA/eddington-1919-cache/director/accept/475/$sha"
mkdir -p "$out"
export EDD_TEST_DEADLINE=180
godot --headless --path . --check-only --script res://tools/darkroom_resume/capture.gd
{
  printf '# PR #475 — Continue capture pairs\n\nCandidate: `%s`\n\n' "$sha"
  printf 'Windowed real renderer, native PNGs, `--always-on-top --fixed-fps 60`.\n'
  printf 'Each before frame is immediately followed by process exit. The next process captures the cold title and presses its existing Continue button.\n'
  printf 'Seed 77; isolated settings/checkpoints; English default text, Korean maximum text (1.2).\n'
  printf 'Simulation equality is checked after Continue; JSON receipts accompany each PNG. edd-art acceptance is pending.\n\n'
  printf '| Locale / pixels | State | Just before quitting | Cold title | Right after Continue |\n| --- | --- | --- | --- | --- |\n'
} > "$out/index.md"
for config in en:1920:1080 en:1280:720 ko:1280:720; do
  locale=${config%%:*}
  size=${config#*:}
  width=${size%:*}
  height=${size#*:}
  label="$locale-${width}x$height"
  dir="$out/$label"
  mkdir -p "$dir"
  for stage in unlocked reselected; do
    export EDD_SETTINGS_PATH="$dir/$stage/settings.cfg"
    mkdir -p "$dir/$stage"
    for mode in before after; do
      godot --path . --windowed --resolution "${width}x$height" --always-on-top --fixed-fps 60 \
        --script res://tools/darkroom_resume/capture.gd -- "$dir" "$stage" "$mode" "$locale" "$width" "$height"
    done
    printf '| %s | %s | [before](%s/%s-before-quit.png) | [Continue](%s/%s-title-continue.png) | [after](%s/%s-after-continue.png) |\n' \
      "$label" "$stage" "$label" "$stage" "$label" "$stage" "$label" "$stage" >> "$out/index.md"
  done
done
printf '\nCaptured: %s\n' "$(date '+%F %H:%M %Z')" >> "$out/index.md"
printf 'Continue capture complete: 6 pairs, 6 title frames; %s/index.md\n' "$out"
