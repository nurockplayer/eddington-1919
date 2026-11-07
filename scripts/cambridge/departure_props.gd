extends Node3D
class_name CambridgeDepartureWorkbook

const Fonts := preload("res://scripts/fonts.gd")
## Small procedural workbook prop used in the Cambridge departure room and the
## Príncipe darkroom. Keeps the final Kit sentence on the night page.

var _leaf: MeshInstance3D
var _cover_pivot: Node3D
var _opened := false
var kit_line := ""


func _ready() -> void:
	var leather := StandardMaterial3D.new()
	leather.albedo_color = Color(0.30, 0.21, 0.14)
	leather.roughness = 0.9
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.80, 0.74, 0.62)
	paper.roughness = 0.95
	_cover_pivot = Node3D.new()
	_cover_pivot.name = "WorkbookCoverHinge"
	_cover_pivot.position = Vector3(0, 0.018, -0.17)
	add_child(_cover_pivot)
	var cover_mesh := BoxMesh.new()
	cover_mesh.size = Vector3(0.48, 0.035, 0.34)
	var cover := MeshInstance3D.new()
	cover.name = "WorkbookCover"
	cover.mesh = cover_mesh
	cover.material_override = leather
	cover.position = Vector3(0, 0, 0.17)
	_cover_pivot.add_child(cover)
	var page_mesh := BoxMesh.new()
	page_mesh.size = Vector3(0.44, 0.012, 0.30)
	_leaf = MeshInstance3D.new()
	_leaf.name = "DatedBlankPage"
	_leaf.mesh = page_mesh
	_leaf.material_override = paper
	_leaf.position = Vector3(0, 0.047, 0)
	_leaf.visible = false
	add_child(_leaf)
	var date := Label3D.new()
	date.name = "WorkbookDate"
	date.text = L.t("1919 年 5 月 29 日")
	date.font = Fonts.cjk()
	date.font_size = 38
	date.pixel_size = 0.0013
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date.modulate = Color(0.24, 0.18, 0.12)
	date.position = Vector3(0, 0.057, -0.09)
	date.rotation.x = deg_to_rad(-90)
	date.visible = false
	add_child(date)
	set_meta("date_label", date)


func open_workbook() -> void:
	if _opened:
		return
	_opened = true
	_leaf.visible = true
	var date: Label3D = get_meta("date_label")
	date.visible = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_cover_pivot, "rotation:x", deg_to_rad(-112), 0.55)


func write_kit_line(line: String) -> void:
	kit_line = line
	var note := Label3D.new()
	note.name = "WorkbookKitLine"
	note.text = kit_line
	note.font = Fonts.cjk()
	note.font_size = 18
	note.pixel_size = 0.001
	note.width = 380
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color(0.24, 0.18, 0.12)
	note.position = Vector3(0, 0.058, 0.03)
	note.rotation.x = deg_to_rad(-90)
	add_child(note)
