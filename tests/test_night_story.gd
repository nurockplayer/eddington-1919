extends SceneTree

const Sim := preload("res://scripts/eclipse_sim.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Content := preload("res://scripts/content.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func _initialize() -> void:
	_run.call_deferred()

func make_game(value: float, dirty := false) -> Node:
	root.get_node("Story").from_prologue = true
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.phase = game.Phase.NIGHT
	game.sim.rule_id = "strict"
	if value >= 0:
		game.sim.plates = [{"number": 1, "usable": true, "quality": "good", "included": true,
			"trail": 0.1, "value": value, "sigma": 0.1, "read": true,
			"reading": game.sim.reading_for_value(value)}]
		if dirty:
			game.sim.plates.append({"number": 2, "usable": true, "quality": "good", "included": false, "trail": 0.1})
	game._reasons = Judgment.reasons_for(game.sim)
	return game

func text_of(seq: Array) -> String:
	return "\n".join(seq.map(func(e): return str(e.get("t", ""))))

func dispose(game: Node) -> void:
	game.stop_all_audio()
	game.queue_free()

func _run() -> void:
	await _test_judgment_stretch()
	var cases := [
		{"value": 1.75, "dirty": false, "evidence": "favors_e", "needle": "你不用一個人回家了"},
		{"value": 1.75, "dirty": true, "evidence": "favors_e", "needle": "挑得還不夠乾淨"},
		{"value": 1.31, "dirty": false, "evidence": "ambiguous", "needle": "我還說不準"},
		{"value": -1.0, "dirty": false, "evidence": "none", "needle": "我們一起回家"},
	]
	for c in cases:
		var game := make_game(c.value, c.dirty)
		game._after_judgment({"telegram": 1, "reason": 0})
		var seq: Array = game.ui._seq
		var index := -1
		for i in seq.size():
			if str(seq[i].t).contains(c.needle):
				index = i
		check(game._grade.evidence == c.evidence and game._grade.clean == not c.dirty, "real grade reaches " + c.evidence)
		check(index == game._grade.get("presentation", game._grade.lines).size() and index < seq.size() - 1 and str(seq[-1].t).ends_with(Content.cottingham_coda(game.sim)) and seq[-1].s == Content.C, "payoff follows grade and precedes coda: " + c.needle)
		dispose(game)
		await process_frame
	var grades := []
	for pick in [0, 1]:
		var game := make_game(1.75)
		game.sim.bet_pick = 2
		game._pending = "interval"
		game._on_dialogue_done({"interval": Judgment.interval_truth(game.sim)})
		var keys: Array = game.ui._seq.map(func(e): return e.get("key", ""))
		check(keys.find("press") >= 0 and keys.find("press") < keys.find("telegram"), "press appears before telegram")
		while game.ui._seq[game.ui._seq_i].get("key", "") != "press":
			game.ui._advance()
		game.ui._choose(pick)
		var text := text_of(game.ui._seq)
		check(text.contains("我希望是") == (pick == 0) and text.contains("兩個懷著希望的人") == (pick == 0), "press reply follows choice")
		while game._pending == "judgment":
			var entry: Dictionary = game.ui._seq[game.ui._seq_i]
			if entry.has("choices"):
				game.ui._choose(1 if entry.get("key", "") == "telegram" else 0)
			else:
				game.ui._advance()
		grades.append(game._grade.duplicate(true))
		check(game._pressed_eddington == (pick == 0), "choice records press")
		game.phase = game.Phase.CODA
		game.coda_step = game.CodaStep.LOUPE
		game._interact("mentor_loupe")
		check(text_of(game.ui._seq).contains("那天晚上你問他") == (pick == 0), "real loupe receives press choice")
		dispose(game)
		await process_frame
	check(grades[0].score == grades[1].score and grades[0].evidence == grades[1].evidence, "press leaves grade score and evidence unchanged")
	var no_bet := make_game(1.75)
	no_bet.sim.bet_pick = -1
	no_bet._pending = "interval"
	no_bet._on_dialogue_done({"interval": Judgment.interval_truth(no_bet.sim)})
	check(not no_bet.ui._seq.any(func(e): return e.get("key", "") == "press"), "no bet offers no press")
	dispose(no_bet)
	await process_frame
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_judgment_stretch() -> void:
	# All conditional selection groups, confirmed context, and an automatic reread.
	var game := make_game(1.75, true)
	game._came_from_departure = true
	game._departure_workbook_seen = true
	game._add_night_workbook()
	var saved := "給 Kit：我看見了雲。"
	game._night_departure_workbook.write_kit_line(saved)
	game.sim.plates.append({"number": 3, "usable": true, "quality": "poor", "included": true,
		"trail": 0.5, "sigma": 0.3, "read": true, "reading": game.sim.reading_for_value(1.75)})
	game.sim.plates.append({"number": 4, "usable": false, "quality": "unusable", "included": true})
	game.sim.reselected_after_seeing = true
	game.sim.reselect_history = [{"reason": "result", "removed": [2], "added": [3, 4]}]
	game._after_judgment({"telegram": 0, "reason": 3})
	var count := 0
	var shown := ""
	while game._pending in ["reaction", "coda_opening", "coda_workbook"] and count < 30:
		shown += str(game.ui._seq[game.ui._seq_i].t) + "\n"
		count += 1
		game.ui._advance()
	check(count == 8 and game.coda_step == game.CodaStep.LOUPE,
		"longest judgment to reread route uses at most eight entries (got %d)" % count)
	for line in game._grade.lines:
		check(shown.contains(line), "judgment preserves raw feedback: " + line)
	for entry in Content.go_home_alone(game._grade.evidence, game._grade.clean):
		check(shown.contains(entry.t), "judgment preserves homecoming: " + entry.t)
	for line in [Content.cottingham_coda(game.sim), "（Eddington 把電報稿折好，收進外套口袋，出去找送電報的人。）",
		"（你又讀了一遍工作簿最後一頁。字比你記得的還要歪。）", saved]:
		check(shown.contains(line), "judgment preserves departure and reread: " + line)
	dispose(game)
	await process_frame
