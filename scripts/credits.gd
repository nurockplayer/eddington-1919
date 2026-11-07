class_name Credits
extends RefCounted

const AUTHOR := "nurockplayer"
const DISCLAIMER := "Dyson、Eddington、Cottingham 與 1919 年的日食遠征為史實；你、Kit、Ashby 先生、劍橋的那一夜與所有對白為虛構，場景為推測重建。"


static func text() -> String:
	var lines := PackedStringArray([
		L.t("[center][b]製作名單[/b]\n%s · v%s[/center]") % [
			str(ProjectSettings.get_setting("application/config/name")).replace("[", "[lb]"),
			str(ProjectSettings.get_setting("application/config/version")).replace("[", "[lb]")],
		L.t("[b]製作[/b]\n%s\n以 Godot Engine 製作") % AUTHOR,
		L.t("[b]史實與虛構[/b]\n%s") % L.t(DISCLAIMER),
		L.t("[b]第三方素材與授權[/b]\n%s\n\n%s") % [_md_to_bbcode(FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.md")), Engine.get_license_text().replace("[", "[lb]")],
		L.t("[b]Godot 第三方元件[/b]"),
	])
	for component in Engine.get_copyright_info():
		lines.append(str(component.name).replace("[", "[lb]"))
		for part in component.parts:
			for copyright in part.copyright:
				lines.append(str(copyright).replace("[", "[lb]"))
			lines.append(str(part.license).replace("[", "[lb]"))
	lines.append(L.t("[b]Godot 第三方授權全文[/b]"))
	var licenses := Engine.get_license_info()
	for license in licenses:
		lines.append(str(license).replace("[", "[lb]") + "\n" + str(licenses[license]).replace("[", "[lb]"))
	return "\n\n".join(lines)


static func _md_to_bbcode(md: String) -> String:
	var rendered := md.replace("[", "[lb]")
	var regex := RegEx.new()
	regex.compile("\\[lb\\]([^]\\n]+)\\]\\([^)]*\\)")
	rendered = regex.sub(rendered, "$1", true)
	regex.compile("\\*\\*(.+?)\\*\\*")
	rendered = regex.sub(rendered, "[b]$1[/b]", true)
	regex.compile("(?m)^#{1,2} (.+)$")
	rendered = regex.sub(rendered, "[b]$1[/b]", true)
	regex.compile("(?m)^- ")
	return regex.sub(rendered, L.t("・ "), true)
