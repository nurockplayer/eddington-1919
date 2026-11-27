extends PanelContainer

const Settings := preload("res://scripts/settings.gd")
const PRINT_SIZE := 204.0
## Owner-selected P1 prints. This CanvasLayer control never receives the 3D
## environment grade: the source images already carry their toned-print look.
const Cast := preload("res://scripts/cambridge/cast.gd")
const PRINTS := {
	Cast.MENTOR: {
		"neutral": "res://assets/portraits/ashby_neutral.jpg",
		"doubt": "res://assets/portraits/ashby_doubt.jpg",
	},
	Cast.EDDINGTON: {
		"neutral": "res://assets/portraits/eddington_neutral.jpg",
		"intent": "res://assets/portraits/eddington_intent.jpg",
	},
}

var prints_override := {}
var image: TextureRect
var disclosure: Label
var _paper := false
var _disclosure_text: String


func setup(muted: Color) -> void:
	name = "DialoguePortrait"
	size = Vector2(224, 256)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mount := StyleBoxFlat.new()
	mount.bg_color = Color(0.12, 0.105, 0.085, 0.98)
	mount.border_color = Color(0.42, 0.36, 0.27)
	mount.set_border_width_all(1)
	mount.set_content_margin_all(10)
	add_theme_stylebox_override("panel", mount)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	add_child(column)
	image = TextureRect.new()
	image.custom_minimum_size = Vector2(PRINT_SIZE, PRINT_SIZE)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(image)
	disclosure = Label.new()
	disclosure.size.x = 204
	_disclosure_text = L.t("重建肖像，非歷史照片")
	disclosure.text = _disclosure_text
	disclosure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disclosure.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Settings.track_font(disclosure, 18)
	disclosure.add_theme_color_override("font_color", muted)
	disclosure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(disclosure)
	hide()


func set_paper(paper: bool) -> void:
	if paper == _paper:
		return
	_paper = paper
	image.custom_minimum_size = Vector2(162, 216) if paper else Vector2(PRINT_SIZE, PRINT_SIZE)
	image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if paper else Control.SIZE_FILL
	disclosure.autowrap_mode = TextServer.AUTOWRAP_OFF if paper else TextServer.AUTOWRAP_WORD_SMART
	var ideographic_comma := String.chr(0x3001)
	var fullwidth_comma := String.chr(0xff0c)
	disclosure.text = _disclosure_text.replace(", ", ",").replace(",", ",\n").replace(ideographic_comma, ideographic_comma + "\n").replace(fullwidth_comma, fullwidth_comma + "\n") if paper else _disclosure_text
	Settings.track_font(disclosure, 16 if paper else 18)


func show_entry(entry: Dictionary) -> void:
	var fictional_portrait: Texture2D = entry.get("fictional_portrait")
	if fictional_portrait != null:
		image.texture = fictional_portrait
		disclosure.text = "(Fiction)"
		show()
		return
	if not _paper:
		disclosure.text = _disclosure_text
	var speaker := str(entry.get("s", ""))
	var variants: Dictionary = PRINTS.get(speaker, {})
	if prints_override.has(speaker):
		image.texture = load(prints_override[speaker]) as Texture2D
		visible = image.texture != null
		return
	if variants.is_empty():
		image.texture = null
		hide()
		return
	# Lazy load only after Cambridge opts in; shared 1919 UI pays no texture cost.
	# Only approved variants: an unknown mood falls back to neutral.
	var path: String = variants.get(str(entry.get("mood", "neutral")), variants.neutral)
	image.texture = load(path) as Texture2D
	visible = image.texture != null
