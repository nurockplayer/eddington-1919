extends SceneTree
## Locale resolution, the startup choice, translation lookup and per-locale glyphs.

const L := preload("res://scripts/l10n.gd")
const Fonts := preload("res://scripts/fonts.gd")
const Settings := preload("res://scripts/settings.gd")
const Content := preload("res://scripts/content.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Prompts := preload("res://scripts/prompts.gd")

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


## The plural path: msgid and msgid_plural are the same source sentence, and the
## real en.po supplies the two English forms.
func plural_checks() -> void:
	var msgid := "Eddington：「還有 %d 張底片。」"
	L.apply("en")
	check(L.tn(msgid, 1) == "Eddington: \"%d plate left.\"", "en singular form at 1, got " + L.tn(msgid, 1))
	check(L.tn(msgid, 3) == "Eddington: \"%d plates left.\"", "en plural form at 3, got " + L.tn(msgid, 3))
	check(L.tn(msgid, 3) % 3 == "Eddington: \"3 plates left.\"", "the caller formats the count")
	check(L.t("") == "", "the header entry does not leak into a blank speaker")
	L.apply("zh_TW")
	check(L.tn(msgid, 1) == msgid and L.tn(msgid, 3) == msgid, "zh-TW shows the source text at every count")


## In English the cable stands alone; the zh gloss would only repeat it.
func telegram_checks() -> void:
	L.apply("en")
	var labels: Array = Judgment.telegram_choices()
	check(labels[0] == "ECLIPSE SPLENDID. EINSTEIN CONFIRMED.",
		"en cable with no gloss, got " + str(labels[0]))
	check(labels.size() == 4 and not str(labels[3]).contains("（"),
		"en cables carry no full-width gloss")
	L.apply("zh_TW")
	check(Judgment.telegram_choices()[0] == "ECLIPSE SPLENDID. EINSTEIN CONFIRMED.（日食極佳，愛因斯坦得證）",
		"zh-TW keeps the gloss, got " + str(Judgment.telegram_choices()[0]))


## Both hold modes keep the instruction sentence the player saw before the split.
func hold_line_checks() -> void:
	var previous := Settings.hold_toggle
	Settings.hold_toggle = false
	check(Content.cottingham_first()[2].t
		== "你先在驅動箱上[b]按住 %s 上發條[/b]，然後到桌上的[b]天文鐘[/b]那裡替我報秒。" % Prompts.key("interact"),
		"holding mode keeps the old sentence")
	Settings.hold_toggle = true
	check(Content.cottingham_first()[2].t
		== "你先在驅動箱上[b]按一下 %s 開始上發條[/b]，然後到桌上的[b]天文鐘[/b]那裡替我報秒。" % Prompts.key("interact"),
		"single-press mode keeps the old sentence")
	Settings.hold_toggle = previous


## Saved text stays source text: a run recorded under en keeps the zh-TW msgid.
func record_reason_check() -> void:
	var story = root.get_node("Story")
	check(change_scene_to_file("res://scenes/main.tscn") == OK, "main scene loads for the reason record")
	await settle()
	var game = current_scene
	game.set_process(false)
	L.apply("en")
	game._reasons = []
	game._reason = 0
	game._grade = {"score": 0, "clean": true}
	game._record_run()
	check(story.runs.size() == 1, "the run is recorded")
	var stored: String = str(story.runs.back().get("reason_text", ""))
	check(stored == "量得的偏折較接近 1.75″，而且有足夠星點的底片支持。",
		"en stores the source text of reason_text, got " + stored)
	L.apply("zh_TW")


## The saved language reads back the way _startup_locale reads it before Settings loads.
## Suites start under --script, which skips the saved choice, so this calls the reader
## directly, on a scratch file: the env path points away from any real settings file.
func saved_locale_checks() -> void:
	var env_before := OS.get_environment("EDD_SETTINGS_PATH")
	var path := ProjectSettings.globalize_path("user://test-i18n-saved-locale.cfg")
	OS.set_environment("EDD_SETTINGS_PATH", path)
	var language := Settings.language
	for pair in [["ko", "ko"], ["ja", "ja"], ["en", "en"], ["zh_TW", "zh_TW"], ["xx", ""]]:
		Settings.language = pair[0]
		check(Settings.save_language() == OK, "language %s saved" % pair[0])
		check(L._saved_locale() == pair[1], "saved %s reads back as '%s', got '%s'" % [pair[0], pair[1], L._saved_locale()])
	Settings.language = language
	DirAccess.remove_absolute(path)
	if env_before.is_empty():
		OS.unset_environment("EDD_SETTINGS_PATH")
	else:
		OS.set_environment("EDD_SETTINGS_PATH", env_before)


## Startup uses the saved player language after the script and environment overrides.
func startup_locale_checks() -> void:
	var env_before := OS.get_environment("EDD_SETTINGS_PATH")
	var path := ProjectSettings.globalize_path("user://test-i18n-startup-locale.cfg")
	DirAccess.remove_absolute(path)
	OS.set_environment("EDD_SETTINGS_PATH", path)
	var language := Settings.language
	var empty_args := PackedStringArray()
	var empty_user_args := PackedStringArray()
	if L.TRANSLATED:
		Settings.language = "ko"
		check(Settings.save_language() == OK, "startup saved ko")
		check(L._startup_locale(empty_args, empty_user_args, "", "en_US") == "ko",
			"startup prefers saved ko over en_US")
		Settings.language = "ja"
		check(Settings.save_language() == OK, "startup saved ja")
		check(L._startup_locale(empty_args, empty_user_args, "", "ko_KR") == "ja",
			"startup prefers saved ja over ko_KR")

	DirAccess.remove_absolute(path)
	check(L._startup_locale(empty_args, empty_user_args, "", "ja_JP") == "ja",
		"startup uses ja_JP when no language is saved")
	check(L._startup_locale(empty_args, empty_user_args, "", "de_DE") == "en",
		"startup resolves de_DE to en when no language is saved")

	if L.TRANSLATED:
		Settings.language = "ko"
		check(Settings.save_language() == OK, "startup saved ko for env precedence")
		check(L._startup_locale(empty_args, empty_user_args, "en", "ko_KR") == "en",
			"startup env wins over saved ko")
		check(L._startup_locale(PackedStringArray(["--script", "x.gd"]), empty_user_args, "", "en_US") == "zh_TW",
			"startup script launch stays zh-TW")
		check(L._startup_locale(empty_args, PackedStringArray(["--autoplay=careful"]), "", "en_US") == "zh_TW",
			"startup autoplay launch stays zh-TW")
		Settings.language = "xx"
		check(Settings.save_language() == OK, "startup saved unsupported xx")
		check(L._startup_locale(empty_args, empty_user_args, "", "ko_KR") == "ko",
			"startup ignores unsupported saved language and uses ko_KR")

	Settings.language = language
	DirAccess.remove_absolute(path)
	if env_before.is_empty():
		OS.unset_environment("EDD_SETTINGS_PATH")
	else:
		OS.set_environment("EDD_SETTINGS_PATH", env_before)


## The dev pseudo locale: L.t and L.tn reach the ASCII catalogue, and the game's
## own language stays en so fonts and language logic do not change.
func pseudo_checks() -> void:
	var path := ProjectSettings.globalize_path("res://.godot/test-pseudo.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"設定": "xxxxxxaaaa",
		"Eddington：「還有 %d 張底片。」": "Eddington:\"xxxxxxbbbb %d xxxxxxxxxbbbb.\"",
	}))
	file.close()
	var before := L.current()
	L._load_pseudo(path)
	check(TranslationServer.get_locale() == "en_XA", "the pseudo locale is active")
	check(L.current() == before, "the pseudo locale leaves L.language alone")
	check(L.t("設定") == "xxxxxxaaaa", "L.t returns the pseudo text, got " + L.t("設定"))
	var plural := "Eddington：「還有 %d 張底片。」"
	var expected := "Eddington:\"xxxxxxbbbb %d xxxxxxxxxbbbb.\""
	check(L.tn(plural, 1) == expected, "L.tn returns the pseudo text at 1, got " + L.tn(plural, 1))
	check(L.tn(plural, 3) == expected, "L.tn returns the pseudo text at 3, got " + L.tn(plural, 3))
	check(L.t("沒有這一句") == "沒有這一句", "an unknown string returns itself under the pseudo locale")
	TranslationServer.remove_translation(L.pseudo_translation)
	L.pseudo_translation = null
	L.apply(before)
	DirAccess.remove_absolute(path)


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
	plural_checks()
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
	telegram_checks()
	hold_line_checks()
	await reload_check()
	await record_reason_check()
	saved_locale_checks()
	startup_locale_checks()
	pseudo_checks()
	print("test_i18n: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
