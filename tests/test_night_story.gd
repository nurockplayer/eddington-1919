extends SceneTree

const Sim := preload("res://scripts/eclipse_sim.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Content := preload("res://scripts/content.gd")
const Coda := preload("res://scripts/content_coda.gd")
const PlateRender := preload("res://scripts/plate_render.gd")
const DYSON := {"zh_TW": "Dyson", "en": "Dyson", "ja": "ダイソン", "ko": "다이슨"}
var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	_run.call_deferred()


func make_game() -> Node:
	var story := root.get_node("Story")
	story.reset()
	story.from_prologue = true
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.phase = game.Phase.NIGHT
	game.ui.hide_title()
	game.sim.rule_id = "strict"
	return game


func dispose(game: Node) -> void:
	game.stop_all_audio()
	game.queue_free()


func choose_or_advance(game: Node, picks: Dictionary, show := false) -> void:
	var entry: Dictionary = game.ui._seq[game.ui._seq_i]
	if show:
		print(game.ui.speaker_label.text, " | ", game.ui.text_label.get_parsed_text().replace("\u2060", ""))
	if entry.has("choices"):
		var pick: int = picks[entry.key]
		if show:
			print("  > ", entry.choices[pick])
		game.ui._choice_buttons[pick].pressed.emit()
		if entry.key == "verdict":
			game._process(0.0)
			game._process(1.5)
	else:
		game.ui._advance()


func walk_dispatch(measured: bool) -> void:
	var game := make_game()
	game.sim.drive_wound = measured
	game.sim.drive_rate_checked = measured
	if measured:
		game.sim.drive_error = 0.0
	game.sim.bet_pick = 2
	game.sim.open_shutter(215.0)
	game.sim.accumulate(8.0, 0.0 if measured else 1.0)
	var plate: Dictionary = game.sim.close_shutter()
	game.comparison_tex = PlateRender.render(game.sim, null)
	game.plate_textures = [PlateRender.render(game.sim, plate)]
	game._interact("measure")
	if measured:
		game.ui.plate_toggled.emit(0, true)
		game.ui.reading_set.emit(0, game.sim.reading_for_value(plate.value))
	game.ui.measure_btn.pressed.emit()
	var combined: Dictionary = game.sim.combined()
	check(combined.n == int(measured), "seeded plate produces the intended reading count")
	var wording := 1 if measured else 3
	var basis := 0 if measured else 3
	var verdict := Judgment.verdict_truth(game.sim) if measured else -1
	var picks := {"verdict": verdict, "telegram": wording, "reason": basis, "press": 1}
	print("DISPATCH WALK ", L.current(), " ", "measured" if measured else "zero")
	game.ui.report_btn.pressed.emit()
	var chart = game.ui.chart
	var evidence := {"chart": chart.rows.duplicate(true), "combined": chart.combined.duplicate(true),
		"bounds": Judgment.interval_bounds(game.sim) if measured else {},
		"ledger": chart.ledger.duplicate(true), "plate": plate.duplicate(true),
		"choices": {}, "verdict": verdict}
	check(game._pending == ("verdict" if measured else "judgment"), "report opens the correct route")
	while game._pending in ["verdict", "judgment"] and game.ui.dialog_active():
		var entry: Dictionary = game.ui._seq[game.ui._seq_i]
		if entry.get("key", "") in ["verdict", "telegram", "reason"]:
			evidence.choices[entry.key] = entry.choices
		choose_or_advance(game, picks, true)
	var record_shown: bool = game.ui.dialog_active() and game._pending == "telegram_record"
	check(record_shown, "committing shows the record before the room replies")
	if record_shown:
		var record: Dictionary = game.ui._seq[game.ui._seq_i]
		var rendered: String = game.ui.text_label.get_parsed_text().replace("\u2060", "")
		check(game.ui._seq.size() == 1 and record.s == Content.YOU and game.ui._choice_buttons.is_empty(),
			"committed record has its own advance without another choice")
		check(rendered.contains(DYSON[L.current()]) and rendered.contains(evidence.choices.telegram[wording])
			and rendered.contains(evidence.choices.reason[basis]), "the recipient, wording and basis share one slip")
		if measured:
			check(rendered.contains(evidence.choices.verdict[verdict]), "record shows the chosen verdict")
		else:
			check(not evidence.choices.has("verdict") and rendered.split("\n").size() == 4,
				"zero readings still have a finding in the record")
		choose_or_advance(game, picks, true)
	check(game._pending == "reaction", "one advance opens the technical review")
	if record_shown:
		var review: Array = game.ui._seq
		var first: int = 2 if measured else 0
		var last: int = first + game._grade.presentation.size()
		check(review.slice(first, last).map(func(entry): return entry.t) == game._grade.presentation,
			"review preserves the technical feedback")
		check(review[last] == {"s": Content.C, "t": Content.cottingham_coda(game.sim)},
			"drive feedback stays in review")
		check(review.size() == last + 1 + int(measured), "review contains only its technical and forecast beats")
	while game._pending == "reaction" and game.ui.dialog_active():
		choose_or_advance(game, picks, true)
	evidence["evidence"] = game._grade.evidence
	evidence["fit"] = game._grade.fit
	evidence["clean"] = game._grade.clean
	evidence["reason_ok"] = game._grade.reason_ok
	evidence["score"] = game._grade.score
	print("EVIDENCE ", L.current(), " ", measured, " ", JSON.stringify(evidence))
	check(game.sim.combined() == combined and chart.rows == evidence.chart and plate == evidence.plate,
		"dispatch and review preserve the chart and plate")
	dispose(game)
	await process_frame


func _test_judgment_stretch() -> void:
	# All conditional selection groups, confirmed context, and an automatic reread.
	var game := make_game()
	game._came_from_departure = true
	game._departure_workbook_seen = true
	game._add_night_workbook()
	var saved := "給 Kit：我看見了雲。"
	game._night_departure_workbook.write_kit_line(saved)
	game.sim.plates = [
		{"number": 1, "usable": true, "quality": "good", "included": true,
			"trail": 0.1, "sigma": 0.1, "read": true, "reading": game.sim.reading_for_value(1.75)},
		{"number": 2, "usable": true, "quality": "good", "included": false, "trail": 0.1},
		{"number": 3, "usable": true, "quality": "poor", "included": true,
			"trail": 0.5, "sigma": 0.3, "read": true, "reading": game.sim.reading_for_value(1.75)},
		{"number": 4, "usable": false, "quality": "unusable", "included": true}]
	game.sim.reselected_after_seeing = true
	game.sim.reselect_history = [{"reason": "result", "removed": [2], "added": [3, 4]}]
	game.sim.measured = true
	game._interact("eddington")
	var picks := {"verdict": 2, "telegram": 0, "reason": 3}
	while game._pending in ["verdict", "judgment"]:
		choose_or_advance(game, picks)
	var count := 0
	var shown := ""
	while game._pending in ["telegram_record", "reaction", "coda_opening", "coda_workbook"] and count < 30:
		shown += str(game.ui._seq[game.ui._seq_i].t) + "\n"
		count += 1
		choose_or_advance(game, picks)
	check(count <= 9 and game.coda_step == game.CodaStep.LOUPE,
		"judgment to reread reaches the loupe within nine entries (got %d)" % count)
	for line in game._grade.lines + [Content.cottingham_coda(game.sim), Coda.opening()[0].t, Coda.workbook_again(saved)[0].t]:
		check(shown.contains(line), "judgment preserves review, departure and reread: " + line)
	dispose(game)
	await process_frame


func _run() -> void:
	for locale in L.LOCALES:
		L.apply(locale)
		await walk_dispatch(true)
		await walk_dispatch(false)
	L.apply("zh_TW")
	await _test_judgment_stretch()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
