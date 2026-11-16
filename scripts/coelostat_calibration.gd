extends Control
## FICTION: illustrative tracking diagram, not a documented pre-eclipse check.
## Cottingham handles the mechanism; the player observes and requests changes.
const Settings := preload("res://scripts/settings.gd")
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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 48
	box.offset_right = -48
	box.offset_top = 36
	box.offset_bottom = -36
	add_child(box)
	caption = _label(box, L.t("追蹤示意圖——示意重建，非史料"))
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(space)
	status = _label(box, "")
	hint = _label(box, L.t("觀察星像的移動，再請 Cottingham 微調。位置是否居中並不重要。"))
	controls = _label(box, "")
	_refresh_text()


func _label(parent: Control, text_: String) -> Label:
	var label := Label.new()
	label.text = text_
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
	queue_redraw()


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
	queue_redraw()
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.055, 0.065, 0.08, 0.98))
	var center := size * Vector2(0.5, 0.4)
	var ink := Color(0.88, 0.83, 0.68)
	draw_line(center - Vector2(10, 0), center + Vector2(10, 0), ink, 2.0)
	draw_line(center - Vector2(0, 10), center + Vector2(0, 10), ink, 2.0)
	if Settings.reduced_motion:
		# Fixed rows; the sampled horizontal separation changes only once a second.
		var font := get_theme_default_font()
		draw_string(font, center + Vector2(-150, -45), L.t("剛才"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
		draw_string(font, center + Vector2(-150, 55), L.t("現在"), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
		draw_circle(center + Vector2(previous_mark, -50), 5.0, ink)
		draw_circle(center + Vector2(now_mark, 50), 5.0, ink)
	else:
		# Wrapping recentres only the drawing, never the rate or success rule.
		var x := wrapf(displacement, -size.x * 0.3, size.x * 0.3)
		draw_circle(center + Vector2(x, 0), 5.0, ink)
