extends Node
## Presentation only. Workers own synthesis; the scene clock owns totality fades.
const Score := preload("res://scripts/audio/score.gd")
const SETTINGS_PATH := "user://settings.cfg"
const SILENCE_DB := -80.0

static var cue_log: Array[Dictionary] = []
static var _jobs: Dictionary = {}
static var _rendered: Dictionary = {}
static var _queue: Array[String] = []
static var _active_cue := ""
static var _enabled := true

var layers: Dictionary = {}
var playback_enabled := DisplayServer.get_name() != "headless"
var _log_open := false


static func ensure_bus() -> int:
	var index := AudioServer.get_bus_index("Music")
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, "Music")
		AudioServer.set_bus_send(index, "Master")
	AudioServer.set_bus_mute(index, not _enabled)
	return index


static func music_enabled() -> bool:
	return _enabled


static func load_settings(path := SETTINGS_PATH) -> void:
	var cfg := ConfigFile.new()
	_enabled = true
	if cfg.load(path) == OK:
		_enabled = bool(cfg.get_value("audio", "music_enabled", true))
	ensure_bus()


static func set_music_enabled(enabled: bool, path := SETTINGS_PATH) -> Error:
	_enabled = enabled
	ensure_bus()
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value("audio", "music_enabled", enabled)
	return cfg.save(path)


func _ready() -> void:
	# Playback may continue under pause, but neither fades nor trigger adoption do.
	process_mode = Node.PROCESS_MODE_ALWAYS
	ensure_bus()


func warm(cues: Array) -> void:
	if not playback_enabled:
		return
	for cue in cues:
		if not _jobs.has(cue) and not _rendered.has(cue) and cue not in _queue:
			_queue.append(cue)
	_pump_worker()


static func _render_worker(cue: String) -> void:
	var started := Time.get_ticks_usec()
	Score.stream(cue)
	print("[SCORE RENDER] cue=%s worker_ms=%.3f" % [cue, (Time.get_ticks_usec() - started) / 1000.0])


static func _pump_worker() -> void:
	if _active_cue != "":
		var id: int = _jobs[_active_cue]
		if not WorkerThreadPool.is_task_completed(id):
			return
		WorkerThreadPool.wait_for_task_completion(id) # already completed; never waits on synthesis
		_rendered[_active_cue] = true
		_jobs.erase(_active_cue)
		_active_cue = ""
	if not _queue.is_empty():
		_active_cue = _queue.pop_front()
		_jobs[_active_cue] = WorkerThreadPool.add_task(_render_worker.bind(_active_cue), false, "Score " + _active_cue)


func _record(event: String, cue: String, db := SILENCE_DB, fade := 0.0) -> void:
	var entry := {"event": event, "cue": cue, "db": db, "fade": fade}
	cue_log.append(entry)
	print("[SCORE] ", JSON.stringify(entry))


func play(cue: String, fade_in := 0.0) -> void:
	if cue not in Score.CUES:
		push_error("Unknown score cue: " + cue)
		return
	if layers.has(cue) and layers[cue].wanted:
		return
	var db: float = Score.level_db(cue)
	layers[cue] = {"db": SILENCE_DB if fade_in > 0.0 else db, "target_db": db,
		"from_gain": 0.0 if fade_in > 0.0 else db_to_linear(db), "to_gain": db_to_linear(db),
		"elapsed": 0.0, "duration": fade_in, "wanted": true, "playing": false, "player": null}
	_record("request", cue, db, fade_in)
	warm([cue])
	if not playback_enabled:
		_start(cue)


func _start(cue: String) -> void:
	var layer: Dictionary = layers[cue]
	if playback_enabled:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.stream = Score.stream(cue) # only reached after worker completion / cache hit
		player.volume_db = layer.db
		add_child(player)
		layer.player = player
		if not Score.is_loop(cue):
			player.finished.connect(func():
				layer.wanted = false
				_finish_stop(cue))
		player.play()
	layer.playing = true
	_record("start", cue, layer.db, layer.duration)


func set_layer_db(cue: String, db: float, time := 0.0) -> void:
	if not layers.has(cue) or not layers[cue].wanted:
		return
	var layer: Dictionary = layers[cue]
	if is_equal_approx(layer.target_db, db):
		return
	layer.target_db = db
	layer.from_gain = db_to_linear(layer.db) if layer.db > SILENCE_DB else 0.0
	layer.to_gain = db_to_linear(db) if db > SILENCE_DB else 0.0
	layer.elapsed = 0.0
	layer.duration = time
	_record("layer", cue, db, time)
	if time <= 0.0:
		layer.db = db
		_apply_volume(layer)


func stop(cue: String, fade_out := 0.0) -> void:
	if not layers.has(cue) or not layers[cue].wanted:
		return
	set_layer_db(cue, SILENCE_DB, fade_out)
	layers[cue].wanted = false
	_record("stop", cue, SILENCE_DB, fade_out)
	if fade_out <= 0.0 or not layers[cue].playing:
		_finish_stop(cue)


func _finish_stop(cue: String) -> void:
	var layer: Dictionary = layers[cue]
	if is_instance_valid(layer.player):
		layer.player.stop()
		layer.player.queue_free()
	layer.player = null
	layer.playing = false
	layer.db = SILENCE_DB
	_record("stopped", cue)


func _apply_volume(layer: Dictionary) -> void:
	if is_instance_valid(layer.player):
		layer.player.volume_db = layer.db


func set_log_open(open: bool) -> void:
	_log_open = open


func advance(delta: float, totality_only := true) -> void:
	if _log_open or (is_inside_tree() and get_tree().paused):
		return
	for cue in layers:
		if cue.begins_with("totality_") != totality_only:
			continue
		var layer: Dictionary = layers[cue]
		if not layer.playing:
			continue
		if layer.duration > 0.0 and layer.elapsed < layer.duration:
			layer.elapsed = minf(layer.elapsed + delta, layer.duration)
			var gain := lerpf(layer.from_gain, layer.to_gain, layer.elapsed / layer.duration)
			layer.db = linear_to_db(gain) if gain > 0.0001 else SILENCE_DB
			_apply_volume(layer)
		if not layer.wanted and layer.elapsed >= layer.duration:
			_finish_stop(cue)


func _process(delta: float) -> void:
	if playback_enabled:
		_pump_worker()
	if _log_open or get_tree().paused:
		return
	if playback_enabled:
		for cue in layers:
			var layer: Dictionary = layers[cue]
			if layer.wanted and not layer.playing and _rendered.has(cue):
				# A late cue enters softly, even if its trigger requested an immediate start.
				layer.duration = maxf(layer.duration, 0.6)
				layer.db = SILENCE_DB
				layer.from_gain = 0.0
				_start(cue)
	advance(delta, false)


static func run_failures(include_prologue := false) -> Array[String]:
	## Bots read the presentation log without supplying any input to gameplay.
	var failures: Array[String] = []
	var expected := ["totality_drone", "totality_glass", "totality_edge", "coda_resolution"]
	if include_prologue:
		expected.append_array(["cambridge_rain", "departure_motif"])
	for cue in expected:
		var starts := 0
		for entry in cue_log:
			if entry.event == "start" and entry.cue == cue:
				starts += 1
		if starts != 1:
			failures.append("score %s starts=%d, expected 1" % [cue, starts])
	var drone_start := -1
	var duck := -1
	var returned := -1
	var drone_stop := -1
	var resolution := -1
	for i in cue_log.size():
		var entry: Dictionary = cue_log[i]
		if entry.event == "start" and entry.cue == "totality_drone":
			drone_start = i
		if entry.event == "layer" and entry.cue == "totality_glass":
			if duck < 0 and entry.db <= SILENCE_DB and is_equal_approx(entry.fade, 0.4):
				duck = i
			if duck >= 0 and returned < 0 and is_equal_approx(entry.db, -34.0) and is_equal_approx(entry.fade, 1.2):
				returned = i
		if entry.event == "stop" and entry.cue == "totality_drone" and is_equal_approx(entry.fade, 1.5):
			drone_stop = i
		if entry.event == "start" and entry.cue == "coda_resolution":
			resolution = i
	if not (drone_start >= 0 and duck > drone_start and returned > duck and drone_stop > returned and resolution > drone_stop):
		failures.append("score cue order/duck/return/totality fade contract failed")
	for cue in ["totality_glass", "totality_edge"]:
		var stopped := false
		for entry in cue_log:
			if entry.event == "stop" and entry.cue == cue and is_equal_approx(entry.fade, 1.5):
				stopped = true
		if not stopped:
			failures.append("score %s missing totality fade" % cue)
	return failures
