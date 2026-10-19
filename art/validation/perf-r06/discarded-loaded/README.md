# Discarded: final-head perf attempt under heavy load

Run 2026-10-20 06:09–06:13 on `dafc94e` vs `aa730ef`, 3 interleaved reps. The load average rose to **25–27** (another project's `cargo` test binary at ~98% CPU and Godot processes outside this session). Paired deltas swung by ±4 ms between reps, so **no conclusion is drawn from this data**. The r06 performance evidence is the 5-rep paired run on `0ff8c60` (`../SUMMARY.md`). Later commits change only the arm pose, build-time licence checks, setup script, load fallback and look-at caching (cheaper per frame), none of which adds render work.
