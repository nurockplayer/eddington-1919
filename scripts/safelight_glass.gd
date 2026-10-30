extends MeshInstance3D
## The ruby pane of the darkroom safelight: it glows with the light behind it,
## so the coda's fade to black darkens the glass with the room.

const GLOW := 2.4  # emission per unit of light_energy

var light: OmniLight3D


func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.03, 0.02)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.12, 0.05)
	m.roughness = 0.3
	material_override = m
	_sync()


func _process(_delta: float) -> void:
	_sync()


func _sync() -> void:
	if light:
		(material_override as StandardMaterial3D).emission_energy_multiplier = light.light_energy * GLOW
