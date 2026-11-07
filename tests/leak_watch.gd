extends Node
## Watches every visible text node for CJK while the game runs under the pseudo
## locale (EDD_PSEUDO_JSON). Any hit is a string that never reached L.t.
## A bot adds this node, calls finish() once at the end, and the route fails when
## `[LEAK] total` is above 0.

const INTERVAL := 30

var _cjk := RegEx.new()
var _seen: Dictionary = {}
var _leaks: Array[String] = []
var _frames := 0
var _done := false


func _ready() -> void:
	# Same ranges as CJK_RE in tools/i18n.py.
	_cjk.compile("[\\x{3000}-\\x{303f}\\x{3040}-\\x{30ff}\\x{3400}-\\x{9fff}\\x{ac00}-\\x{d7af}\\x{ff00}-\\x{ffef}]")


func _process(_delta: float) -> void:
	_frames += 1
	if _frames % INTERVAL == 0:
		scan()


func scan() -> void:
	if is_inside_tree():
		_walk(get_tree().root)


func _walk(node: Node) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	if node is Node3D and not node.is_visible_in_tree():
		return
	var shown := _text_of(node)
	if not shown.is_empty() and _cjk.search(shown) != null:
		_report(node, shown)
	for child in node.get_children():
		_walk(child)


func _text_of(node: Node) -> String:
	if node is RichTextLabel:
		return (node as RichTextLabel).get_parsed_text()
	if node is Label:
		return (node as Label).text
	if node is Button:
		return (node as Button).text
	if node is Label3D:
		return (node as Label3D).text
	if node is LineEdit:
		return (node as LineEdit).text
	if node is TextEdit:
		return (node as TextEdit).text
	if node.has_method("drawn_texts"):
		return "\n".join(node.drawn_texts())
	return ""


func _report(node: Node, shown: String) -> void:
	var where := (node as Node).scene_file_path
	if where.is_empty():
		where = str(node.get_path())
	var key := where + "\u0000" + shown
	if _seen.has(key):
		return
	_seen[key] = true
	_leaks.append(key)
	print("[LEAK] %s: %s" % [where, shown])


## The route's end: one last scan, then the count the bot and e2e_headless.sh read.
func finish() -> int:
	if not _done:
		_done = true
		scan()
		set_process(false)
		print("[LEAK] total %d" % _leaks.size())
	return _leaks.size()
