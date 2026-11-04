extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const UI := preload("res://scripts/ui.gd")
const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")
var checks := 0
var failures := 0
var context := ""


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
	for window in [Vector2i(1600, 900), Vector2i(1280, 800), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = Vector2i(1600, 900)
		root.size = window
		for scale in [1.0, 1.2]:
			context = "%s scale %.1f" % [window, scale]
			Settings.text_scale = scale
			var ui := UI.new()
			ui.process_mode = Node.PROCESS_MODE_ALWAYS
			root.add_child(ui)
			await settle()
			var expected := Vector2(1600, 1000) if window == Vector2i(1280, 800) else Vector2(1600, 900)
			check(root.get_visible_rect().size.is_equal_approx(expected), "visible rect %s expected %s" % [root.get_visible_rect(), expected])
			ui.hide_title()
			ui.play([C17.trial_task()[3]])
			await settle()
			bounds(ui.dialog_panel)
			check(ui._choice_buttons.size() == 3, "three choices are visible")
			check(not ui.text_label.get_global_rect().intersects(ui.choice_box.get_global_rect()), "dialogue text overlaps choices")
			for i in ui._choice_buttons.size():
				for j in range(i + 1, ui._choice_buttons.size()):
					check(not ui._choice_buttons[i].get_global_rect().intersects(ui._choice_buttons[j].get_global_rect()), "choice buttons overlap")
			ui.toggle_pause()
			await settle()
			bounds(ui.pause_panel)
			ui.toggle_pause()
			ui.open_viewer([], null, [], false)
			ui.set_viewer_note("測量筆記")
			await settle()
			bounds(ui.viewer)
			ui.viewer_rule.text = "測量規則"
			ui.set_viewer_report(true)
			await settle()
			bounds(ui.viewer)
			ui.close_viewer()
			var overlay := Overlay.new()
			root.add_child(overlay)
			overlay.open()
			await settle()
			bounds(overlay)
			overlay.free()
			var checklist := Checklist.new()
			root.add_child(checklist)
			checklist.open()
			await settle()
			bounds(checklist)
			checklist.free()
			ui.show_ending("結局", "結束。", "歷史", "回顧", "電報內容", null, "底片")
			await settle()
			bounds(ui.ending_panel)
			ui._open_credits()
			await settle()
			bounds(ui.credits_panel)
			ui.free()
	Settings.load_settings()
	print("test_layout_bounds: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
