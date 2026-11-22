#!/bin/bash
# Dispatch, wait and download without a TTY. Run under job-run for long waits.
# Usage: tools/ci_capture.sh <ref> <out_dir> [views=... height=720 style_set=k=v,... cloud_t=215]
set -euo pipefail
[ "$#" -ge 2 ] || { echo "Usage: $0 <ref> <out_dir> [k=v ...]" >&2; exit 2; }
ref=$1
out=$2
shift 2
case "$out" in
  /Volumes/KIOXIA/*) ;;
  *) echo 'out_dir must be under /Volumes/KIOXIA/' >&2; exit 2 ;;
esac
mkdir -p "$out"
[ -z "$(ls -A "$out")" ] || { echo "out_dir must be empty: $out" >&2; exit 2; }
export GH_PROMPT_DISABLED=1 GH_PAGER=cat
repo=nurockplayer/eddington-1919
request_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
fields=(-f "ref=$ref" -f "request_id=$request_id")
for field in "$@"; do
  case "$field" in
    views=*|height=*|style_set=*|cloud_t=*) fields+=(-f "$field") ;;
    *) echo "Unknown input: $field" >&2; exit 2 ;;
  esac
done
dispatch=$(rtk gh workflow run visual-capture.yml --repo "$repo" --ref main "${fields[@]}")
printf '%s\n' "$dispatch"
# Current gh returns the run URL. Older gh can locate the exact request token;
# neither path selects a run by recency, actor, or a shared render ref.
run_url=$(printf '%s\n' "$dispatch" | sed -nE 's@.*(https://github.com/[^/]+/[^/]+/actions/runs/[0-9]+).*@\1@p')
if [ -n "$run_url" ]; then
  run_id=${run_url##*/}
else
  run_id=$(rtk gh run list --repo "$repo" --workflow visual-capture.yml \
    --event workflow_dispatch --limit 100 --json databaseId,displayTitle \
    --jq ".[] | select(.displayTitle | endswith(\" $request_id\")) | .databaseId")
  [[ $run_id =~ ^[0-9]+$ ]] || { echo "Cannot locate request $request_id; no run selected" >&2; exit 1; }
  run_url="https://github.com/$repo/actions/runs/$run_id"
fi
printf '%s\n' "$run_id" > "$out/run-id.txt"
printf '%s\n' "$run_url" > "$out/run-url.txt"
rtk gh run watch "$run_id" --repo "$repo" --exit-status
rtk gh run download "$run_id" --repo "$repo" --name "visual-capture-$run_id" --dir "$out"
printf '%s\n' "$out"/frames/*.png
