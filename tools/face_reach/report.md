# Row 8 face reach

Status: measurement and capture incomplete. The first run at `8d14440` produced
24 diagnostic approaches in
`/Volumes/KIOXIA/eddington-1919-cache/director/face-reach/8d14440/measurements.json`.
They are not acceptance evidence: the runner explicitly sets `player.can_move`
to true for every approach. In particular, `scripts/main.gd`'s
`_sync_player_input()` permits movement in PREP, NIGHT and CODA, but not
TOTALITY. The four totality approaches therefore do not describe what the player
can walk to during totality. The runner also starts each approach by placing the
player two metres from the character without checking whether that starting
position overlaps scene geometry; its recorded minima need validation against a
reachable start. Its head-bone offset is an approximation, not a verified
anatomical eye-line point.

No windowed face frames or visual assessment have been produced. The intended
capture must use positions established by valid play-reachable movement; the
measurement method and totality scope must be resolved first.
