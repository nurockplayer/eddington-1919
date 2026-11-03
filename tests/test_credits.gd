extends SceneTree

const Credits := preload("res://scripts/credits.gd")

var checks := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	call_deferred("_run")


func _button(panel: Control, text: String) -> Button:
	for button in panel.find_children("*", "Button", true, false):
		if button.text == text:
			return button as Button
	return null


func _run() -> void:
	var text := Credits.text()
	check(text.contains(str(ProjectSettings.get_setting("application/config/version"))), "credits contain project version")
	check(text.contains(Credits.AUTHOR), "credits contain Owner-editable author")
	check(text.contains("以 Godot Engine 製作"), "credits name the engine")
	check(text.contains("史實與虛構") and text.contains(Credits.DISCLAIMER), "credits contain historical disclaimer")
	var notice := FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.md")
	check(text.contains(notice.replace("[", "[lb]")), "credits contain complete escaped third-party notice")
	check(text.contains(Engine.get_license_text().replace("[", "[lb]")), "credits contain complete escaped engine licence")
	var components := Engine.get_copyright_info()
	check(not components.is_empty(), "engine supplies third-party components")
	for component in components:
		check(text.contains(str(component.name).replace("[", "[lb]")), "credits name component " + str(component.name))
		for part in component.parts:
			for copyright in part.copyright:
				check(text.contains(str(copyright).replace("[", "[lb]")), "credits contain component copyright")
			check(text.contains(str(part.license).replace("[", "[lb]")), "credits contain component licence identifier")
	var licenses := Engine.get_license_info()
	check(not licenses.is_empty(), "engine supplies third-party licence texts")
	for license in licenses:
		check(text.contains(str(license).replace("[", "[lb]")), "credits name licence " + str(license))
		check(text.contains(str(licenses[license]).replace("[", "[lb]")), "credits contain full licence " + str(license))
	check(change_scene_to_file(str(ProjectSettings.get_setting("application/run/main_scene"))) == OK, "headless main loads")
	await process_frame
	await process_frame
	var ui = current_scene.ui
	check(not ui.credits_panel.visible, "credits start hidden")
	var title_has_disclaimer := false
	for label in ui.title_panel.find_children("*", "RichTextLabel", true, false):
		if label.text.contains(Credits.DISCLAIMER):
			title_has_disclaimer = true
	check(title_has_disclaimer, "title uses the identical historical disclaimer")
	var back := _button(ui.credits_panel, "返回")
	check(back != null, "credits have a return button")
	var scroll := ui.credits_panel.find_child("Scroll", true, false) as ScrollContainer
	check(scroll != null, "credits have a scroll container")
	var label := scroll.get_child(0) as RichTextLabel
	check(label != null and label.text == text, "scroll panel displays all credits")
	check(label.get_theme_font("normal_font") == ui.font, "credits inherit the theme font")
	check(label.get_parsed_text().contains(Engine.get_license_text()), "BBCode parsing preserves engine licence verbatim")
	check(label.get_parsed_text().contains(notice), "BBCode parsing preserves notice links and brackets verbatim")
	ui.hide_title()
	ui.show_ending("結局", "雲層之後")
	for menu in [ui.ending_panel, ui.title_panel]:
		ui.ending_panel.visible = menu == ui.ending_panel
		ui.title_panel.visible = menu == ui.title_panel
		var open := _button(menu, "製作名單")
		check(open != null, "menu contains credits button")
		if open == null or back == null:
			continue
		open.pressed.emit()
		await process_frame
		await process_frame
		check(ui.credits_panel.is_visible_in_tree(), "menu button opens shared credits panel")
		check(back.has_focus(), "return receives keyboard/gamepad focus")
		check(root.get_visible_rect().encloses(back.get_global_rect()), "return stays inside viewport")
		check(root.get_visible_rect().encloses(open.get_global_rect()), "credits menu button stays inside viewport")
		check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "licence content overflows and can scroll")
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await process_frame
		check(label.get_global_rect().end.y <= scroll.get_global_rect().end.y + 2, "scroll reaches the end of all licence texts")
		check(back.is_visible_in_tree(), "return remains visible at bottom of credits")
		back.pressed.emit()
		check(not ui.credits_panel.visible, "return hides credits")
		check(menu.visible, "return preserves originating menu")
		open.pressed.emit()
		check(scroll.scroll_vertical == 0, "reopening credits resets scroll")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape)
		await process_frame
		check(not ui.credits_panel.visible and not paused, "Escape closes credits without pausing main")
		open.pressed.emit()
		var accept := InputEventAction.new()
		accept.action = "ui_accept"
		accept.pressed = true
		root.push_input(accept)
		accept = InputEventAction.new()
		accept.action = "ui_accept"
		accept.pressed = false
		root.push_input(accept)
		await process_frame
		check(not ui.credits_panel.visible, "focused return closes with ui_accept")
	current_scene.queue_free()
	await process_frame
	print("%d credits checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
