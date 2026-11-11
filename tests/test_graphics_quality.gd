extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const Benchmark := preload("res://tests/benchmark.gd")
var test_path := Settings.settings_path() + ".test_graphics_quality"
class TestBenchmark extends Benchmark:
	func _ready() -> void:
		pass

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _press_a() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _check_quality(low: bool) -> void:
	check(is_equal_approx(root.scaling_3d_scale, 0.75 if low else 1.0), "root viewport scale")
	var standard_msaa: int = ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")
	check(root.msaa_3d == (Viewport.MSAA_DISABLED if low else standard_msaa), "root viewport MSAA")
	check(not get_nodes_in_group("quality_env").is_empty(), "built environments registered")
	check(not get_nodes_in_group("quality_shadow").is_empty(), "built secondary lights registered")
	for node in get_nodes_in_group("quality_env"):
		check(node.environment.ssao_enabled == (false if low else node.get_meta("standard_ssao")), "SSAO: " + node.name)
	for light in get_nodes_in_group("quality_shadow"):
		check(light.shadow_enabled == (false if low else light.get_meta("standard_shadow")), "secondary shadow: " + light.name)


func _run() -> void:
	var had_settings := FileAccess.file_exists(Settings.settings_path())
	var original := FileAccess.get_file_as_bytes(Settings.settings_path()) if had_settings else PackedByteArray()
	check(Benchmark.quality_arg(PackedStringArray(["--bench-quality=low"])) == "low", "benchmark parses low")
	check(Benchmark.quality_arg(PackedStringArray(["--bench-quality=standard"])) == "standard", "benchmark parses standard")
	check(Benchmark.quality_arg(PackedStringArray(["--bench-quality=invalid"])) == "", "benchmark ignores invalid quality")
	var bench := TestBenchmark.new()
	root.add_child(bench)
	Settings.quality = "standard"
	bench.apply_quality_arg(PackedStringArray(["--bench-quality=low"]))
	check(Settings.quality == "low" and is_equal_approx(root.scaling_3d_scale, 0.75), "benchmark applies low quality")
	check(FileAccess.get_file_as_bytes(Settings.settings_path()) == original if had_settings
		else not FileAccess.file_exists(Settings.settings_path()), "benchmark leaves settings file unchanged")
	check(is_equal_approx(Benchmark.cloud_t_arg(PackedStringArray(["--bench-cloud-t=126.5"])), 126.5), "benchmark parses cloud time")
	check(is_nan(Benchmark.cloud_t_arg(PackedStringArray(["--bench-cloud-t=soon"]))), "benchmark ignores a non-number cloud time")
	check(Benchmark.size_arg(PackedStringArray(["--bench-size=3840x2160"])) == Vector2i(3840, 2160), "benchmark parses size")
	check(Benchmark.size_arg(PackedStringArray(["--bench-size=3840"])) == Vector2i.ZERO, "benchmark ignores a malformed size")
	check(Benchmark.selected(Benchmark.BOOKMARKS, PackedStringArray()).size() == Benchmark.BOOKMARKS.size(), "no --bench-only keeps every bookmark")
	var picked := Benchmark.selected(Benchmark.BOOKMARKS, Benchmark.only_arg(PackedStringArray(["--bench-only=totality_horizon,totality_sky"])))
	check(picked.size() == 2 and picked[0][0] == "totality_sky" and picked[1][0] == "totality_horizon", "--bench-only keeps the named bookmarks in bookmark order")
	check(Benchmark.selected(Benchmark.BOOKMARKS, PackedStringArray(["totality_sky", "typo"])).is_empty(), "an unknown bookmark name selects nothing")
	bench.apply_capture_args(PackedStringArray([]))
	check(is_equal_approx(bench.totality_cloud_t, 230.0) and bench.only.is_empty() and not bench.capture_args, "no capture args leaves the benchmark as it was")
	var scale_mode := root.content_scale_mode
	var scale_aspect := root.content_scale_aspect
	var scale_size := root.content_scale_size
	bench.apply_capture_args(PackedStringArray(["--bench-cloud-t=212", "--bench-only=totality_sky", "--bench-size=3840x2160"]))
	await process_frame
	check(is_equal_approx(bench.totality_cloud_t, 212.0) and bench.only == PackedStringArray(["totality_sky"]) and bench.capture_args, "benchmark applies cloud time and bookmark filter")
	check(Vector2i(root.get_texture().get_size()) == Vector2i(3840, 2160), "benchmark renders the root viewport at --bench-size")
	root.content_scale_mode = scale_mode
	root.content_scale_aspect = scale_aspect
	root.content_scale_size = scale_size
	await process_frame
	bench.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	Settings.load_settings(test_path)
	check(Settings.quality == "standard", "missing quality defaults to standard")
	for quality in ["low", "standard"]:
		Settings.quality = quality
		check(Settings.save_settings(test_path) == OK, "save " + quality)
		Settings.quality = ""
		Settings.load_settings(test_path)
		check(Settings.quality == quality, "roundtrip " + quality)
	var cfg := ConfigFile.new()
	cfg.load(test_path)
	check(cfg.get_value("video", "quality") == "standard", "stored key is video/quality")
	cfg.set_value("video", "quality", "invalid")
	cfg.save(test_path)
	Settings.load_settings(test_path)
	check(Settings.quality == "standard", "invalid quality defaults to standard")
	Settings.load_settings()
	Settings.quality = "low"
	Settings.save_settings()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_check_quality(true)
	check(game.sun.shadow_enabled, "low retains the real sun shadow")
	check(game.env.glow_enabled and game.env.fog_enabled, "low retains glow and fog")
	check(not game.world.lamp.shadow_enabled, "low disables the 1919 lamp shadow")
	var ui = game.ui
	ui.toggle_pause()
	var focus: Control = root.gui_get_focus_owner()
	for step in 12:
		if focus == ui.quality_button:
			break
		focus = focus.find_next_valid_focus()
	check(focus == ui.quality_button and focus.focus_mode == Control.FOCUS_ALL, "pause focus reaches quality")
	check(ui.text_size_button.find_next_valid_focus() == ui.quality_button, "quality follows text size")
	ui.quality_button.grab_focus()
	await _press_a()
	check(Settings.quality == "standard" and ui.quality_button.text == "畫質：標準", "A cycles low to standard once")
	_check_quality(false)
	check(game.sun.shadow_enabled and game.world.lamp.shadow_enabled, "standard restores lamp and retains sun")
	await _press_a()
	check(Settings.quality == "low" and ui.quality_button.text == "畫質：低", "A cycles standard to low once")
	_check_quality(true)
	Settings.load_settings()
	check(Settings.quality == "low", "pause choice saves immediately")
	ui.toggle_pause()
	game.free()
	# Enter each real chapter with low already saved, including the fill built after UI startup.
	for scene in ["cambridge", "departure"]:
		var chapter = load("res://scenes/" + scene + ".tscn").instantiate()
		root.add_child(chapter)
		await process_frame
		_check_quality(true)
		check(not chapter.world.environment.environment.ssao_enabled and not chapter.world.lamp.shadow_enabled,
			scene + " builds with low SSAO and lamp shadows")
		if scene == "cambridge":
			check(not chapter._speaker_fill.shadow_enabled, "low disables Cambridge speaker fill shadow")
		var env: Environment = chapter.world.environment.environment
		var glow := env.glow_enabled
		var fog := env.fog_enabled
		Settings.quality = "standard"
		Settings.apply_quality(self)
		_check_quality(false)
		check(env.ssao_enabled and chapter.world.lamp.shadow_enabled, scene + " revert restores SSAO and lamp shadow")
		check(env.glow_enabled == glow and env.fog_enabled == fog, "revert preserves glow and fog")
		if scene == "cambridge":
			check(chapter._speaker_fill.shadow_enabled, "revert restores Cambridge speaker fill shadow")
		chapter.free()
		Settings.quality = "low"
	if had_settings:
		var file := FileAccess.open(Settings.settings_path(), FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.settings_path()))
	Settings.load_settings()
	Settings.apply_quality(self)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	check(FileAccess.get_file_as_bytes(Settings.settings_path()) == original if had_settings
		else not FileAccess.file_exists(Settings.settings_path()), "real settings bytes restored")
	print("test_graphics_quality: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
