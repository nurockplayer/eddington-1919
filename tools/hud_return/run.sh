#!/bin/bash
# Run from the worktree root through job-run.
set -euo pipefail

pr=$1
head_sha=$(git rev-parse HEAD)
main_sha=$(git rev-parse 58b91640^)
base="/Volumes/KIOXIA/eddington-1919-cache/director/accept/$pr"
mkdir -p "$base/$head_sha"
head_out=$(mktemp -d "$base/$head_sha/attempt.XXXXXXXX")
main_out="$head_out/pre-fix-main/$main_sha"
revert_out="$head_out/reverted"
project=$PWD
capture="$project/tools/hud_return/capture.gd"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/hud-return.XXXXXX")
trap 'trash "$scratch"' EXIT
mkdir -p "$main_out" "$revert_out" "$scratch/main" "$scratch/revert"

nice -n 15 git archive "$main_sha" | nice -n 15 tar -xf - -C "$scratch/main"
nice -n 15 git archive "$head_sha" | nice -n 15 tar -xf - -C "$scratch/revert"
nice -n 15 git diff "$main_sha" 58b91640 -- scripts/hud_paper.gd |
    nice -n 15 git -C "$scratch/revert" apply --reverse

capture_pass() {
    local source=$1 out=$2 label=$3
    local scale mode settings attempt
    local -a expect
    printf '%s\n' "$pr" > "$out/.archive-pr"
    {
        printf '# #549 · %s\n\n' "$label"
        printf 'Seed 1551, totality_live, 1280×720 at 60 fps, zh_TW, reduced motion off.\n'
        printf 'C3 is frame zero. Each scale retains all 601 frames through C3+10 s.\n\n'
        printf 'The unrecorded preparation starts at its final second. Both contacts and the full totality clock run normally.\n\n'
    } > "$out/index.md"
    if [[ "$out" == "$head_out" ]]; then
        printf 'First capture list at C3+6 s, scale 1.0: [clear](1.0/clear-c3-plus6.png), [thin](1.0/thin-c3-plus6.png), [thick](1.0/thick-c3-plus6.png).\n\n' >> "$out/index.md"
    fi
    for scale in 1.0 1.2; do
        settings="$out/settings-$scale.cfg"
        cat > "$settings" <<SETTINGS
[ui]
language="zh_TW"
text_scale=$scale
reduced_motion=false
[video]
quality="standard"
fullscreen=false
SETTINGS
        mode=sequence
        if [[ "$out" == "$head_out" && "$scale" == 1.0 ]]; then mode=clouds; fi
        expect=(--expect '601:f_*.png' --expect 1:receipts.json)
        if [[ "$mode" == clouds ]]; then expect+=(--expect '3:*-c3-plus6.png'); fi
        local -a cmd=(
            env EDD_LOCALE=zh_TW tachi-run --heavy --host --
            bash -c '"$@" > "$0"' "$scratch/capture-result"
            "$HOME/.local/bin/python3" "$project/tools/windowed_capture.py"
            --project "$source" --settings "$settings" --wall-seconds 650 --first-frame-seconds 60
            --engine-arg=--audio-driver --engine-arg=Dummy "${expect[@]}"
            "$out/attempts-$scale" "$capture" -- "$scale" "$mode"
        )
        {
            printf '## Text scale %s\n\n' "$scale"
            printf '[PNG frames](%s/) · [Frame receipts and JST times](%s/receipts.json) · [Per-frame measurements](%s/measurements.csv)\n\n' "$scale" "$scale" "$scale"
            printf '```sh\n'
            printf '%q ' "${cmd[@]}"
            printf '\n```\n\n'
        } >> "$out/index.md"
        "${cmd[@]}"
        IFS= read -r attempt < "$scratch/capture-result"
        ln -s "$attempt" "$out/$scale"
    done
}

capture_pass "$project" "$head_out" "Candidate $head_sha"
capture_pass "$scratch/main" "$main_out" "Pre-fix main $main_sha"
capture_pass "$scratch/revert" "$revert_out" "Candidate with the HUD palette change reversed"
{
    printf '## Comparison\n\n'
    printf '[Pre-fix main](pre-fix-main/%s/index.md) · [Revert](reverted/index.md)\n\n' "$main_sha"
    printf 'The revert reverses only the palette patch to scripts/hud_paper.gd from #559 on the candidate.\n\n'
    printf 'Indexed %s.\n\n' "$(TZ=Asia/Tokyo date '+%F %H:%M:%S %Z')"
} >> "$head_out/index.md"
nice -n 15 "$HOME/.local/bin/python3" tools/hud_return/measure.py "$main_out" "$head_out" "$revert_out"
cat "$head_out/summary.md" >> "$head_out/index.md"
printf 'Capture index %s\n' "$head_out/index.md"
