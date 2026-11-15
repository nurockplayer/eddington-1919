extends RefCounted
## Style audition stub: poster. Replaced by the style's own task.

const PARAMS := {"vignette": 0.22, "grain": 0.03}
const DIALOGUE := {"portrait": "res://assets/portraits/eddington_neutral.jpg"}


func apply(main: Node, style: RefCounted) -> void:
	style.set_post(main, style.params.vignette, style.params.grain)


func light(_main: Node, _style: RefCounted, _contact: float, _darkness: float, _night: float) -> void:
	pass
