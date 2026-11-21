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

The runner now leaves the player at the position set by the totality transition
and turns toward each character without enabling movement. Fixed-position
distances are the applicable face-clause evidence; the eye point and which
faces are visible still need validation. The day and darkroom approaches still
need reachable starting positions. The wrapper's run failed to write its output
because the requested HEAD directory did not exist; the runner now creates it.

The corrected output-directory run completed with 18 records. Its totality
distances used the earlier head-bone approximation and are superseded by the
windowed run at `83fdf36`, which targets the centre of the paired iris mesh:

| Totality character | Fixed camera to iris midpoint | Frame |
| --- | ---: | --- |
| Eddington | 0.857 m | `frames/totality_eddington.png` |
| Cottingham | 0.706 m | `frames/totality_cottingham.png` |

The fixed camera was at approximately (0, 1.619, -0.9) m. The captured frames
and measurements are under
`/Volumes/KIOXIA/eddington-1919-cache/director/face-reach/83fdf36/`.
The iris-mesh centre is the eye-line point; both meshes contain the paired iris
discs, and their bounding-box centre lies halfway between them. The runner now
walks a collision-sampled route to each starting position. Its first run could
not find a route within one metre of the requested Cottingham day start. The
search now considers positions farther away on the same approach side. The
measurement at `63b83dd` failed at the same Cottingham day start:
`Assertion failed: No reachable approach near (2.35, 0.0, -4.367949)`.
It produced no completed walking measurements.

The measurement at `57199d6` completed. Minimum camera-to-iris distances over
the reachable sides are:

| Phase | Character | Minimum | Direction |
| --- | --- | ---: | ---: |
| Day | Eddington | 0.446 m | 2 |
| Day | Cottingham | 1.658 m | 0 |
| Darkroom | Eddington | 0.709 m | 0 |
| Darkroom | Cottingham | 0.449 m | 2 |

Day Cottingham directions 1, 2 and 3 were unreachable. Their nearest blocked
sampled points were respectively (3.0, 0, -5.0), (2.5, 0, -7.0), and
(0.5, 0, -7.0) m. Directions are indexed in quarter turns from the
character's rotation. These are results of the sampled route search; walking
frames remain pending.
