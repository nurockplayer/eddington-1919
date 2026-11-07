class_name Fonts
extends RefCounted
## Traditional Chinese keeps the native macOS face first; the other locales use the
## bundled faces only, so layout gates see the same glyphs on every OS.

const L := preload("res://scripts/l10n.gd")

const TC := preload("res://assets/fonts/NotoSansTC-Regular.otf")
const JP := preload("res://assets/fonts/NotoSansJP-Regular.otf")
const KR := preload("res://assets/fonts/NotoSansKR-Regular.otf")
## Primary face first, the rest as fallbacks.
const ORDERS := {
	"zh_TW": ["TC", "JP", "KR"],
	"en": ["TC", "JP", "KR"],
	"ja": ["JP", "TC", "KR"],
	"ko": ["KR", "JP", "TC"],
}


static func cjk() -> Font:
	return for_locale(L.current())


static func for_locale(locale: String) -> Font:
	var order: Array = ORDERS.get(locale, ORDERS["en"])
	if locale == "zh_TW":
		var system := SystemFont.new()
		system.font_names = PackedStringArray(["PingFang TC", "Heiti TC", "Noto Sans CJK TC", "Noto Sans TC", "Microsoft JhengHei", "Source Han Sans TC", "sans-serif"])
		system.fallbacks = _faces(order)
		return system
	var bundled := FontVariation.new()
	bundled.base_font = _face(order[0])
	bundled.fallbacks = _faces(order.slice(1))
	return bundled


static func _face(key: String) -> Font:
	return {"TC": TC, "JP": JP, "KR": KR}[key]


static func _faces(keys: Array) -> Array[Font]:
	var out: Array[Font] = []
	for key in keys:
		out.append(_face(key))
	return out
