class_name Player
extends Actor

# Ely (Alfa-04): survivors-style — player only moves/dashes; weapons fire
# automatically on their own cooldowns. World units are pixels.

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
# Q aktif yeteneği — şasi başına farklı (NOVA/SİPER/ATILIM)
var skill_cd := 0.0
var skill_max := 9.0
var _haste_t := 0.0
var _haste_mult := 1.0
var _skill_held := false
var _iksir_held := false
var iksir_n := 0          # choralim iksiri stoğu — R ile içilir, koşular arasında kalır
var _sarap_held := false
var sarap_n := 0          # kor şarabı stoğu — T ile içilir: 25sn +%25 hasar +%8 hız
var sarap_t := 0.0        # şarap etkisi kalan süre
var _parry_t := 0.0
var _parry_cd := 0.0
var _combo := 0
var _combo_t := 0.0
var _combo_lock := 0.0
var _combo_queued := false
var _plasma_charge := -1.0   # <0 = not charging
var _attack_slow := 1.0
var revived := false
var revives_extra := 0   # lütuf kaynaklı ek dirilmeler
var boost_t := 0.0       # yükleme kalıntısı/aşırı yük: >0 iken saldırılar %35 hızlı
var _over_used := 0      # bu koşuda F aşırı yükü kaç kez basıldı (bedel artar)
var _over_held := false
var _swing_hit_done := false
var charge_rate := 1.0       # plasma charge speed (Rex overcharge boon)
var _charge_full := false

# survivors systems: auto-weapons, passives, XP/level, pickup magnet
var weapons: Array = []        # [{id, lvl, t, orbs, pools, tk, ang}]
var passives: Array = []       # [{id, lvl}]
var level := 1
var xp := 0.0
var xp_next := 8.0
var magnet_r := 95.0
var xp_mult := 1.0
var frag_mult := 1.0        # ekipman "frag" modu — parçacık toplama verimi
var cd_mult := 1.0
var area_mult := 1.0
var proj_spd := 1.0
var bonus_proj := 0            # ÇOĞALTAN pasifi: mermi/gülle silahlarına ek adet
var _pulse_t := 0.0

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
	speed = 205.0 * (1.0 + G.meta.upg(Meta.U.SPD) * 0.06)
	magnet_r = 95.0 + G.meta.upg(Meta.U.MAG) * 45.0
	xp_mult += G.meta.upg(Meta.U.XP) * 0.08
	crit_ch += G.meta.upg(Meta.U.CRIT) * 0.04
	knock_resist = 2.0
	skill_cd = 0.0
	_haste_t = 0.0
	_haste_mult = 1.0
	_apply_hero()
	super.init()
	_apply_stance()
	body = Sprite2D.new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(body)
	_load_frames(_hero_set(), 7.0)
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
	_tick_skill(d)
	_auto_aim()
	if G.state == G.State.ROOM:
		Weapons.tick(self, d)
	if boost_t > 0.0:
		boost_t -= d
	if _combo_lock > 0:
		_combo_lock -= d
		if _combo_lock <= 0:
			_attack_slow = 1.0
			blade.modulate = Color(0.45, 0.9, 1, 0)
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
	# Rex EMP boon repurposed as a periodic shock pulse
	if has_meta("pulse") and G.state == G.State.ROOM:
		_pulse_t -= d
		if _pulse_t <= 0:
			_pulse_t = float(get_meta("pulse"))
			_pulse()

var _static_t := 0.0

func _read_input() -> void:
	move_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move_dir.x += 1
	if move_dir.length_squared() > 1:
		move_dir = move_dir.normalized()
	if is_instance_valid(body) and move_dir.length_squared() > 0.01:
		body.flip_h = move_dir.x < -0.1

# weapons aim themselves at the nearest threat; the mouse only matters in camp
func _auto_aim() -> void:
	if G.state != G.State.ROOM:
		return
	var best: Enemy = null
	var bd := 460.0 * 460.0
	for e in G.enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var dd := pos.distance_squared_to(e.pos)
		if dd < bd:
			bd = dd
			best = e
	if best != null:
		aim_dir = (best.pos - pos).normalized()

func _move(d: float) -> void:
	if _dash_t > 0:
		pos += _dash_dir * 560.0 * d
		return
	var sp := speed * _attack_slow * (G.room.slow_at(pos) if is_instance_valid(G.room) else 1.0) * (1.05 if stealth_t > 0 else 1.0) * (_haste_mult if _haste_t > 0 else 1.0)
	# Seri Ritim lütfu: katliam serisi x30 üstünde hız patlaması
	if has_meta("streak_spd") and G.run != null and int(G.run.streak) >= 30:
		sp *= 1.30
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

func _tick_skill(d: float) -> void:
	if skill_cd > 0:
		skill_cd -= d
	if _haste_t > 0:
		_haste_t -= d
		if _haste_t <= 0:
			_haste_mult = 1.0
	var q_now := Input.is_key_pressed(KEY_Q)
	if q_now and not _skill_held and skill_cd <= 0 and _dash_t <= 0 and G.state == G.State.ROOM:
		_use_skill()
	_skill_held = q_now
	var r_now := Input.is_key_pressed(KEY_R)
	if r_now and not _iksir_held and iksir_n > 0 and not dead and hp < max_hp - 1.0 and G.state == G.State.ROOM:
		iksir_n -= 1
		heal(max_hp * 0.45 * (1.5 if has_meta("table") else 1.0))
		G.fx.burst(pos, Px.C("8affc9"), 14, 140.0, 3.0, 0.5)
		G.audio.play("heal", 1.2, 0.55)
		G.ui.toast("choralim iksiri — can yenilendi")
		Quests.tick("iksir")
	_iksir_held = r_now
	# F aşırı yük: koşu parçacığını yak, 8sn boyunca silahlar +%35 hızlı
	var f_now := Input.is_key_pressed(KEY_F)
	if f_now and not _over_held and boost_t <= 0 and G.state == G.State.ROOM and G.run.fragments >= _over_cost():
		G.run.fragments -= _over_cost()
		_over_used += 1
		boost_t = 8.0 + float(get_meta("over_dur", 0.0))
		G.meta.data["over_uses"] = int(G.meta.data.get("over_uses", 0)) + 1
		G.meta.save()
		G.fx.burst(pos, Px.C("ffd75f"), 18, 160.0, 3.0, 0.5)
		G.fx.float_text(pos + Vector2(0, -44), "AŞIRI YÜK", Px.C("ffd75f"), 1.0)
		G.audio.play("boon", 1.1, 0.6)
	_over_held = f_now
	var t_now := Input.is_key_pressed(KEY_T)
	if t_now and not _sarap_held and sarap_n > 0 and not dead and G.state == G.State.ROOM:
		sarap_n -= 1
		if sarap_t <= 0.0:
			dmg_mult *= 1.25
			speed *= 1.08
		sarap_t = maxf(sarap_t, 25.0 * (1.5 if has_meta("table") else 1.0))
		G.fx.burst(pos, Px.C("ff7722"), 16, 150.0, 3.5, 0.5)
		G.audio.play("boon", 0.9, 0.55)
		G.ui.toast("KOR ŞARABI — %dsn güç ve hız" % int(sarap_t))
	_sarap_held = t_now
	if sarap_t > 0.0:
		sarap_t -= d
		if sarap_t <= 0.0:
			dmg_mult /= 1.25
			speed /= 1.08
			G.ui.toast("şarap etkisi geçti")

# şasi yeteneği: ely → NOVA (AoE), elyb → SİPER (zırh fazı), via → ATILIM (dash refill + hız)
func _use_skill() -> void:
	skill_cd = skill_max
	match str(G.meta.data.get("hero", "ely")):
		"elyb":
			invuln = maxf(invuln, 1.6)
			_haste_t = 3.0
			_haste_mult = 1.15
			G.fx.flash(Px.C("9db4c8"), 0.15)
			G.fx.burst(pos + Vector2(0, -14), Px.C("9db4c8"), 20, 150.0, 4.0, 0.5)
			G.fx.float_text(pos + Vector2(0, -44), "SİPER", Px.C("9db4c8"), 1.0)
			G.audio.play("stance", 0.8)
		"via":
			dash_charges = dash_max
			_haste_t = 2.5
			_haste_mult = 1.45
			G.fx.directional(pos + Vector2(0, -8), aim_dir, Px.C("00E5FF"), 14, 220.0, 5.0, 0.4)
			G.fx.float_text(pos + Vector2(0, -44), "ATILIM", Px.C("00E5FF"), 1.0)
			G.audio.play("dash", 1.25)
		"h9":
			var got := 0
			for g2 in G.room.pickups_node.get_children():
				if str(g2.get_meta("kind", "")) == "xp":
					g2.set_meta("vac", 1)
					got += 1
			G.fx.tele_ring(pos, 340.0, 0.5, Color(1.0, 0.72, 0.2, 0.5))
			G.fx.flash(Px.C("ffb74d"), 0.12)
			for e in G.enemies.duplicate():
				if is_instance_valid(e) and not e.dead and pos.distance_to(e.pos) < 200.0:
					e.take_hit({"dmg": 20.0 * dmg_mult, "type": G.DamageType.SHOCK, "from": pos, "knock": 10.0, "source": self})
			G.fx.float_text(pos + Vector2(0, -44), "MIKNATIS", Px.C("ffb74d"), 1.0)
			G.audio.play("boon", 0.9)
			if got > 0:
				G.ui.toast("mıknatıs darbesi — %d kristal çekildi" % got)
		"k7":
			invuln = maxf(invuln, 2.4)
			G.fx.tele_ring(pos, 260.0, 0.5, Color(0.5, 0.66, 0.8, 0.5))
			G.fx.flash(Px.C("7fa8c9"), 0.18)
			G.fx.shake(0.15, 0.2)
			for e in G.enemies.duplicate():
				if is_instance_valid(e) and not e.dead and pos.distance_to(e.pos) < 260.0:
					e.take_hit({"dmg": 12.0 * dmg_mult, "type": G.DamageType.MELEE, "from": pos, "knock": 22.0, "stagger": 0.6, "source": self})
			G.fx.float_text(pos + Vector2(0, -44), "SIĞINAK", Px.C("7fa8c9"), 1.0)
			G.audio.play("parryOk", 0.8)
		"dg":
			G.fx.tele_ring(pos, 280.0, 0.5, Color(0.3, 0.85, 0.9, 0.5))
			G.fx.flash(Px.C("4dd0e1"), 0.15)
			G.fx.shake(0.35, 0.3)
			G.fx.hitstop(0.08)
			invuln = maxf(invuln, 1.0)
			for e in G.enemies.duplicate():
				if not is_instance_valid(e) or e.dead:
					continue
				if pos.distance_to(e.pos) < 280.0:
					e.take_hit({"dmg": 55.0 * dmg_mult, "type": G.DamageType.MELEE, "from": pos, "knock": 26.0, "stagger": 0.7, "source": self})
			G.fx.burst(pos + Vector2(0, -10), Px.C("4dd0e1"), 24, 200.0, 6.0, 0.5)
			G.fx.float_text(pos + Vector2(0, -44), "DAMAR NABZI", Px.C("4dd0e1"), 1.0)
			G.audio.play("explode", 0.9, 0.5)
		_:
			G.fx.tele_ring(pos, 240.0, 0.4, Color(0.76, 0.42, 1.0, 0.45))
			G.fx.flash(Px.C("c26bff"), 0.15)
			G.fx.shake(0.2, 0.2)
			G.fx.hitstop(0.06)
			for e in G.enemies.duplicate():
				if not is_instance_valid(e) or e.dead:
					continue
				if pos.distance_to(e.pos) < 240.0:
					e.take_hit({"dmg": 45.0 * dmg_mult, "type": G.DamageType.SHOCK, "from": pos, "knock": 14.0, "stagger": 0.5, "source": self})
			G.fx.float_text(pos + Vector2(0, -44), "NOVA", Px.C("c26bff"), 1.0)
			G.audio.play("explode", 0.9, 0.6)

# şasi farkları oynanışı değiştirir: elyb ağır topçu, via hızlı keskin
func _over_cost() -> int:
	return int((120 + 90 * _over_used) * (1.0 + float(get_meta("over_cost", 0.0))))

func _apply_hero() -> void:
	var hk := str(G.meta.data.get("hero", "ely"))
	actor_name = "Ely"
	match hk:
		"elyb":
			actor_name = "Ely-B"
			max_hp = maxi(40, max_hp - 20)
			hp = max_hp
			dmg_mult += 0.12
			speed *= 0.92
			skill_max = 10.0
		"via":
			actor_name = "V-Serkay"
			max_hp = maxi(40, max_hp - 12)
			hp = max_hp
			speed *= 1.08
			crit_ch += 0.08
			skill_max = 8.0
		"h9":
			actor_name = "H-9 Hurdacı"
			max_hp = maxi(40, max_hp - 8)
			hp = max_hp
			dmg_mult -= 0.06
			frag_mult += 0.15
			magnet_r += 60.0
			skill_max = 12.0
		"k7":
			actor_name = "K-7 Kalkan"
			max_hp = maxi(40, max_hp + 45)
			hp = max_hp
			armor += 1.5
			dmg_mult -= 0.12
			speed *= 0.90
			skill_max = 9.0
		"dg":
			actor_name = "G-1 Damargüç"
			max_hp = maxi(40, max_hp + 60)
			hp = max_hp
			armor += 2.0
			dmg_mult -= 0.08
			speed *= 0.86
			skill_max = 11.0
	# şasi perkleri — ELY-B panelinde choralim ile alınan kalıcı modlar
	var pk: Dictionary = Items.perk_stats(hk)
	max_hp += float(pk.get("hp", 0.0))
	armor += float(pk.get("armor", 0.0))
	dmg_mult += float(pk.get("dmg", 0.0))
	speed *= 1.0 + float(pk.get("spd", 0.0))
	crit_ch += float(pk.get("crit", 0.0))
	magnet_r += float(pk.get("mag", 0.0))
	xp_mult += float(pk.get("xp", 0.0))
	frag_mult += float(pk.get("frag", 0.0))
	skill_max = maxf(4.0, skill_max * (1.0 + float(pk.get("skill", 0.0))))
	if float(pk.get("hp", 0.0)) != 0.0:
		hp = max_hp
	hp = mini(hp, max_hp)

func _hero_set() -> String:
	return {"elyb": "c_elyb", "via": "c_viawar", "h9": "c_h9", "k7": "c_k7", "dg": "c_dg"}.get(str(G.meta.data.get("hero", "ely")), "ely")

func _hero_start() -> String:
	return {"elyb": "plasma", "via": "dagger", "h9": "mortar", "k7": "sentry", "dg": "volt"}.get(str(G.meta.data.get("hero", "ely")), "blade")

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

func hit_arc(dmg: float, ang: float, reach: float, arc: float, heavy: bool, wpn := "") -> void:
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
			"source": self, "crit": crit, "wpn": wpn,
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
	var wid := str(h.get("wpn", ""))
	if wid != "" and G.run != null:
		var k := "wdmg_" + wid
		G.run.stats[k] = float(G.run.stats.get(k, 0.0)) + float(h.get("dmg", 0.0))
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

# survivors auto-swing: called by the blade weapon with its own numbers
func auto_swing(ang: float, reach: float, arc_deg: float, dmg: float, heavy: bool, wpn := "") -> void:
	aim_dir = Vector2.from_angle(ang)
	_anim = ""
	_set_anim("atk%d" % G.ri(1, 3), 8.0)
	_combo_lock = 0.2
	_attack_slow = 0.55
	blade.modulate = Color(0.45, 0.9, 1, 0.22)
	var arc := deg_to_rad(arc_deg) * st_arc
	var tw := create_tween()
	var start_rot := ang - arc / 2.0 - PI / 2.0
	blade.rotation = start_rot
	tw.tween_property(blade, "rotation", start_rot + arc, 0.16)
	G.fx.slash_fx(pos, ang, reach, Px.C("7fd4ff"), heavy)
	G.audio.play("slash", G.rf(0.95, 1.15), 0.55)
	get_tree().create_timer(0.09, false).timeout.connect(func():
		if dead:
			return
		hit_arc(dmg, ang, reach + st_reach, arc, heavy, wpn)
		G.audio.play("hitHeavy" if heavy else "hit", G.rf(0.9, 1.15), 0.6))
	tw.tween_callback(func(): blade.modulate = Color(0.45, 0.9, 1, 0))

static func xp_for(lvl: int) -> float:
	return 6.0 + float(lvl - 1) * 5.0 + pow(maxi(0, lvl - 1), 1.7) * 1.2

func add_xp(v: float) -> void:
	if dead:
		return
	xp += v * xp_mult
	while xp >= xp_next:
		xp -= xp_next
		level += 1
		xp_next = xp_for(level)
		G.run.pending_drafts += 1
		G.fx.burst(pos + Vector2(0, -22), Px.C("00E5FF"), 14, 140.0, 4.0, 0.5)
		G.fx.light_flash(pos + Vector2(0, -22), Px.C("7fd4ff"), 1.5, 2.6, 0.28)
		G.audio.play("boon", 1.4, 0.5)

func _pulse() -> void:
	G.fx.burst(pos + Vector2(0, -8), Px.C("7B1FA2"), 18, 240.0, 5.0, 0.4)
	G.audio.play("parryOk", 1.3, 0.4)
	for e in G.enemies.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		if pos.distance_to(e.pos) < 108.0:
			e.take_hit({"dmg": 18.0 * dmg_mult, "type": G.DamageType.SHOCK, "from": pos, "knock": 6.0, "stagger": 0.6, "source": self})

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
	G.run.stats["_nodmg"] = 0.0   # hasarsiz seri kirildi
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
	G.ui.hurt_dir(from)
	invuln = maxf(invuln, 0.55)
	if hp <= 0:
		var rev_meta := G.meta.upg(Meta.U.REVIVE) > 0 and not revived
		if rev_meta or revives_extra > 0:
			if rev_meta:
				revived = true
			else:
				revives_extra -= 1
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
	stealth_t = 0.0; revived = false; revives_extra = 0; boost_t = 0.0; _over_used = 0; _over_held = false
	charge_rate = 1.0; _charge_full = false
	# survivors reset: starter blade, empty passives, level 1
	for w in weapons:
		for o in w.get("orbs", []):
			if is_instance_valid(o):
				o.queue_free()
		for pl in w.get("pools", []):
			if is_instance_valid(pl.get("node")):
				pl.node.queue_free()
	var start_id := _hero_start()
	weapons = [{"id": start_id, "lvl": 1, "t": 0.35, "orbs": [], "pools": [], "tk": 0.0, "ang": 0.0}]
	passives = []
	level = 1
	xp = 0.0
	xp_next = xp_for(1)
	magnet_r = 95.0; xp_mult = 1.0; cd_mult = 1.0; area_mult = 1.0; proj_spd = 1.0; bonus_proj = 0
	frag_mult = 1.0
	_attack_slow = 1.0; _pulse_t = 0.0
	_apply_stance()
	for k in ["shred", "shockslam", "aegis", "regen", "static", "pulse", "killer", "streak_spd", "elite_heal", "heal_luck", "drones", "harvest"]:
		remove_meta(k)
	max_hp = 100 + G.meta.upg(Meta.U.HP) * 20
	armor = G.meta.upg(Meta.U.SHIELD) * 1.0
	dmg_mult += G.meta.upg(Meta.U.DMG) * 0.08
	# altın nüveler: kalıcı koşu-başı hasar artışı (VS golden egg)
	dmg_mult += float(G.meta.data.get("eggs", 0)) * 0.005
	# efendi koleksiyonu: düşürülen her farklı efendi kalıcı +%1 hasar (meta grind)
	dmg_mult += float((G.meta.data.get("bosses", []) as Array).size()) * 0.01
	dash_max = 1 + G.meta.upg(Meta.U.DASH)
	speed = 205.0 * (1.0 + G.meta.upg(Meta.U.SPD) * 0.06)
	magnet_r = 95.0 + G.meta.upg(Meta.U.MAG) * 45.0
	xp_mult += G.meta.upg(Meta.U.XP) * 0.08
	crit_ch += G.meta.upg(Meta.U.CRIT) * 0.04
	# ekipman modları — 7 slot HoT zırh/tılsım sistemi (items.gd)
	var eq: Dictionary = Items.equip_stats()
	max_hp += float(eq.get("hp", 0.0))
	armor += float(eq.get("armor", 0.0))
	dmg_mult += float(eq.get("dmg", 0.0))
	speed *= 1.0 + float(eq.get("spd", 0.0))
	crit_ch += float(eq.get("crit", 0.0))
	crit_mult += float(eq.get("critmult", 0.0))
	lifesteal += float(eq.get("ls", 0.0))
	magnet_r += float(eq.get("mag", 0.0))
	xp_mult += float(eq.get("xp", 0.0))
	frag_mult += float(eq.get("frag", 0.0))
	dash_regen_mult += float(eq.get("dash_regen", 0.0))
	revives_extra += int(eq.get("revive", 0))
	hp = max_hp
	dash_charges = dash_max
	_apply_hero()
	skill_max = maxf(4.0, skill_max * (1.0 + float(eq.get("skill", 0.0))))
	_load_frames(_hero_set(), 7.0)
	Px.fit(body, 94.0)
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
