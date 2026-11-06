extends SceneTree
## Conversion arc move E: the closed box, played by hand. Drives the real Cambridge
## and departure directors through their own dialogue and the sketch's own buttons.
## Run: godot --headless --path . --script res://tests/test_box_sketch.gd

const DIRECTOR := "res://scripts/cambridge/director.gd"
const DEPARTURE := "res://scripts/cambridge/departure_director.gd"
const Sketch := preload("res://scripts/cambridge/box_sketch.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _wait_for(cond: Callable, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return cond.call()


## Click through the director's real dialogue, one choice/advance per frame.
func _drain(ui, answers := {}, fallback := 0) -> void:
	var guard := 200
	while ui.dialog_active() and guard > 0:
		guard -= 1
		if not ui._choice_buttons.is_empty():
			var entry: Dictionary = ui._seq[ui._seq_i]
			ui._choose(int(answers.get(str(entry.get("key", "")), fallback)))
		else:
			ui._advance()
		await process_frame
	check(guard > 0, "dialogue terminates")


func _run() -> void:
	print("box: 1 rates")
	_test_rates()
	print("box: 2 drop through the Cambridge director")
	await _test_drop_through_director()
	print("box: 3 light through the departure director")
	await _test_light_through_departure()
	print("box: 4 input blocked")
	await _test_input_blocked()
	print("box: 5 the sketch's own layout")
	await _test_layout()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_rates() -> void:
	check(is_equal_approx(Sketch.drop_y(0.0), 0.0), "a released pencil starts at its height")
	check(Sketch.drop_y(0.2) < Sketch.drop_y(0.4) and Sketch.drop_y(0.4) < Sketch.drop_y(0.6),
		"the pencil falls further each equal time")
	check(is_equal_approx(Sketch.drop_y(10.0), Sketch.FLOOR_Y), "the pencil stops at the floor")
	check(is_equal_approx(Sketch.PENCIL_Y + Sketch.FLOOR_Y + Sketch.PENCIL_LEN, Sketch.BOX_H),
		"the pencil's tip rests on the floor line when the fall ends (%.1f vs %.1f)" % [Sketch.PENCIL_Y + Sketch.FLOOR_Y + Sketch.PENCIL_LEN, Sketch.BOX_H])
	check(Sketch.fall_time() > 0.8 and Sketch.fall_time() < 1.0,
		"the fall lasts about 0.9 s (%.3f)" % Sketch.fall_time())
	check(is_equal_approx(Sketch.box_rise(0.3), Sketch.drop_y(0.3)), "the box rises at the rate the pencil falls")
	check(is_equal_approx(Sketch.light_drop(0.3), Sketch.box_rise(0.3)),
		"the light in the box drops at that same rate")


## The 1917 close-up: three falls with real presses, then Eddington's box question.
func _test_drop_through_director() -> void:
	var story := root.get_node("Story")
	story.reset()
	var chapter = load(DIRECTOR).new()
	root.add_child(chapter)
	var ready: bool = await _wait_for(func(): return chapter._pending == "opening", 20.0)
	check(ready, "the Cambridge director reaches its opening")
	if not ready:
		chapter.free()
		return
	await _drain(chapter.ui)
	var sketch = chapter.box_sketch
	chapter._pending = "exam"
	chapter._dialogue_done({"q1": 0, "q2": 0, "box": 0})
	check(sketch.visible and sketch.mode == "drop" and sketch.stage == 0,
		"the exam opens the drop sketch at its first cell")
	check(not chapter.player.can_move and not chapter.player.can_look, "the modal stops walking and looking")
	var before: Vector3 = chapter.player.global_position
	Input.action_press("move_forward")
	for i in 10:
		await physics_frame
	Input.action_release("move_forward")
	check(chapter.player.global_position.distance_to(before) < 0.05,
		"holding forward does not move the player under the modal (%.3f m)" % chapter.player.global_position.distance_to(before))
	check(_has_label(sketch, Sketch.DROP_NOTE), "the drop sketch always says it is not to scale")

	var samples: Array = []
	for stage in 3:
		check(sketch.stage == stage, "stage %d comes in order" % stage)
		check(_has_label(sketch, Sketch.DROP_PROMPTS[stage]), "stage %d shows its own prompt" % stage)
		check(not sketch.release_btn.disabled and sketch.next_btn.disabled,
			"stage %d: next stays disabled before the fall" % stage)
		sketch.release_btn.pressed.emit()
		check(sketch.next_btn.disabled, "stage %d: next stays disabled during the fall" % stage)
		sketch.next_btn.pressed.emit()
		check(sketch.next_btn.disabled and sketch.stage == stage and sketch.visible,
			"stage %d: pressing the disabled next does nothing" % stage)
		var landed: bool = await _wait_for(func(): return not sketch.next_btn.disabled, 5.0)
		check(landed, "stage %d fall ends and enables next" % stage)
		var ticks: Array = sketch.fall_ticks[stage].duplicate() if sketch.fall_ticks.size() > stage else []
		samples.append(ticks)
		check(ticks.size() >= 7, "stage %d leaves equal-time tick marks (%d)" % [stage, ticks.size()])
		var wanted := "回到桌邊" if stage == 2 else "換一格"
		check(sketch.next_btn.text == wanted, "stage %d labels the next button %s" % [stage, wanted])
		sketch.next_btn.pressed.emit()
		await process_frame

	check(not sketch.visible, "回到桌邊 closes the sketch")
	check(chapter._pending == "exam_box" and chapter.ui.dialog_active(), "finished starts Eddington's box question")
	# The pencil's equal-time marks are what the three falls actually drew, and they agree.
	for stage in 3:
		check(samples[stage] == samples[0], "stage %d drew the same equal-time fall as stage 0" % stage)
	for i in samples[0].size():
		check(is_equal_approx(float(samples[0][i]), Sketch.drop_y(Sketch.TICK_STEP * (i + 1))),
			"sample %d is drop_y at its equal time (%.2f vs %.2f)" % [i, float(samples[0][i]), Sketch.drop_y(Sketch.TICK_STEP * (i + 1))])

	# The box question comes back in this half; answer it and the light question.
	var guard := 200
	while chapter._pending == "exam_box" and chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		if not chapter.ui._choice_buttons.is_empty():
			var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
			var key := str(entry.get("key", ""))
			chapter.ui._choose(1 if key == "box_light" else 2)
		else:
			chapter.ui._advance()
		await process_frame
	check(chapter._pending == "plan_intro" and chapter.beat == chapter.Beat.PLAN, "the box hands on to the plan")
	check(story.exam == {"q1": 0, "q2": 0, "box": 2, "box_light": 1},
		"Story.exam holds q1, q2, the box and the light (%s)" % [story.exam])
	await _drain(chapter.ui)
	check(chapter.plan_board.visible, "the plan board opens after the box")
	chapter.free()
	await process_frame


## The departure: the light in the box, both views, then Ashby's rest and the gift.
func _test_light_through_departure() -> void:
	var story := root.get_node("Story")
	story.reset()
	story.slip_fix = 0
	var chapter = load(DEPARTURE).new()
	root.add_child(chapter)
	var ready: bool = await _wait_for(func(): return chapter._pending == "opening", 20.0)
	check(ready, "the departure director reaches its opening")
	if not ready:
		chapter.free()
		return
	await _drain(chapter.ui)
	var sketch = chapter.box_sketch
	chapter._pending = "farewell"
	chapter._dialogue_done({})
	check(sketch.visible and sketch.mode == "light", "the farewell opens the light sketch")
	check(sketch.next_btn.disabled, "收起來 starts disabled")
	check(_has_label(sketch, Sketch.LIGHT_NOTE), "the light sketch always says it is an illustration at a huge scale")

	sketch.release_btn.pressed.emit()
	var outside_done: bool = await _wait_for(func(): return not sketch.release_btn.disabled, 5.0)
	check(outside_done, "the outside view lets the light land")
	check(sketch.next_btn.disabled, "one view does not enable 收起來")
	check(sketch.landing.has("outside"), "the outside view records where the light lands")
	var outside_point: Vector2 = sketch.landing.get("outside", Vector2.ZERO)

	sketch.frame_btns[1].pressed.emit()
	check(sketch.view == "inside", "從箱裡看 switches the frame")
	sketch.release_btn.pressed.emit()
	var inside_done: bool = await _wait_for(func(): return not sketch.release_btn.disabled, 5.0)
	check(inside_done, "the inside view lets the light land")
	check(not sketch.next_btn.disabled, "both views enable 收起來")
	var inside_point: Vector2 = sketch.landing.get("inside", Vector2.ONE)
	check(outside_point.is_equal_approx(inside_point),
		"the landing point matches in box coordinates (%s vs %s)" % [outside_point, inside_point])
	check(is_equal_approx(outside_point.x, Sketch.BOX_W), "the light lands on the far wall")
	check(is_equal_approx(outside_point.y - Sketch.HOLE_Y, Sketch.light_drop(Sketch.LIGHT_SPAN)),
		"the landing sits light_drop below the hole (%.1f)" % (outside_point.y - Sketch.HOLE_Y))

	sketch.next_btn.pressed.emit()
	await process_frame
	check(chapter._pending == "gift" and chapter.ui.dialog_active(), "收起來 starts Ashby's rest with purpose gift")
	await _drain(chapter.ui, {"light_box": 0})
	var gifted: bool = await _wait_for(func(): return chapter.keepsake.visible, 3.0)
	check(gifted, "the keepsake still appears after the sketch")
	chapter.set_process(false)
	for audio in chapter.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	chapter.free()
	await process_frame


## input_blocked is the log/pause guard: every handler returns early.
func _test_input_blocked() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var sketch = Sketch.new()
	layer.add_child(sketch)
	await process_frame
	sketch.open("drop")
	await process_frame
	sketch.input_blocked = true
	sketch.release_btn.pressed.emit()
	check(sketch.fall_ticks.is_empty() and not sketch.release_btn.disabled, "input_blocked stops 鬆手")
	sketch.open("light")
	await process_frame
	sketch.input_blocked = true
	sketch.frame_btns[1].pressed.emit()
	check(sketch.view == "outside", "input_blocked stops the frame buttons")
	sketch.release_btn.pressed.emit()
	check(not sketch.landing.has("outside") and not sketch.release_btn.disabled, "input_blocked stops 讓光進來")
	layer.queue_free()
	await process_frame


## The buttons land inside the sheet once the sketch is open, so a real click can reach them.
func _test_layout() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var sketch = Sketch.new()
	layer.add_child(sketch)
	await process_frame
	var screen: Rect2 = root.get_visible_rect()
	sketch.open("drop")
	for i in 4:
		await process_frame
	for button in [sketch.release_btn, sketch.next_btn]:
		var rect: Rect2 = button.get_global_rect()
		check(screen.encloses(rect) and rect.size.x > 100.0 and rect.position.y > screen.size.y * 0.7,
			"the sketch button %s is laid out near the bottom (%s)" % [button.text, rect])
	sketch.open("light")
	for i in 4:
		await process_frame
	for button in sketch.frame_btns:
		check(screen.encloses(button.get_global_rect()),
			"the light frame button %s sits inside the screen (%s)" % [button.text, button.get_global_rect()])
	layer.queue_free()
	await process_frame


func _has_label(node: Node, text: String) -> bool:
	for label in node.find_children("*", "Label", true, false):
		if str(label.text) == text:
			return true
	return false
