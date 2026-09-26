class_name Player
extends Actor

# Ely (Alfa-04): 8-way movement, 3-hit blade combo, charged plasma shot,
# dash with i-frames (12f), timed parry (6f). World units are pixels.

var speed := 205.0
var melee_dmg := 14.0
var plasma_dmg := 26.0
var dmg_mult := 1.0
var plasma_mult := 1.0
var atk_speed := 1.0
var crit_ch := 0.05
var crit_mult := 2.0
var dmg_taken_mult := 1.0
var lifesteal := 0.0
var heal_on_kill := 0.0
var dash_max := 1
var dash_regen := 1.1
var dash_regen_mult := 1.0
var parry_window := 0.10
var parry_cd := 0.55
var plasma_size := 1.0
# boon flags
var b_gravity_well := false
var b_homing := false
var b_poison := false
var b_emp := false
var b_parry_shock := false
var b_stealth_dash := false
var stealth_t := 0.0

var dash_charges := 1
var _dash_regen_t := 0.0
var _dash_t := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector2.ZERO
var _parry_t := 0.0
var _parry_cd := 0.0
var _combo := 0
var _combo_t := 0.0
var _combo_lock := 0.0
var _combo_queued := false
var _plasma_charge := -1.0   # <0 = not charging
var _attack_slow := 1.0
var revived := false
var _swing_hit_done := false
var charge_rate := 1.0       # plasma charge speed (Rex overcharge boon)
var _charge_full := false

# doctrine (Rhasa stance): cleave = wide arcs / duelist = fast single-target
var st_arc := 1.0
var st_dmg := 1.0
var st_spd := 1.0
var st_parry := 0.0
var st_reach := 0.0

# input buffers — presses register a short window ahead of the actionable frame
var _buf_lmb := 0.0
var _buf_dash := 0.0
var _buf_parry := 0.0
const BUF_T := 0.14

var _aura: PointLight2D
var _hurt_anim_t := 0.0

var move_dir := Vector2.ZERO
var aim_dir := Vector2.RIGHT
var blade: Sprite2D

func is_dashing() -> bool: return _dash_t > 0
func parry_active() -> bool: return _parry_t > 0
func plasma_charge() -> float: return clampf(_plasma_charge, 0.0, 1.0)

func init() -> void:
	team = G.Team.PLAYER
	radius = 13.0
	hit_radius = 16.0
	actor_name = "Ely"
	max_hp = 100 + G.meta.upg(Meta.U.HP) * 20
	hp = max_hp
	armor = G.meta.upg(Meta.U.SHIELD) * 1.0
	dmg_mult += G.meta.upg(Meta.U.DMG) * 0.08
	dash_max += G.meta.upg(Meta.U.DASH)
	dash_charges = dash_max
	knock_resist = 2.0
	super.init()
	_apply_stance()
	body = Sprite2D.new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(body)
	_load_frames("ely", 7.0)
	Px.fit(body, 94.0)
	_aura = G.fx.mk_light(self, Vector2(0, -20), Px.C("00E5FF"), 0.45, 2.0)
	blade = Sprite2D.new()
	blade.texture = Px.S("wedge")
	blade.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	blade.modulate = Color(0.45, 0.9, 1, 0)
	blade.z_index = 40
	blade.scale = Vector2.ONE * 1.1
	add_child(blade)

func _process(_d: float) -> void:
	if dead:
		return
	var d := get_process_delta_time()
	tick(d)
	if G.state != G.State.ROOM and G.state != G.State.HUB:
		return
	_read_input()
	_tick_dash(d)
	_tick_combat(d)
	_tick_plasma(d)
	_move(d)
	_tick_anim(d)
	_pick_anim()
	# Saphire regen + Rex static field
	if has_meta("regen") and G.state == G.State.ROOM:
		heal(get_meta("regen") * d)
	if has_meta("static") and G.state == G.State.ROOM:
		_static_t -= d
		if _static_t <= 0:
			_static_t = 0.5
			for e in G.enemies.duplicate():
				if not is_instance_valid(e) or e.dead:
					continue
				if pos.distance_to(e.pos) < 95.0:
					e.take_hit({"dmg": get_meta("static") * 0.5, "type": G.DamageType.SHOCK, "from": pos, "source": self})
					G.fx.burst(e.pos + Vector2(0, -10), Px.C("00E5FF"), 2, 60.0, 2.5, 0.2)

var _static_t := 0.0

func _read_input() -> void:
	move_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_dir.x += 1
	if move_dir.length_squared() > 1:
		move_dir = move_dir.normalized()
	var mw := get_global_mouse_position()
	aim_dir = (mw - pos).normalized()
	if is_instance_valid(body):
		body.flip_h = mw.x < pos.x - 2

func _move(d: float) -> void:
	if _dash_t > 0:
		pos += _dash_dir * 560.0 * d
		return
	var sp := speed * _attack_slow * (G.room.slow_at(pos) if is_instance_valid(G.room) else 1.0) * (1.05 if stealth_t > 0 else 1.0)
	pos += move_dir * sp * d
	if is_instance_valid(G.room):
		pos = G.room.clamp_pos(pos, radius)
	if is_instance_valid(body):
		if stealth_t > 0:
			stealth_t -= d
			body.modulate.a = 0.45
		elif body.modulate.a < 0.95:
			body.modulate.a = 1.0

# pick the animation state by current action priority
func _pick_anim() -> void:
	if _hurt_anim_t > 0:
		_hurt_anim_t -= get_process_delta_time()
		return
	if _dash_t > 0:
		_set_anim("dash", 12.0)
	elif _parry_t > 0:
		_set_anim("parry", 8.0)
	elif _combo_lock > 0 and _anim.begins_with("atk"):
		pass  # attack anim runs on its own clock
	elif _plasma_charge >= 0.0:
		_set_anim("charge", 8.0)
	elif move_dir.length_squared() > 0.01:
		_set_anim("run", 9.0)
	else:
		_set_anim("idle", 3.0)

func _tick_dash(d: float) -> void:
	if _dash_cd > 0: _dash_cd -= d
	if dash_charges < dash_max:
		_dash_regen_t += d * dash_regen_mult
		if _dash_regen_t >= dash_regen:
			dash_charges += 1
			_dash_regen_t = 0
	if _dash_t > 0:
		_dash_t -= d
		if G.chance(d * 30):
			G.fx.ghost(body, Px.C("00E5FF"))
		if _dash_t <= 0 and is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
	if _buf_dash > 0:
		_buf_dash -= d
	var space_now := Input.is_key_pressed(KEY_SPACE)
	if space_now and not _space_held:
		_buf_dash = BUF_T
	_space_held = space_now
	if _buf_dash > 0 and dash_charges > 0 and _dash_cd <= 0:
		_buf_dash = 0
		var dir := move_dir if move_dir.length_squared() > 0.01 else aim_dir
		_dash_dir = dir.normalized()
		_dash_t = 0.16
		_dash_cd = 0.5
		dash_charges -= 1
		invuln = maxf(invuln, 0.20)      # 12-frame i-frames
		if has_meta("aegis"):
			invuln += 0.15             # Neva: Telekinetik Zırh
		G.audio.play("dash", G.rf(0.95, 1.1))
		G.fx.directional(pos + Vector2(0, -10), -_dash_dir, Px.C("00E5FF"), 8, 160.0, 4.0, 0.3)
		if b_stealth_dash:
			stealth_t = 1.2
		if _combo_lock > 0:
			_combo_lock = 0
			_attack_slow = 1.0
			blade.modulate = Color(0.45, 0.9, 1, 0)

var _space_held := false

func _tick_combat(d: float) -> void:
	if _parry_cd > 0: _parry_cd -= d
	if _parry_t > 0: _parry_t -= d
	if _combo_t > 0:
		_combo_t -= d
		if _combo_t <= 0: _combo = 0
	if _combo_lock > 0:
		_combo_lock -= d
		if _combo_lock <= 0:
			_attack_slow = 1.0
			blade.modulate = Color(0.45, 0.9, 1, 0)
			if _combo_queued:
				_combo_queued = false
				_start_swing()

	# parry — buffered edge press
	if _buf_parry > 0:
		_buf_parry -= d
	var parry_now := Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_F)
	if parry_now and not _parry_held:
		_buf_parry = BUF_T
	_parry_held = parry_now
	if _buf_parry > 0 and _parry_cd <= 0 and G.state == G.State.ROOM:
		_buf_parry = 0
		_parry_t = parry_window + Boons.parry_bonus() + st_parry
		_parry_cd = parry_cd
		G.audio.play("parry", 1.1, 0.7)
		G.fx.burst(pos + Vector2(0, -10) + aim_dir * 16.0, Px.C("00E5FF"), 6, 90.0, 3.0, 0.2)

	# melee — buffered edge-detect LMB
	if _buf_lmb > 0:
		_buf_lmb -= d
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if lmb and not _lmb_held and G.state == G.State.ROOM:
		_buf_lmb = BUF_T
	_lmb_held = lmb
	if _buf_lmb > 0:
		if _combo_lock > 0:
			if not _combo_queued:
				_combo_queued = true
				_buf_lmb = 0
		else:
			_buf_lmb = 0
			_start_swing()

var _parry_held := false
var _lmb_held := false

func _apply_stance() -> void:
	st_arc = 1.0; st_dmg = 1.0; st_spd = 1.0; st_parry = 0.0; st_reach = 0.0
	match str(G.meta.data.get("stance", "")):
		"cleave":
			st_arc = 1.45; st_dmg = 0.92; st_spd = 0.92; st_reach = 12.0
		"duelist":
			st_arc = 0.72; st_dmg = 1.16; st_spd = 1.14; st_parry = 0.05

func _start_swing() -> void:
	var stage := _combo % 3
	_combo += 1
	_combo_t = 0.75
	var dur := (0.34 if stage == 2 else 0.22) / (atk_speed * st_spd)
	_combo_lock = dur
	_attack_slow = 0.35
	_anim = ""  # force re-enter so each swing restarts its 2-frame pose
	_set_anim("atk%d" % (stage + 1), 2.0 / maxf(dur, 0.05))
	_swing(stage, dur)

func _swing(stage: int, dur: float) -> void:
	var ang := aim_dir.angle()
	var reach := (80.0 if stage == 2 else 68.0) + st_reach
	var arc := deg_to_rad(150.0 if stage == 2 else 115.0) * st_arc
	blade.modulate = Color(0.45, 0.9, 1, 0.22)  # subtle — painted frames carry the swing
	ext_vel += aim_dir * (190.0 if stage == 2 else 110.0)  # attack lunge
	_swing_hit_done = false
	var tw := create_tween()
	# sweep the blade visual across the arc over the swing duration
	var start_rot := ang - arc / 2.0 - PI / 2.0
	blade.rotation = start_rot
	tw.tween_property(blade, "rotation", start_rot + arc, dur)
	G.fx.slash_fx(pos, ang, reach, Px.C("7fd4ff"), stage == 2)
	G.audio.play("slash", G.rf(0.9, 1.2), 0.7)
	# hit test lands partway through the swing
	get_tree().create_timer(dur * 0.28).timeout.connect(func():
		if dead or _swing_hit_done:
			return
		_swing_hit_done = true
		var dmg := melee_dmg * dmg_mult * st_dmg * (1.7 if stage == 2 else 1.0)
		hit_arc(dmg, ang, reach, arc, stage == 2)
		G.audio.play("hitHeavy" if stage == 2 else "hit", G.rf(0.9, 1.15), 0.85)
	)
	tw.tween_callback(func(): blade.modulate = Color(0.45, 0.9, 1, 0))

func hit_arc(dmg: float, ang: float, reach: float, arc: float, heavy: bool) -> void:
	var hits := 0
	for e in G.enemies.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		var dd: Vector2 = e.pos - pos
		if dd.length() > reach + e.hit_radius:
			continue
		var diff := absf(angle_difference(ang, dd.angle()))
		if diff > arc / 2.0 + 0.3:
			continue
		var crit := G.chance(crit_ch)
		var h := {
			"dmg": dmg * (crit_mult if crit else 1.0),
			"type": G.DamageType.MELEE, "from": pos,
			"knock": 7.0 if heavy else 3.5,
			"stagger": 0.5 if heavy else 0.18,
			"source": self, "crit": crit,
			"shred": has_meta("shred")
		}
		e.take_hit(h)
		on_dealt_damage(e, h)
		hits += 1
	if heavy and has_meta("shockslam"):
		# Rhasa shockwave: AoE stagger around the heavy hit
		G.fx.burst(pos + aim_dir * 40.0, Px.C("a8842f"), 16, 220.0, 5.0, 0.4)
		for e in G.enemies.duplicate():
			if not is_instance_valid(e) or e.dead:
				continue
			if pos.distance_to(e.pos) < 120.0:
				e.take_hit({"dmg": 10.0 * dmg_mult, "type": G.DamageType.SHOCK, "from": pos, "knock": 5.0, "stagger": 0.5, "source": self})
	if hits > 0 and heavy:
		G.fx.hitstop(0.08)
		G.fx.shake(0.14, 0.15)
	elif hits > 0:
		G.fx.hitstop(0.04)  # micro freeze on every connect — sells impact
		G.fx.shake(0.05, 0.08)

func on_dealt_damage(target: Actor, h: Dictionary) -> void:
	if lifesteal > 0:
		heal(h.get("dmg", 0.0) * lifesteal)
	if b_gravity_well and G.chance(0.25):
		_gravity_well(target.pos)
	if b_poison and G.chance(0.5):
		target.poison_t = 2.5
		target.poison_dps = h.get("dmg", 0.0) * 0.25
	if b_emp and G.chance(0.2):
		_emp_chain(target)
	if target.dead and heal_on_kill > 0:
		heal(heal_on_kill)

func _gravity_well(c: Vector2) -> void:
	G.fx.burst(c + Vector2(0, -8), Px.C("7B1FA2"), 14, 130.0, 4.5, 0.5)
	for e in G.enemies:
		if e.dead:
			continue
		var d: Vector2 = c - e.pos
		if d.length() < 150.0:
			e.ext_vel += d.normalized() * 280.0

func _emp_chain(first: Actor) -> void:
	G.audio.play("parryOk", 1.4, 0.5)
	var cur: Actor = first
	var hit_set := {}
	var n := 0
	while cur != null and n < 3:
		hit_set[cur] = true
		G.fx.burst(cur.pos + Vector2(0, -14), Px.C("00E5FF"), 10, 160.0, 4.0, 0.25)
		cur.take_hit({"dmg": 8.0 * dmg_mult, "type": G.DamageType.SHOCK, "from": cur.pos, "source": self})
		var next: Actor = null
		var best := 140.0
		for e in G.enemies:
			if e.dead or hit_set.has(e):
				continue
			var d := cur.pos.distance_to(e.pos)
			if d < best:
				best = d
				next = e
		cur = next
		n += 1

func _tick_plasma(d: float) -> void:
	var rmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if rmb and _plasma_charge < 0 and G.state == G.State.ROOM and _combo_lock <= 0:
		_plasma_charge = 0.0
		G.audio.play("plasmaCharge", 1.0, 0.5)
	if _plasma_charge >= 0:
		_plasma_charge += d / (0.85 / charge_rate)
		_attack_slow = 0.5
		if _plasma_charge >= 1.0 and not _charge_full:
			_charge_full = true
			G.audio.play("chargeFull", 1.0, 0.5)
			G.fx.burst(pos + Vector2(0, -14), Px.C("00E5FF"), 8, 90.0, 3.5, 0.3)
		if G.chance(d * 20):
			G.fx.burst(pos + Vector2(0, -12) + aim_dir * 12.0, Px.C("00E5FF"), 1, 30.0, 3.0, 0.25)
		if not rmb:
			var ch := clampf(_plasma_charge, 0.0, 1.0)
			_plasma_charge = -1.0
			_charge_full = false
			_attack_slow = 1.0
			_fire_plasma(ch)

func _fire_plasma(ch: float) -> void:
	var p := Projectile.new()
	G.game.world.add_child(p)
	var size := plasma_size * lerpf(0.6, 1.5, ch)
	p.setup(G.Team.PLAYER, pos + aim_dir * 22.0, aim_dir * lerpf(320.0, 420.0, ch),
		plasma_dmg * plasma_mult * dmg_mult * lerpf(0.5, 1.6, ch),
		10.0 * size, Px.C("00E5FF"), "dot")
	p.homing = b_homing
	p.knock = 4.0
	p.stag = 0.3
	G.audio.play("plasma", G.rf(0.9, 1.1))
	G.fx.directional(pos + Vector2(0, -12), aim_dir, Px.C("00E5FF"), 8, 190.0, 4.0, 0.3)
	G.fx.light_flash(pos + Vector2(0, -12) + aim_dir * 20.0, Px.C("00E5FF"), 1.6, 2.2, 0.18)
	ext_vel -= aim_dir * 60.0

func take_hit(h: Dictionary) -> void:
	if dead or invuln > 0:
		return
	var src = h.get("source")
	if parry_active() and src is Actor and h.get("type") != G.DamageType.HAZARD:
		# successful parry
		G.audio.play("parryOk")
		G.fx.burst(pos + Vector2(0, -12), Px.C("00E5FF"), 18, 190.0, 4.5, 0.35)
		G.fx.hitstop(0.09)
		G.fx.shake(0.12, 0.15)
		G.fx.float_text(pos + Vector2(0, -36), "PARRY!", Px.C("00E5FF"), 1.1)
		src.stagger = maxf(src.stagger, 1.3)
		invuln = maxf(invuln, 0.35)
		if b_parry_shock:
			for e in G.enemies.duplicate():
				if e.dead:
					continue
				if pos.distance_to(e.pos) < 105.0:
					e.take_hit({"dmg": 20.0 * dmg_mult, "type": G.DamageType.SHOCK, "from": pos, "knock": 6.0, "stagger": 0.8, "source": self})
			G.fx.burst(pos + Vector2(0, -8), Px.C("7B1FA2"), 24, 250.0, 5.5, 0.4)
		return
	var dmg := maxf(1.0, (h.get("dmg", 1.0) - armor) * dmg_taken_mult)
	hp -= dmg
	set_flash()
	_anim = ""
	_set_anim("hurt", 6.0)
	_hurt_anim_t = 0.14
	var from: Vector2 = h.get("from", pos)
	ext_vel += (pos - from).normalized() * h.get("knock", 0.0) * 20.0
	G.audio.play("hurt", G.rf(0.9, 1.1))
	G.fx.burst(pos + Vector2(0, -12), Color(0.8, 0.1, 0.15), 10, 160.0, 4.0, 0.4, 5.0)
	G.fx.shake(0.16, 0.2)
	G.fx.float_text(pos + Vector2(0, -32), str(roundi(dmg)), Color(1, 0.35, 0.3), 1.0)
	G.ui.hurt_flash()
	invuln = maxf(invuln, 0.55)
	if hp <= 0:
		if G.meta.upg(Meta.U.REVIVE) > 0 and not revived:
			revived = true
			hp = max_hp * 0.4
			invuln = 2.0
			G.fx.burst(pos + Vector2(0, -12), Px.C("7B1FA2"), 40, 280.0, 6.0, 0.8)
			G.fx.flash(Px.C("7B1FA2"), 0.5)
			G.audio.play("roar", 1.3, 0.6)
			G.fx.float_text(pos + Vector2(0, -42), "NEVA'NIN BAĞI!", Px.C("c26bff"), 1.3)
			return
		die(h)

func heal(v: float) -> void:
	if dead:
		return
	var real := minf(v, max_hp - hp)
	if real <= 0.5:
		return
	hp += real
	G.fx.float_text(pos + Vector2(0, -34), "+" + str(roundi(real)), Px.C("00E676"), 0.9)

func reset_for_run() -> void:
	# wipe run-scoped boons/metas, re-apply meta upgrades, full heal
	melee_dmg = 14.0; plasma_dmg = 26.0; dmg_mult = 1.0; plasma_mult = 1.0
	atk_speed = 1.0; crit_ch = 0.05; crit_mult = 2.0; dmg_taken_mult = 1.0
	lifesteal = 0.0; heal_on_kill = 0.0; dash_regen_mult = 1.0
	b_gravity_well = false; b_homing = false; b_poison = false
	b_emp = false; b_parry_shock = false; b_stealth_dash = false
	stealth_t = 0.0; revived = false
	charge_rate = 1.0; _charge_full = false
	_apply_stance()
	for k in ["shred", "shockslam", "aegis", "regen", "static", "killer"]:
		remove_meta(k)
	max_hp = 100 + G.meta.upg(Meta.U.HP) * 20
	hp = max_hp
	armor = G.meta.upg(Meta.U.SHIELD) * 1.0
	dmg_mult += G.meta.upg(Meta.U.DMG) * 0.08
	dash_max = 1 + G.meta.upg(Meta.U.DASH)
	dash_charges = dash_max
	_combo = 0; _combo_t = 0.0; _combo_lock = 0.0; _plasma_charge = -1.0

func die(h: Dictionary) -> void:
	if dead:
		return
	var src = h.get("source")
	set_meta("killer", src.actor_name if src is Actor else "kovan")
	super.die(h)
	G.fx.burst(pos + Vector2(0, -12), Color(0.7, 0.05, 0.1), 40, 250.0, 5.5, 0.9, 6.0)
	G.fx.flash(Color(0.6, 0, 0), 0.6)
	G.audio.play("die", 0.8)
	if is_instance_valid(body):
		if _frames.has("die") and _frames["die"].size() > 0:
			body.texture = _frames["die"][mini(1, _frames["die"].size() - 1)]
		var tw := create_tween()
		tw.tween_property(body, "modulate:a", 0.0, 1.4)
	if is_instance_valid(blade):
		blade.visible = false
	if is_instance_valid(_aura):
		_aura.queue_free()
	G.run.on_player_death(h)
