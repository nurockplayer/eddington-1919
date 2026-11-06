extends Node
## Session continuity and completed experiment snapshots. No scene references.

var runs: Array[Dictionary] = []

var from_prologue := false
var prologue_done := false
var clues: Dictionary = {}
var report: Dictionary = {}
var plan: Array = []
var kit_choice := -1
var kit_first := -1
var trial_note := -1
var exam: Dictionary = {}
var bet: Dictionary = {}
var bet_1917: Dictionary = {}
## Conversion arc move B: the player's marks on the orrery check
## ({"neptune": 0|1, "halley": 0|1, "mercury": 0|1}) and what they suspect.
var orrery: Dictionary = {}
var mercury_suspect := -1
var sky_promise := -1
var bond_tone := ""
var slip_fix := -1
var departure_done := false
## Conversion arc move D: the October 1919 Cambridge epilogue and the ending plate
## it carries across the scene change.
var epilogue_done := false
var ending_plate: Texture2D = null
var ending_plate_caption := ""

## Chapter checkpoints write these fields; the plate travels as PNG bytes instead.
const SAVED := [
	"runs", "from_prologue", "prologue_done", "clues", "report", "plan",
	"kit_choice", "kit_first", "trial_note", "exam", "bet", "bet_1917",
	"orrery", "mercury_suspect", "sky_promise", "bond_tone", "slip_fix",
	"departure_done", "epilogue_done", "ending_plate_caption",
]


func to_save() -> Dictionary:
	var data := {}
	for key in SAVED:
		var value = get(key)
		if value is Array or value is Dictionary:
			value = value.duplicate(true)
		data[key] = value
	var image: Image = ending_plate.get_image() if ending_plate != null else null
	data["ending_plate_png"] = image.save_png_to_buffer() if image != null else PackedByteArray()
	return data


func from_save(data: Dictionary) -> void:
	reset()
	for key in SAVED:
		if not data.has(key):
			continue
		if key == "runs":
			runs.assign(data[key])
		else:
			set(key, data[key])
	var png = data.get("ending_plate_png", PackedByteArray())
	if png is PackedByteArray and not png.is_empty():
		var image := Image.new()
		if image.load_png_from_buffer(png) == OK:
			ending_plate = ImageTexture.create_from_image(image)


func reset(keep_runs := false) -> void:
	if not keep_runs:
		runs.clear()
	from_prologue = false
	prologue_done = false
	clues.clear()
	report.clear()
	plan.clear()
	kit_choice = -1
	kit_first = -1
	trial_note = -1
	exam.clear()
	bet.clear()
	bet_1917.clear()
	orrery.clear()
	mercury_suspect = -1
	sky_promise = -1
	bond_tone = ""
	slip_fix = -1
	departure_done = false
	epilogue_done = false
	ending_plate = null
	ending_plate_caption = ""
