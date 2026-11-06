class_name Checkpoint
extends RefCounted
## One automatic checkpoint per chapter: departure, Príncipe and the October 1919
## epilogue. Story state is written together with the chapter name, so a player who
## quits between chapters resumes at the start of the chapter they reached.
## No slots, no mid-chapter saves.

const Settings := preload("res://scripts/settings.gd")

const VERSION := 1
## Test suites and bots share one settings directory; they set this and clear the file.
static var force_enabled := false

const LABELS := {
	"departure": "繼續：出發前夜",
	"principe": "繼續：普林西比",
	"epilogue": "繼續：1919 年 10 月",
}
const SCENES := {
	"departure": "res://scenes/departure.tscn",
	"principe": "res://scenes/main.tscn",
	"epilogue": "res://scenes/epilogue.tscn",
}
const BOT_ARGS := ["autoplay", "prologue-autoplay", "benchmark"]


static func path() -> String:
	return Settings.settings_path().get_base_dir().path_join("checkpoint.save")


## Test suites and bots share one settings directory: a leftover file would add a
## title button in a later suite. `--script` covers every suite; bots use user args.
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


static func save(chapter: String) -> void:
	if not enabled():
		return
	var story := _story()
	if story == null:
		return
	var data := {"version": VERSION, "chapter": chapter, "story": story.to_save()}
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
	var data := _read()
	if data.is_empty():
		return ""
	var chapter := str(data.get("chapter", ""))
	return chapter if SCENES.has(chapter) else ""


static func restore() -> String:
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
	return chapter


static func clear() -> void:
	if FileAccess.file_exists(path()):
		DirAccess.remove_absolute(path())


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
