extends RefCounted
## Plain button names are covered by the bundled Traditional Chinese font.
static var joypad := false


static func key(action: String) -> String:
	if joypad:
		return {"interact": "A 鍵", "shutter": "RB／X 鍵", "pause": "Start", "toggle_log": "Back", "rotate": "LB／RB"}.get(action, action)
	return {"interact": "E", "shutter": "空白鍵", "pause": "Esc", "toggle_log": "Tab", "rotate": "Q／E"}.get(action, action)
