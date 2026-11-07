class_name L
extends RefCounted
## Translation for every player-facing string. zh-TW source text is the msgid.

const Settings := preload("res://scripts/settings.gd")
const Checkpoint := preload("res://scripts/checkpoint.gd")

const LOCALES := ["zh_TW", "en", "ja", "ko"]
const NAMES := {"zh_TW": "繁體中文", "en": "English", "ja": "日本語", "ko": "한국어"}
## Turn on once en, ja and ko are fully translated. Until then a release stays on the
## source text with no language button; EDD_LOCALE still reaches the other locales.
const TRANSLATED := false

## The locale in use; `_static_init` picks it before any scene reads a string.
static var language := ""


static func _static_init() -> void:
	apply(_startup_locale())


static func t(s: String) -> String:
	return String(TranslationServer.translate(s))


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
