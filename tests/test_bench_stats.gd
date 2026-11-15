extends SceneTree

const Benchmark := preload("res://tests/benchmark.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	var img := Image.create(320, 180, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	var stats := Benchmark.image_stats(img)
	check(stats.clip_white_pct == 100.0 and stats.clip_black_pct == 0.0, "white clipping")
	check(stats.luma_mean == 1.0 and stats.sat_mean == 0.0, "white means")
	img.fill(Color.BLACK)
	stats = Benchmark.image_stats(img)
	check(stats.clip_black_pct == 100.0 and stats.clip_white_pct == 0.0, "black clipping")
	check(stats.sat_mean == 0.0, "black saturation")
	img.fill(Color8(128, 128, 128))
	img.fill_rect(Rect2i(0, 90, 320, 90), Color.RED)
	stats = Benchmark.image_stats(img)
	check(stats.sat_low_mean == 1.0 and stats.sat_mean == 0.5, "saturation halves")
	check(absf(stats.luma_p05 - 0.213) <= 0.002 and absf(stats.luma_p95 - 0.502) <= 0.002, "luma percentiles")
	check(stats.clip_white_pct == 0.0 and stats.clip_black_pct == 0.0, "mixed clipping")
	img = Image.create(1280, 720, false, Image.FORMAT_RGB8)
	img.fill(Color8(128, 128, 128))
	img.fill_rect(Rect2i(0, 0, 128, 720), Color.WHITE)
	stats = Benchmark.image_stats(img)
	check(absf(stats.clip_white_pct - 10.0) <= 0.5, "resized proportions")
	check(img.get_size() == Vector2i(1280, 720) and img.get_format() == Image.FORMAT_RGB8, "large input unchanged")
	img = Image.create(320, 180, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	Benchmark.image_stats(img)
	check(img.get_size() == Vector2i(320, 180) and img.get_format() == Image.FORMAT_RGBA8, "RGBA input unchanged")
	print("test_bench_stats: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
