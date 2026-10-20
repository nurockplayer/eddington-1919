extends SceneTree
## Real-reload regression for 1919 replays (Codex review on PR #12): all three restart buttons keep
## prologue continuity and the coda; 「序章」 resets Story; direct players never inherit it.
## Adapted from the gpt-6-astra review probe. Headless: godot --headless --path . --script res://tests/test_replay.gd

var checks := 0
var failures := 0
var story
const MAIN := "res://scenes/main.tscn"
const FIELDS := ["from_prologue", "prologue_done", "clues", "report", "plan", "kit_choice", "bond_tone", "slip_fix", "departure_done"]

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func snapshot() -> Dictionary:
	var result := {}
	for key in FIELDS:
		result[key] = story.get(key)
	return result.duplicate(true)

func seed_story() -> void:
	story.from_prologue = true
	story.prologue_done = true
	story.clues = {"residual": true}
	story.report = {"cause": "mirror"}
	story.plan = ["comparison", "far_stars", "rules_first"]
	story.kit_choice = 1
	story.bond_tone = "close"
	story.slip_fix = 1
	story.departure_done = true

func settle() -> void:
	for i in range(3):
		await process_frame
	if is_instance_valid(current_scene):
		current_scene.set_process(false)

func enter_main() -> void:
	check(change_scene_to_file(MAIN) == OK, "load actual main scene")
	await settle()

func button(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := button(child, label)
		if found:
			return found
	return null

func assert_origin(main, prologue: bool, expected_story: Dictionary, label: String) -> void:
	check(main._came_from_departure == prologue, label + " origin")
	check(snapshot() == expected_story, label + " all Story fields")
	check(main.has_node("AshbyLoupeHotspot") == prologue, label + " loupe")
	check(not main.get_script().replay_from_prologue, label + " consumed flag")

func _run() -> void:
	story = root.get_node("Story")
	check(not load("res://scripts/main.gd").replay_from_prologue, "fresh process replay flag defaults false")
	check(not story.from_prologue and not story.departure_done and story.bond_tone == "", "fresh process Story defaults")
	if OS.get_cmdline_user_args().has("--cold-only"):
		await enter_main()
		check(current_scene.phase == current_scene.Phase.TITLE and current_scene.ui.title_panel.visible, "relaunch title")
		check(not current_scene._came_from_departure and not current_scene.has_node("AshbyLoupeHotspot"), "relaunch direct isolation")
		print("COLD PROBE: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	for prologue in [false, true]:
		story.reset()
		seed_story()
		story.from_prologue = prologue
		await enter_main()
		var main = current_scene
		var expected := snapshot()
		check(main.phase == (main.Phase.PREP if prologue else main.Phase.TITLE), "initial entry phase")
		check(main.ui.title_panel.visible == (not prologue), "initial title only for direct")
		if not prologue:
			check(not story.prologue_done and not story.departure_done and story.clues.is_empty() and story.bond_tone == "", "direct entry clears stale continuity")
			main.ui.start_btn.pressed.emit()
		assert_origin(main, prologue, expected, "initial")
		for label in ["同一片雲，再試一次", "新的天空", "從頭開始"]:
			var old_id: int = main.get_instance_id()
			var old_seed: int = main.sim.run_seed
			main._grade = {"title": "probe", "fit": 2, "clean": true, "lines": ["probe response"]}
			if label == "從頭開始":
				main.ui.toggle_pause()
				check(paused and main.ui.pause_panel.visible, "pause before restart")
			else:
				main.ui.dialog_panel.hide()
				main._show_ending()
			var target := button(main.ui, label)
			check(target != null and target.is_visible_in_tree(), "restart button visible: " + label)
			target.pressed.emit()
			await settle()
			main = current_scene
			check(main.get_instance_id() != old_id, "actual scene reload: " + label)
			check(not paused, "restart unpauses: " + label)
			check(main.phase == main.Phase.TITLE and main.ui.title_panel.visible, "restart returns title: " + label)
			check(main.sim.run_seed == old_seed if label != "新的天空" else main.sim.run_seed >= 0, "restart seed: " + label)
			assert_origin(main, prologue, expected, label + " title")
			print("RESTART prologue=%s button=%s seed=%d->%d title=%s" % [prologue, label, old_seed, main.sim.run_seed, main.ui.title_panel.visible])
			main.ui.start_btn.pressed.emit()
			check(main.phase == main.Phase.PREP and not main.ui.title_panel.visible, "1919 title button starts PREP")
			assert_origin(main, prologue, expected, label + " start")
			main._grade = {"title": "probe", "fit": 2, "clean": true, "lines": ["probe response"]}
			main._pending = "reaction"
			main._on_dialogue_done({})
			check(main.phase == (main.Phase.CODA if prologue else main.Phase.ENDING), "reaction routes correctly after replay")
			# Prepare another restart from an active 1919 phase.
			main.ui.dialog_panel.hide()
			main.ui.ending_panel.hide()
			main.phase = main.Phase.PREP
			main.ui.pause_enabled = true
		# Return via the actual restart path, then select the actual prologue button.
		main.ui.toggle_pause()
		button(main.ui, "從頭開始").pressed.emit()
		await settle()
		main = current_scene
		check(main.ui.title_panel.visible, "title before selecting prologue")
		main.ui.prologue_btn.pressed.emit()
		await settle()
		check(current_scene.scene_file_path == "res://scenes/cambridge.tscn", "prologue title button reaches Cambridge")
		check(not story.from_prologue and not story.prologue_done and not story.departure_done and story.clues.is_empty() and story.report.is_empty() and story.plan.is_empty() and story.kit_choice == -1 and story.bond_tone == "" and story.slip_fix == -1, "Cambridge resets every Story field")
		check(not load("res://scripts/main.gd").replay_from_prologue, "no replay flag left after choosing prologue")
		await enter_main()
		check(not current_scene._came_from_departure and not current_scene.has_node("AshbyLoupeHotspot"), "later direct entry has no prologue state")
	print("REPLAY PROBE: %d checks, %d failures" % [checks, failures])
	# Leave dirty in-memory continuity at process exit; cold-only must still start clean.
	seed_story()
	current_scene.get_script().replay_from_prologue = true
	quit(1 if failures else 0)
