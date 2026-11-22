extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const Content := preload("res://scripts/content.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
const Render := preload("res://scripts/plate_render.gd")
const Judgment := preload("res://scripts/judgment.gd")
const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")
const EpilogueChart := preload("res://scripts/cambridge/epilogue_chart.gd")
const Coda := preload("res://scripts/content_coda.gd")
const Epilogue := preload("res://scripts/cambridge/content_epilogue.gd")
const BoxSketch := preload("res://scripts/cambridge/box_sketch.gd")
var checks := 0
var failures := 0
var context := ""
var test_path := Settings.settings_path() + ".test_layout_bounds"
## The viewer action button height on main at text scale 1.0 (zh-TW): one line.
const VIEWER_BUTTON_HEIGHT := 50.0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", context, " ", message)


func bounds(node: Node) -> void:
	if node is Control:
		var control := node as Control
		if not control.is_visible_in_tree():
			return
		var rect := control.get_global_rect()
		if rect.size.x > 0 and rect.size.y > 0:
			var viewport := root.get_visible_rect()
			check(viewport.grow(1.0).encloses(rect), "%s rect %s viewport %s" % [control.get_path(), rect, viewport])
		if control is ScrollContainer:
			return
	for child in node.get_children():
		bounds(child)


func settle() -> void:
	for frame in 5:
		await process_frame


func _run() -> void:
	load("res://scripts/main.gd")._ensure_inputs()
	await _test_darkroom_chart()
	if "--darkroom-chart-only" in OS.get_cmdline_user_args():
		print("test_layout_bounds darkroom chart: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	await _test_totality_toast()
	if "--totality-toast-only" in OS.get_cmdline_user_args():
		print("test_layout_bounds totality toast: %d checks, %d failures" % [checks, failures])
		quit(1 if failures else 0)
		return
	await _test_merged_dialogue()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	Settings.load_settings(test_path)
	var real_path := ProjectSettings.globalize_path(Settings.settings_path())
	var had_settings := FileAccess.file_exists(Settings.settings_path())
	var original := FileAccess.get_file_as_bytes(Settings.settings_path()) if had_settings else PackedByteArray()
	var original_mtime := FileAccess.get_modified_time(real_path) if had_settings else 0
	var story := root.get_node("Story")
	var original_runs: Array = story.runs.duplicate(true)
	var sim := Sim.new(77)
	sim.plates_delivered = sim.MAX_EXTRA_PLATES
	sim.drive_rate_checked = true
	# Run the maximum 12 exposures through the same shutter and cloud model.
	for i in sim.plates_available():
		var start := float(i * 24)
		sim.open_shutter(start)
		for step in 32:
			var t := start + step * 0.25
			sim.accumulate(0.25, sim.cloud_over_sun(t))
		sim.close_shutter(false)
	for plate in sim.plates:
		plate.included = plate.usable
		if plate.included:
			# Conversion arc C: only a plate the player has read counts.
			plate.read = true
			plate.reading = sim.reading_for_value(plate.value)
	check(sim.plates.size() == 12 and not sim.included_usable().is_empty(), "maximum real exposures include measurable plates")
	var textures: Array = []
	for plate in sim.plates:
		textures.append(Render.render(sim, plate))
	var comparison := Render.render(sim, null)
	for window in [Vector2i(1600, 900), Vector2i(1280, 800), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(3440, 1440), Vector2i(2560, 1440)]:
		root.content_scale_size = Vector2i(1600, 900)
		root.size = window
		for scale in [1.0, 1.2]:
			context = "%s scale %.1f" % [window, scale]
			Settings.text_scale = scale
			Settings.save_settings(test_path)
			var game: Node = load("res://scenes/main.tscn").instantiate()
			root.add_child(game)
			# Layout needs the live UI, not player physics or animated 3D scenery.
			game.process_mode = Node.PROCESS_MODE_DISABLED
			game.ui.process_mode = Node.PROCESS_MODE_PAUSABLE
			game.sim = sim
			game.plate_textures = textures
			game.comparison_tex = comparison
			var ui = game.ui
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			await settle()
			check(ui.title_panel.visible, "title is up before the chapter buttons are read")
			check(ui.prologue_btn.text == L.t("開始遊戲：序章・劍橋，1917") and ui.start_btn.text == L.t("只玩尾章：普林西比，1919"),
				"title buttons say which game each one starts")
			check(ui.title_note != null and ui.title_note.is_visible_in_tree()
				and ui.title_note.text == L.t("第一次玩請從序章開始；只玩尾章會略過劍橋的調查、出發前的準備與結尾的後續。"),
				"title warns that the tail chapter skips Cambridge")
			bounds(ui.title_panel)
			var title_buttons: Array = ui.prologue_btn.get_parent().get_children()
			for i in title_buttons.size():
				check(root.get_visible_rect().encloses(title_buttons[i].get_global_rect()), "title button fits")
				for j in range(i):
					check(not title_buttons[i].get_global_rect().intersects(title_buttons[j].get_global_rect()), "title buttons do not overlap")
			if L.current() == "zh_TW":
				var title_row_y: float = title_buttons[0].get_global_rect().position.y
				for button in title_buttons:
					check(is_equal_approx(button.get_global_rect().position.y, title_row_y),
						"zh-TW title buttons stay on one row: " + button.text)
			# A chapter checkpoint adds one 繼續 button; the longer row must still fit.
			Checkpoint.force_enabled = true
			Checkpoint.save("principe")
			var resume_game: Node = load("res://scenes/main.tscn").instantiate()
			root.add_child(resume_game)
			resume_game.process_mode = Node.PROCESS_MODE_DISABLED
			resume_game.ui.process_mode = Node.PROCESS_MODE_PAUSABLE
			await settle()
			var resume_ui = resume_game.ui
			# The new UI loads the settings file this suite does not use; keep the pass at its scale.
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			await settle()
			check(resume_ui.continue_btn != null and resume_ui.continue_btn.text == L.t(Checkpoint.label("principe")),
				"title offers the chapter checkpoint")
			bounds(resume_ui.title_panel)
			var resume_buttons: Array = resume_ui.prologue_btn.get_parent().get_children()
			for i in resume_buttons.size():
				check(root.get_visible_rect().encloses(resume_buttons[i].get_global_rect()),
					"checkpoint title button fits: " + resume_buttons[i].text)
				for j in range(i):
					check(not resume_buttons[i].get_global_rect().intersects(resume_buttons[j].get_global_rect()),
						"checkpoint title buttons do not overlap: " + resume_buttons[i].text)
			if L.current() == "zh_TW":
				var resume_row_y: float = resume_buttons[0].get_global_rect().position.y
				for button in resume_buttons:
					check(is_equal_approx(button.get_global_rect().position.y, resume_row_y),
						"zh-TW checkpoint title buttons stay on one row: " + button.text)
			resume_game.stop_all_audio()
			resume_game.free()
			Checkpoint.clear()
			Checkpoint.force_enabled = false
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			await settle()
			ui.hud.visible = true
			game.phase = game.Phase.PREP
			game._refresh_objectives()
			await settle()
			bounds(ui.objectives.get_parent())
			var measure_line := L.t("[color=#a99]今天要量的：太陽旁邊的星，有沒有被往外推。[/color]").trim_prefix("[color=#a99]").trim_suffix("[/color]")
			var walk_line := L.t("%s 從暗房（鐵皮屋頂的木屋）搬底片匣到望遠鏡架（已放 %d／%d，手上 %d）").get_slice("%s", 1).get_slice("%d", 0)
			check(ui.objectives.text.contains(measure_line) and ui.objectives.text.contains(walk_line),
				"PREP objectives name the measurement and the darkroom")
			check(ui.objectives.get_content_height() <= ui.objectives.size.y + 1.0,
				"PREP objectives text fits its panel (content %s, label %s)" % [ui.objectives.get_content_height(), ui.objectives.size.y])
			# aspect=expand keeps the 1600×900 base and widens: the scale is the
			# smaller of the two window/base ratios, so 2560×1080 → 2133×900 and
			# 3440×1440 → 2150×900.
			# The viewport keeps whole pixels (2560×1080 → 2133, not 2133.333).
			var factor := minf(window.x / 1600.0, window.y / 900.0)
			var expected := (Vector2(window) / factor).round()
			check(root.get_visible_rect().size.is_equal_approx(expected), "visible rect %s expected %s" % [root.get_visible_rect(), expected])
			ui.hide_title()
			ui.play([Content.rules_prompt(true)[-1]])
			await settle()
			bounds(ui.dialog_panel)
			check(ui._choice_buttons.size() == 3, "three choices are visible")
			check(ui._choice_buttons[0].get_theme_font_size("font_size") == roundi(20 * scale), "choice font follows text scale")
			check(not ui.text_label.get_global_rect().intersects(ui.choice_box.get_global_rect()), "dialogue text overlaps choices")
			for i in ui._choice_buttons.size():
				for j in range(i + 1, ui._choice_buttons.size()):
					check(not ui._choice_buttons[i].get_global_rect().intersects(ui._choice_buttons[j].get_global_rect()), "choice buttons overlap")
			# Conversion arc move B: the orrery suspect is the longest choice list.
			ui.play([C17.orrery_suspect_entry()])
			await settle()
			bounds(ui.dialog_panel)
			check(ui._choice_buttons.size() == 5, "five orrery suspects are visible")
			check(not ui.text_label.get_global_rect().intersects(ui.choice_box.get_global_rect()), "orrery text overlaps choices")
			for i in ui._choice_buttons.size():
				for j in range(i + 1, ui._choice_buttons.size()):
					check(not ui._choice_buttons[i].get_global_rect().intersects(ui._choice_buttons[j].get_global_rect()), "orrery choice buttons overlap")
			ui.toggle_pause()
			await settle()
			ui._open_help()
			await settle()
			bounds(ui.help_panel)
			ui._close_help()
			bounds(ui.pause_panel)
			var scroll: ScrollContainer = ui.pause_panel.find_children("*", "ScrollContainer", true, false)[0]
			var buttons: Array = scroll.find_children("*", "Button", true, false)
			for button in buttons:
				scroll.ensure_control_visible(button)
				await settle()
				check(scroll.get_global_rect().grow(1.0).encloses(button.get_global_rect()), "pause button reachable: " + button.text)
			for i in buttons.size():
				for j in range(i + 1, buttons.size()):
					check(not buttons[i].get_global_rect().intersects(buttons[j].get_global_rect()), "pause buttons overlap")
			var armed_buttons: Array = [ui._pause_title_btn, ui.restart_button, ui.quit_button]
			for button: Button in armed_buttons:
				button.pressed.emit()
			await settle()
			for button: Button in armed_buttons:
				scroll.ensure_control_visible(button)
				await settle()
				check(scroll.get_global_rect().grow(1.0).encloses(button.get_global_rect()), "armed pause button reachable: " + button.text)
				check(scroll.size.x <= 301.0, "armed pause column stays 300 px: " + button.text)
				var content_width: float = button.size.x - button.get_theme_stylebox("normal").get_minimum_size().x
				var font := button.get_theme_font("font")
				var font_size := button.get_theme_font_size("font_size")
				var text_size := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
				if button.autowrap_mode != TextServer.AUTOWRAP_OFF:
					var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
					text_size = font.get_multiline_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, content_width, font_size, -1, flags)
				check(text_size.x <= content_width + 1.0, "armed pause text fits: " + button.text)
				check(text_size.y <= button.size.y - button.get_theme_stylebox("normal").get_minimum_size().y + 1.0, "armed pause text height fits: " + button.text)
			ui.toggle_pause()
			ui.toggle_pause()
			ui.toggle_pause()
			ui.open_settings()
			await settle()
			bounds(ui.pause_panel)
			ui.close_settings()
			ui.toggle_log()
			await settle()
			bounds(ui.log_panel)
			ui.toggle_log()
			sim.measured = false
			sim.first_result = null
			sim.measured_selection = null
			sim.rule_id = "strict"
			game._open_viewer()
			ui.measure_btn.pressed.emit()
			check(sim.measured and ui.chart.revealed and not ui.chart.rows.is_empty(), "real measurement reveals chart")
			check(ui.thumbs.get_child_count() == 13 and ui.viewer_note.text.contains(
				L.t("\n細線是兩倍誤差：Eddington 的判準是，兩倍誤差之內容得下哪個預測、又排除了哪個。")),
				"twelve plates and measured note are visible")
			await settle()
			bounds(ui.viewer)
			# Drawn ledger text is not a Control; check its actual painted rectangles.
			var saved_bet_1917: Dictionary = story.bet_1917.duplicate(true)
			var saved_bet_pick: int = sim.bet_pick
			for picks in [[1, 2], [2, 1], [3, 2], [0, 3], [3, 3], [2, 2], [-1, 2], [-1, 3]]:
				story.bet_1917 = {"pick": picks[0], "year": 1917} if picks[0] >= 0 else {}
				sim.bet_pick = picks[1]
				game._refresh_viewer()
				await settle()
				var ledger_bounds: Array = ui.chart.drawn().ledger_bounds
				check(not ledger_bounds.is_empty(), "real viewer paints ledger text for bounds checks")
				for i in ledger_bounds.size():
					var rect: Rect2 = ledger_bounds[i]
					check(Rect2(0, 0, ui.chart.size.x, 30).grow(0.01).encloses(rect), "ledger tag stays inside the top band: %s" % rect)
					for j in range(i):
						check(not rect.intersects(ledger_bounds[j]), "ledger tags do not overlap")
				story.bet_1917 = saved_bet_1917
				sim.bet_pick = saved_bet_pick
			game._refresh_viewer()
			var viewer_buttons: Array = ui.viewer.find_children("*", "BaseButton", true, false).filter(func(b): return b.is_visible_in_tree())
			for i in viewer_buttons.size():
				for j in range(i + 1, viewer_buttons.size()):
					check(not viewer_buttons[i].get_global_rect().intersects(viewer_buttons[j].get_global_rect()), "viewer buttons overlap")
			if L.current() == "zh_TW" and is_equal_approx(scale, 1.0):
				for button in ui.measure_btn.get_parent().get_children():
					check(is_equal_approx(button.size.y, VIEWER_BUTTON_HEIGHT),
						"zh-TW viewer button stays one line high: " + button.text)
			if window == Vector2i(1280, 720):
				check(is_equal_approx(ui.big_plate.size.y, 460.0), "720p plate remains 460 logical pixels")
			if window == Vector2i(1920, 1080) and scale == 1.0:
				var screen_scale := float(window.y) / root.get_visible_rect().size.y
				check(ui.big_plate.size.y * screen_scale >= 640.0, "1080p plate is at least 640 screen pixels")
				var lowest := 0.0
				for button in ui.viewer.find_children("*", "BaseButton", true, false):
					if button.is_visible_in_tree():
						lowest = maxf(lowest, button.get_global_rect().end.y)
				check(lowest * screen_scale >= window.y * 0.75, "lowest viewer control reaches bottom quarter")
			if window == Vector2i(1920, 1080):
				root.size = Vector2i(1280, 720)
				await settle()
				check(is_equal_approx(ui.big_plate.size.y, 460.0), "plate returns to 720p size on resize")
				root.size = window
				await settle()
				check(ui.big_plate.size.y > 460.0, "plate grows again on resize")
			if window == Vector2i(1280, 720) and scale == 1.2:
				check(ui.mic_btn.is_visible_in_tree() and ui.mic_btn.text == L.t("測微器"), "micrometer toggle is offered at 720p/1.2")
				ui.mic_btn.button_pressed = true
				await settle()
				bounds(ui.viewer)
				check(ui.mic_row.is_visible_in_tree() and ui.mic_readout.is_visible_in_tree(), "micrometer readout and record button appear after toggling")
				check(root.get_visible_rect().encloses(ui.mic_btn.get_global_rect()) and root.get_visible_rect().encloses(ui.mic_row.get_global_rect()),
					"micrometer controls fit 1280x720 at text scale 1.2")
				ui.mic_btn.button_pressed = false
				await settle()
			ui.set_viewer_report(true)
			await settle()
			bounds(ui.viewer)
			ui.close_viewer()
			ui.dialog_panel.hide()
			var overlay := Overlay.new()
			overlay.ui = ui
			root.add_child(overlay)
			overlay.flipped = true
			overlay.angle_deg = 3.2
			overlay.open()
			ui.hud.visible = false
			ui.show_toast(C17.viewer_feedback("label_mirrored"), 6.0)
			await settle()
			bounds(overlay)
			check(ui.toast.is_visible_in_tree(), "overlay toast visible while HUD hidden")
			check(ui.toast.has_theme_stylebox_override("normal"), "overlay toast has a backing")
			var toast_rect: Rect2 = ui.toast.get_global_rect()
			check(not toast_rect.intersects(overlay._status_label.get_global_rect()), "overlay toast clears aligned status")
			check(not toast_rect.intersects(overlay.buttons.flip.get_parent().get_global_rect()), "overlay toast clears button row")
			check(root.get_visible_rect().encloses(toast_rect), "overlay toast stays on screen")
			var backing: StyleBoxFlat = ui.toast.get_theme_stylebox("normal")
			check(backing.bg_color.a > 0.0, "backing drawn while toast has text")
			ui.show_toast("", 0.0)
			await settle()
			check(is_zero_approx(backing.bg_color.a), "backing hidden when toast text is empty")
			ui.show_toast(C17.viewer_feedback("label_mirrored"), 6.0)
			await settle()
			overlay.close()
			check(ui.toast.get_parent() == ui.hud, "overlay restores toast to HUD")
			check(not ui.toast.has_theme_stylebox_override("normal"), "backing removed on close")
			overlay.free()
			var checklist := Checklist.new()
			root.add_child(checklist)
			checklist.open()
			await settle()
			bounds(checklist)
			checklist.free()
			# Conversion arc D: the epilogue chart overlay carries one button and up
			# to two notes under the chart at both window sizes and both text scales.
			var epilogue_chart := EpilogueChart.new()
			epilogue_chart.theme = ui.theme_res
			root.add_child(epilogue_chart)
			epilogue_chart.open({"combined": {"n": 3, "value": 1.90, "sigma": 0.09}})
			epilogue_chart._press()
			epilogue_chart._press()
			await settle()
			bounds(epilogue_chart)
			# Step 3: the Sobral reading question and its four answers stay inside
			# the viewport with the chart still above them.
			epilogue_chart._press()
			await settle()
			bounds(epilogue_chart)
			epilogue_chart.choices[1].pressed.emit()
			await settle()
			bounds(epilogue_chart)
			check(epilogue_chart.button.is_visible_in_tree() and root.get_visible_rect().encloses(epilogue_chart.button.get_global_rect()),
				"%dx%d @%.1f epilogue overlay button fits" % [window.x, window.y, scale])
			check(root.get_visible_rect().encloses(epilogue_chart.chart.get_global_rect()),
				"%dx%d @%.1f epilogue chart fits" % [window.x, window.y, scale])
			if window.y == 1080:
				check(epilogue_chart.chart.size.y < root.get_visible_rect().size.y * 0.6, "1080p epilogue chart is under 60% height")
			epilogue_chart.free()
			# Conversion arc E: the box sketch's text and buttons at every size.
			var sketch_layer := CanvasLayer.new()
			root.add_child(sketch_layer)
			var sketch := BoxSketch.new()
			sketch_layer.add_child(sketch)
			await settle()
			for sketch_case in [["drop", 0], ["drop", 1], ["drop", 2], ["light", 0]]:
				sketch.open(sketch_case[0])
				sketch.stage = sketch_case[1]
				sketch._refresh_stage()
				await settle()
				bounds(sketch)
				var sketch_label := "%dx%d @%.1f box sketch %s %d" % [window.x, window.y, scale, sketch_case[0], sketch_case[1]]
				check(not sketch._prompt.get_global_rect().intersects(sketch._note.get_global_rect()), sketch_label + ": prompt clears the note")
				check(not sketch._note.get_global_rect().intersects(sketch._buttons.get_global_rect()), sketch_label + ": note clears the buttons")
				for sketch_text in [sketch._prompt, sketch._note]:
					check(sketch_text.get_line_count() * sketch_text.get_line_height() <= sketch_text.get_global_rect().size.y + 1.0, sketch_label + ": text fits its label")
			sketch_layer.free()
			story.runs.clear()
			game._telegram = 1
			game._reason = 0
			game._reasons = Judgment.reasons_for(sim)
			game._grade = Judgment.grade(sim, "hopeful", game._reasons[0].id)
			game._run_record_index = -1
			game._show_ending()
			game._run_record_index = -1
			game._telegram = 2 # Longest authored telegram.
			game._show_ending()
			var review: String = ui.ending_review.text + "\n\n" + Content.run_comparison(story.runs[0], story.runs[1])
			ui.show_ending(ui.ending_title.text, ui.ending_text.text, ui.ending_history.text, review,
				ui.ending_telegram.text, ui.ending_plate.texture, ui.ending_plate_caption.text)
			check(ui.ending_plate.texture != null and ui.ending_telegram.text.contains(Judgment.TELEGRAMS[2].text), "real ending plate and longest telegram")
			await settle()
			bounds(ui.ending_panel)
			bounds(ui.ending_slip)
			bounds(ui.ending_plate_card)
			var hint_rect: Rect2 = ui.ending_replay_hint.get_global_rect()
			check(hint_rect.size.x > 0 and hint_rect.size.y > 0 and root.get_visible_rect().encloses(hint_rect),
				"ending replay hint fits on screen")
			check(not hint_rect.intersects(ui.ending_scroll.get_global_rect()), "ending replay hint clears the scroll")
			for b in ui.ending_replay.get_parent().get_children().filter(func(c): return c is Button and c.is_visible_in_tree()):
				check(root.get_visible_rect().encloses(b.get_global_rect()), "ending button fits: " + b.text)
				check(not b.get_global_rect().intersects(hint_rect), "ending button clears the replay hint: " + b.text)
			ui._open_credits()
			await settle()
			bounds(ui.credits_panel)
			game.stop_all_audio()
			game.free()
	story.runs = original_runs
	check(FileAccess.file_exists(Settings.settings_path()) == had_settings, "real settings existence is unchanged")
	if had_settings:
		check(FileAccess.get_file_as_bytes(Settings.settings_path()) == original, "real settings bytes are unchanged")
		check(FileAccess.get_modified_time(real_path) == original_mtime, "real settings mtime is unchanged")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	Settings.load_settings()
	print("test_layout_bounds: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_totality_toast() -> void:
	var locale := L.current()
	var scale := Settings.text_scale
	var window := root.size
	# Same seed, camera and Sun direction as the totality_live capture on main.
	var player = preload("res://scripts/player.gd").new()
	root.add_child(player)
	player.set_physics_process(false)
	player.global_position = Vector3(0, 0.05, -0.9)
	var sun: Vector3 = Sim.new(7).sun_dir
	player.look_at_point(player.camera.global_position + sun * 10.0)
	player.rotation.y = player.yaw
	player.camera.rotation.x = player.pitch
	for language in L.LOCALES:
		L.apply(language)
		var ui = preload("res://scripts/ui.gd").new()
		root.add_child(ui)
		ui.hide_title()
		var paper = preload("res://scripts/hud_paper.gd").new()
		paper.setup(ui, preload("res://scripts/styles/engraving.gd").PAGES)
		ui.set_objectives("")
		for viewport in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1280, 800)]:
			root.size = viewport
			for text_scale in [1.0, 1.2]:
				Settings.text_scale = text_scale
				Settings.refresh_fonts(self)
				ui.set_totality(true, L.t("[b]全食[/b]　剩餘 %d 秒（共 302）") % 302 + "\n" + L.t("[color=#9c9]底片就緒[/color]"),
					preload("res://scripts/totality_cues.gd").strip_model(0.0, 302.0, [], -1.0, 4))
				await process_frame
				await process_frame
				var panel: Rect2 = ui.tot_panel.get_global_rect()
				var dialogue: Rect2 = ui.dialog_panel.get_global_rect()
				var prompt: Rect2 = ui.prompt_label.get_global_rect()
				var transform := root.get_stretch_transform()
				var sun_world: Vector3 = player.camera.global_position + sun * 10.0
				var sun_pixels: Vector2 = transform * player.camera.unproject_position(sun_world)
				var corona_edge: Vector3 = sun_world + player.camera.global_basis.x * tan(3.0 * Sim.SUN_R) * 10.0
				var corona_radius: float = sun_pixels.distance_to(transform * player.camera.unproject_position(corona_edge))
				# Main's camera also points directly at the Sun, at the frame centre.
				var main_sun_pixels := Vector2(viewport) * 0.5
				for note in ["", L.t("\nCottingham 只能自己趕著上發條，來不及對時。"), L.t("\n發條上滿了，但走速沒有校過。")]:
					context = "totality toast %s %s scale %.1f note %s" % [language, viewport, text_scale, note]
					ui.show_toast(L.t("帆布遮陽頂已經捲起。第二接觸——全食開始，節拍器開始數秒。\n抬頭看雲：雲薄時按［%s］喊「開始」，雲厚或快結束時再按一次喊「停」。") % preload("res://scripts/prompts.gd").key("shutter") + note, 7.0)
					await process_frame
					await process_frame
					var style: StyleBoxFlat = ui.toast.get_theme_stylebox("normal")
					var toast_rect: Rect2 = ui.toast.get_global_rect().grow_individual(style.expand_margin_left,
						style.expand_margin_top, style.expand_margin_right, style.expand_margin_bottom)
					var toast_pixels: Rect2 = transform * toast_rect
					var panel_pixels: Rect2 = transform * ui.tot_panel.get_global_rect()
					var gap: float = 12.0 * viewport.y / 720.0
					check(not toast_pixels.intersects(panel_pixels.grow(gap - 0.01)), "painted toast and totality panel keep scaled 12 px gap: %s / %s" % [toast_pixels, panel_pixels])
					check(toast_pixels.end.x <= panel_pixels.position.x - gap + 0.01, "toast clears panel sideways")
					for centre in [sun_pixels, main_sun_pixels]:
						var closest := Vector2(clampf(centre.x, toast_pixels.position.x, toast_pixels.end.x),
							clampf(centre.y, toast_pixels.position.y, toast_pixels.end.y))
						check(closest.distance_to(centre) >= corona_radius, "toast clears three solar radii at totality_live/main screen position %s" % centre)
					check(is_equal_approx(toast_rect.end.y, ui.hud.size.y - 60.0 + style.expand_margin_bottom), "toast keeps main's bottom margin")
					check(root.get_visible_rect().encloses(toast_rect), "all toast paper stays on screen: %s in %s" % [toast_rect, root.get_visible_rect()])
					bounds(ui.tot_panel)
					check(ui.toast.get_visible_line_count() == ui.toast.get_line_count(), "every toast line fits: %d/%d in %s (minimum %s)" % [ui.toast.get_visible_line_count(), ui.toast.get_line_count(), ui.toast.size, ui.toast.get_minimum_size()])
					check(ui.tot_label.get_content_height() <= ui.tot_label.size.y + 1, "every totality header line fits")
					check(ui.tot_panel.get_global_rect() == panel, "totality panel keeps position and size")
					check(ui.dialog_panel.get_global_rect() == dialogue and ui.prompt_label.get_global_rect() == prompt, "dialogue and prompt keep position and size")
				ui.set_totality(false)
				await process_frame
				check(is_equal_approx(ui.toast.position.y, ui.hud.size.y - 150.0), "day toast returns to its original position")
		ui.free()
	player.free()
	L.apply(locale)
	Settings.text_scale = scale
	Settings.refresh_fonts(self)
	root.size = window


func _test_merged_dialogue() -> void:
	var locale := L.current()
	var scale := Settings.text_scale
	var ui = preload("res://scripts/ui.gd").new()
	root.add_child(ui)
	ui.hide_title()
	ui.cambridge_portraits = true
	root.content_scale_size = Vector2i(1600, 900)
	root.size = Vector2i(1280, 720)
	Settings.text_scale = 1.2
	for language in L.LOCALES:
		L.apply(language)
		Settings.refresh_fonts(self)
		context = "merged dialogue %s largest text" % language
		var sim := Sim.new(1919)
		sim.rule_id = "strict"
		sim.reselected_after_seeing = true
		sim.reselect_history = [{"reason": "result"}]
		sim.plates = [
			{"number": 1, "quality": "good", "usable": true, "included": true, "read": true,
				"sigma": 0.1, "trail": 0.1, "duration": 20.0, "reading": sim.reading_for_value(1.75)},
			{"number": 2, "quality": "good", "usable": true, "included": false},
			{"number": 3, "quality": "poor", "usable": true, "included": true, "read": true,
				"sigma": 0.3, "trail": 0.5, "reading": sim.reading_for_value(1.75)},
			{"number": 4, "quality": "unusable", "usable": false, "included": true}]
		var entries: Array = []
		for telegram in Judgment.TELEGRAMS:
			for reason in Judgment.REASONS:
				for line in Judgment.grade(sim, telegram.id, reason.id).presentation:
					entries.append({"s": Content.E, "t": line})
		# Also cover the clean poor-only rule qualification and multi-plate corroboration.
		for plate in sim.plates:
			plate.included = plate.quality == "poor"
		for line in Judgment.grade(sim, "confirmed", "trailed").presentation:
			entries.append({"s": Content.E, "t": line})
		for measured in [true, false]:
			for fit in [0, 1, 2]:
				for clean in [true, false]:
					entries.append_array(Coda.ashby_answer(fit, clean, measured, true, true, true))
			entries.append_array(Coda.small_numbers(true, measured))
		for evidence in ["favors_e", "ambiguous", "none"]:
			for clean in [true, false]:
				var home := Content.go_home_alone(evidence, clean)
				if home[-1].s == Content.C:
					home[-1].t += "\n\n" + Content.cottingham_coda(sim)
				entries.append_array(home)
		for bond in ["close", "warm"]:
			for first in [0, 1, 2, -1]:
				for promise in [0, 1]:
					entries.append_array(Epilogue.kit_reunion(first, bond, promise, L.t("給 Kit：%s") % Coda.kit_first_reply(2, false)))
			entries.append_array(Coda.kit_close(bond, 0, true, false, false, 1))
		entries.append_array(Coda.workbook_again(L.t("給 Kit：%s") % Coda.kit_first_reply(2, false)))
		var seen := {}
		for entry in entries:
			if seen.has(entry.t):
				continue
			seen[entry.t] = true
			ui.play([entry])
			await settle()
			bounds(ui.dialog_panel)
			check(ui.text_label.get_content_height() <= ui.text_label.size.y + 1,
				"merged text fits dialogue box: " + str(entry.t))
	ui.free()
	L.apply(locale)
	Settings.text_scale = scale


func _test_darkroom_chart() -> void:
	var old_locale := L.current()
	var old_scale := Settings.text_scale
	var old_size := root.size
	root.size = Vector2i(1280, 720)
	var sim := Sim.new(77)
	var plate := sim.develop({"start": 0.0, "duration": 8.0, "clear": 8.0, "cloudy": 0.0, "sunlit": false}, 0)
	plate.included = true
	plate.read = true
	sim.plates = [plate]
	var max_value := sim.reading_value({"reading": float(Render.SIZE)})
	print("micrometer range: 0 to %.2f arcsec; 3.00 needs %.2f of %d plate pixels" % [max_value, sim.reading_for_value(3.0), Render.SIZE])
	check(sim.reading_for_value(3.0) <= Render.SIZE, "3.00 is reachable with the player's micrometer")
	var capture_dir := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	for locale in ["zh_TW", "en", "ja", "ko"]:
		L.apply(locale)
		var ui = load("res://scripts/ui.gd").new()
		root.add_child(ui)
		ui.hide_title()
		for scale in [1.0, 1.2]:
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			ui.chart.refresh_fonts()
			ui.open_viewer(sim.plates, null, [null], true)
			ui.viewer_rule.text = L.t("你寫下的規則：%s") % Content.rules_prompt(false)[-1].choices[0]
			ui.set_viewer_report(true)
			ui.chart.set_ledger([{"pick": 3, "kind": "original", "tag": L.t("1917 年押的：說不準")},
				{"pick": 2, "kind": "current", "tag": L.t("現在押的")}])
			var values := [0.0, 1.3, 1.75, 3.0, max_value]
			for index in values.size():
				var value: float = values[index]
				context = "darkroom %s scale %.1f result %.2f" % [locale, scale, value]
				plate.reading = sim.reading_for_value(value)
				var combined := sim.combined()
				ui.chart.set_data([{"label": "1", "value": value, "sigma": combined.sigma}], combined, true)
				var interval := L.t("%.2f″ ± %.2f″，兩倍誤差是 %.2f″ 到 %.2f″") % [value, combined.sigma, value - 2 * combined.sigma, value + 2 * combined.sigma]
				ui.play(Content.verdict_prompt(interval))
				for frame in 12:
					await process_frame
				var chart_rect: Rect2 = ui.chart.get_global_rect()
				check(chart_rect.end.y + 4 <= ui.dialog_panel.get_global_rect().position.y, "axis labels clear report dialogue: chart %s, dialogue %s" % [chart_rect, ui.dialog_panel.get_global_rect()])
				var painted: Dictionary = ui.chart.drawn()
				var label: Rect2 = painted.get("result_bounds", Rect2())
				check(label.has_area() and Rect2(Vector2.ZERO, ui.chart.size).encloses(label.grow(2)), "painted result label stays inside chart")
				check(painted.get("result_backing", false), "opaque result backing masks crossing lines")
				check(painted.label_px == Settings.fs(14), "row text keeps present size")
				for endpoint in [value - 2 * combined.sigma, value + 2 * combined.sigma]:
					var x: float = ui.chart._x(endpoint, ui.chart.size.x)
					check(x >= 1 and x <= ui.chart.size.x - 1, "whisker endpoint stays inside chart")
				if locale == "en":
					for source in ["1917 年押的：說不準", "1919 年押的：說不準", "押的（1917 年至今沒改）：說不準", "現在押的：說不準"]:
						check(L.t(source).contains("can't"), "English apostrophe uses the proportional Latin glyph")
				if capture_dir != "":
					await RenderingServer.frame_post_draw
					var path := capture_dir.path_join("%s-%s-%s.png" % [locale, "default" if scale == 1.0 else "maximum", ["zero", "left", "einstein", "3", "limit"][index]])
					check(root.get_texture().get_image().save_png(path) == OK, "windowed frame saved: " + path)
			ui.close_viewer()
			ui.dialog_panel.hide()
		ui.free()
	L.apply(old_locale)
	Settings.text_scale = old_scale
	root.size = old_size
