extends Control
## FICTION: illustrative tracking diagram, not a documented pre-eclipse check.
## Cottingham handles the mechanism; the player observes and requests changes.
const Settings := preload("res://scripts/settings.gd")
const Print := preload("res://scripts/styles/engraving.gd")
const Prompts := preload("res://scripts/prompts.gd")
signal finished
const DEADBAND := preload("res://scripts/eclipse_sim.gd").DRIVE_DEADBAND
const COARSE_RATE := 0.06
const FINE_RATE := 0.015
var sim
var elapsed := 0.0
var stable := 0.0
var measured_drift := 24.0 # signed pixels per second, observable by player and bots
var sample_time := 0.0
var displacement := 0.0
var sampled_position := 0.0
var previous_mark := 0.0
var now_mark := 0.0
var no_improvement := 0.0
var best_drift := INF
var hinted := false
var released := false
var caption: Label
var status: Label
var controls: Label
var hint: Label
var sheet: PanelContainer
var diagram: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	sheet = PanelContainer.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.offset_left = 32
	sheet.offset_right = -32
	sheet.offset_top = 24
	sheet.offset_bottom = -24
	var paper := StyleBoxFlat.new()
	paper.bg_color = Print.PAPER
	paper.border_color = Print.INK
	paper.set_border_width_all(1)
	paper.set_content_margin_all(24)
	sheet.add_theme_stylebox_override("panel", paper)
	add_child(sheet)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	sheet.add_child(box)
	caption = _label(box, L.t("追蹤示意圖——示意重建，非史料"))
	diagram = Control.new()
	diagram.custom_minimum_size.y = 180
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.draw.connect(_draw_diagram)
	box.add_child(diagram)
	status = _label(box, "")
	hint = _label(box, L.t("觀察星像的移動，再請 Cottingham 微調。位置是否居中並不重要。"))
	controls = _label(box, "")
	_refresh_text()


func _label(parent: Control, text_: String) -> Label:
	var label := Label.new()
	label.text = text_
	label.add_theme_color_override("font_color", Print.INK)
	Settings.track_font(label, 22)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func open(state) -> void:
	sim = state
	elapsed = 0.0
	stable = 0.0
	sample_time = 0.0
	displacement = 0.0
	sampled_position = 0.0
	previous_mark = 0.0
	now_mark = 0.0
	measured_drift = 0.0
	best_drift = absf(sim.drive_error) * 24.0
	no_improvement = 0.0
	hinted = false
	released = false
	hint.text = L.t("觀察星像的移動，再請 Cottingham 微調。位置是否居中並不重要。")
	show()
	_refresh_text()
	diagram.queue_redraw()


func advance(delta: float) -> void:
	if not visible or get_tree().paused:
		return
	if not Input.is_action_pressed("interact"):
		released = true
	var dt := minf(delta, 45.0 - elapsed)
	var direction := Input.get_axis("ui_left", "ui_right")
	var rate := FINE_RATE if Input.is_action_pressed("trim_fine") else COARSE_RATE
	if direction != 0.0:
		sim.drive_error = clampf(sim.drive_error + direction * rate * dt, -1.0, 1.0)
	if absf(sim.drive_error) <= DEADBAND:
		stable += dt
		if stable >= 3.0:
			sim.drive_rate_checked = true
	else:
		stable = 0.0
		sim.drive_rate_checked = false
	elapsed += dt
	displacement += sim.drive_error * 24.0 * dt
	sample_time += dt
	no_improvement += dt
	if sample_time >= 1.0:
		measured_drift = (displacement - sampled_position) / sample_time
		previous_mark = 0.0
		now_mark = measured_drift
		sampled_position = displacement
		sample_time = 0.0
		if absf(measured_drift) < best_drift - 0.05:
			best_drift = absf(measured_drift)
			no_improvement = 0.0
	if no_improvement >= 10.0 and not hinted:
		hinted = true
		hint.text = L.t("Cottingham：「看看它剛才在哪裡，現在又在哪裡。試著微調一下。」")
	_refresh_text()
	diagram.queue_redraw()
	if elapsed >= 45.0:
		finished.emit()


func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	# Pause belongs to the existing pause menu above this panel.
	if event.is_action_pressed("pause"):
		return
	var enter: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER
	if (released and event.is_action_pressed("interact") and not event.is_echo()) or enter or event.is_action_pressed("trim_leave"):
		finished.emit()
	# Keep movement, camera and log inputs out of the world while observing.
	get_viewport().set_input_as_handled()


func _refresh_text() -> void:
	var direction := L.t("向右") if measured_drift > 0.0 else L.t("向左")
	if absf(measured_drift) <= DEADBAND * 24.0:
		direction = L.t("近乎靜止")
	status.text = L.t("%s · 間距 %.1f · 穩定 %.1f／3 秒 · 本次剩餘 %.0f 秒") % [direction, absf(measured_drift), minf(stable, 3.0), 45.0 - elapsed]
	if sim != null and sim.drive_rate_checked:
		status.text += "\n" + L.t("走速已驗證；可記錄目前設定。")
	controls.text = L.t("［%s］請他調慢／調快　［%s］微調\n［%s］記錄　［%s］保留設定離開　［%s］暫停") % [Prompts.key("trim"), Prompts.key("trim_fine"), Prompts.key("trim_record"), Prompts.key("trim_leave"), Prompts.key("pause")]


func _draw_diagram() -> void:
	var center := diagram.size * 0.5
	var ink := Print.INK
	diagram.draw_line(Vector2.ZERO, Vector2(diagram.size.x, 0), ink, 1.0)
	diagram.draw_line(Vector2(0, diagram.size.y), diagram.size, ink, 1.0)
	if Settings.reduced_motion:
		# Fixed rows; the sampled horizontal separation changes only once a second.
		var font := get_theme_default_font()
		diagram.draw_string(font, center + Vector2(-150, -45), L.t("剛才"), HORIZONTAL_ALIGNMENT_LEFT, -1, Settings.fs(22), ink)
		diagram.draw_string(font, center + Vector2(-150, 55), L.t("現在"), HORIZONTAL_ALIGNMENT_LEFT, -1, Settings.fs(22), ink)
		_tracking_mark(center + Vector2(0, -50), previous_mark)
		_tracking_mark(center + Vector2(0, 50), now_mark)
	else:
		# Wrapping recentres only the drawing, never the rate or success rule.
		var x := wrapf(displacement, -diagram.size.x * 0.3, diagram.size.x * 0.3)
		_tracking_mark(center, x)


func _tracking_mark(center: Vector2, offset: float) -> void:
	diagram.draw_line(center - Vector2(10, 0), center + Vector2(10, 0), Print.INK, 1.0)
	diagram.draw_line(center - Vector2(0, 10), center + Vector2(0, 10), Print.INK, 1.0)
	var star := center + Vector2(offset, 0)
	diagram.draw_polyline(PackedVector2Array([star + Vector2(0, -6), star + Vector2(5, 0), star + Vector2(0, 6), star + Vector2(-5, 0), star + Vector2(0, -6)]), Print.INK, 1.0)
