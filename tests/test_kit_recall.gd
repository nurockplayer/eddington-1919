extends SceneTree
## Kit's 1917 question about the childhood star chart returns in the 1919
## coda close: 「畫錯，跟說謊，不是一回事」 is measured against the telegram,
## and a silent answer is remembered. No prologue answer, no line.
const C17 = preload("res://scripts/cambridge/content_1917.gd")
const MAIN_PATH := "res://scripts/main.gd"
const CHART := "小時候那張星圖"
const OVER := "寫得比底片上的多"
const HONEST := "只寫了底片上有的"
const SILENT := "你沒有回答"
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
	await _test_kit_want()
	# telegram index: 0 confirmed, 1 hopeful, 3 none (Judgment.TELEGRAMS)
	await _case(0, 0, [CHART, OVER], [HONEST, SILENT])
	await _case(0, 1, [CHART, HONEST], [OVER, SILENT])
	await _case(0, 3, [CHART, HONEST], [OVER])
	await _case(2, 0, [SILENT], [CHART])
	await _case(1, 0, [], [CHART, SILENT])
	await _case(-1, 0, [], [CHART, SILENT])
	root.get_node("Story").reset()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _case(kit_choice: int, telegram: int, has: Array, lacks: Array) -> void:
	var story: Node = root.get_node("Story")
	story.from_prologue = true
	var game = load(MAIN_PATH).new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.ui.hide_title()
	story.kit_choice = kit_choice
	story.bond_tone = "warm"
	game._telegram = telegram
	game._grade = {"title": "測試", "fit": 2, "clean": true, "lines": []}
	game._pending = "coda_loupe"
	game._on_dialogue_done({})
	var text := ""
	for entry in game.ui._seq:
		text += str(entry.get("t", "")) + "\n"
	var label := "kit_choice=%d telegram=%d" % [kit_choice, telegram]
	check(game._pending == "coda_kit", "%s: the loupe answer leads to Kit's close" % label)
	for s in has:
		check(text.contains(s), "%s: the close says 「%s」" % [label, s])
	for s in lacks:
		check(not text.contains(s), "%s: the close does not say 「%s」" % [label, s])
	check(text.contains("你吹熄了燈"), "%s: the close still ends with the lamp" % label)
	game.stop_all_audio()
	game.queue_free()
	await process_frame

func _test_kit_want() -> void:
	var story = root.get_node("Story")
	var replies := ["每天晚上都有人在看你泡的茶。……我懂你的意思。", "那你就回來告訴我，上面什麼都沒有。那也是你親眼看見的東西。", "……算了。"]
	for choice in 3:
		story.reset()
		var chapter = load("res://scripts/cambridge/director.gd").new()
		root.add_child(chapter)
		await process_frame
		chapter.set_process(false)
		chapter._say(C17.kit_coda({}, {}), "coda")
		var shown: Array = []
		while chapter._pending == "coda" and chapter.ui.dialog_active():
			var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
			shown.append(str(entry.get("t", "")))
			if entry.has("choices"):
				chapter.ui._choose(choice if entry.get("key", "") == "want" else 0)
			else:
				chapter.ui._advance()
		check(shown.has(replies[choice]), "want %d shows Kit's reply" % choice)
		check(story.want == choice, "want %d reaches Story through the director" % choice)
		chapter.queue_free()
		await process_frame
	story.reset()

