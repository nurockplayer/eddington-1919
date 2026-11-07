extends SceneTree
## Locale resolution, the startup choice, translation lookup and per-locale glyphs.

const L := preload("res://scripts/l10n.gd")
const Fonts := preload("res://scripts/fonts.gd")

var checks := 0
var failures := 0


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
	for pair in [["zh_TW", "zh_TW"], ["zh_HK", "zh_TW"], ["zh_CN", "zh_TW"], ["ja_JP", "ja"],
			["ko_KR", "ko"], ["en_US", "en"], ["de_DE", "en"], ["", "en"]]:
		check(L.resolve(pair[0]) == pair[1], "resolve(%s) is %s" % [pair[0], pair[1]])
	L.apply("zh_TW")
	check(L.t("設定") == "設定", "zh-TW shows the source text, got " + L.t("設定"))
	check(L.t("語言：%s") % L.NAMES["zh_TW"] == "語言：繁體中文", "zh-TW language caption, got " + L.t("語言：%s"))
	L.apply("en")
	check(L.t("設定") == "Settings", "en translates 設定, got " + L.t("設定"))
	check(L.t("語言：%s") % L.NAMES["en"] == "Language: English", "en language caption")
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
	print("test_i18n: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
