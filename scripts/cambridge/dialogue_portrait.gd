extends PanelContainer
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

var image: TextureRect
var disclosure: Label


func setup(muted: Color) -> void:
	name = "DialoguePortrait"
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
	image.custom_minimum_size = Vector2(204, 204)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(image)
	disclosure = Label.new()
	disclosure.text = "重建肖像，非歷史照片"
	disclosure.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disclosure.add_theme_font_size_override("font_size", 18)
	disclosure.add_theme_color_override("font_color", muted)
	disclosure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(disclosure)
	hide()


func show_entry(entry: Dictionary) -> void:
	var variants: Dictionary = PRINTS.get(str(entry.get("s", "")), {})
	if variants.is_empty():
		image.texture = null
		hide()
		return
	# Lazy load only after Cambridge opts in; shared 1919 UI pays no texture cost.
	# Only approved variants: an unknown mood falls back to neutral.
	var path: String = variants.get(str(entry.get("mood", "neutral")), variants.neutral)
	image.texture = load(path) as Texture2D
	visible = image.texture != null
