extends SceneTree

const Prompts := preload("res://scripts/prompts.gd")
const L := preload("res://scripts/l10n.gd")

func _initialize() -> void:
	Prompts.joypad = false
	assert(Prompts.key("trim") == L.t("←／→"), "keyboard hint uses arrow keys")
	Prompts.joypad = true
	assert(Prompts.key("trim") == L.t("方向鍵左／右"), "pad hint uses the D-pad")
	Prompts.joypad = false
	print("test_ui: 2 checks passed")
	quit()
