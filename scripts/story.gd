extends Node
## Chapter continuity only. No scene references, world nodes, scoring or behavior.

var from_prologue := false
var prologue_done := false
var clues: Dictionary = {}
var report: Dictionary = {}
var plan: Array = []
var kit_choice := -1
var bond_tone := ""
var slip_fix := -1
var departure_done := false


func reset() -> void:
	from_prologue = false
	prologue_done = false
	clues.clear()
	report.clear()
	plan.clear()
	kit_choice = -1
	bond_tone = ""
	slip_fix = -1
	departure_done = false
