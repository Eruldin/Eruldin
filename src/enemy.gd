class_name Enemy
extends Actor

# Data-driven melee/ranged enemy AI with readable telegraphs.
# States: RISE -> SEEK -> WINDUP -> STRIKE -> RECOVER -> SEEK ...

enum EKind { HUSK, SPITTER, TURRET, DRONE, SENTINEL }
enum St { RISE, SEEK, WINDUP, STRIKE, RECOVER }

var kind: int = EKind.HUSK
var elite := false
var speed := 100.0
var touch_dmg := 10.0
var touch_r := 36.0
var windup_t := 0.45
var recover_t := 0.55
var attack_cd := 0.9
var burst_n := 0
var burst_gap := 0.12
var proj_spd := 230.0
var proj_dmg := 9.0
var keep_min := 0.0
var keep_max := 9999.0
var kamikaze := false

var _st: int = St.RISE
var _rise_t := 0.55
var _state_t := 0.0
var _cd_t := 0.0
var _strike_dir := Vector2.ZERO
var _tele := {}
var _has_tok := false          # holds an attack-director token
var _orbit := 1.0              # strafe direction while waiting for a token

static func spawn(p_kind: int, p_pos: Vector2, p_elite: bool, hp_scale: float, dmg_scale: float, parent: Node) -> Enemy:
	var e := Enemy.new()
	e.kind = p_kind
	e.elite = p_elite
	e.team = G.Team.ENEMY
	parent.add_child(e)
	e.global_position = p_pos
	e._setup_stats(hp_scale, dmg_scale)
	e.init()
	G.enemies.append(e)
	return e

func _setup_stats(hs: float, ds: float) -> void:
	match kind:
		EKind.HUSK:
			max_hp = 34; speed = 108; touch_dmg = 8; radius = 13; hit_radius = 16
			windup_t = 0.45; recover_t = 0.55; attack_cd = 1.15; touch_r = 36
			actor_name = "Proterian Husk"
		EKind.SENTINEL:
			max_hp = 55; speed = 135; touch_dmg = 14; radius = 14; hit_radius = 17
			windup_t = 0.5; recover_t = 0.6; attack_cd = 1.1; touch_r = 40
			actor_name = "İmparatorluk Muhafızı"
		EKind.SPITTER:
			max_hp = 26; speed = 75; touch_dmg = 6; radius = 14; hit_radius = 17
			windup_t = 0.55; recover_t = 0.8; attack_cd = 1.7; keep_min = 150; keep_max = 260
			proj_spd = 230; proj_dmg = 9; burst_n = 1
			actor_name = "Tükürükçü"
		EKind.TURRET:
			max_hp = 40; speed = 0; touch_dmg = 0; radius = 15; hit_radius = 17
			windup_t = 0.6; recover_t = 2.2; attack_cd = 2.4; keep_min = 0; keep_max = 9999
			proj_spd = 260; proj_dmg = 7; burst_n = 4; burst_gap = 0.12
			actor_name = "Taret"
			knock_resist = 100.0
		EKind.DRONE:
			max_hp = 12; speed = 165; touch_dmg = 12; radius = 10; hit_radius = 13
			windup_t = 0.55; recover_t = 0.4; attack_cd = 0.8; touch_r = 34; kamikaze = true
			actor_name = "Vızıltı Dronu"
	if elite:
		max_hp *= 2.6; touch_dmg *= 1.35; proj_dmg *= 1.3; speed *= 1.1
		actor_name = "Elit " + actor_name
	max_hp *= hs
	touch_dmg *= ds
	proj_dmg *= ds
	hp = max_hp

func init() -> void:
	super.init()
	_make_body()
	G.fx.burst(pos + Vector2(0, -6), Px.C("7B1FA2") if elite else Color(0.3, 0.5, 0.2), 12, 90.0, 4.0, 0.5)

func _make_body() -> void:
	body = Sprite2D.new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(body)
	var kn: String = EKind.keys()[kind].to_lower()
	if is_instance_valid(G.room) and G.room.biome > 0:
		var bk := "%s_%d" % [kn, G.room.biome]
		if not Px._ext_frames(bk).is_empty():
			kn = bk
	_load_frames(kn, 5.0)
	Px.fit(body, 118.0 if elite else 86.0)
	if elite:
		base_color = Color(0.9, 0.65, 1.0)
		G.fx.mk_light(self, Vector2(0, -18), Px.C("7B1FA2"), 0.5, 1.6)
	body.modulate = Color(0.2, 0.2, 0.2, 0)
	_orbit = -1.0 if G.chance(0.5) else 1.0

func _process(_d: float) -> void:
	if dead:
		return
	var d := get_process_delta_time()
	tick(d)
	if stagger > 0:
		_cancel_attack()
		return
	if G.state != G.State.ROOM or G.player == null or G.player.dead:
		return
	match _st:
		St.RISE:
			_rise_t -= d
			if is_instance_valid(body):
				var a := clampf(1.0 - _rise_t / 0.55, 0.0, 1.0)
				body.modulate = Color(a, a, a, a)
			if _rise_t <= 0:
				_st = St.SEEK
				body.modulate = base_color
		St.SEEK: _seek(d)
		St.WINDUP: _windup(d)
		St.STRIKE: _strike(d)
		St.RECOVER:
			_state_t -= d
			if _state_t <= 0:
				_st = St.SEEK
				_release_tok()
				_set_anim("idle", 5.0)
	if _cd_t > 0:
		_cd_t -= d
	_tick_anim(d)

func _seek(d: float) -> void:
	var to_p: Vector2 = G.player.pos - pos
	var dist := to_p.length()
	# arena leash: far stragglers recycle back onto the off-screen ring
	if dist > 1500.0 and G.room is Arena:
		pos = G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * G.rf(700.0, 860.0)
		pos = G.room.clamp_pos(pos, radius)
		to_p = G.player.pos - pos
		dist = to_p.length()
	var dir := to_p.normalized()
	# separation — bounded checks, hordes stay O(n)
	var _seen := 0
	for o in G.enemies:
		if o == self or o.dead:
			continue
		_seen += 1
		if _seen > 10:
			break
		var away: Vector2 = pos - o.pos
		var dd := away.length()
		if dd < radius + o.radius + 5.0 and dd > 0.01:
			dir += away.normalized() * (1.2 - dd / 40.0) * 1.4
	if kind == EKind.SPITTER:
		if dist < keep_min:
			dir = -dir
		elif dist < keep_max:
			dir = dir.rotated(PI / 2 * sin(Time.get_ticks_msec() * 0.0008))
	if speed > 0:
		pos += dir.normalized() * speed * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
	_face_p()
	# stealth: player hidden briefly after dash
	var seen := G.player.stealth_t <= 0
	if _cd_t <= 0 and seen:
		match kind:
			EKind.TURRET:
				if dist < 400.0: _begin_windup()
			EKind.SPITTER:
				if dist < keep_max + 40.0: _begin_windup()
			EKind.DRONE:
				if dist < 55.0: _begin_windup()
			EKind.HUSK, EKind.SENTINEL:
				if dist < 110.0:
					if _has_tok or G.melee_tokens > 0:
						if not _has_tok:
							_has_tok = true
							G.melee_tokens -= 1
						_begin_windup()
					else:
						# attack director full — orbit the player instead of crowding
						pos += dir.rotated(PI / 2 * _orbit) * speed * 0.55 * d
						pos = G.room.clamp_pos(pos, radius) if is_instance_valid(G.room) else pos

func _begin_windup() -> void:
	_st = St.WINDUP
	_state_t = windup_t
	_set_anim("windup", 6.0)
	if is_instance_valid(body):
		body.modulate = Color(1.5, 0.45, 0.35)
	if kind == EKind.DRONE:
		_tele = G.fx.tele_circle(pos, 55.0, windup_t, Color(1, 0.3, 0.1, 0.3))
		_tele["follow"] = self
	elif kind == EKind.HUSK or kind == EKind.SENTINEL:
		var ang := rad_to_deg((G.player.pos - pos).angle())
		_tele = G.fx.tele_wedge(pos, ang, 78.0, windup_t)
	G.audio.play("ui", 0.6, 0.3)

func _windup(d: float) -> void:
	_state_t -= d
	_face_p()
	if _state_t <= 0:
		_st = St.STRIKE
		_state_t = 0.22
		_strike_dir = (G.player.pos - pos).normalized()
		G.fx.kill_tele(_tele)
		_tele = {}
		_set_anim("strike", 8.0)
		if is_instance_valid(body):
			body.modulate = base_color
		_do_strike()

func _strike(d: float) -> void:
	_state_t -= d
	if kind == EKind.HUSK or kind == EKind.SENTINEL:
		pos += _strike_dir * (420.0 if kind == EKind.SENTINEL else 320.0) * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
		if G.player != null and not G.player.dead and pos.distance_to(G.player.pos) < radius + G.player.hit_radius + 8.0:
			G.player.take_hit({"dmg": touch_dmg, "type": G.DamageType.MELEE, "from": pos, "knock": 5.0, "source": self})
			_state_t = 0
	if _state_t <= 0:
		_st = St.RECOVER
		_state_t = recover_t
		_cd_t = attack_cd

func _do_strike() -> void:
	match kind:
		EKind.SPITTER:
			_shoot_at(G.player.pos, proj_spd, proj_dmg, Px.C("39ff14"), 9.0)
		EKind.TURRET:
			_burst_co()
		EKind.DRONE:
			_explode()

func _burst_co() -> void:
	for i in burst_n:
		if dead or G.player == null or G.player.dead:
			return
		var dir := (G.player.pos - pos).normalized().rotated(deg_to_rad(G.rf(-6, 6)))
		_shoot_dir(dir, proj_spd, proj_dmg, Px.C("ff4444"), 7.0)
		await get_tree().create_timer(burst_gap).timeout

func _shoot_at(target: Vector2, spd: float, dmg: float, col: Color, rad: float) -> void:
	_shoot_dir((target - pos).normalized(), spd, dmg, col, rad)

func _shoot_dir(dir: Vector2, spd: float, dmg: float, col: Color, rad: float) -> void:
	var p := Projectile.new()
	G.game.world.add_child(p)
	p.setup(G.Team.ENEMY, pos + dir * 16.0, dir * spd, dmg, rad, col, "dot")
	p.source = self
	G.audio.play("shoot", G.rf(0.9, 1.2), 0.4)

func _explode() -> void:
	G.audio.play("explode", 1.1, 0.7)
	G.fx.burst(pos + Vector2(0, -8), Px.C("ff7722"), 26, 220.0, 6.0, 0.5)
	G.fx.shake(0.2, 0.2)
	if G.player != null and not G.player.dead and pos.distance_to(G.player.pos) < 62.0:
		G.player.take_hit({"dmg": touch_dmg, "type": G.DamageType.EXPLOSION, "from": pos, "knock": 7.0, "source": self})
	die({"dmg": 9999.0, "type": G.DamageType.PURE, "from": pos, "source": self})

func _face_p() -> void:
	if is_instance_valid(body) and G.player != null:
		body.flip_h = G.player.pos.x < pos.x

func _release_tok() -> void:
	if _has_tok:
		_has_tok = false
		G.melee_tokens = mini(G.melee_tokens + 1, G.MELEE_TOKENS_MAX)

func _cancel_attack() -> void:
	if _st == St.WINDUP or _st == St.STRIKE:
		_st = St.SEEK
		_release_tok()
		_set_anim("idle", 5.0)
		G.fx.kill_tele(_tele)
		_tele = {}
		if is_instance_valid(body):
			body.modulate = base_color

func take_hit(h: Dictionary) -> void:
	super.take_hit(h)
	if _st == St.RISE:
		_rise_t = minf(_rise_t, 0.15)

func die(h: Dictionary) -> void:
	if dead:
		return
	_release_tok()
	G.fx.kill_tele(_tele)
	super.die(h)
	G.enemies.erase(self)
	G.meta.data.kills += 1
	if is_instance_valid(G.run):
		G.run.stats.kills = int(G.run.stats.get("kills", 0)) + 1
	G.audio.play("die", G.rf(0.9, 1.2), 0.6)
	G.fx.light_flash(pos + Vector2(0, -12), Color(1, 0.5, 0.3), 1.4, 2.4, 0.2)
	G.fx.burst(pos + Vector2(0, -10), Color(0.5, 0.05, 0.05), 30 if elite else 16, 190.0, 5.0, 0.6, 6.0)
	G.fx.burst(pos + Vector2(0, -10), Color(0.9, 0.7, 0.4), 8 if elite else 4, 210.0, 3.0, 0.3)
	if elite:
		G.fx.hitstop(0.05)
	G.fx.splat(pos + Vector2(0, 4), Color(0.4, 0.03, 0.03), 1.4 if elite else 0.8)
	if kind == EKind.DRONE or kind == EKind.SPITTER:
		G.fx.burst(pos + Vector2(0, -6), Px.C("00E676"), 12, 130.0, 4.0, 0.5)
	if is_instance_valid(G.room):
		# XP gem every kill; elites also drop a chest; rare heal orb
		var xp_val: float = [1.0, 2.0, 3.0, 1.0, 3.0][kind] + (10.0 if elite else 0.0)
		G.room.spawn_gem(pos, xp_val)
		if elite:
			G.room.spawn_chest(pos)
			G.run.drop_fragments(pos, G.ri(8, 14))
		elif G.chance(0.12):
			G.run.drop_fragments(pos, G.ri(1, 3))
		if G.chance(0.045):
			G.room.spawn_heal(pos)
		G.room.on_enemy_dead(self)
	queue_free()
