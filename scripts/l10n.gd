class_name L
extends RefCounted
## Translation for every player-facing string. zh-TW source text is the msgid.

const Settings := preload("res://scripts/settings.gd")
const Checkpoint := preload("res://scripts/checkpoint.gd")

const LOCALES := ["zh_TW", "en", "ja", "ko"]
const NAMES := {"zh_TW": "繁體中文", "en": "English", "ja": "日本語", "ko": "한국어"}
## en, ja and ko are fully translated (oracle meaning checks, blind reads #286/#287), so a
## release picks the saved or OS language and shows the language button. Set false to ship
## on the source text only; EDD_LOCALE still reaches the other locales.
const TRANSLATED := true

## The locale in use; `_static_init` picks it before any scene reads a string.
static var language := ""
## The dev-only pseudo Translation, kept so the suites can remove it again.
static var pseudo_translation: Translation = null


static func _static_init() -> void:
	apply(_startup_locale())
	if not OS.has_feature("template") and OS.has_environment("EDD_PSEUDO_JSON"):
		_load_pseudo(OS.get_environment("EDD_PSEUDO_JSON"))


## A generated catalogue whose every msgid is ASCII: any CJK left on screen is a
## leak. The server locale changes, `language` does not, so fonts and language
## logic keep acting as `en`. Exported templates never see EDD_PSEUDO_JSON.
static func _load_pseudo(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	var data = JSON.parse_string(text) if not text.is_empty() else null
	if not data is Dictionary:
		push_warning("pseudo catalogue not readable: " + path)
		return
	var translation := Translation.new()
	translation.locale = "en_XA"
	for msgid in data:
		var value := str(data[msgid])
		translation.add_message(msgid, value)
		# L.tn asks for both forms; the pseudo text is the same at any count.
		translation.add_plural_message(msgid, PackedStringArray([value, value]))
	TranslationServer.add_translation(translation)
	TranslationServer.set_locale("en_XA")
	pseudo_translation = translation


static func t(s: String) -> String:
	return String(TranslationServer.translate(s))


## A sentence with one count whose noun inflects in English. The msgid is both forms.
static func tn(s: String, n: int) -> String:
	return String(TranslationServer.translate_plural(s, s, n))


## Simplified and Hong Kong readers get Traditional rather than English.
static func resolve(os_locale: String) -> String:
	var tag := os_locale.replace("-", "_").to_lower()
	if tag.begins_with("zh"):
		return "zh_TW"
	if tag.begins_with("ja"):
		return "ja"
	if tag.begins_with("ko"):
		return "ko"
	return "en"


static func apply(locale: String) -> void:
	language = locale
	TranslationServer.set_locale(locale)
	# project.godot's config/name is the zh-TW title; the window follows the locale.
	# Deferred, so the engine's own startup title cannot land after this one.
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title.call_deferred(L.t("雲層之後 · Eddington 1919"))


static func current() -> String:
	return language


static func cycle() -> String:
	apply(LOCALES[(LOCALES.find(current()) + 1) % LOCALES.size()])
	Settings.language = current()
	Settings.save_language()
	return current()


## Env override, then the suites and bots (zh-TW text is what they assert), then the
## saved choice, then the OS locale.
static func _startup_locale() -> String:
	var env := OS.get_environment("EDD_LOCALE")
	if not env.is_empty():
		return resolve(env)
	if _script_or_bot():
		return "zh_TW"
	if not TRANSLATED:
		return "zh_TW"
	var saved := _saved_locale()
	if not saved.is_empty():
		return saved
	return resolve(OS.get_locale())


static func _script_or_bot() -> bool:
	if OS.get_cmdline_args().has("--script"):
		return true
	var flags := {}
	for argument in OS.get_cmdline_user_args():
		flags[argument.trim_prefix("--").split("=", true, 1)[0]] = true
	for flag in Checkpoint.BOT_ARGS:
		if flags.has(flag):
			return true
	return false


## Read the settings file directly: load_settings may not have run yet.
static func _saved_locale() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(Settings.settings_path()) != OK:
		return ""
	var saved := str(cfg.get_value("ui", "language", ""))
	return saved if saved in LOCALES else ""
