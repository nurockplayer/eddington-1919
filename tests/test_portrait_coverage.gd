extends SceneTree
const Coverage := preload("res://tools/portrait_coverage.gd")
const Portrait := preload("res://scripts/cambridge/dialogue_portrait.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const Engraving := preload("res://scripts/styles/engraving.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func mapping_errors(prints: Dictionary) -> Array:
	var errors := []
	var identities := {Cast.MENTOR: "ashby", Cast.EDDINGTON: "eddington"}
	for speaker in prints:
		for path in prints[speaker].values():
			if not FileAccess.file_exists(path):
				errors.append("missing portrait: " + path)
			if not identities.has(speaker) or not path.get_file().begins_with(str(identities[speaker]) + "_"):
				errors.append("wrong person: " + speaker + " -> " + path)
	return errors


func _run() -> void:
	var mappings := Portrait.PRINTS.duplicate(true)
	mappings[Cast.EDDINGTON]["engraving"] = Engraving.DIALOGUE.portrait
	check(mapping_errors(mappings).is_empty(), "all mapped files exist and belong to the speaker: " + str(mapping_errors(mappings)))
	var missing := mappings.duplicate(true)
	missing[Cast.MENTOR].neutral = "res://assets/portraits/ashby_missing.jpg"
	check(mapping_errors(missing).has("missing portrait: " + missing[Cast.MENTOR].neutral), "revert check: missing file rejected")
	var wrong := mappings.duplicate(true)
	wrong[Cast.MENTOR].neutral = mappings[Cast.EDDINGTON].neutral
	check(mapping_errors(wrong).has("wrong person: " + Cast.MENTOR + " -> " + wrong[Cast.MENTOR].neutral), "revert check: another person's existing portrait rejected")
	var report: String = Coverage.render(self, Coverage.authored_entries())
	var changed: Array = Coverage.authored_entries()
	changed.append({"chapter": 0, "s": Cast.KIT, "t": "new line", "mood": "neutral"})
	check(Coverage.render(self, changed) != report, "revert check: added content makes table stale")
	print("%d portrait coverage checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
