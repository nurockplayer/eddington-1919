extends RefCounted
## Music for the 1919 score. Cues with a rendered OGG in SAMPLED_DIR play the
## sample; every other cue (and the totality layers) is synthesized here.

const RATE := 22050
const SAMPLED_DIR := "res://assets/music/"
## Level of each sampled cue, matched to its synthesis RMS (see D014).
const SAMPLED_DB := {
	"cambridge_rain": -38.5,
	"departure_motif": -38.5,
	"coda_resolution": -34.0,
}
const CUES := [
	"cambridge_rain",
	"departure_motif",
	"totality_drone",
	"totality_glass",
	"totality_edge",
	"coda_resolution",
]

const _TABLE_SIZE := 4096
const _TABLE_MASK := _TABLE_SIZE - 1
const _REED_CUTOFF_HZ := 700.0
const _SEAM_S := 0.05

static var _cache: Dictionary = {}
static var _cache_mutex := Mutex.new()
static var _table_cache: Dictionary = {}
static var _table_mutex := Mutex.new()


static func duration(cue: String) -> float:
	match cue:
		"cambridge_rain": return 56.0
		"departure_motif": return 9.2
		"totality_drone", "totality_glass", "totality_edge": return 24.0
		"coda_resolution": return 16.5
	return 0.0


static func is_loop(cue: String) -> bool:
	return cue in ["cambridge_rain", "totality_drone", "totality_glass", "totality_edge"]


static func is_sampled(cue: String) -> bool:
	return ResourceLoader.exists(SAMPLED_DIR + cue + ".ogg")


static func level_db(cue: String) -> float:
	if SAMPLED_DB.has(cue):
		return SAMPLED_DB[cue]
	match cue:
		"cambridge_rain", "departure_motif", "totality_drone": return -30.0
		"totality_glass": return -34.0
		"totality_edge": return -32.0
		"coda_resolution": return -28.0
	return -80.0


static func stream(cue: String) -> AudioStream:
	if not CUES.has(cue):
		return null
	_cache_mutex.lock()
	if _cache.has(cue):
		var cached: AudioStream = _cache[cue]
		_cache_mutex.unlock()
		return cached
	_cache_mutex.unlock()

	# Synthesis, PCM conversion and the OGG decode can take hundreds of
	# milliseconds. Keep that work outside the dictionary mutex so a ready cue
	# is never held behind it.
	var candidate: AudioStream
	if is_sampled(cue):
		candidate = _sampled(cue)
	else:
		candidate = _wav(render(cue), RATE, is_loop(cue))
	_cache_mutex.lock()
	if not _cache.has(cue):
		_cache[cue] = candidate
	var result: AudioStream = _cache[cue]
	_cache_mutex.unlock()
	return result


static func _sampled(cue: String) -> AudioStreamOggVorbis:
	var ogg := load(SAMPLED_DIR + cue + ".ogg") as AudioStreamOggVorbis
	ogg.loop = is_loop(cue)
	ogg.loop_offset = 0.0
	return ogg


static func render(cue: String) -> PackedFloat32Array:
	if not CUES.has(cue):
		return PackedFloat32Array()
	_table_mutex.lock()
	var count := int(round(duration(cue) * RATE))
	var seam_width := int(round(_SEAM_S * RATE))
	var crossfade_totality := cue in ["totality_drone", "totality_glass", "totality_edge"]
	var samples := PackedFloat32Array()
	samples.resize(count + (seam_width if crossfade_totality else 0))
	samples.fill(0.0)
	match cue:
		"cambridge_rain": _render_cambridge(samples)
		"departure_motif": _render_departure(samples)
		"totality_drone": _render_drone(samples)
		"totality_glass": _render_glass(samples)
		"totality_edge": _render_edge(samples)
		"coda_resolution": _render_coda(samples)
	if crossfade_totality:
		samples = _crossfade_loop_seam(samples, count, seam_width)
	elif is_loop(cue):
		_seal_loop_seam(samples)
	_table_mutex.unlock()
	return samples


static func _render_cambridge(out: PackedFloat32Array) -> void:
	# Sparse two- and three-note D-centered harmonium sonorities. The four
	# chords each have a 4.6-second gate, leaving room for the plate motif.
	_add_chord(out, 2.0, 4.6, ["D3", "F3", "A3"], 0.065)
	_add_motif(out, 10.0, false, 0.073, 1.5)
	_add_chord(out, 23.0, 4.6, ["D3", "G3", "A#3"], 0.061)
	_add_chord(out, 36.0, 4.6, ["D3", "C4", "G4"], 0.058)
	_add_chord(out, 49.0, 4.6, ["A3", "C4", "E4"], 0.058)


static func _render_departure(out: PackedFloat32Array) -> void:
	_add_motif(out, 0.25, false, 0.105, 1.5)
	# A final gentle tail gives the one-shot statement a clear fade.
	_fade_region(out, 7.0, 9.2, false)


static func _render_drone(out: PackedFloat32Array) -> void:
	# Keep the loop region fully sustained. The player supplies the one-time
	# entrance fade and release; the overlap seam avoids a repeated attack.
	_add_sustained_reed(out, "D2", 0.061)
	_add_sustained_reed(out, "A2", 0.048)


static func _render_glass(out: PackedFloat32Array) -> void:
	# The two close sine components create a very slow, restrained beat.
	_add_sustained_glass(out, 329.6276, 0.36, 0.029)
	_add_sustained_glass(out, 440.0, 0.52, 0.027)


static func _render_edge(out: PackedFloat32Array) -> void:
	# Like the drone, sustain across the loop without a recurring envelope.
	_add_sustained_reed(out, "G2", 0.055)


static func _render_coda(out: PackedFloat32Array) -> void:
	_add_motif(out, 0.2, true, 0.094, 1.5)
	# The changed third appears only here, in the D-major answer chord.
	for note in ["D3", "A3", "D4", "F#4"]:
		_add_reed(out, 7.25, 7.0, note, 0.066, 0.7, 1.2)


static func _add_motif(out: PackedFloat32Array, start: float, major: bool, gain: float, spacing: float) -> void:
	var notes := ["A3", "D4", "E4", "F#4" if major else "F4"]
	for i in notes.size():
		_add_reed(out, start + float(i) * spacing, 1.72, notes[i], gain, 0.68, 1.2)


static func _add_chord(out: PackedFloat32Array, start: float, gate: float, notes: Array, gain: float) -> void:
	for note in notes:
		_add_reed(out, start, gate, note, gain, 0.72, 1.2)


static func _add_reed(out: PackedFloat32Array, start: float, gate: float, note: String, gain: float, attack: float, release: float) -> void:
	var frequency := _note_hz(note)
	var table: PackedFloat32Array = _reed_table(frequency)
	var begin := maxi(0, int(floor(start * RATE)))
	var end := mini(out.size(), int(ceil((start + gate + release) * RATE)))
	var phase_step := frequency * _TABLE_SIZE / RATE
	var phase := 0.0
	for i in range(begin, end):
		var t := float(i) / RATE - start
		var env := _reed_envelope(t, gate, attack, release)
		if env <= 0.00001:
			phase = fposmod(phase + phase_step, _TABLE_SIZE)
			continue
		var idx := int(phase) & _TABLE_MASK
		var frac := phase - float(int(phase))
		var sample := lerpf(table[idx], table[(idx + 1) & _TABLE_MASK], frac)
		# Slow bellows movement: about +/-1.5 dB at 0.15 Hz, with fixed phase.
		var bellows := pow(10.0, (1.5 * sin(TAU * 0.15 * float(i) / RATE)) / 20.0)
		out[i] += sample * gain * env * bellows
		phase = fposmod(phase + phase_step, _TABLE_SIZE)


static func _add_glass(out: PackedFloat32Array, start: float, gate: float, frequency: float, beat: float, gain: float) -> void:
	var begin := maxi(0, int(floor(start * RATE)))
	var end := mini(out.size(), int(ceil((start + gate) * RATE)))
	for i in range(begin, end):
		var t := float(i) / RATE - start
		var env := _slow_envelope(t, gate, 1.2, 1.4)
		var carrier := sin(TAU * frequency * t)
		var detuned := sin(TAU * (frequency + beat) * t)
		out[i] += gain * env * (carrier + detuned * 0.48)


static func _add_sustained_reed(out: PackedFloat32Array, note: String, gain: float) -> void:
	var frequency := _note_hz(note)
	var table: PackedFloat32Array = _reed_table(frequency)
	var phase_step := frequency * _TABLE_SIZE / RATE
	var phase := 0.0
	for i in out.size():
		var idx := int(phase) & _TABLE_MASK
		var frac := phase - float(int(phase))
		var sample := lerpf(table[idx], table[(idx + 1) & _TABLE_MASK], frac)
		var bellows := pow(10.0, (1.5 * sin(TAU * 0.15 * float(i) / RATE)) / 20.0)
		out[i] += sample * gain * bellows
		phase = fposmod(phase + phase_step, _TABLE_SIZE)


static func _add_sustained_glass(out: PackedFloat32Array, frequency: float, beat: float, gain: float) -> void:
	for i in out.size():
		var t := float(i) / RATE
		var carrier := sin(TAU * frequency * t)
		var detuned := sin(TAU * (frequency + beat) * t)
		out[i] += gain * (carrier + detuned * 0.48)


static func _reed_envelope(t: float, gate: float, attack: float, release: float) -> float:
	if t < 0.0 or t >= gate + release:
		return 0.0
	var a := 1.0 if attack <= 0.0 else _s_curve(t / attack)
	if t <= gate:
		return a
	var x := clampf((t - gate) / release, 0.0, 1.0)
	return a * (1.0 - _s_curve(x))


static func _slow_envelope(t: float, gate: float, attack: float, release: float) -> float:
	if t < 0.0 or t >= gate + release:
		return 0.0
	var a := _s_curve(t / attack)
	if t <= gate:
		return a
	return a * (1.0 - _s_curve((t - gate) / release))


static func _s_curve(value: float) -> float:
	var x := clampf(value, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


static func _reed_table(frequency: float) -> PackedFloat32Array:
	var key := int(round(frequency * 100.0))
	if _table_cache.has(key):
		return _table_cache[key]
	var table := PackedFloat32Array()
	table.resize(_TABLE_SIZE)
	var normalization := 0.0
	for i in range(_TABLE_SIZE):
		var phase := TAU * float(i) / _TABLE_SIZE
		var value := 0.0
		for partial in range(1, 8):
			var ratio := float(partial)
			var harmonic_hz := frequency * ratio
			# Seven organ partials with a soft three-pole low-pass. This sharply
			# suppresses the 1.5–2.4 kHz metronome band while retaining the reed tone.
			var lp := 1.0 / sqrt(1.0 + pow(harmonic_hz / _REED_CUTOFF_HZ, 6.0))
			var weight := (1.15 if partial == 2 else 1.0) * lp / ratio
			value += sin(phase * ratio) * weight
			if i == 0:
				normalization += absf(weight)
		table[i] = value / maxf(normalization, 1.0)
	_table_cache[key] = table
	return table


static func _note_hz(note: String) -> float:
	var semitones := {
		"D2": -31, "G2": -26, "A2": -24,
		"D3": -19, "F3": -16, "G3": -14, "A3": -12, "A#3": -11,
		"C4": -9, "D4": -7, "E4": -5, "F4": -4, "F#4": -3, "G4": -2,
	}
	return 440.0 * pow(2.0, float(semitones.get(note, 0)) / 12.0)


static func _seal_loop_seam(samples: PackedFloat32Array) -> void:
	var width := mini(samples.size() / 2, int(round(_SEAM_S * RATE)))
	if width < 2:
		return
	for j in width:
		var x := float(j) / float(width - 1)
		var fade := 0.5 - 0.5 * cos(PI * x)
		samples[j] *= fade
		samples[samples.size() - width + j] *= 1.0 - fade


static func _crossfade_loop_seam(raw: PackedFloat32Array, output_count: int, width: int) -> PackedFloat32Array:
	# Start one overlap window into the raw synthesis, then blend its final
	# window toward the matching beginning samples. This preserves the natural
	# waveform slope at the seam without repeating a note attack.
	var output := PackedFloat32Array()
	output.resize(output_count)
	var crossfade_start := output_count - width
	for i in output_count:
		var raw_index := i + width
		if i < crossfade_start:
			output[i] = raw[raw_index]
		else:
			var j := i - crossfade_start
			var x := float(j) / float(width - 1)
			var fade := 0.5 - 0.5 * cos(PI * x)
			output[i] = lerpf(raw[raw_index], raw[j], fade)
	return output


static func _fade_region(samples: PackedFloat32Array, start: float, finish: float, fade_in: bool) -> void:
	var first := maxi(0, int(floor(start * RATE)))
	var last := mini(samples.size(), int(ceil(finish * RATE)))
	var width := maxi(1, last - first)
	for i in range(first, last):
		var x := float(i - first) / float(width - 1)
		var factor := _s_curve(x) if fade_in else 1.0 - _s_curve(x)
		samples[i] *= factor


static func _wav(samples: PackedFloat32Array, rate: int = RATE, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
