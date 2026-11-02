# Shared patch table for the music render scripts. Source it from the repo
# root, after $CACHE is set; see docs/audio/SOURCES.md for provenance.
#
# PATCH_* paths are relative to $CACHE.

PATCH_violin="VSCO-2-CE/SViolinVib.sfz"
PATCH_viola="VSCO-2-CE/ViolaEnsSusVib.sfz"
PATCH_cello="VSCO-2-CE/CelloEnsSusVib.sfz"
PATCH_piano="VCSL/Chordophones/Zithers/Upright Piano, Knight.sfz"

# Per-stem gain and pan (equal power). Harmonium is our own synthesis; its
# additive voice is much hotter than the sampled stems, hence the small gain.
# mix.py prints each stem's RMS against the cello's (keep within +6 dB).
GAIN_harmonium=0.05; PAN_harmonium=0.0
GAIN_cello=1.0;      PAN_cello=-0.2
GAIN_viola=0.8;      PAN_viola=0.15
GAIN_violin=1.4;     PAN_violin=0.3
GAIN_piano=2.4;      PAN_piano=0.0

patch_for() {
    case "$1" in
        violin) printf '%s' "$PATCH_violin" ;;
        viola)  printf '%s' "$PATCH_viola" ;;
        cello)  printf '%s' "$PATCH_cello" ;;
        piano)  printf '%s' "$PATCH_piano" ;;
        *) echo "no patch for $1" >&2; return 1 ;;
    esac
}
