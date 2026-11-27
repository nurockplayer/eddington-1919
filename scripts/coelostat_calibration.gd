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
var previous_mark := NAN
var now_mark := NAN
var quiet_time := 0.0
var quiet_position := 0.0
var last_full_drift := NAN
var was_trimming := false
var trail := PackedVector2Array()
var no_improvement := 0.0
var best_drift := INF
var hinted := false
var released := false
var fine_direction := 0.0
var caption: Label
var status: Label
var verified: Label
var controls: Label
var hint: Label
var sheet: PanelContainer
var diagram: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 24
	row.offset_right = -24
	row.offset_top = 24
	row.offset_bottom = -24
	add_child(row)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	sheet = PanelContainer.new()
	sheet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sheet)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Print.PAPER
	paper.border_color = Print.INK
	paper.set_border_width_all(1)
	paper.set_content_margin_all(16)
	sheet.add_theme_stylebox_override("panel", paper)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	sheet.add_child(box)
	caption = _label(box, L.t("追蹤示意圖——示意重建，非史料"))
	diagram = Control.new()
	diagram.custom_minimum_size.y = 180
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.draw.connect(_draw_diagram)
	box.add_child(diagram)
	status = _label(box, "")
	verified = _label(box, L.t("走速已驗證；可記錄目前設定。"))
	hint = _label(box, L.t("觀察星像的移動，再請 Cottingham 微調。位置是否居中並不重要。"))
	controls = _label(box, "")
	_refresh_text()
	resized.connect(_fit_sheet)
	box.minimum_size_changed.connect(_fit_sheet)
	_fit_sheet()


func _fit_sheet() -> void:
	sheet.custom_minimum_size.x = minf(1000.0, size.x - 48.0)
	var text_height := 32.0 + 5.0 * 8.0
	for label in [caption, status, verified, hint, controls]:
		text_height += label.get_combined_minimum_size().y
	diagram.custom_minimum_size.y = minf(460.0, maxf(180.0, size.y - 48.0 - text_height))
	diagram.queue_redraw()


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
	trail = PackedVector2Array([Vector2.ZERO])
	sampled_position = 0.0
	previous_mark = NAN
	now_mark = NAN
	quiet_time = 0.0
	quiet_position = 0.0
	last_full_drift = NAN
	was_trimming = false
	measured_drift = 0.0
	best_drift = absf(sim.drive_error) * 24.0
	no_improvement = 0.0
	hinted = false
	released = false
	fine_direction = 0.0
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
	var fine := Input.is_action_pressed("trim_fine")
	if fine:
		fine_direction = direction
	elif direction != fine_direction:
		fine_direction = 0.0
	# Releasing fine trim ends the nudge without turning it into a coarse one.
	var trimming := direction != 0.0 and (fine or fine_direction == 0.0)
	if trimming:
		var rate := FINE_RATE if fine else COARSE_RATE
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
	# The comparison only uses full intervals without trim input.
	if trimming:
		if not was_trimming:
			previous_mark = last_full_drift
			now_mark = NAN
		quiet_time = 0.0
		quiet_position = displacement
	else:
		quiet_time += dt
		if quiet_time >= 1.0:
			last_full_drift = (displacement - quiet_position) / quiet_time
			if is_nan(now_mark):
				now_mark = last_full_drift
			quiet_position = displacement
			quiet_time = 0.0
	was_trimming = trimming
	trail.append(Vector2(elapsed, displacement))
	while trail.size() > 2 and trail[1].x < elapsed - 1.0:
		trail.remove_at(0)
	sample_time += dt
	no_improvement += dt
	if sample_time >= 1.0:
		measured_drift = (displacement - sampled_position) / sample_time
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
	status.text = L.t("%s · 漂移 %.1f · 穩定 %.1f／3 秒 · 本次剩餘 %.0f 秒") % [direction, absf(measured_drift), minf(stable, 3.0), 45.0 - elapsed]
	verified.modulate.a = 1.0 if sim != null and sim.drive_rate_checked else 0.0
	controls.text = L.t("［%s］請他調慢／調快　［%s］微調\n［%s］記錄　［%s］保留設定離開　［%s］暫停") % [Prompts.key("trim"), Prompts.key("trim_fine"), Prompts.key("trim_record"), Prompts.key("trim_leave"), Prompts.key("pause")]


func _stroke_width() -> float:
	var scale := diagram.get_screen_transform().get_scale().abs()
	return maxf(1.0, 1.0 / minf(scale.x, scale.y))


func _field_radius() -> float:
	return minf(diagram.size.x, diagram.size.y) * 0.5 - 8.0


func _draw_diagram() -> void:
	var center := diagram.size * 0.5
	var ink := Print.INK
	var width := _stroke_width()
	var radius := _field_radius()
	diagram.draw_line(Vector2.ZERO, Vector2(diagram.size.x, 0), ink, width, true)
	diagram.draw_line(Vector2(0, diagram.size.y), diagram.size, ink, width, true)
	diagram.draw_arc(center, radius, 0.0, TAU, 128, ink, width, true)
	diagram.draw_line(center - Vector2(radius, 0), center + Vector2(radius, 0), ink, width, true)
	diagram.draw_line(center - Vector2(0, radius), center + Vector2(0, radius), ink, width, true)
	var font := get_theme_default_font()
	var font_size := mini(Settings.fs(22), floori(radius * 0.26))
	var diamond_width := minf(12.0, radius * 0.06)
	var diamond_height := diamond_width * 7.0 / 6.0
	# Expand the fine-trim range while keeping ±24 within the field.
	var mark_scale := radius * 0.83 / atan(24.0 / 1.7)
	for row: Array in [[L.t("剛才"), -0.40, previous_mark], [L.t("現在"), 0.24, now_mark]]:
		var origin := center + Vector2(0, row[1] * radius)
		var drift: float = row[2]
		var mark := 0.0
		if not is_nan(drift):
			mark = atan(drift / 1.7) * mark_scale
			diagram.draw_line(origin, origin + Vector2(mark, 0), ink, width, true)
			var star := origin + Vector2(mark, 0)
			diagram.draw_polyline(PackedVector2Array([
				star + Vector2(0, -diamond_height), star + Vector2(diamond_width, 0),
				star + Vector2(0, diamond_height), star + Vector2(-diamond_width, 0),
				star + Vector2(0, -diamond_height),
			]), ink, width, true)
		var label_top := origin.y + diamond_height + 4.0
		var label_edge := maxf(absf(label_top - center.y), absf(label_top + font.get_height(font_size) - center.y))
		var label_width := font.get_string_size(row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var label_span := sqrt(radius * radius - label_edge * label_edge) - label_width * 0.5 - width
		var label_origin := Vector2(center.x + clampf(mark, -label_span, label_span) - label_width * 0.5, label_top + font.get_ascent(font_size))
		diagram.draw_string(font, label_origin, row[0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
	if not Settings.reduced_motion:
		# Wrap only the figure; trail points stay relative to the current star.
		var x := wrapf(displacement, -radius + 20.0, radius - 20.0)
		var star_center := center - Vector2(0, radius * 0.7)
		var points := PackedVector2Array()
		for i in trail.size():
			var sample := trail[i]
			if sample.x < elapsed - 1.0 and i + 1 < trail.size():
				var next := trail[i + 1]
				sample.y = lerpf(sample.y, next.y, (elapsed - 1.0 - sample.x) / (next.x - sample.x))
			points.append(star_center + Vector2(x + sample.y - displacement, 0))
		if points.size() >= 2:
			diagram.draw_polyline(points, ink, width, true)
		diagram.draw_circle(star_center + Vector2(x, 0), 2.5, ink, true, -1, true)
