extends RefCounted
## Plain button names are covered by the bundled Traditional Chinese font.
static var joypad := false


static func key(action: String) -> String:
	if joypad:
		return {"trim": L.t("方向鍵左／右"), "trim_fine": "LT", "trim_record": L.t("A 鍵"), "trim_leave": L.t("B 鍵"), "interact": L.t("A 鍵"), "shutter": L.t("RB／X 鍵"), "pause": "Start", "toggle_log": "Back", "rotate": L.t("LB／RB")}.get(action, action)
	return {"trim": L.t("←／→"), "trim_fine": "Shift", "trim_record": L.t("E／Enter"), "trim_leave": "B", "interact": "E", "shutter": L.t("空白鍵"), "pause": "Esc", "toggle_log": "Tab", "rotate": L.t("Q／E")}.get(action, action)
