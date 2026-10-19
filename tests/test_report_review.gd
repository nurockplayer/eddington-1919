extends SceneTree
## Exhaustive mentor-review content contract and report revision selection test.
## Run: godot --headless --path . --script res://tests/test_report_review.gd

const C17 = preload("res://scripts/cambridge/content_1917.gd")
const ReportSheet = preload("res://scripts/cambridge/report_sheet.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	var causes := ["unknown", "both", "accuse"]
	var originals := ["keep", "redraw"]
	var residuals := ["not_found", "unresolved", "delete", "new_object"]
	for row in C17.report_rows():
		if row.id == "cause":
			causes.clear()
			for option in row.options:
				causes.append(str(option.id))
		elif row.id == "original":
			originals.clear()
			for option in row.options:
				originals.append(str(option.id))
		elif row.id == "residual":
			residuals = ["not_found"]
			for option in row.options:
				residuals.append(str(option.id))
	for cause in causes:
		for original in originals:
			for residual in residuals:
				for kit_credited in [false, true]:
					for kit_checked in [false, true]:
						for aligned in [false, true]:
							var report := {"cause": cause, "original": original, "residual": residual,
								"kit_credited": kit_credited, "kit_checked": kit_checked, "aligned": aligned}
							var review := C17.mentor_review(report)
							check(not review.is_empty(), "mentor_review is non-empty for %s" % report)
							var mentions_missing := _contains_not_found_line(review)
							check(not mentions_missing or residual == "not_found", "not_found line matches residual for %s" % report)
	
	await _test_revision_selections()
	print("test_report_review: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _test_revision_selections() -> void:
	var sheet = ReportSheet.new()
	root.add_child(sheet)
	await process_frame
	sheet.open({"label_mirrored": true, "arrow_tilted": true, "residual_found": true, "kit_checked": true}, {
		"cause": "both", "original": "keep", "residual": "new_object", "kit_checked": true, "kit_credited": false
	})
	await process_frame
	check(sheet.selected.get("cause") == "both", "revision preserves cause selection")
	check(sheet.selected.get("original") == "keep", "revision preserves original selection")
	check(sheet.selected.get("residual") == "new_object", "revision preserves residual selection")
	for id in ["cause/both", "original/keep", "residual/new_object"]:
		check(sheet.option_buttons[id].button_pressed, "revision visibly restores %s selection" % id)
	check(not sheet.option_buttons["kit_credited/credited"].button_pressed if sheet.option_buttons.has("kit_credited/credited") else not sheet.selected.get("kit_credited", false), "revision preserves unchecked Kit credit")
	var resubmitted: Array[Dictionary] = []
	sheet.submitted.connect(func(report: Dictionary): resubmitted.append(report))
	sheet._submit()
	check(resubmitted.size() == 1, "revised report can be submitted again")
	var second_review := C17.mentor_review(resubmitted[0])
	var has_revision_prompt := false
	for line in second_review:
		if line.get("key", "") == "revise_report":
			has_revision_prompt = true
	check(has_revision_prompt, "resubmitted hasty report replays mentor_review with revise choice")
	sheet.queue_free()


func _contains_not_found_line(value: Variant) -> bool:
	if value is Dictionary:
		if str(value.get("t", "")).contains("你沒看見"):
			return true
		for child in value.values():
			if _contains_not_found_line(child):
				return true
	elif value is Array:
		for child in value:
			if _contains_not_found_line(child):
				return true
	return false
