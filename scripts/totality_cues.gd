extends RefCounted
class_name TotalityCues
## Pure shaping for the M5 totality legibility layer (docs/design/M5_TOTALITY.md).
## Hindsight bands and strip data only: nothing here looks at the upcoming sky.

const CLEAR_FRACTION := 0.65   # f >= this reads "clear"
const MIXED_FRACTION := 0.30   # f >= this reads "mixed", below reads "cloud"
const BRIEF_S := 1.0           # shorter than this reads "brief" regardless of f


## Hindsight band for one closed exposure: clear | mixed | cloud | brief.
static func sky_band(clear: float, duration: float) -> String:
	if duration < BRIEF_S:
		return "brief"
	var f := clear / duration
	if f >= CLEAR_FRACTION:
		return "clear"
	if f >= MIXED_FRACTION:
		return "mixed"
	return "cloud"


## Everything the exposure strip draws, clamped to [0, total].
static func strip_model(t: float, total: float, plates: Array, open_start: float, plates_total: int) -> Dictionary:
	var span := maxf(total, 0.001)
	var tt := clampf(t, 0.0, span)
	var segments: Array = []
	for p in plates:
		var start := clampf(float(p.get("start", 0.0)), 0.0, span)
		var end := clampf(float(p.get("start", 0.0)) + float(p.get("duration", 0.0)), 0.0, span)
		if end > start:
			segments.append([start, end])
	var open_segment: Array = []
	var os := -1.0
	if open_start >= 0.0:
		os = clampf(open_start, 0.0, span)
		if tt > os:
			open_segment = [os, tt]
	return {
		"t": tt,
		"total": span,
		"segments": segments,
		"open_start": os,
		"open_segment": open_segment,
		"plates_total": plates_total,
		"plates_used": plates.size() + (1 if open_start >= 0.0 else 0),
	}
