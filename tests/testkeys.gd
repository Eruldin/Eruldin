extends Node

# --testkeys debug harness (NOT for shipping): F-key hooks for manual testing.
# Loaded only when the game is launched with `-- --testkeys` (see game.gd hook).
#   F1  god mode            F2  cycle time_scale 1/4/8     F3  grant one level-up
#   F4  lethal self-hit     F5  force victory             F6  spawn elite nearby
#   F7  make blade evo-ready (lvl8 + greaves)             F8  kill all enemies (drops chests)
#   F9  jump timer to ~miniboss (5:28)   F10 jump to ~final boss (10:57)
#   F11 jump to ~collapse failsafe (12:57)

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	print("[testkeys] armed — F1 god, F2 timescale, F3 lvl, F4 die, F5 win, F6 elite, F7 evo-ready, F8 clear, F9/F10/F11 time jumps")

func _say(msg: String) -> void:
	print("[testkeys] " + msg)
	if is_instance_valid(G.ui):
		G.ui.toast("[dbg] " + msg)

func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	match ev.keycode:
		KEY_F1:
			if is_instance_valid(G.run):
				G.run.dbg_god()
				_say("godmode ON")
		KEY_F2:
			Engine.time_scale = 1.0 if Engine.time_scale >= 8.0 else Engine.time_scale * 4.0
			_say("time_scale=%.0f" % Engine.time_scale)
		KEY_F3:
			if is_instance_valid(G.player):
				G.player.add_xp(G.player.xp_next)
				_say("xp granted (lvl %d)" % G.player.level)
		KEY_F4:
			if is_instance_valid(G.run):
				G.run.dbg_hurt_player(999999.0)
				_say("lethal hit")
		KEY_F5:
			if is_instance_valid(G.run):
				G.run.victory()
				_say("victory() forced")
		KEY_F6:
			if is_instance_valid(G.room) and is_instance_valid(G.player):
				var e := Enemy.spawn(Enemy.EKind.SENTINEL, G.player.pos + Vector2(160, 0), true, 1.0, 1.0, G.room)
				_say("elite sentinel spawned")
		KEY_F7:
			if is_instance_valid(G.player):
				for w in G.player.weapons:
					if str(w.id) == "blade":
						w.lvl = 8
				if not Weapons.has_p(G.player, "greaves"):
					G.player.passives.append({"id": "greaves", "lvl": 1})
					Weapons.apply_passive("greaves", G.player)
				_say("blade=8 + greaves — evo_ready=%d" % Weapons.evo_ready(G.player).size())
		KEY_F8:
			if is_instance_valid(G.run):
				G.run.dbg_clear_room()
				_say("room cleared")
		KEY_F9:
			if is_instance_valid(G.director):
				G.director.t = 328.0
				_say("t=328 — miniboss imminent")
		KEY_F10:
			if is_instance_valid(G.director):
				G.director.t = 657.0
				_say("t=657 — final boss imminent")
		KEY_F11:
			if is_instance_valid(G.director):
				G.director.t = 777.0
				_say("t=777 — collapse imminent")
