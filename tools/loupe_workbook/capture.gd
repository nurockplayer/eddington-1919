extends SceneTree
const World = preload("res://scripts/world_builder.gd")
const Bench = preload("res://tests/benchmark.gd")
var base: String
var sha: String
var game
var aim_target: Vector3
var state: String
var staging: String
var receipts: FileAccess
var interactables: Dictionary = {}
var labels: Array = []
var variant: Dictionary
var reference := false
var baseline := false
var door_energy := 16.0
var lantern_range := 3.5
var slip_drop := 100.0
var fill: Light3D
var diag: Shader
func _initialize() -> void:
    _run.call_deferred()
func frames(n: int) -> void:
    for i in n:
        await process_frame


func xyz(v: Vector3) -> Array:
    return [v.x, v.y, v.z]


func aim(eye: Vector3, target: Vector3, fov: float = 60.0) -> void:
    game.player.global_position = eye - Vector3(0, 1.62, 0)
    game.player.camera.position = Vector3(0, 1.62, 0)
    game.player.rotation = Vector3.ZERO
    game.player.camera.rotation = Vector3.ZERO
    game.player.look_at_point(target)
    game.player.rotation.y = game.player.yaw
    game.player.camera.rotation.x = game.player.pitch
    game.player.camera.fov = fov
    aim_target = target


func close_dialogue() -> void:
    game.ui.dialog_panel.hide()
    game.ui.dialogue_portrait.hide()
    game.ui._seq.clear()
    for b in game.ui._choice_buttons:
        b.hide()
        b.queue_free()
    game.ui._choice_buttons.clear()


func clear_ui() -> void:
    paused = false
    close_dialogue()
    game.ui.title_panel.hide()
    game.ui.pause_panel.hide()
    game.ui.help_panel.hide()
    game.ui.log_panel.hide()
    game.ui.credits_panel.hide()
    game.ui.ending_panel.hide()
    game.ui.close_viewer()
    game.ui.hud.show()
    game.ui._toast_t = 0.0
    game.ui.toast.modulate.a = 0
    game.ui.caption.modulate.a = 0
    game.ui.fade.color.a = 0
    game.ui.set_totality(false)
    game.ui.set_clock("")
    game.ui.set_prompt("")
    game.ui.set_hold(0)


func light(contact: float, darkness: float, cloud_t: float, night: float) -> void:
    game._apply_light(contact, darkness, cloud_t, night)


func set_state(which: String, in_play: bool = true) -> void:
    clear_ui()
    state = which
    staging = "play" if in_play else "benchmark"
    game.world.eddington.show()
    game.world.cottingham.show()
    for body in [game.world.eddington, game.world.cottingham]:
        body.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
        body.process_mode = Node.PROCESS_MODE_DISABLED
        body.set_process(false)
        for ap in body.find_children("*", "AnimationPlayer", true, false):
            ap.seek(0.0, true)
        for mi in body.find_children("*", "MeshInstance3D", true, false):
            for i in mi.mesh.get_surface_count():
                mi.set_surface_override_material(i, null)
    game.world.eddington.position = Vector3(-1.1, 0, -0.9)
    game.world.cottingham.position = Vector3(1.35, 0, -6.1)
    game.world.eddington.rotation.y = PI
    game.world.cottingham.rotation.y = deg_to_rad(-60)
    game.world.roof.visible = which != "totality"
    game.world.lamp.light_energy = 1.1 if which == "night" else 0.0
    game.world.safelight.light_energy = 0.5 if which == "night" else 0.6
    game.sim._open = {}
    game.change_left = 0
    game.tot_done = false
    game._busy = false
    match which:
        "day":
            game.phase = game.Phase.PREP
            game.prep_left = 150.0
            light(0.62, 0.0, -150.0, 0.0)
            game._refresh_objectives()
            game._process_prep(0)
        "totality":
            game.phase = game.Phase.TOTALITY
            game.t_game = 215.0
            game.plates_left = game.sim.plates_available()
            if in_play:
                game.world.eddington.position = Vector3(-0.75, 0, -1.55)
                game.world.cottingham.position = Vector3(0.75, 0, -1.3)
            game.ui.set_objectives("")
            game._process_totality(0)
        "night":
            game.phase = game.Phase.NIGHT
            World.night_dress(game.world.eddington)
            World.night_dress(game.world.cottingham)
            game.world.eddington.position = game.world.eddington_night
            game.world.eddington.rotation.y = deg_to_rad(-120)
            game.world.cottingham.position = game.world.darkroom_spot + Vector3(-1.5, 0, 1.2)
            light(0, 0, 400, 1)
            game._refresh_objectives()


func collect(n: Node) -> void:
    if n.has_meta("interact_id"):
        interactables[str(n.get_meta("interact_id"))] = n
    if n is Label3D:
        labels.append(n)
    for child in n.get_children():
        collect(child)


func sync_pass() -> void:
    var style = game.get("_style")
    if style != null:
        style.quad_material.set_shader_parameter("contact", game.sky_mat.get_shader_parameter("contact"))
        style.quad_material.set_shader_parameter("diamond", game.sky_mat.get_shader_parameter("third_contact").y)


func fresh() -> void:
    if is_instance_valid(game):
        game.stop_all_audio()
        game.free()
        await frames(2)
    seed(7)
    root.get_node("Story").reset()
    root.get_node("Story").from_prologue = true
    root.get_node("Story").departure_done = true
    game=load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    game.set_process(false)
    game.player.set_physics_process(false)
    await frames(20)
    game._start_game()
    game.player.set_physics_process(false)
    game.player.can_look=false
    Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
    game.ui.fade.color.a=0
    await frames(4)


func centre(n: Node3D) -> Vector3:
    # Hotspots are already centred on the object, actors' body colliders are not.
    for shape in n.find_children("*","CollisionShape3D",true,false):
        return shape.global_position
    return n.global_position


func ray(from: Vector3, to: Vector3) -> Dictionary:
    var q:=PhysicsRayQueryParameters3D.create(from,to)
    q.exclude=[game.player.get_rid()]
    return game.get_world_3d().direct_space_state.intersect_ray(q)


func owner_node(n: Node) -> Node:
    while n and not n.has_meta("interact_id"): n=n.get_parent()
    return n


func find_view(n: Node3D, distance: float) -> Dictionary:
    var target:=centre(n)
    var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
    var cap:=CapsuleShape3D.new()
    cap.radius=0.30
    cap.height=1.75
    for j in 144:
        var angle:=float(j)*TAU/144
        var dir:=Vector3(cos(angle),0,sin(angle))
        var eye_y:=1.63
        var horizontal:=sqrt(maxf(0,distance*distance-pow(eye_y-target.y,2)))
        var foot:=Vector3(target.x,0.01,target.z)+dir*horizontal
        # Only standing floors at ground/walkway height; do not stand on roofs/tables.
        var floor_hit:=ray(foot+Vector3(0,0.55,0),foot-Vector3(0,0.55,0))
        if floor_hit.is_empty() or floor_hit.normal.y<0.8: continue
        foot.y=floor_hit.position.y+0.01
        eye_y=foot.y+1.62
        horizontal=sqrt(maxf(0,distance*distance-pow(eye_y-target.y,2)))
        foot.x=target.x+dir.x*horizontal
        foot.z=target.z+dir.z*horizontal
        var floor2:=ray(foot+Vector3(0,0.1,0),foot-Vector3(0,0.1,0))
        if floor2.is_empty() or floor2.normal.y<0.8: continue
        foot.y=floor2.position.y+0.01
        var query:=PhysicsShapeQueryParameters3D.new()
        query.shape=cap
        query.transform=Transform3D(Basis.IDENTITY,foot+Vector3(0,0.875,0))
        query.exclude=[game.player.get_rid()]
        query.collision_mask=game.player.collision_mask
        if not space.intersect_shape(query,1).is_empty(): continue
        var eye:=foot+Vector3(0,1.62,0)
        var hit:=ray(eye,target+(target-eye).normalized()*0.01)
        if hit.is_empty() or owner_node(hit.collider)!=n: continue
        return {"eye":eye,"target":target,"floor_node":str(floor2.collider.get_path()),"capsule_clear":true,"distance_m":eye.distance_to(target),"angles_checked":j+1}
    return {}


func record(path: String, extra: Dictionary = {}) -> void:
    var img: Image = root.get_texture().get_image()
    assert(img.get_size() == DisplayServer.window_get_size())
    assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
    assert(img.save_png(base.path_join(path)) == OK)
    var cam: Camera3D = game.player.camera
    var hit = game.player.aimed_interactable()
    var rec := {"frame":path,"sha":sha,"variant":variant.id,"style_set":variant.style,
        "overrides":variant,"captured_at":Time.get_datetime_string_from_system()+" JST",
        "size":[img.get_width(),img.get_height()],"windowed":true,"title_visible":game.ui.title_panel.is_visible_in_tree(),"narration_visible":game.ui.dialog_panel.is_visible_in_tree(),"state":state,"phase":game.Phase.keys()[game.phase],
        "camera_position":xyz(cam.global_position),"camera_target":xyz(aim_target),"fov":cam.fov,
        "content_scale_size":[root.content_scale_size.x,root.content_scale_size.y],
        "ray_id":hit.get_meta("interact_id") if hit else null,
        "prompt":game.ui.prompt_label.text,"sun_energy":game.sun.light_energy,
        "ambient_energy":game.env.ambient_light_energy,"ambient_rgb":[game.env.ambient_light_color.r,game.env.ambient_light_color.g,game.env.ambient_light_color.b],
        "lamp_energy":game.world.lamp.light_energy,"safelight_energy":game.world.safelight.light_energy,
        "night":game._style.quad_material.get_shader_parameter("night"),
        "darkness":game._style.quad_material.get_shader_parameter("darkness")}
    rec["prompt_rect"] = rect_array(game.ui.prompt_label.get_global_rect().grow(16))
    rec["prompt_visible"] = game.ui.prompt_label.is_visible_in_tree()
    rec["hud_rects"] = hud_rects()
    if not reference:
        rec["door_energy"] = game.world.doorway_daylight.light_energy
        rec["lantern_energy"] = game.world.oxford_lantern_light.light_energy
        rec["lantern_range"] = game.world.oxford_lantern_light.omni_range
    rec.merge(extra)
    receipts.store_line(JSON.stringify(rec))
    receipts.flush()

func save(path: String, extra: Dictionary = {}) -> void:
    if staging == "play":
        close_dialogue()
        game.ui.title_panel.hide()
        game.ui.caption.hide()
    sync_pass()
    await frames(4)
    await RenderingServer.frame_post_draw
    record(path, extra)

func mask(path: String, target: Node = null) -> void:
    # White target, black other geometry; or white still frame, black foliage.
    var saved := []
    var hidden := []
    var surfaces := []
    var white := StandardMaterial3D.new()
    white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    white.albedo_color = Color.WHITE
    var black := white.duplicate()
    black.albedo_color = Color.BLACK
    var env: Environment = game.env
    var old_bg: int = env.background_mode
    var old_color: Color = env.background_color
    var old_fog: bool = env.fog_enabled
    var old_ao: bool = env.ssao_enabled
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color.WHITE if target == null else Color.BLACK
    env.fog_enabled = false
    env.ssao_enabled = false
    var target_meshes := []
    var target_white: Material = white
    if target != null:
        if target is MeshInstance3D: target_meshes.append(target)
        target_meshes.append_array(target.find_children("*", "MeshInstance3D", true, false))
        if target.get_meta("interact_id", "") == "mentor_loupe":
            for n in game.find_children("AshbyBrassLoupe*", "Node3D", true, false):
                if n is MeshInstance3D: target_meshes.append(n)
                target_meshes.append_array(n.find_children("*", "MeshInstance3D", true, false))
    if target != null:
        var id: String = target.get_meta("interact_id", "")
        if id == "departure_workbook":
            target_meshes.append_array(game._night_departure_workbook.find_children("*", "MeshInstance3D", true, false))
        if id in ["drive", "station"]:
            var model_id := "coelostat" if id == "drive" else "horizontal_tube"
            for model in game.get_children():
                if model.scene_file_path.ends_with("/"+model_id+".glb"):
                    if model is MeshInstance3D: target_meshes.append(model)
                    target_meshes.append_array(model.find_children("*", "MeshInstance3D", true, false))
            # These shipped models combine several parts into one mesh. Restrict
            # the white auxiliary material to the named drive/carrier's real triangles.
            var clip := Shader.new()
            clip.code = "shader_type spatial; render_mode unshaded, fog_disabled; uniform vec3 centre; uniform vec3 extent; varying vec3 wp; void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){ALBEDO=all(lessThan(abs(wp-centre),extent))?vec3(1.0):vec3(0.0);}"
            var clipped := ShaderMaterial.new()
            clipped.shader = clip
            clipped.set_shader_parameter("centre", centre(target))
            clipped.set_shader_parameter("extent", Vector3(0.23,0.20,0.19) if id == "drive" else Vector3(0.32,0.32,0.13))
            target_white = clipped
        if id == "sundy":
            for mesh in game.find_children("*", "MeshInstance3D", true, false):
                var p: Vector3 = mesh.global_position
                # The procedural house, roof, veranda and window frames; not its hotspot.
                if p.x >= -22 and p.x <= -8 and p.z >= -24.1 and p.z <= -13.7 and p.y <= 8:
                    target_meshes.append(mesh)
        if target.has_meta("packet_bench"):
            target_meshes.clear()
            for mesh in game.find_children("*", "MeshInstance3D", true, false):
                var p: Vector3 = mesh.global_position
                if p.y >= 0.769 and p.y <= 1.5 and abs(p.x+1.9) < 0.96 and abs(p.z+3.4) < 0.40:
                    target_meshes.append(mesh)
        assert(not target_meshes.is_empty(), "No visible mesh mapped for "+id)
    for n in game.find_children("*", "GeometryInstance3D", true, false):
        if n is MeshInstance3D or n is MultiMeshInstance3D:
            if n.is_in_group("style_quad"):
                hidden.append([n,n.visible]); n.hide(); continue
            var veg := false
            var parent: Node = n
            while parent != game:
                if parent.is_in_group("veg_palm") or parent.is_in_group("veg_shrub"): veg = true
                parent = parent.get_parent()
            saved.append([n,n.material_override])
            n.material_override = (black if veg else white) if target == null else (target_white if n in target_meshes else black)
            if n is MeshInstance3D:
                for i in n.mesh.get_surface_count():
                    surfaces.append([n,i,n.get_surface_override_material(i)])
                    n.set_surface_override_material(i,null)
        elif n is GPUParticles3D or n is Label3D:
            hidden.append([n,n.visible]); n.hide()
    for n in game.find_children("*", "CanvasLayer", true, false):
        hidden.append([n,n.visible]); n.hide()
    await save(path,{"auxiliary":"object occupancy" if target != null else "still-surface mask; sky and static geometry white; vegetation black", "target_meshes":target_meshes.map(func(n): return str(n.get_path()))})
    for item in surfaces: item[0].set_surface_override_material(item[1],item[2])
    for item in saved: item[0].material_override = item[1]
    for item in hidden: item[0].visible = item[1]
    env.background_mode = old_bg
    env.background_color = old_color
    env.fog_enabled = old_fog
    env.ssao_enabled = old_ao

func diagnostic(path: String, target: Node) -> void:
    var hidden := []
    for n in game.find_children("*", "CanvasLayer", true, false):
        hidden.append([n,n.visible]); n.hide()
    for q in get_nodes_in_group("style_quad"): q.hide()
    await save(path+"-pass-off.png", {"auxiliary":"pass off; same native lighting/environment; no grade bypass"})
    for q in get_nodes_in_group("style_quad"): q.show()
    var mat: ShaderMaterial = game._style.quad_material
    var original: Shader = mat.shader
    mat.shader = diag
    mat.set_shader_parameter("diagnostic", 1.0)
    await save(path+"-tones.png", {"auxiliary":"linear decoded RGB = raw tone, normalized tone, ink coverage"})
    mat.set_shader_parameter("diagnostic", 2.0)
    await save(path+"-edges.png", {"auxiliary":"linear decoded RGB = clamped exposed plate luminance, edge strength, darkness"})
    mat.shader = original
    for item in hidden: item[0].visible = item[1]
    await mask(path+"-object-mask.png", target)


func rect_array(r: Rect2) -> Array:
    return [r.position.x,r.position.y,r.size.x,r.size.y]

func hud_rects() -> Dictionary:
    var result := {}
    for pair in [["checklist",game.ui.objectives.get_parent()],["clock",game.ui.clock_label],["dialogue",game.ui.dialog_panel],["choices",game.ui.choice_box],["caption",game.ui.caption],["totality",game.ui.tot_panel],["viewer",game.ui.viewer],["hold",game.ui.hold_bar],["toast",game.ui.toast]]:
        var c: Control = pair[1]
        if c.is_visible_in_tree() and c.modulate.a > 0.01:
            result[pair[0]] = rect_array(c.get_global_rect().grow(16 if pair[0] in ["clock","caption","toast"] else 0))
    return result


func _run() -> void:
    var resolution := ""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--out="): base = arg.trim_prefix("--out=")
        if arg.begins_with("--sha="): sha = arg.trim_prefix("--sha=")
        if arg.begins_with("--size="): resolution = arg.trim_prefix("--size=")
        if arg == "--baseline": baseline = true
    assert(not base.is_empty() and not sha.is_empty() and not resolution.is_empty())
    receipts = FileAccess.open(base.path_join("receipts.jsonl"), FileAccess.READ_WRITE if FileAccess.file_exists(base.path_join("receipts.jsonl")) else FileAccess.WRITE)
    receipts.seek_end()
    var prefix := "main" if baseline else "head"
    variant = {"id": prefix, "style":""}
    var views_path := base.path_join("views-" + resolution + ".json")
    var views: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(views_path)) if baseline else {}
    await fresh()
    game._add_night_workbook()
    collect(game)
    set_state("night")
    game.world.safelight.light_energy = 0.5
    game.world.lamp.light_energy = 1.1
    game.world.doorway_daylight.light_energy = 0.0
    game.ui.prompt_label.position.y = 550.0
    for scene_name in ["night", "coda"]:
        if scene_name == "coda":
            game._begin_coda()
            if game._camera_turn: game._camera_turn.kill()
            close_dialogue()
            game._busy = false
            state = "coda"
        for id in ["mentor_loupe", "departure_workbook"]:
            if scene_name == "coda":
                game.coda_step = game.CodaStep.LOUPE if id == "mentor_loupe" else game.CodaStep.WORKBOOK
            for distance in [3.0, 1.5]:
                var key: String = scene_name + "-" + id + "-" + str(distance)
                var n: Node3D = interactables[id]
                await physics_frame
                var eye: Vector3
                var target: Vector3
                if baseline:
                    var v: Dictionary = views[key]
                    eye = Vector3(v.eye[0], v.eye[1], v.eye[2])
                    target = Vector3(v.target[0], v.target[1], v.target[2])
                else:
                    var view := find_view(n, distance)
                    assert(not view.is_empty(), "No standing view: " + key)
                    eye = view.eye
                    target = view.target
                    views[key] = {"eye":xyz(eye), "target":xyz(target), "distance_m":eye.distance_to(target)}
                aim(eye, target, 72.0)
                await frames(3)
                game._process_interaction(0)
                assert(game.player.aimed_interactable() == n, "Ray misses " + prefix + " " + key)
                var path: String = "frames/" + prefix + "-" + resolution + "-" + key
                await save(path + ".png", {"label":key,"distance_m":eye.distance_to(target),"interactable":id})
                for object_id in ["mentor_loupe", "departure_workbook"]:
                    await mask(path + "-" + object_id + "-mask.png", interactables[object_id])
    if not baseline:
        set_state("night")
        aim(Vector3(9.2, 1.67, 4.2), Vector3(10.6, 0.82, 4.1), 72.0)
        FileAccess.open(views_path, FileAccess.WRITE).store_string(JSON.stringify(views, "  "))
        # Same throughput method as tests/benchmark.gd: 20 settle and 240
        # force_draw(false) frames per rep, no presentation pacing.
        await frames(20)
        var results := []
        for rep in 3:
            var start := Time.get_ticks_usec()
            for i in 240: RenderingServer.force_draw(false)
            var avg := (Time.get_ticks_usec() - start) / 240000.0
            results.append({"rep":rep+1, "forced_draw_ms_avg":avg, "estimate_fps_x3":1000.0/(avg*3.0)})
        FileAccess.open(base.path_join("perf-" + resolution + ".json"), FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
    game.stop_all_audio()
    game.free()
    receipts.close()
    print("CAPTURE COMPLETE ",prefix," ",resolution)
    quit()
