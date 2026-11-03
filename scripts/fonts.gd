extends RefCounted
## Keep the native macOS face first, with a shipped Traditional Chinese fallback.


static func cjk() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["PingFang TC", "Heiti TC", "Noto Sans CJK TC", "Noto Sans TC", "Microsoft JhengHei", "Source Han Sans TC", "sans-serif"])
	font.fallbacks = [preload("res://assets/fonts/NotoSansTC-Regular.otf")]
	return font
