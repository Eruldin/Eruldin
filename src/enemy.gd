class_name Enemy
extends Actor

# Data-driven melee/ranged enemy AI with readable telegraphs.
# States: RISE -> SEEK -> WINDUP -> STRIKE -> RECOVER -> SEEK ...

enum EKind { HUSK, SPITTER, TURRET, DRONE, SENTINEL, VARL, CEREB, KONAKCI, ALFA, CARRIER }

const KIND_NAME := {EKind.HUSK: "Proterian Husk", EKind.SENTINEL: "İmparatorluk Muhafızı", EKind.SPITTER: "Tükürükçü", EKind.TURRET: "Taret", EKind.DRONE: "Vızıltı Dronu", EKind.VARL: "Çölayan Varl", EKind.CEREB: "Cerebellum Kisti", EKind.KONAKCI: "Konakçı Yaratık", EKind.ALFA: "Alfa Şövalye", EKind.CARRIER: "Hamal Taşıyıcı"}
enum St { RISE, SEEK, WINDUP, STRIKE, RECOVER }

# painted concept-art sets for the new kinds; biome variants fall back to the
# base set automatically in _make_body
const KIND_SET := {
	EKind.VARL: "c_varl", EKind.CEREB: "c_cereb",
	EKind.KONAKCI: "c_konakci", EKind.ALFA: "c_alfa", EKind.CARRIER: "c_konakci",
}

var kind: int = EKind.HUSK
var elite := false
var affix := ""            # elite modifier: armored / volatile / swift / sparked
var _spk_t := 0.0
var _sum_t := 0.0   # çağırıcı elit: döl saçma sayacı
var _mend_t := 0.0  # şifalı elit: alan onarımı sayacı
var _sum_n := 0     # bu elitin saldığı döl sayısı
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
var splits := 0             # on death, burst into this many parasite runners

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
		EKind.VARL:
			max_hp = 16; speed = 192; touch_dmg = 7; radius = 11; hit_radius = 14
			windup_t = 0.35; recover_t = 0.4; attack_cd = 0.9; touch_r = 30
			actor_name = "Çölayan Varl"
		EKind.CEREB:
			max_hp = 34; speed = 62; touch_dmg = 7; radius = 15; hit_radius = 18
			windup_t = 0.6; recover_t = 0.9; attack_cd = 2.2; keep_min = 170; keep_max = 300
			proj_spd = 175; proj_dmg = 13; burst_n = 1
			actor_name = "Cerebellum Kisti"
		EKind.KONAKCI:
			max_hp = 150; speed = 60; touch_dmg = 20; radius = 19; hit_radius = 22
			windup_t = 0.7; recover_t = 0.8; attack_cd = 1.6; touch_r = 48
			actor_name = "Konakçı Yaratık"
			knock_resist = 60.0
			splits = 2
		EKind.ALFA:
			max_hp = 88; speed = 128; touch_dmg = 16; radius = 15; hit_radius = 18
			windup_t = 0.5; recover_t = 0.55; attack_cd = 1.0; touch_r = 42
			actor_name = "Alfa Şövalye"
		EKind.CARRIER:
			max_hp = 130; speed = 66; touch_dmg = 12; radius = 18; hit_radius = 21
			windup_t = 0.65; recover_t = 0.8; attack_cd = 1.5; touch_r = 44
			actor_name = "Hamal Taşıyıcı"
			knock_resist = 80.0
	if elite:
		max_hp *= 2.6; touch_dmg *= 1.35; proj_dmg *= 1.3; speed *= 1.1
		actor_name = "Elit " + actor_name
		affix = ["armored", "volatile", "swift", "sparked", "caller", "vampir", "mender"][randi() % 7]
		match affix:
			"armored":
				armor += 5.0
				actor_name = "ZIRHLI " + actor_name
			"volatile":
				actor_name = "PATLAYICI " + actor_name
			"swift":
				speed *= 1.45; attack_cd *= 0.8
				actor_name = "HIZLI " + actor_name
			"sparked":
				_spk_t = 1.2
				actor_name = "ŞİMŞEKLİ " + actor_name
			"caller":
				_sum_t = 5.0
				actor_name = "ÇAĞIRICI " + actor_name
			"vampir":
				actor_name = "VAMPİR " + actor_name
			"mender":
				_mend_t = 1.6
				actor_name = "ŞİFALI " + actor_name
	max_hp *= hs
	touch_dmg *= ds
	proj_dmg *= ds
	if G.run != null and G.run.slow_all:
		speed *= 0.9
	hp = max_hp

func init() -> void:
	super.init()
	_make_body()
	G.fx.burst(pos + Vector2(0, -6), Px.C("7B1FA2") if elite else Color(0.3, 0.5, 0.2), 12, 90.0, 4.0, 0.5)

func _make_body() -> void:
	body = Sprite2D.new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(body)
	var kn: String = KIND_SET.get(kind, EKind.keys()[kind].to_lower())
	if is_instance_valid(G.room) and G.room.biome > 0:
		var bk := "%s_%d" % [kn, G.room.biome]
		if not Px._ext_frames(bk).is_empty():
			kn = bk
	_load_frames(kn, 5.0)
	Px.fit(body, 118.0 if elite else (108.0 if kind == EKind.KONAKCI else 86.0))
	if kind == EKind.CARRIER and not elite:
		base_color = Color(1.0, 0.85, 0.45)
		G.fx.mk_light(self, Vector2(0, -18), Px.C("ffb74d"), 0.4, 1.4)
	if elite:
		base_color = Color(0.9, 0.65, 1.0)
		var lc: String = {"armored": "8ea0b5", "volatile": "ff5533", "swift": "00E5FF", "sparked": "ffe066", "caller": "4dd0e1", "vampir": "d32f2f", "mender": "69f0ae"}.get(affix, "7B1FA2")
		G.fx.mk_light(self, Vector2(0, -18), Px.C(lc), 0.5, 1.6)
		_hp_bg = ColorRect.new()
		_hp_bg.color = Color(0.04, 0.02, 0.06, 0.85)
		_hp_bg.position = Vector2(-24, -80)
		_hp_bg.size = Vector2(48, 6)
		_hp_bg.z_index = 30
		add_child(_hp_bg)
		_hp_fg = ColorRect.new()
		_hp_fg.color = Px.C("ffb74d")
		_hp_fg.position = Vector2(1, 1)
		_hp_fg.size = Vector2(46, 4)
		_hp_bg.add_child(_hp_fg)
	body.modulate = Color(0.2, 0.2, 0.2, 0)
	_orbit = -1.0 if G.chance(0.5) else 1.0

var _hp_bg: ColorRect
var _hp_fg: ColorRect

func _process(_d: float) -> void:
	if dead:
		return
	if is_instance_valid(_hp_fg):
		_hp_fg.size.x = 46.0 * clampf(float(hp) / float(max_hp), 0.0, 1.0)
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
	# sparked elite: periodic lightning strike on a close player
	if affix == "sparked":
		_spk_t -= d
		if _spk_t <= 0.0:
			_spk_t = 2.4
			if pos.distance_to(G.player.pos) < 240.0:
				G.player.take_hit({"dmg": maxf(4.0, touch_dmg * 0.5), "type": G.DamageType.SHOCK, "from": pos + Vector2(0, -40), "knock": 0.0, "source": self})
				G.fx.light_flash(G.player.pos + Vector2(0, -24), Px.C("ffe066"), 1.2, 1.6, 0.12)
				G.fx.directional(G.player.pos + Vector2(0, -60), Vector2.DOWN, Px.C("ffe066"), 4, 200.0, 2.5, 0.14)
	# çağırıcı elit: periyodik olarak varl dölleri saçar — öncelik hedef olur
	if affix == "caller" and _sum_n < 8:
		_sum_t -= d
		if _sum_t <= 0.0:
			_sum_t = 6.5
			_sum_n += 2
			for i in 2:
				var off := Vector2.RIGHT.rotated(TAU * i / 2.0 + G.rf(0, 0.8)) * 42.0
				Enemy.spawn(EKind.VARL, pos + off, false, G.run.hp_scale() * 0.6, G.run.dmg_scale() * 0.8, G.room)
			G.fx.burst(pos + Vector2(0, -14), Px.C("4dd0e1"), 10, 120.0, 4.0, 0.4)
			G.audio.play("roar", 1.6, 0.3)
	# şifalı elit: yakın sürü üyelerini periyodik onarır — öncelik hedef olur
	if affix == "mender":
		_mend_t -= d
		if _mend_t <= 0.0:
			_mend_t = 2.0
			var mn := 0
			for e in G.enemies:
				if e != self and is_instance_valid(e) and not e.dead and pos.distance_to(e.pos) < 180.0 and e.hp < e.max_hp:
					e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.05)
					mn += 1
			if mn > 0:
				G.fx.burst(pos + Vector2(0, -14), Px.C("69f0ae"), 10, 140.0, 4.0, 0.4)
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
	if kind == EKind.SPITTER or kind == EKind.CEREB:
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
			EKind.SPITTER, EKind.CEREB:
				if dist < keep_max + 40.0: _begin_windup()
			EKind.DRONE:
				if dist < 55.0: _begin_windup()
			EKind.HUSK, EKind.SENTINEL, EKind.VARL, EKind.KONAKCI, EKind.ALFA:
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
	elif kind in [EKind.HUSK, EKind.SENTINEL, EKind.VARL, EKind.KONAKCI, EKind.ALFA]:
		var ang := rad_to_deg((G.player.pos - pos).angle())
		_tele = G.fx.tele_wedge(pos, ang, 78.0 if kind != EKind.KONAKCI else 104.0, windup_t)
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
	if kind in [EKind.HUSK, EKind.SENTINEL, EKind.VARL, EKind.KONAKCI, EKind.ALFA]:
		var lunge := 320.0
		match kind:
			EKind.SENTINEL: lunge = 420.0
			EKind.VARL: lunge = 400.0
			EKind.ALFA: lunge = 470.0
			EKind.KONAKCI: lunge = 240.0
		pos += _strike_dir * lunge * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
		if G.player != null and not G.player.dead and pos.distance_to(G.player.pos) < radius + G.player.hit_radius + 8.0:
			G.player.take_hit({"dmg": touch_dmg, "type": G.DamageType.MELEE, "from": pos, "knock": 5.0, "source": self})
			if affix == "vampir":
				hp = minf(hp + touch_dmg * 0.6, max_hp)
			_state_t = 0
	if _state_t <= 0:
		_st = St.RECOVER
		_state_t = recover_t
		_cd_t = attack_cd

func _do_strike() -> void:
	match kind:
		EKind.SPITTER:
			_shoot_at(G.player.pos, proj_spd, proj_dmg, Px.C("39ff14"), 9.0)
		EKind.CEREB:
			_lob(G.player.pos)
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

# mortar lob: mark the landing zone, the glob bursts there in an AoE
func _lob(target: Vector2) -> void:
	var dist := pos.distance_to(target)
	var flight := clampf(dist / proj_spd, 0.5, 1.6)
	var blast_r := 62.0
	G.fx.tele_circle(target, blast_r, flight, Color(0.6, 0.2, 1.0, 0.3))
	var p := Projectile.new()
	G.game.world.add_child(p)
	var dir := (target - pos).normalized()
	p.setup(G.Team.ENEMY, pos + dir * 16.0, dir * (dist / flight), proj_dmg, 12.0, Px.C("7B1FA2"), "dot")
	p.life = flight
	p.aoe = blast_r
	p.source = self
	G.audio.play("shoot", G.rf(0.7, 0.9), 0.5)

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
		var kk: Dictionary = G.run.stats.get("kind_kills", {})
		var kn := str(KIND_NAME.get(kind, actor_name))
		kk[kn] = int(kk.get(kn, 0)) + 1
		G.run.stats["kind_kills"] = kk
		G.run.on_kill(elite)
	G.audio.play("die", G.rf(0.9, 1.2), 0.6)
	G.fx.light_flash(pos + Vector2(0, -12), Color(1, 0.5, 0.3), 1.4, 2.4, 0.2)
	G.fx.burst(pos + Vector2(0, -10), Color(0.5, 0.05, 0.05), 30 if elite else 16, 190.0, 5.0, 0.6, 6.0)
	G.fx.burst(pos + Vector2(0, -10), Color(0.9, 0.7, 0.4), 8 if elite else 4, 210.0, 3.0, 0.3)
	if elite:
		G.fx.hitstop(0.05)
	G.fx.splat(pos + Vector2(0, 4), Color(0.4, 0.03, 0.03), 1.4 if elite else 0.8)
	if kind == EKind.DRONE or kind == EKind.SPITTER:
		G.fx.burst(pos + Vector2(0, -6), Px.C("00E676"), 12, 130.0, 4.0, 0.5)
	if splits > 0 and is_instance_valid(G.room) and G.state == G.State.ROOM:
		for i in splits:
			var off := Vector2.RIGHT.rotated(TAU * float(i) / float(splits) + G.rf(0, 0.6)) * 30.0
			Enemy.spawn(EKind.VARL, pos + off, false, 0.5, 0.7, G.room)
		G.fx.burst(pos, Px.C("8dc63f"), 14, 150.0, 4.0, 0.4)
	if is_instance_valid(G.room):
		# XP gem every kill; elites also drop a chest; rare heal orb
		var xp_val: float = [1.0, 2.0, 3.0, 1.0, 3.0, 1.0, 3.0, 6.0, 5.0][kind] + (10.0 if elite else 0.0)
		G.room.spawn_gem(pos, xp_val)
		if elite:
			G.room.spawn_chest(pos)
			G.run.drop_fragments(pos, G.ri(8, 14))
			if is_instance_valid(G.player) and G.player.has_meta("elite_heal"):
				G.player.heal(8.0)
			if actor_name.contains("HASATÇI"):
				G.meta.data["reapers"] = int(G.meta.data.get("reapers", 0)) + 1
				G.meta.save()
			if G.chance(0.12):
				G.room.spawn_special(G.pick(["vacuum", "bomb", "freeze", "boost", "guard"]), pos)
			# altın nüve: nadir kalıcı güç düşüşü (VS golden egg)
			if G.chance(0.03):
				G.room.spawn_special("egg", pos)
		elif G.chance(0.12):
			G.run.drop_fragments(pos, G.ri(1, 3))
	# volatile elite: telegraphed blast after death
	if elite and affix == "volatile":
		var warn := Sprite2D.new()
		warn.texture = Px.S("ring")
		warn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		warn.modulate = Color(1.0, 0.35, 0.2, 0.8)
		warn.position = pos
		warn.z_index = 40
		var host: Node = G.room if is_instance_valid(G.room) else G.game.world
		host.add_child(warn)
		var blast_pos := pos
		var bd := touch_dmg * 1.2
		var tw := warn.create_tween()
		tw.tween_property(warn, "scale", Vector2.ONE * (236.0 / 72.0), 0.55)
		tw.tween_callback(func():
			if is_instance_valid(warn):
				warn.queue_free()
			if is_instance_valid(G.player) and not G.player.dead and G.player.pos.distance_to(blast_pos) < 118.0:
				G.player.take_hit({"dmg": bd, "type": G.DamageType.EXPLOSION, "from": blast_pos, "knock": 14.0, "source": null})
			G.fx.burst(blast_pos, Color(1.0, 0.45, 0.15), 26, 240.0, 6.0, 0.5)
			G.fx.light_flash(blast_pos, Color(1, 0.6, 0.2), 2.2, 3.0, 0.25)
			G.audio.play("explode", 0.9, 0.7)
			G.fx.shake(0.18, 0.2))
		if G.chance(0.045 * (2.0 if is_instance_valid(G.player) and G.player.has_meta("heal_luck") else 1.0)) and not G.run.dark:
			G.room.spawn_heal(pos)
		# HASAT ŞENLİĞİ kozu: kesim başına küçük parçacık damlası
		if is_instance_valid(G.player) and G.player.has_meta("harvest") and G.chance(0.02):
			G.run.drop_fragments(pos, 1)
		# hamal taşıyıcı yükünü düşürür — rastgele saha kalıntısı
		if kind == EKind.CARRIER:
			G.room.spawn_special(G.pick(["vacuum", "bomb", "freeze", "boost", "guard"]), pos)
			G.fx.float_text(pos + Vector2(0, -40), "YÜK DÜŞTÜ", Px.C("ffb74d"), 0.9)
		G.room.on_enemy_dead(self)
	queue_free()
