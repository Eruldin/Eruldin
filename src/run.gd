class_name Run
extends Node

# One arena run: hub → open field → time-scripted swarm → miniboss → final boss.
# Victory by killing the final boss (or outlasting the collapse timer).
# Holds run-scoped state (fragments, boons). On death all of it resets;
# meta progression (Pure Choralim + upgrades) persists via G.meta.

const ROOMS_PER_BIOME := 3  # combat rooms before the boss room
const FINAL_BOSS := 3
const BOSS_IDS := ["rex", "host", "twins", "final"]
const BOSS_NAMES := ["REX / ALPHA-05", "PROTERIAN HOST", "NAHUM & TUMAN", "KIRIN & CONSTANTIN"]

var game: Node2D
var biome := 0
var depth := 0
var hyper := false          # AŞILAMA modu — David'in saha panelinden açılır
var reward_mult := 1.0     # choralim payout multiplier (hyper ×1.5)
var fragments := 0        # impure choralim gathered this run → purified on death
var boon_ids: Array = []
var luck := 0.0           # raised by elites; sways epic boon rolls
var alive := true
var time := 0.0           # seconds survived this run (Director drives it)
var pending_drafts := 0     # queued level-up drafts
var draft_reroll := false   # one card reroll available per level-up draft
var stats := {"kills": 0, "rooms": 0}

func _init(g: Node2D) -> void:
	game = g

func hp_scale() -> float: return 1.0 + biome * 0.35 + depth * 0.12
func dmg_scale() -> float: return 1.0 + biome * 0.18 + depth * 0.06

func hub() -> void:
	biome = 0
	depth = 0
	G.state = G.State.HUB
	G.fx.transition()
	_room_to(G.room)
	var r := Room.new()
	game.world.add_child(r)
	r.build_hub()
	_spawn_player(r.spawn_point())
	_contract_tick()
	G.ui.hub_ui(true)

func start_run() -> void:
	biome = clampi(int(G.meta.data.get("arena_biome", 0)), 0, 3)
	hyper = bool(G.meta.data.get("hyper", false))
	reward_mult = 1.5 if hyper else 1.0
	depth = -1
	fragments = 0
	boon_ids.clear()
	luck = G.meta.upg(Meta.U.LUCK) * 0.15
	alive = true
	time = 0.0
	pending_drafts = 0
	stats = {"kills": 0, "rooms": 0}
	G.meta.data["runs"] += 1
	G.meta.save()
	G.fx.transition()
	_room_to(G.room)
	var a := Arena.new()
	game.world.add_child(a)
	G.state = G.State.TRANSITION
	a.build_arena(biome)
	_place_player(a)
	G.player.reset_for_run()
	G.ui.hub_ui(false)
	if hyper:
		G.ui.toast("AŞILAMA AKTİF — kovan hızlı akıyor, ödeme ×1.5")
	var dr := Director.new()
	dr.biome = biome
	add_child(dr)
	G.director = dr
	G.state = G.State.ROOM

# level-up drafts queue up while an overlay is open; open the next when clear
func _process(_d: float) -> void:
	if pending_drafts > 0 and G.state == G.State.ROOM and is_instance_valid(G.ui) and not G.ui.overlay_open():
		pending_drafts -= 1
		G.ui.levelup_draft()

func open_chest() -> void:
	var evos := Weapons.evo_ready(G.player)
	if evos.is_empty():
		fragments += 120
		G.player.heal(G.player.max_hp * 0.25)
		G.ui.toast("sandık: +120 parçacık · can yenilendi")
		G.audio.jingle("boon")
		return
	G.ui.chest_choice(evos)

func apply_evo(spec: Dictionary) -> void:
	Weapons.apply_evo(spec, G.player)

func next_room(reward: int) -> void:
	depth += 1
	stats.rooms += 1
	var is_boss := depth >= ROOMS_PER_BIOME
	var rt := Room.Type.BOSS if is_boss else (Room.Type.ELITE if _elite_room() else Room.Type.COMBAT)
	G.fx.transition()
	_room_to(G.room)
	var r := Room.new()
	game.world.add_child(r)
	G.state = G.State.TRANSITION
	r.build(biome, rt, reward, depth, randi())
	G.state = G.State.ROOM
	_place_player(r)
	G.ui.hub_ui(false)
	# cinematic cards: dossier still on biome entry, portrait card on boss
	if is_boss:
		var por: String = {"rex": "rex", "host": "host", "twins": "nahum", "final": "kirin"}[BOSS_IDS[biome]]
		G.ui.cinematic("por_" + por, BOSS_NAMES[biome], _boss_intro_sub(biome), 2.4)
	elif depth == 0:
		G.ui.cinematic("cine_%d_0" % biome, Room.BIOME_NAME[biome], _biome_sub(biome), 2.8)

func _biome_sub(b: int) -> String:
	return ["Proterian çoraklığı — Alfa-05'in izi burada.",
			"Simithar damarları — kovanın derinliklere uzandığı yer.",
			"Sol Primus enkazı — imparatorluğun çürüyen tahtı.",
			"Aeterna Kulesi — protokolün kalbi."][b]

func _boss_intro_sub(b: int) -> String:
	return ["Alfa-05 · Düşmüş Kardeş — transistörü hâlâ şarkı söylüyor.",
			"Proterian Yeni Nesil Konakçı — kovan eti hatırlıyor.",
			"Nahum & Tuman — ikiz protokol, çift ölüm.",
			"Kirin & Constantin — masanın son iki sandalyesi."][b]

func _elite_room() -> bool:
	return depth == 1 and G.chance(0.35)

func descend() -> void:
	# boss beaten — go deeper (or win)
	if biome >= FINAL_BOSS:
		victory()
		return
	biome += 1
	depth = -1
	next_room(Room.Reward.BOON)

# Ehnar's rotating contracts — one field task per camp visit, pays choralim
const CONTRACTS := [
	{"key": "kills", "need": 150, "reward": 45},
	{"key": "kills", "need": 400, "reward": 90},
	{"key": "time",  "need": 480, "reward": 60},
	{"key": "time",  "need": 660, "reward": 85},
	{"key": "level", "need": 10,  "reward": 40},
	{"key": "level", "need": 16,  "reward": 70},
	{"key": "win",   "need": 1,   "reward": 120},
]

func contract_text(c: Dictionary) -> String:
	if c.is_empty():
		return "—"
	match str(c.get("key", "")):
		"kills": return "Tek koşuda %d kesim" % int(c.need)
		"time":  return "Tek koşuda %d saniye dayan" % int(c.need)
		"level": return "Tek koşuda seviye %d'e ulaş" % int(c.need)
		"win":   return "Son efendiyi düşür ve dön"
	return "—"

func _write_last_run(win: bool) -> void:
	G.meta.data["last_run"] = {
		"kills": int(stats.get("kills", 0)),
		"time": int(time),
		"level": G.player.level if is_instance_valid(G.player) else 1,
		"win": win,
	}

func _contract_met(c: Dictionary, lr: Dictionary) -> bool:
	if c.is_empty() or lr.is_empty():
		return false
	match str(c.get("key", "")):
		"kills": return int(lr.get("kills", 0)) >= int(c.need)
		"time":  return int(lr.get("time", 0)) >= int(c.need)
		"level": return int(lr.get("level", 0)) >= int(c.need)
		"win":   return bool(lr.get("win", false))
	return false

# evaluate the last run against Ehnar's contract, then hand out the next one
func _contract_tick() -> void:
	var c: Dictionary = G.meta.data.get("contract", {})
	if _contract_met(c, G.meta.data.get("last_run", {})):
		var r := int(c.get("reward", 0))
		G.meta.add_choralim(r)
		G.ui.toast("EHNAR: sözleşme tuttu — +%d◆" % r)
		G.audio.jingle("boon")
		c = {}
	if c.is_empty():
		var nxt: Dictionary = CONTRACTS[randi() % CONTRACTS.size()]
		# don't repeat the identical task back-to-back
		var last_k: String = G.meta.data.get("_last_contract_key", "")
		if str(nxt.key) == last_k:
			nxt = CONTRACTS[(CONTRACTS.find(nxt) + 1) % CONTRACTS.size()]
		G.meta.data["contract"] = {"key": nxt.key, "need": nxt.need, "reward": nxt.reward}
		G.meta.data["_last_contract_key"] = nxt.key
		G.meta.save()

func victory() -> void:
	if not alive:
		return
	G.state = G.State.VICTORY
	alive = false
	if is_instance_valid(G.director):
		G.director.running = false
	if is_instance_valid(G.room):
		G.room.boss = null
	G.ui.boss_bar(false, null)
	stats.time = time
	stats.level = G.player.level if is_instance_valid(G.player) else 1
	_write_last_run(true)
	var gained := int(fragments * G.meta.frag_mult() * reward_mult)
	G.meta.add_choralim(gained)
	stats.gained = gained
	fragments = 0
	G.meta.data["victories"] += 1
	G.meta.save()
	G.audio.jingle("boss")
	G.ui.victory_screen(stats)

func on_player_death(h: Dictionary) -> void:
	if not alive:
		return
	alive = false
	G.state = G.State.DEAD
	var killer := "kovan"
	var src = h.get("source")
	if src is Actor:
		killer = src.actor_name
	var was_boss := is_instance_valid(G.room) and G.room.boss != null
	if is_instance_valid(G.director):
		G.director.running = false
	G.ui.boss_bar(false, null)
	_write_last_run(false)
	G.meta.record_death(killer, biome, int(time), was_boss)
	var gained := int(fragments * G.meta.frag_mult() * reward_mult)
	G.meta.add_choralim(gained)
	fragments = 0
	G.ui.death_screen(killer, gained)

func abandon_to_hub() -> void:
	if not alive:
		return
	alive = false
	var gained := int(fragments * G.meta.frag_mult() * reward_mult)
	if gained > 0:
		G.meta.add_choralim(gained)
	fragments = 0
	respawn_to_hub()

func respawn_to_hub() -> void:
	# purge the dead player shell, rebuild at camp
	if is_instance_valid(G.player):
		G.player.queue_free()
	G.player = null
	hub()
	G.ui.death_reaction()

func on_room_cleared() -> void:
	# grant the reward promised by the door we entered through
	match G.room.pending_reward:
		Room.Reward.BOON:
			G.ui.boon_choice()
		Room.Reward.HEAL:
			G.player.heal(G.player.max_hp * 0.4)
			G.room.spawn_fragments(Vector2(0, -60), 14 + biome * 4)
			G.ui.toast("yenilendin")
		_:
			G.room.spawn_fragments(Vector2(0, -60), 18 + biome * 6)
			G.ui.toast("+%d choralim parçacığı" % (18 + biome * 6))
	if G.room.rtype == Room.Type.ELITE:
		luck += 0.15
		G.ui.toast("elit ganimeti — şans arttı")

func on_boss_dead() -> void:
	G.meta.boss_down(BOSS_IDS[biome])
	G.room.spawn_fragments(Vector2(0, -40), 60 + biome * 50)
	G.ui.toast("%s düştü — kapı açıldı" % BOSS_NAMES[biome])

func take_boon(b: Dictionary) -> void:
	boon_ids.append(b.id)
	Boons.apply(b.id, G.player)
	G.fx.burst(G.player.pos + Vector2(0, -24), b.color, 20, 150.0, 4.0, 0.7)
	G.audio.jingle("boon")
	G.ui.toast("%s — %s" % [b.name, b.desc])
	if b.patron == "Kovan":
		G.fx.flash(Color(0.1, 0.9, 0.2, 0.1), 0.6)

func drop_fragments(p: Vector2, total: int) -> void:
	if is_instance_valid(G.room):
		G.room.spawn_fragments(p, total)

func _room_to(old: Room) -> void:
	if old != null and is_instance_valid(old):
		old.queue_free()
	for e in G.enemies.duplicate():
		if is_instance_valid(e):
			e.queue_free()
		G.enemies.erase(e)
	for p in G.projectiles.duplicate():
		if is_instance_valid(p):
			p.queue_free()
		G.projectiles.erase(p)
	for c in game.world.get_children():
		if c is Enemy and is_instance_valid(c):
			c.queue_free()
			G.enemies.erase(c)
	G.melee_tokens = 2
	G.MELEE_TOKENS_MAX = 2
	if is_instance_valid(G.ui):
		G.ui.boss_bar(false, null)
	if is_instance_valid(G.director):
		G.director.queue_free()
		G.director = null
	if is_instance_valid(G.fx):
		G.fx.clear_decals()
		G.fx.hitstop_t = 0.0
		G.fx.prev_scale = 1.0
	Engine.time_scale = 1.0

func _spawn_player(p: Vector2) -> void:
	if G.player == null or not is_instance_valid(G.player) or G.player.dead:
		if is_instance_valid(G.player):
			G.player.queue_free()
		var pl := Player.new()
		game.world.add_child(pl)
		pl.pos = p
		pl.init()
		G.player = pl
	else:
		G.player.pos = p
		if G.player.get_parent() == null:
			game.world.add_child(G.player)

func _place_player(r: Room) -> void:
	_spawn_player(r.spawn_point())
	G.player.pos = r.spawn_point()
	G.player.ext_vel = Vector2.ZERO

# ---------------------------------------------------------------- debug (MCP playtest)

func dbg() -> Dictionary:
	var es := []
	if is_instance_valid(G.room):
		for e in G.enemies:
			if is_instance_valid(e):
				es.append({"p": [roundi(e.pos.x), roundi(e.pos.y)], "hp": roundi(e.hp), "dead": e.dead, "path": str(e.get_path())})
	var ds := []
	if is_instance_valid(G.room):
		for d in G.room.doors:
			ds.append({"p": [roundi(d.pos.x), roundi(d.pos.y)], "locked": d.locked, "gate": d.get("gate", false), "descend": d.get("descend", false), "reward": d.reward})
	return {
		"state": G.state, "biome": biome, "depth": depth, "alive": alive,
		"fragments": fragments, "boons": boon_ids.size(), "luck": luck,
		"p_pos": [roundi(G.player.pos.x), roundi(G.player.pos.y)] if is_instance_valid(G.player) else [],
		"p_hp": roundi(G.player.hp) if is_instance_valid(G.player) else -1,
		"p_dead": G.player.dead if is_instance_valid(G.player) else false,
		"p_path": str(G.player.get_path()) if is_instance_valid(G.player) else "",
		"r_cleared": G.room.cleared if is_instance_valid(G.room) else false,
		"r_hub": G.room.is_hub if is_instance_valid(G.room) else false,
		"r_wave": [G.room.wave_idx, G.room.waves.size(), G.room.alive] if is_instance_valid(G.room) else [],
		"enemies": es, "doors": ds,
		"overlay": G.ui.overlay_open() if is_instance_valid(G.ui) else false,
		"o_kind": G.ui._overlay.get_meta("kind", "") if is_instance_valid(G.ui) and G.ui.overlay_open() else "",
		"paused": get_tree().paused,
		"t_scale": Engine.time_scale,
		"choralim": G.meta.data.choralim if G.meta != null else -1,
	}

func dbg_to_door(i: int = 0) -> void:
	# teleport the player onto door i (or the first unlocked one) — skips walking
	if not is_instance_valid(G.player) or not is_instance_valid(G.room):
		return
	var idx := i
	if i < 0:
		for j in G.room.doors.size():
			if not G.room.doors[j].locked:
				idx = j
				break
	if idx < G.room.doors.size():
		G.player.pos = G.room.doors[idx].pos + Vector2(0, 6)

func dbg_hit_enemy(i: int, dmg: float) -> void:
	# scalar-only args so MCP runtime_call can marshal them safely
	var live: Array = []
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead:
			live.append(e)
	if i >= 0 and i < live.size():
		var e: Actor = live[i]
		e.take_hit({"dmg": dmg, "type": G.DamageType.MELEE, "from": e.pos + Vector2(0, 20), "knock": 4.0, "stagger": 0.3, "source": G.player})

func dbg_clear_room() -> void:
	for e in G.enemies.duplicate():
		if is_instance_valid(e) and not e.dead:
			e.invuln = 0.0
			if "shielded" in e:
				e.set("shielded", false)
			e.die({"dmg": 99999.0, "type": G.DamageType.PURE, "from": e.pos, "source": G.player})

func dbg_god() -> void:
	# test-only godmode: survive long enough to stage visuals
	if is_instance_valid(G.player):
		G.player.max_hp = 99999.0
		G.player.hp = 99999.0
		G.player.armor = 99.0

func dbg_hurt_player(dmg: float) -> void:
	if is_instance_valid(G.player):
		G.player.invuln = 0.0
		G.player.take_hit({"dmg": dmg, "type": G.DamageType.MELEE, "from": G.player.pos + Vector2(10, 0), "source": null})

func dbg_swing() -> void:
	# fire the sword swing directly — input polling can't be driven while suspended
	if is_instance_valid(G.player) and not G.player.dead:
		G.player._start_swing()

func dbg_aim(x: float, y: float) -> void:
	if is_instance_valid(G.player):
		G.player.aim_dir = (Vector2(x, y) - G.player.pos).normalized()

func dbg_pick_boon(i: int) -> void:
	if is_instance_valid(G.ui._overlay) and str(G.ui._overlay.get_meta("kind", "")) in ["boon", "draft", "chest"]:
		var opts: Array = G.ui._overlay.get_meta("opts", [])
		if i >= 0 and i < opts.size():
			G.ui._pick_card(opts[i])

func dbg_step_to_clear(max_steps: int = 20) -> int:
	# returns how many door-steps remain; used to sanity-check progression
	return max_steps

func dbg_give_choralim(n: int) -> void:
	G.meta.add_choralim(n)

func dbg_shoot(speed: float = 170.0, dist: float = 150.0) -> void:
	# enemy bolt fired straight at the player from the east — parry test staging
	if not is_instance_valid(G.player):
		return
	var p := Projectile.new()
	G.game.world.add_child(p)
	p.setup(G.Team.ENEMY, G.player.pos + Vector2(dist, 0), Vector2(-speed, 0),
		6.0, 8.0, Px.C("FF5252"), "dot")

func dbg_buy(u: int) -> bool:
	return G.meta.buy(u)
