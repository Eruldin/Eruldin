extends Node

# --probe autopilot (vanilla Godot): title -> hub -> portal -> arena, godmode,
# auto-picks level-up drafts/chests, saves viewport screenshots to
# user://probe/, logs status lines, then quits.

var _step := 0
var _shot_at := -1.0
var _msg_at := 0.0
var _shot_n := 0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://probe"))
	Engine.time_scale = 5.0
	print("[probe] armed, shots -> %s" % ProjectSettings.globalize_path("user://probe"))

func _process(_d: float) -> void:
	match _step:
		0:
			if is_instance_valid(G.ui) and G.ui.overlay_open():
				G.ui._advance_overlay()
				_step = 1
				print("[probe] title -> hub")
		1:
			if G.state == G.State.HUB and is_instance_valid(G.player) and is_instance_valid(G.room) and not G.room.doors.is_empty():
				G.player.pos = G.room.doors[0].pos + Vector2(0, 6)
				_step = 2
		2:
			if G.state == G.State.ROOM:
				G.run.dbg_god()
				_step = 3
				print("[probe] arena live")
		3:
			if G.ui.overlay_open():
				var k := str(G.ui._overlay.get_meta("kind", ""))
				if k in ["draft", "chest", "boon"]:
					G.run.dbg_pick_boon(0)
			if not G.run.alive:
				_shoot()
				print("[probe] run ended (alive=%s)" % G.run.alive)
				get_tree().quit()
				return
			var t := G.run.time
			if t >= _msg_at:
				_msg_at = t + 15.0
				print("[probe] t=%.0f hp=%.0f lvl=%d enemies=%d kills=%d pending=%d" % [t, G.player.hp, G.player.level, G.enemies.size(), int(G.run.stats.get("kills", 0)), G.run.pending_drafts])
			if t >= _shot_at:
				_shot_at = t + 15.0
				_shoot()
			if t > 150.0:
				_shoot()
				print("[probe] done t=%.0f" % t)
				get_tree().quit()

func _shoot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://probe/shot_%02d.png" % _shot_n)
	_shot_n += 1
