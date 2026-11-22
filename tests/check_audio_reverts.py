"""F22/F23 source-mutation checks. Run through tachi-run on an imported tree.

Each mutation is restored before the next case, including on test failure.
No game behaviour changes are retained. The normal suites are the positive control.
"""
from pathlib import Path
import fcntl
import subprocess

# Keep the lock file in Godot's per-checkout import directory. It must persist:
# unlinking it would let a later process lock a different inode.
lock_file = Path(".godot/audio-reverts.lock").open("a")
fcntl.flock(lock_file, fcntl.LOCK_EX)


def suite(name):
    script = f"res://tests/{name}.gd"
    parsed = subprocess.run(
        ["godot", "--headless", "--path", ".", "--check-only", "--script", script],
        capture_output=True, text=True,
    )
    if parsed.returncode or "SCRIPT ERROR" in parsed.stdout + parsed.stderr:
        raise RuntimeError(parsed.stdout + parsed.stderr)
    result = subprocess.run(
        ["perl", "-e", "alarm shift; exec @ARGV", "1500", "godot", "--headless",
         "--path", ".", "--script", script], capture_output=True, text=True,
    )
    output = result.stdout + result.stderr
    if result.returncode < 0 or "SCRIPT ERROR" in output:
        raise RuntimeError(f"{name}: exit={result.returncode}\n{output}")
    return result.returncode, output


for name in ["test_gramophone", "test_audio_invariants"]:
    code, output = suite(name)
    if code:
        raise RuntimeError(output)
    print(next(line for line in output.splitlines() if "checks," in line), flush=True)

# Required failure substrings identify the assertions each reverted behaviour kills.
main = "scripts/main.gd"
gram = "scripts/cambridge/director.gd"
player = "scripts/audio/score_player.gd"
cases = [
    ("wrong-verdict", main, "_verdict = results.verdict", "_verdict = 0",
     "test_audio_invariants", ["real route reaches ending after verdict"]),
    ("skip-october", main,
     "return _came_from_departure and Story.departure_done and not Story.epilogue_done",
     "return false", "test_audio_invariants", ["chapter route", "resolution belongs to route ending"]),
    ("duplicate-resolution", main, "func _show_ending() -> void:\n",
     'func _show_ending() -> void:\n\t_resolution_started = false\n\tscore.stop("coda_resolution")\n',
     "test_audio_invariants", ["resolution starts exactly once"]),
    ("early-resolution", main, '\tscore.warm(["totality_drone", "totality_glass", "totality_edge", "coda_resolution"])',
     '\tscore.warm(["totality_drone", "totality_glass", "totality_edge", "coda_resolution"])\n\tscore.play("coda_resolution")',
     "test_audio_invariants", ["no resolution before verdict", "resolution belongs to route ending"]),
    ("verdict-sting", main, '\t\t\t_verdict = results.verdict',
     '\t\t\tscore.play("departure_motif")\n\t\t\t_verdict = results.verdict',
     "test_audio_invariants", ["no verdict win sting"]),
    ("repeated-ending", main, "func _on_dialogue_done(results: Dictionary) -> void:\n",
     'func _on_dialogue_done(results: Dictionary) -> void:\n\tif phase == Phase.ENDING:\n\t\tscore.play("coda_resolution")\n',
     "test_audio_invariants", ["repeated ending cannot replay resolution"]),
    ("instant-ramps", player,
     'layer.db = linear_to_db(gain) if gain > 0.0001 else SILENCE_DB',
     'layer.db = layer.target_db', "test_gramophone",
     ["duck ramp is in progress at 0.75 s", "return ramp is in progress at 1.5 s"]),
    ("slow-duck", gram, 'score.set_layer_db("cambridge_rain", ScorePlayer.SILENCE_DB, 1.5)',
     'score.set_layer_db("cambridge_rain", ScorePlayer.SILENCE_DB, 3.0)', "test_gramophone",
     ["score reaches silence within 1.5 s"]),
    ("slow-return", gram, 'score.set_layer_db("cambridge_rain", Score.level_db("cambridge_rain"), 3.0)',
     'score.set_layer_db("cambridge_rain", Score.level_db("cambridge_rain"), 6.0)', "test_gramophone",
     ["score returns to its original level at 3 s"]),
    ("play-writes-story", gram, '\tgramophone_plays += 1',
     '\tgramophone_plays += 1\n\tStory.kit_choice = gramophone_plays', "test_gramophone",
     ["first press leaves story flags unchanged", "replay leaves story flags unchanged"]),
    ("stop-writes-story", gram, 'func _gramophone_end(_fade: bool) -> void:\n',
     'func _gramophone_end(_fade: bool) -> void:\n\tStory.kit_choice = 0\n', "test_gramophone",
     ["stop leaves story flags unchanged", "natural finish leaves story flags unchanged"]),
    ("cut-on-leaving", gram, 'fade.tween_property(_gramophone, "volume_db", -80.0, 0.8)',
     'fade.tween_property(_gramophone, "volume_db", -80.0, 0.0)', "test_gramophone",
     ["leaving fades the record instead of cutting it"]),
    ("audible-on-leaving", gram, 'fade.tween_property(_gramophone, "volume_db", -80.0, 0.8)',
     'fade.tween_property(_gramophone, "volume_db", -40.0, 0.8)', "test_gramophone",
     ["departure fade reaches silence and stops the player"]),
    ("restore-on-leaving", gram, 'score.stop("cambridge_rain", 0.8)',
     'score.set_layer_db("cambridge_rain", Score.level_db("cambridge_rain"), 0.8)', "test_gramophone",
     ["leaving never restores the outgoing Cambridge score"]),
    ("departure-writes-story", gram, 'func _montage() -> void:\n',
     'func _montage() -> void:\n\tStory.kit_choice = 3\n', "test_gramophone",
     ["gramophone departure fade leaves story flags unchanged"]),
]
for label, filename, old, new, name, expected in cases:
    path = Path(filename)
    original = path.read_text()
    assert original.count(old) == 1, (label, "mutation anchor is not unique")
    try:
        path.write_text(original.replace(old, new, 1))
        code, output = suite(name)
        assert code != 0, (label, "mutation survived")
        for message in expected:
            assert any(line.startswith("FAIL:") and message in line for line in output.splitlines()), (label, message, output)
        print(f"REVERT {label}: rejected; " + "; ".join(expected), flush=True)
    finally:
        path.write_text(original)
print(f"audio revert checks: {len(cases)} mutations rejected, sources restored", flush=True)
