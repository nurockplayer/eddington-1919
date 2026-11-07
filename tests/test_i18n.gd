extends SceneTree
## Locale resolution, the startup choice, translation lookup and per-locale glyphs.

const L := preload("res://scripts/l10n.gd")
const Fonts := preload("res://scripts/fonts.gd")
const Settings := preload("res://scripts/settings.gd")

var checks := 0
var failures := 0


func settle() -> void:
	for i in 4:
		await process_frame


## msgid/msgstr pairs of a .po file; the tools/i18n.py writer puts each on one line.
func po_entries(path: String) -> Array:
	var entries: Array = []
	var text := FileAccess.get_file_as_string(path)
	var msgid := ""
	for line in text.split("\n"):
		if line.begins_with("msgid "):
			msgid = str(JSON.parse_string(line.substr(6)))
		elif line.begins_with("msgstr "):
			entries.append([msgid, str(JSON.parse_string(line.substr(7)))])
	return entries


## The language button reloads the scene: the title must come back, not a panel,
## and the chosen text size must survive the reload.
func reload_check() -> void:
	# A throwaway settings file, never the player's and never another suite's.
	var previous_env := OS.get_environment("EDD_SETTINGS_PATH")
	var temp_path := ProjectSettings.globalize_path("user://test-i18n-reload.cfg")
	DirAccess.remove_absolute(temp_path)
	OS.set_environment("EDD_SETTINGS_PATH", temp_path)
	var previous := Settings.text_scale
	check(change_scene_to_file("res://scenes/main.tscn") == OK, "title scene loads")
	await settle()
	var main = current_scene
	main.set_process(false)
	Settings.text_scale = 1.2
	check(Settings.save_settings() == OK, "text size saved before reload")
	check(reload_current_scene() == OK, "reload_current_scene")
	await settle()
	main = current_scene
	var ui = main.ui
	check(ui.title_panel.visible, "reload lands on the title")
	check(not ui.pause_panel.visible and not ui.dialog_active(), "no panel open after reload")
	check(Settings.text_scale == 1.2, "text size kept across the reload, got " + str(Settings.text_scale))
	check(ui.theme_res.default_font_size == Settings.fs(21), "reloaded theme uses the kept text size")
	Settings.text_scale = previous
	OS.set_environment("EDD_SETTINGS_PATH", previous_env)
	DirAccess.remove_absolute(temp_path)


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Suites run with --script, so startup rule 2 keeps the zh-TW source text.
	check(L.current() == "zh_TW", "suite startup stays zh-TW, got " + L.current())
	if not L.TRANSLATED:
		check(L._startup_locale() == "zh_TW", "an untranslated release stays on the source text")
	for pair in [["zh_TW", "zh_TW"], ["zh_HK", "zh_TW"], ["zh_CN", "zh_TW"], ["ja_JP", "ja"],
			["ko_KR", "ko"], ["en_US", "en"], ["de_DE", "en"], ["", "en"]]:
		check(L.resolve(pair[0]) == pair[1], "resolve(%s) is %s" % [pair[0], pair[1]])
	L.apply("zh_TW")
	check(L.t("設定") == "設定", "zh-TW shows the source text, got " + L.t("設定"))
	check(L.t("語言：%s") % L.NAMES["zh_TW"] == "語言：繁體中文", "zh-TW language caption, got " + L.t("語言：%s"))
	L.apply("en")
	check(L.t("設定") == "Settings", "en translates 設定, got " + L.t("設定"))
	check(L.t("語言：%s") % L.NAMES["en"] == "Language: English", "en language caption")
	for pair in po_entries("res://locale/en.po"):
		if pair[0].is_empty() or pair[1].is_empty():
			continue
		check(L.t(pair[0]) == pair[1], "en.po entry reaches the game: " + pair[0])
	L.apply("ja")
	check(L.t("語言：%s") % L.NAMES["ja"] == "言語：日本語", "ja language caption")
	L.apply("ko")
	check(L.t("設定") == "설정", "ko translates 設定, got " + L.t("設定"))
	check(L.t("語言：%s") % L.NAMES["ko"] == "언어: 한국어", "ko language caption")
	check(L.t("沒有這一句") == "沒有這一句", "unknown string returns itself")
	for locale in L.LOCALES:
		var font := Fonts.for_locale(locale)
		check(font != null, locale + " has a UI font")
		for character in ["한", "の", "繁"]:
			check(font.has_char(character.unicode_at(0)), "%s font covers %s" % [locale, character])
	L.apply("zh_TW")
	check(L.current() == "zh_TW", "locale restored to zh-TW")
	check(root.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED,
		"root auto-translate stays off")
	await reload_check()
	print("test_i18n: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
