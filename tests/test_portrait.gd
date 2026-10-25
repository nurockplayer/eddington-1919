extends SceneTree
## Synthetic mood entries and real Cambridge presentation/collision contracts.
const UI := preload("res://scripts/ui.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const Portrait := preload("res://scripts/cambridge/dialogue_portrait.gd")
const Room := preload("res://scripts/cambridge/room_builder.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func frames(n := 4) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	var ui = UI.new()
	root.add_child(ui)
	ui.hide_title()
	ui.cambridge_portraits = true
	for speaker in [Cast.MENTOR, Cast.EDDINGTON]:
		ui.play([{"s": speaker, "t": "Synthetic portrait check."}])
		check(ui.dialogue_portrait.visible, "principal gets a portrait")
		check(ui.dialogue_portrait.image.texture.resource_path == Portrait.PRINTS[speaker].neutral, "default is neutral")
		check(ui.dialogue_portrait.disclosure.text == "重建肖像，非歷史照片", "exact reconstruction disclosure")
		check(ui.dialogue_portrait.disclosure.get_theme_color("font_color") == UI.DIM, "disclosure uses muted UI colour")
		ui.play([{"s": speaker, "t": "Synthetic missing mood.", "mood": "unavailable"}])
		check(ui.dialogue_portrait.image.texture.resource_path == Portrait.PRINTS[speaker].neutral, "unknown mood falls back to neutral")
		var mood := "doubt" if speaker == Cast.MENTOR else "intent"
		ui.play([{"s": speaker, "t": "Synthetic expression.", "mood": mood}])
		check(ui.dialogue_portrait.image.texture.resource_path == Portrait.PRINTS[speaker][mood], "optional mood selects approved expression")
		ui._advance()
		check(not ui.dialogue_portrait.visible, "portrait hides when dialogue ends")
	for speaker in [Cast.YOU, Cast.KIT, Cast.COPYIST, "Unknown"]:
		ui.play([{"s": speaker, "t": "Synthetic non-principal.", "mood": "doubt"}])
		check(not ui.dialogue_portrait.visible and ui.dialogue_portrait.image.texture == null, "no portrait or stale texture for " + speaker)
	for variants in Portrait.PRINTS.values():
		for path in variants.values():
			var texture := load(path) as Texture2D
			check(texture.get_width() <= 1280 and texture.get_height() <= 1280, "portrait obeys image size budget")
	var original_scale_size := root.content_scale_size
	root.content_scale_size = Vector2i.ZERO
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		ui.play([{"s": Cast.MENTOR, "t": "Synthetic choices beside the mounted print.", "choices": ["Keep the original.", "Record the correction.", "Return to the evidence."]}])
		await frames()
		ui._layout_dialogue_portrait()
		await frames()
		var screen := root.get_visible_rect()
		check(screen.size == Vector2(resolution), "layout checks use the requested logical viewport")
		var print_rect: Rect2 = ui.dialogue_portrait.get_global_rect()
		var dialog: Rect2 = ui.dialog_panel.get_global_rect()
		check(screen.encloses(print_rect), "print stays inside " + str(resolution))
		check(screen.encloses(ui.dialogue_portrait.disclosure.get_global_rect()), "disclosure stays inside viewport")
		check(screen.encloses(dialog), "dialogue stays inside viewport")
		check(not print_rect.intersects(dialog), "print has its own column beside dialogue")
		check(not print_rect.has_point(screen.get_center()), "print leaves central evidence clear")
		for button in ui._choice_buttons:
			check(screen.encloses(button.get_global_rect()) and not print_rect.intersects(button.get_global_rect()), "choice remains on screen and clear of print")
	root.content_scale_size = original_scale_size
	ui._advance()
	ui.free()
	await frames()
	# Shared UI defaults keep the 1917 prints out of the Príncipe/departure scenes.
	ui = UI.new()
	root.add_child(ui)
	ui.play([{"s": Cast.EDDINGTON, "t": "Synthetic 1919 entry."}])
	check(not ui.dialogue_portrait.visible, "shared UI requires Cambridge opt-in")
	ui.free()
	var room := Node3D.new()
	root.add_child(room)
	var world := Room.build(room)
	for id in ["mentor", "eddington"]:
		var actor: StaticBody3D = world[id]
		check(actor.name == "CambridgeFigure_" + id and actor.get_meta("interact_id") == id, "principal keeps its interaction identity")
		check(actor.get_child(0) == actor.get_meta("room_collision_shape"), "principal keeps collider metadata and order")
		check(actor.has_node("figure"), "principal uses imported body")
		var figure := actor.get_node("figure")
		var skeleton := figure.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		for side in ["l", "r"]:
			var bone := skeleton.find_bone("hand_" + side)
			var hand := actor.to_local(skeleton.to_global(skeleton.get_bone_global_pose(bone).origin))
			var posed := hand.y > 0.65 and hand.y < 1.05
			if id == "mentor":
				posed = posed and hand.z < -0.3
			check(posed, "%s %s hand uses authored pose rather than rest pose: %s" % [id, side, hand])
		var animation := figure.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		check(not animation.is_playing(), "authored pose is held still")
		actor.show()
		check(not actor.get_meta("room_collision_shape").disabled, "show enables principal collider")
		actor.hide()
		check(actor.get_meta("room_collision_shape").disabled, "hide disables principal collider")
	check(not world.kit.has_node("figure"), "Kit stays procedural")
	room.free()
	room = Node3D.new()
	root.add_child(room)
	world = Room.build(room, true)
	check(not world.mentor.has_node("figure") and not world.eddington.has_node("figure"), "departure people stay procedural")
	room.free()
	await frames()
	var chapter = load("res://scripts/cambridge/director.gd").new()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 15000
	while not chapter.ui.dialog_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter.ui.dialog_active(), "ordinary Cambridge opening reaches dialogue")
	await create_timer(0.5).timeout
	check(is_equal_approx(chapter.player.camera.fov, 55.0), "dialogue settles at 55 degree FOV")
	var tags: Array = []
	for actor in [chapter.world.kit, chapter.world.mentor, chapter.world.eddington]:
		for tag in actor.find_children("*", "Label3D", true, false):
			if tag.has_meta("cambridge_name_tag"):
				tags.append(tag)
	check(tags.size() == 3, "all three Cambridge name tags exist")
	check(tags.all(func(tag): return not tag.visible), "all name tags hide during dialogue")
	while chapter.ui.dialog_active():
		chapter.ui._advance()
	await create_timer(0.5).timeout
	check(is_equal_approx(chapter.player.camera.fov, 72.0), "gameplay restores 72 degree FOV")
	check(tags.all(func(tag): return tag.visible), "name tags restore after dialogue")
	chapter.set_process(false)
	for audio in chapter.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	# Match the existing suites' audio-thread drain before freeing a chapter.
	await create_timer(0.06, true, false, true).timeout
	chapter.free()
	await frames()
	print("%d portrait checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
