class_name Checkpoint
extends RefCounted
## One automatic checkpoint: chapter starts or the darkroom after totality.
## Chapter and live darkroom checkpoints both carry their own Story state.

const Settings := preload("res://scripts/settings.gd")

const VERSION := 1
const DARKROOM_FIELDS := [
	"plates", "plates_delivered", "drive_wound", "drive_rate_checked", "drive_error",
	"rule_id", "bet_pick", "measured", "measured_selection", "measured_readings",
	"first_result", "reselected_after_seeing", "reselect_reason", "reselect_added",
	"reselect_removed", "reselect_history", "reselect_justified_so_far",
]

## Suites that exercise checkpoints set this: it turns them on, on a separate test
## file, so a suite never touches a player's real one.
static var force_enabled := false

const LABELS := {
	"departure": "繼續：出發前夜",
	"principe": "繼續：普林西比",
	"darkroom": "繼續：普林西比",
	"epilogue": "繼續：1919 年 10 月",
}
const SCENES := {
	"departure": "res://scenes/departure.tscn",
	"principe": "res://scenes/main.tscn",
	"darkroom": "res://scenes/main.tscn",
	"epilogue": "res://scenes/epilogue.tscn",
}
const BOT_ARGS := ["autoplay", "prologue-autoplay", "benchmark"]


## Each plate retains the raw exposure inputs alongside its developed values.
static func darkroom_state(sim: RefCounted) -> Dictionary:
	var data := {}
	for field in DARKROOM_FIELDS:
		data[field] = sim.get(field)
	return data.duplicate(true)


static func restore_darkroom(sim: RefCounted, data: Dictionary) -> void:
	for field in DARKROOM_FIELDS:
		sim.set(field, data[field])


static func path() -> String:
	return Settings.settings_path().get_base_dir().path_join("checkpoint.test.save" if force_enabled else "checkpoint.save")


## Test suites and bots neither read, write nor delete checkpoints: a bot's ending
## must not cost a player their save, and a save must not add a title button under a
## test. `--script` covers every suite; bots use user args.
static func enabled() -> bool:
	if force_enabled:
		return true
	if OS.get_cmdline_args().has("--script"):
		return false
	var args := _user_args()
	for flag in BOT_ARGS:
		if args.has(flag):
			return false
	return true


static func save(chapter: String, darkroom: Dictionary = {}) -> void:
	if not enabled():
		return
	var story := _story()
	if story == null:
		return
	var data := {"version": VERSION, "chapter": chapter, "story": story.to_save()}
	if chapter == "darkroom":
		data["darkroom"] = darkroom
		if not darkroom.from_departure:
			# A standalone 1919 run can be played alongside a story chapter.
			var previous := _read()
			if previous.get("chapter") == "darkroom":
				previous = previous.get("previous_chapter", {})
			if not previous.is_empty():
				data["previous_chapter"] = previous
	_write(data)


static func _write(data: Dictionary) -> void:
	var tmp := path() + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("checkpoint: cannot write " + tmp)
		return
	file.store_var(data, false)
	file.close()
	if DirAccess.rename_absolute(tmp, path()) != OK:
		push_warning("checkpoint: cannot replace " + path())


## The chapter the file names, or "" when it is missing, unreadable or another version.
static func peek() -> String:
	if not enabled():
		return ""
	var data := _read()
	if data.is_empty():
		return ""
	var chapter := str(data.get("chapter", ""))
	return chapter if SCENES.has(chapter) else ""


static func restore() -> String:
	if not enabled():
		return ""
	var data := _read()
	if data.is_empty():
		return ""
	var chapter := str(data.get("chapter", ""))
	if not SCENES.has(chapter):
		return ""
	var story := _story()
	if story == null:
		return ""
	story.from_save(data["story"])
	if chapter == "darkroom":
		story.darkroom_resume = data["darkroom"]
	return chapter


static func clear() -> void:
	if enabled() and FileAccess.file_exists(path()):
		DirAccess.remove_absolute(path())


static func complete_standalone_darkroom() -> void:
	if not enabled():
		return
	var data := _read()
	if data.get("chapter") != "darkroom" or data.darkroom.from_departure:
		return
	if data.has("previous_chapter"):
		_write(data.previous_chapter)
	else:
		clear()


static func label(chapter: String) -> String:
	return LABELS.get(chapter, "")


static func scene(chapter: String) -> String:
	return SCENES.get(chapter, "")


static func _read() -> Dictionary:
	var file := FileAccess.open(path(), FileAccess.READ)
	if file == null:
		return {}
	var value = file.get_var(false)
	file.close()
	if not value is Dictionary:
		return {}
	if int(value.get("version", 0)) != VERSION:
		return {}
	if not value.get("story", null) is Dictionary:
		return {}
	if value.get("chapter") == "darkroom" and not value.get("darkroom") is Dictionary:
		return {}
	return value


static func _user_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return out


static func _story() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("Story")
