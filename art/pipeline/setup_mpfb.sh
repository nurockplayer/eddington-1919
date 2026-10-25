#!/bin/sh
# Reproducible, isolated MPFB 2 setup for character builds (art/PIPELINE.md S3c).
#   art/pipeline/setup_mpfb.sh            # downloads, verifies, installs
#   eval "$(art/pipeline/setup_mpfb.sh --env)"   # exports BLENDER_USER_RESOURCES
#
# Nothing is installed into the user's own Blender profile: MPFB lives in an
# isolated BLENDER_USER_RESOURCES under ~/.cache/eddington-1919/mpfb.
#
# Sources and licences (checked 2026-10-20, see art/people/LICENSES.md):
#   MPFB 2.0.18, official Blender Extensions platform, GPL-3.0-or-later (tool only;
#     never shipped in the game). sha256 is part of the official download URL.
#   MakeHuman system assets pack (makehuman_system_assets_cc0.zip), official
#     MakeHuman community asset server, every asset listed as CC0.
set -eu
CACHE=${E1919_MPFB_CACHE:-$HOME/.cache/eddington-1919/mpfb}
export BLENDER_USER_RESOURCES="$CACHE/blender_user"
if [ "${1:-}" = "--env" ]; then echo "export BLENDER_USER_RESOURCES='$BLENDER_USER_RESOURCES'"; exit 0; fi

MPFB_SHA=c075b3e9b94b8e5556a5f03f4653602d02ea306de08126e8f55ed6dee28a2dad
MPFB_URL="https://extensions.blender.org/download/sha256:$MPFB_SHA/add-on-mpfb-v2.0.18.zip?repository=%2Fapi%2Fv1%2Fextensions%2F&blender_version_min=4.2.0"
SYS_SHA=b542127a8e25547c7c29c19f2d1d2adb9a664c80396ecd694095dbc8028a0107  # recorded 2026-10-20 (no official checksum published)
SYS_URL=https://files2.makehumancommunity.org/asset_packs/makehuman_system_assets/makehuman_system_assets_cc0.zip

# The downloaded zips are an Owner-approved reusable cache (2026-10-26, docs/HANDOFF.md).
# Approved caches stay off the Mac SSD: on /Volumes/KIOXIA when it is mounted,
# else under /private/tmp (cleared at reboot). Override with E1919_MPFB_DL.
if [ -z "${E1919_MPFB_DL:-}" ]; then
  if mount | grep -q " on /Volumes/KIOXIA ("; then
    E1919_MPFB_DL=/Volumes/KIOXIA/cache/eddington-1919/mpfb/dl
  else
    E1919_MPFB_DL=/private/tmp/eddington-1919/mpfb/dl
  fi
fi
DL=$E1919_MPFB_DL
mkdir -p "$DL" "$BLENDER_USER_RESOURCES"
ok() { echo "$2  $1" | shasum -a 256 -c - >/dev/null 2>&1; }
fetch() {  # url file sha — never leave an unverified file at the final path
  dst="$DL/$2"
  if [ -f "$dst" ] && ! ok "$dst" "$3"; then
    echo "cached $2 fails its checksum; downloading again" >&2
    rm -f "$dst"
  fi
  if [ ! -f "$dst" ]; then
    curl -fsSL -o "$dst.part" "$1" || { rm -f "$dst.part"; echo "download failed: $2" >&2; exit 1; }
    ok "$dst.part" "$3" || { rm -f "$dst.part"; echo "checksum mismatch: $2" >&2; exit 1; }
    mv "$dst.part" "$dst"
  fi
}
fetch "$MPFB_URL" mpfb-2.0.18.zip "$MPFB_SHA"
fetch "$SYS_URL" makehuman_system_assets_cc0.zip "$SYS_SHA"
blender --command extension install-file -r user_default -e "$DL/mpfb-2.0.18.zip" >/dev/null 2>&1
DATA="$BLENDER_USER_RESOURCES/extensions/.user/user_default/mpfb/data"
mkdir -p "$DATA"
# Staged extraction with a completion marker: an interrupted run never looks installed.
MARK="$DATA/.e1919_system_assets_$SYS_SHA"
if [ ! -f "$MARK" ]; then
  STAGE=$(mktemp -d "$CACHE/stage.XXXXXX")
  unzip -q "$DL/makehuman_system_assets_cc0.zip" -d "$STAGE"
  for need in clothes/male_elegantsuit01 hair/short02 proxymeshes/male1591 eyes/low-poly eyebrows/eyebrow010; do
    [ -d "$STAGE/$need" ] || { echo "asset pack incomplete: $need" >&2; rm -rf "$STAGE"; exit 1; }
  done
  cp -R "$STAGE/." "$DATA/"   # one process: any failure stops the script before the marker
  rm -rf "$STAGE"
  touch "$MARK"
fi
echo "MPFB ready: BLENDER_USER_RESOURCES=$BLENDER_USER_RESOURCES"
