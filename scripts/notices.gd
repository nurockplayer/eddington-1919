class_name Notices
extends RefCounted


static func text() -> String:
	return FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES.md") + "\n\n" + Engine.get_license_text()
