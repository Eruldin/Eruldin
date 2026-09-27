class_name Boss
extends Enemy

# Boss controller — own phase/attack state machine on top of Actor.
# Bosses are spawned by Room; linked twins share a `link` reference.

enum BKind { REX, HOST, NAHUM, TUMAN, KIRIN, CONST, ANASI, DEV, KOR, DAMAR, BUZ }

var bkind: int = BKind.REX
var link: Boss = null
var phase := 1
var _atk_t := 1.6          # next attack countdown
var _busy := false         # an attack coroutine is running
var _intro_t := 0.0
var title := ""
var bark := ""
var shielded := false
var _shield_t := 0.0

const NAMES := {
	BKind.REX: "REX — AVCI FORMU", BKind.HOST: "PROTERIAN KONAKÇI",
	BKind.NAHUM: "NAHUM", BKind.TUMAN: "TUMAN",
	BKind.KIRIN: "MEDIKAE KIRIN", BKind.CONST: "ŞANSİYE CONSTANTIN",
	BKind.ANASI: "KUM ANASI", BKind.DEV: "BATAKLIK DEVİ",
	BKind.KOR: "KOR YÜCELTEN", BKind.DAMAR: "DAMAR KALBI",
	BKind.BUZ: "BUZ ANASI"
}
const TITLES := {
	BKind.REX: "Alfa-05 · Düşmüş Kardeş", BKind.HOST: "Sektör 4-Gama'nın Kabusu",
	BKind.NAHUM: "Zihin Kontrollü Şövalye", BKind.TUMAN: "Zihin Kontrollü Şövalye",
	BKind.KIRIN: "Baş Cerrah", BKind.CONST: "Aeterna'nın Efendisi",
	BKind.ANASI: "Kızıl Çöl'ün Kraliçesi", BKind.DEV: "Çürük Bataklık'ın Kalbi",
	BKind.KOR: "Kül Ovası'nın Son Efendisi", BKind.DAMAR: "Kristal Çukur'un Nabzı",
	BKind.BUZ: "Donmuş Çatlak'ın Hanımı"
}
const BARKS := {
	BKind.REX: "Alfa-04... transistörün sustu mu? Benimki hâlâ ŞARKI SÖYLÜYOR.",
	BKind.HOST: "Et... hatırlıyor. Kovan seni de çağırıyor.",
	BKind.NAHUM: "Ely... kaç. Bu eller artık benim değil.",
	BKind.TUMAN: "Protokol mutlak. Direniş... sadece gecikme.",
	BKind.KIRIN: "Ah, Alfa-04. Masada daha zarif görünüyordun.",
	BKind.CONST: "İmparatorluk içeriden çürür, şövalye. Sen de öyle yaptın.",
	BKind.ANASI: "Kum yutmuş bir şövalye... yavrum sana bayılacak.",
	BKind.DEV: "Bataklık kimseyi geri vermez. Sen de kalacaksın.",
	BKind.KOR: "İmparatorluk yandı — ben külünden doğdum. Sen de ona katılacaksın.",
	BKind.DAMAR: "Damara dokundun, şövalye. Şimdi damar sana dokunacak.",
	BKind.BUZ: "Buz beni getirene dek bekledi. Seni de bekleyecek."
}
const SPR := {
	BKind.REX: "rex", BKind.HOST: "host", BKind.NAHUM: "nahum",
	BKind.TUMAN: "tuman", BKind.KIRIN: "kirin", BKind.CONST: "const",
	BKind.ANASI: "anasi", BKind.DEV: "dev", BKind.KOR: "kor",
	BKind.DAMAR: "damar", BKind.BUZ: "buz"
}
const PHASE_BARKS := {
	BKind.REX: "REX: ŞARKI YÜKSELİYOR — DAHA HIZLI.",
	BKind.HOST: "KONAKÇI: kovan açılıyor...",
	BKind.NAHUM: "NAHUM: kontrol zayıflıyor — BİTİR.",
	BKind.TUMAN: "TUMAN: protokol kırılıyor.",
	BKind.KIRIN: "KIRIN: ameliyat ikinci evreye geçiyor.",
	BKind.CONST: "CONSTANTIN: kalkan dengesiz.",
	BKind.ANASI: "KUM ANASI: kum ayağa kalkıyor.",
	BKind.DEV: "DEV: çamur ayağa kalkıyor — bataklık aç.",
	BKind.KOR: "KOR: ova ikinci kez yanıyor — bu kez seninle.",
	BKind.DAMAR: "DAMAR: nabız hızlanıyor — çukur seninle birlikte atıyor.",
	BKind.BUZ: "BUZ ANASI: çatlak kapanıyor — don.",
}
# faz-2'de portreli hikaye kartı — boss'un yıkımı içeriden görünür
const P2_LINES := {
	BKind.REX: "Şarkı sustuğunda... beni hatırla, Alfa-04.",
	BKind.HOST: "Kovan içimde açılıyor — ya kaç ya katıl.",
	BKind.NAHUM: "Bu eller benim değil. Protokolü kır — beni affet.",
	BKind.TUMAN: "Protokol §7: efendi düşerse köle yanar. İkimize de izin yok.",
	BKind.KIRIN: "Masaya dön, Alfa. Sadece senin parçalarını alacağım.",
	BKind.CONST: "Aeterna'yı izledin mi? Krallıklar işte böyle düşer.",
	BKind.ANASI: "Yavrularım... ziyafet zamanı. Ananız açlıktan ölüyor.",
	BKind.DEV: "Bin yıldır buradaydım — sen bir gün bile dayanamazsın.",
	BKind.KOR: "Kül unutmaz, şövalye. Beni ancak kül anlar.",
	BKind.DAMAR: "Bütün kuyu tek kalp — ve kalp şimdi öfkeyle atıyor.",
	BKind.BUZ: "Çatlak şimdi kapanıyor — altında ikimiz de kalacağız.",
}

# ölüm anı kartı: ikiz boss'larda ancak ikincisi düşünce çalınır
const DEATH_LINES := {
	BKind.REX:   "Avcı formu çözüldü... Neva'ya söyle, sinyal hâlâ temiz.",
	BKind.HOST:  "Konakçı boşaldı. Damarların şarkısı sustu.",
	BKind.NAHUM: "İkizin biri sustu. Tuman da duydu — defter kapanıyor.",
	BKind.TUMAN: "İkizin biri sustu. Nahum da duydu — defter kapanıyor.",
	BKind.KIRIN: "Kirin'in tahtı çatladı. Masa son sahibini bekliyor.",
	BKind.CONST: "Constantin düştü — protokolün son çanı sustu.",
	BKind.ANASI: "Kum Anası kırıldı. Kızıl Çöl'ün kumu ilk kez sessiz.",
	BKind.DEV: "Dev çöktü — bataklık ilk kez birini geri verdi.",
	BKind.KOR: "Taç düştü, kül dağıldı. Ova yüz yıl sonra ilk kez soğudu.",
	BKind.DAMAR: "Kalp sustu. Çukurun damarları yüz yıllığına karardı.",
	BKind.BUZ: "Hanım eridi — çatlağın altında ilk kez sessizlik var.",
}

static func spawn_boss(p_kind: int, p_pos: Vector2, parent: Node, hp_scale := 1.0) -> Boss:
	var b := Boss.new()
	b.bkind = p_kind
	b.team = G.Team.ENEMY
	parent.add_child(b)
	b.global_position = p_pos
	b._boss_stats(hp_scale)
	b.init()
	G.enemies.append(b)
	return b

func _boss_stats(hs: float) -> void:
	kind = EKind.HUSK # placeholder for shared fields; boss uses own logic
	match bkind:
		BKind.REX:
			max_hp = 420; speed = 120; touch_dmg = 16; radius = 20; hit_radius = 26
			windup_t = 0.6; recover_t = 0.7; attack_cd = 1.5
			knock_resist = 30
		BKind.HOST:
			max_hp = 520; speed = 85; touch_dmg = 14; radius = 24; hit_radius = 30
			windup_t = 0.7; recover_t = 0.8; attack_cd = 1.8
			knock_resist = 50
		BKind.NAHUM:
			max_hp = 300; speed = 175; touch_dmg = 15; radius = 15; hit_radius = 19
			windup_t = 0.4; recover_t = 0.5; attack_cd = 1.2
			knock_resist = 8
		BKind.TUMAN:
			max_hp = 260; speed = 95; touch_dmg = 8; radius = 14; hit_radius = 18
			windup_t = 0.5; recover_t = 0.6; attack_cd = 1.6
			knock_resist = 8
		BKind.KIRIN:
			max_hp = 380; speed = 110; touch_dmg = 12; radius = 14; hit_radius = 18
			windup_t = 0.55; recover_t = 0.6; attack_cd = 1.4
			knock_resist = 12
		BKind.CONST:
			max_hp = 340; speed = 80; touch_dmg = 10; radius = 15; hit_radius = 19
			windup_t = 0.6; recover_t = 0.7; attack_cd = 1.7
			knock_resist = 20
			shielded = true
			_shield_t = 14.0
		BKind.ANASI:
			max_hp = 560; speed = 100; touch_dmg = 18; radius = 22; hit_radius = 28
			windup_t = 0.55; recover_t = 0.6; attack_cd = 1.5
			knock_resist = 40
			kind = EKind.AKREP
		BKind.DEV:
			max_hp = 600; speed = 78; touch_dmg = 20; radius = 24; hit_radius = 30
			windup_t = 0.7; recover_t = 0.8; attack_cd = 1.7
			knock_resist = 60
			kind = EKind.KONAKCI
		BKind.KOR:
			max_hp = 480; speed = 88; touch_dmg = 14; radius = 18; hit_radius = 24
			windup_t = 0.6; recover_t = 0.65; attack_cd = 1.4
			knock_resist = 30
			kind = EKind.SENTINEL
		BKind.DAMAR:
			max_hp = 640; speed = 62; touch_dmg = 18; radius = 24; hit_radius = 30
			windup_t = 0.7; recover_t = 0.8; attack_cd = 1.6
			knock_resist = 55
			kind = EKind.DAMARGOL
		BKind.BUZ:
			max_hp = 620; speed = 76; touch_dmg = 19; radius = 23; hit_radius = 29
			windup_t = 0.6; recover_t = 0.7; attack_cd = 1.5
			knock_resist = 50
			kind = EKind.BUZRUH
	max_hp *= hs
	hp = max_hp
	actor_name = NAMES[bkind]
	title = TITLES[bkind]
	bark = BARKS[bkind]
	_intro_t = 1.4

# Enemy.init() calls our overridden _make_body() — boss frames + menace light
func _make_body() -> void:
	body = Sprite2D.new()
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(body)
	_load_frames(SPR[bkind], 4.0)
	Px.fit(body, 118.0 if bkind == BKind.DAMAR else (112.0 if bkind == BKind.DEV or bkind == BKind.BUZ else (108.0 if bkind == BKind.REX or bkind == BKind.HOST or bkind == BKind.ANASI else 94.0)))
	var lc := Px.C("ff2222") if bkind == BKind.REX else (Px.C("00E676") if bkind == BKind.HOST or bkind == BKind.TUMAN else (Px.C("e8a050") if bkind == BKind.ANASI else (Px.C("4ad06a") if bkind == BKind.DEV else (Px.C("ff7722") if bkind == BKind.KOR else (Px.C("4dd0e1") if bkind == BKind.DAMAR else (Px.C("9fd8ff") if bkind == BKind.BUZ else Px.C("c9a227")))))))
	_light = G.fx.mk_light(self, Vector2(0, -30), lc, 0.5, 2.0)
	G.fx.burst(pos + Vector2(0, -10), Px.C("8B0000"), 24, 160.0, 5.0, 0.7)

var _light: PointLight2D

func _abort() -> bool:
	if dead or stagger > 0:
		_busy = false
		return true
	return false

func _process(_d: float) -> void:
	if dead:
		return
	var d := get_process_delta_time()
	tick(d)
	if G.state != G.State.ROOM or G.player == null or G.player.dead:
		return
	if _intro_t > 0:
		_intro_t -= d
		return
	if stagger > 0:
		_busy = false
		return

	# enrage when linked twin dies
	var rage := is_instance_valid(link) and link.dead
	var spd_mult := 1.4 if rage else 1.0

	# phase 2 check
	if phase == 1 and hp < max_hp * 0.5:
		phase = 2
		_on_phase2()

	# animation state: attacking pose vs idle sway
	if _frames.has("p2") and phase == 2 and not _busy:
		_set_anim("p2", 4.0)
	elif _busy:
		_set_anim("atk", 6.0)
	elif phase == 1 or not _frames.has("p2"):
		_set_anim("idle", 4.0)
	_tick_anim(d)

	# Constantin shield cycle
	if bkind == BKind.CONST:
		_shield_t -= d
		if _shield_t <= 0:
			shielded = not shielded
			_shield_t = 10.0 if shielded else 7.0
			if is_instance_valid(body):
				body.modulate = Color(0.5, 0.45, 0.8, 0.9) if shielded else base_color
			G.fx.burst(pos + Vector2(0, -16), Px.C("c9a227"), 16, 160.0, 4.0, 0.5)
			G.audio.play("boon", 0.7, 0.5)
		invuln = 1.0 if shielded else 0.0  # refresh invuln while shielded

	# simple positioning
	var to_p: Vector2 = G.player.pos - pos
	var dist := to_p.length()
	if not _busy:
		var want_range := _want_range()
		var dir := to_p.normalized()
		if dist > want_range + 30:
			pos += dir * speed * spd_mult * d
		elif dist < want_range - 40:
			pos -= dir * speed * 0.7 * d
		if is_instance_valid(G.room):
			pos = G.room.clamp_pos(pos, radius)
		_face_p()

	_atk_t -= d * spd_mult
	if _atk_t <= 0 and not _busy:
		_pick_attack()

func _want_range() -> float:
	match bkind:
		BKind.REX: return 60.0
		BKind.HOST: return 90.0
		BKind.NAHUM: return 55.0
		BKind.TUMAN: return 220.0
		BKind.KIRIN: return 180.0
		BKind.CONST: return 240.0
		BKind.ANASI: return 72.0
		BKind.DEV: return 78.0
		BKind.KOR: return 200.0
		BKind.DAMAR: return 150.0
	return 100.0

func _pick_attack() -> void:
	_busy = true
	match bkind:
		BKind.REX: _rex_attack()
		BKind.HOST: _host_attack()
		BKind.NAHUM: _nahum_attack()
		BKind.TUMAN: _tuman_attack()
		BKind.KIRIN: _kirin_attack()
		BKind.CONST: _const_attack()
		BKind.ANASI: _anasi_attack()
		BKind.DEV: _dev_attack()
		BKind.KOR: _kor_attack()
		BKind.DAMAR: _damar_attack()
		BKind.BUZ: _buz_attack()

func _on_phase2() -> void:
	G.audio.play("roar", 1.0, 0.8)
	G.fx.shake(0.3, 0.4)
	G.fx.burst(pos + Vector2(0, -20), Px.C("ff2222"), 30, 250.0, 6.0, 0.7)
	G.fx.float_text(pos + Vector2(0, -50), "FAZ II", Px.C("ff2222"), 1.5)
	G.fx.light_flash(pos + Vector2(0, -20), Px.C("ff2222"), 1.6, 3.0, 0.5)
	if is_instance_valid(_light):
		_light.energy = 1.4
	if _frames.has("p2"):
		_anim = ""
		_set_anim("p2", 4.0)
	G.ui.toast(PHASE_BARKS.get(bkind, "FAZ II"))
	G.ui.boss_taunt(SPR.get(bkind, "rex"), NAMES.get(bkind, "?"), P2_LINES.get(bkind, "..."))

# ---------- REX ----------
func _rex_attack() -> void:
	var roll := G.rf(0, 1)
	if phase == 2 and roll < 0.25:
		_atk_t = 2.4
		_rex_ring()
	elif dist_to_player() < 130.0 or roll < 0.4:
		_atk_t = 1.7 if phase == 1 else 1.3
		_rex_slam()
	elif roll < 0.75:
		_atk_t = 2.0 if phase == 1 else 1.5
		_rex_charge()
	else:
		_atk_t = 1.8 if phase == 1 else 1.4
		_rex_fan()

func _rex_slam() -> void:
	var target := G.player.pos
	var t := G.fx.tele_circle(target, 70.0, 0.7)
	await _wait(0.7)
	G.fx.kill_tele(t)
	# leap to target
	pos = G.room.clamp_pos(target, radius)
	G.audio.play("explode", 1.2, 0.8)
	G.fx.shake(0.3, 0.3)
	G.fx.burst(pos + Vector2(0, -8), Px.C("ff5522"), 24, 220.0, 6.0, 0.5)
	if dist_to_player() < 80.0:
		G.player.take_hit({"dmg": touch_dmg * 1.3, "type": G.DamageType.EXPLOSION, "from": pos, "knock": 9.0, "source": self})
	_busy = false

func _rex_charge() -> void:
	var dir := (G.player.pos - pos).normalized()
	var ang := rad_to_deg(dir.angle())
	var t := G.fx.tele_wedge(pos, ang, 340.0, 0.6)
	await _wait(0.6)
	G.fx.kill_tele(t)
	G.audio.play("dash", 0.7)
	# dash through player position
	var dest := G.room.clamp_pos(pos + dir * 340.0, radius)
	var steps := 14
	for i in steps:
		if _abort(): return
		pos = G.room.clamp_pos(pos + dir * (340.0 / steps), radius)
		if dist_to_player() < radius + G.player.hit_radius + 6:
			G.player.take_hit({"dmg": touch_dmg, "type": G.DamageType.MELEE, "from": pos, "knock": 8.0, "source": self})
		await _wait(0.016)
	pos = dest
	_busy = false

func _rex_fan() -> void:
	await _wait(0.35)
	for i in range(-2, 3):
		var dir := (G.player.pos - pos).normalized().rotated(deg_to_rad(i * 14.0))
		_shoot_dir(dir, 240.0, 11.0, Px.C("ff2222"), 9.0)
	G.audio.play("shoot", 0.8, 0.7)
	_busy = false

func _rex_ring() -> void:
	var t := G.fx.tele_ring(pos, 60.0, 0.8)
	await _wait(0.8)
	G.fx.kill_tele(t)
	G.audio.play("explode", 0.9)
	for i in 12:
		var dir := Vector2.RIGHT.rotated(TAU * i / 12.0)
		_shoot_dir(dir, 190.0, 10.0, Px.C("ff2222"), 8.0)
	G.fx.shake(0.25, 0.3)
	_busy = false

# ---------- HOST ----------
func _host_attack() -> void:
	var roll := G.rf(0, 1)
	var adds := 0
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead and e != self and not (e is Boss):
			adds += 1
	if roll < 0.3 and adds < 3:
		_atk_t = 2.6
		_host_spawn()
	elif roll < 0.65:
		_atk_t = 2.0 if phase == 1 else 1.5
		_host_acid()
	else:
		_atk_t = 1.9
		_host_lunge()

func _host_spawn() -> void:
	G.audio.play("roar", 1.4, 0.5)
	G.fx.burst(pos + Vector2(0, -10), Px.C("00E676"), 20, 130.0, 5.0, 0.6)
	for i in 2:
		var off := Vector2(G.rf(-80, 80), G.rf(-60, 60))
		var e := Enemy.spawn(EKind.HUSK, G.room.clamp_pos(pos + off, 14.0), false, G.run.hp_scale(), G.run.dmg_scale(), self)
		e.set_meta("add", true)
	await _wait(0.5)
	_busy = false

func _host_acid() -> void:
	# lob 3 acid globs that leave damaging pools
	for i in 3:
		var target := G.player.pos + Vector2(G.rf(-90, 90), G.rf(-70, 70))
		var t := G.fx.tele_circle(target, 40.0, 0.8, Color(0.2, 0.9, 0.1, 0.3))
		await _wait(0.45)
		G.fx.kill_tele(t)
		G.room.add_hazard(target, 40.0, 8.0, 4.0, Color(0.3, 1, 0.2, 0.35))
		G.fx.burst(target, Px.C("39ff14"), 14, 130.0, 5.0, 0.5)
		G.audio.play("shoot", 0.7, 0.6)
	_busy = false

func _host_lunge() -> void:
	var dir := (G.player.pos - pos).normalized()
	var t := G.fx.tele_wedge(pos, rad_to_deg(dir.angle()), 220.0, 0.55)
	await _wait(0.55)
	G.fx.kill_tele(t)
	for i in 10:
		if _abort(): return
		pos = G.room.clamp_pos(pos + dir * 24.0, radius)
		if dist_to_player() < radius + G.player.hit_radius + 8:
			G.player.take_hit({"dmg": touch_dmg * 1.2, "type": G.DamageType.MELEE, "from": pos, "knock": 7.0, "source": self})
		await _wait(0.016)
	_busy = false

# ---------- NAHUM (melee twin) ----------
func _nahum_attack() -> void:
	_atk_t = 1.3 if phase == 1 else 0.9
	_nahum_combo()

func _nahum_combo() -> void:
	for i in (2 if phase == 1 else 3):
		if _abort(): return
		var dir := (G.player.pos - pos).normalized()
		var t := G.fx.tele_wedge(pos, rad_to_deg(dir.angle()), 90.0, 0.35)
		await _wait(0.35)
		G.fx.kill_tele(t)
		for k in 5:
			if _abort(): return
			pos = G.room.clamp_pos(pos + dir * 16.0, radius)
			if dist_to_player() < radius + G.player.hit_radius + 6:
				G.player.take_hit({"dmg": touch_dmg, "type": G.DamageType.MELEE, "from": pos, "knock": 4.0, "source": self})
				break
			await _wait(0.014)
		await _wait(0.15)
	_busy = false

# ---------- TUMAN (caster twin) ----------
func _tuman_attack() -> void:
	_atk_t = 1.9 if phase == 1 else 1.4
	var roll := G.rf(0, 1)
	if roll < 0.3 and dist_to_player() < 160.0:
		_tuman_blink()
	else:
		_tuman_orbs()

func _tuman_orbs() -> void:
	await _wait(0.4)
	for i in 3:
		var dir := (G.player.pos - pos).normalized().rotated(deg_to_rad((i - 1) * 25.0))
		var p := Projectile.new()
		G.game.world.add_child(p)
		p.setup(G.Team.ENEMY, pos + dir * 20.0, dir * 160.0, 10.0, 10.0, Px.C("00E676"), "dot")
		p.source = self
		p.life = 6.0
		p.homing_player = true
	G.audio.play("shoot", 0.7, 0.7)
	_busy = false

func _tuman_blink() -> void:
	G.fx.burst(pos, Px.C("00E676"), 16, 130.0, 4.0, 0.4)
	pos = G.room.clamp_pos(pos + Vector2(G.rf(-260, 260), G.rf(-160, 160)), radius)
	G.fx.burst(pos, Px.C("00E676"), 16, 130.0, 4.0, 0.4)
	_busy = false

# ---------- KIRIN ----------
func _kirin_attack() -> void:
	var roll := G.rf(0, 1)
	if roll < 0.3:
		_atk_t = 2.4
		_kirin_laser()
	elif roll < 0.6:
		_atk_t = 2.0
		_kirin_pools()
	elif roll < 0.8 and phase == 2:
		_atk_t = 3.0
		_kirin_clone()
	else:
		_atk_t = 1.6
		_kirin_darts()

func _kirin_pools() -> void:
	for i in 3:
		var target := G.player.pos + Vector2(G.rf(-110, 110), G.rf(-80, 80))
		var t := G.fx.tele_circle(target, 36.0, 0.7, Color(0.6, 0.1, 0.6, 0.3))
		await _wait(0.4)
		G.fx.kill_tele(t)
		G.room.add_hazard(target, 36.0, 9.0, 4.5, Color(0.55, 0.1, 0.6, 0.35))
		G.fx.burst(target, Px.C("7B1FA2"), 12, 110.0, 4.0, 0.5)
	_busy = false

func _kirin_laser() -> void:
	var dir := (G.player.pos - pos).normalized()
	var ang := rad_to_deg(dir.angle())
	var t := G.fx.tele_wedge(pos, ang, 460.0, 0.9, Color(0.1, 0.9, 0.9, 0.3))
	await _wait(0.9)
	G.fx.kill_tele(t)
	# beam sweep: check player in wedge for 0.6s
	G.audio.play("plasma", 0.6, 0.9)
	var beam_t := 0.6
	var sweep_ang := ang
	while beam_t > 0:
		if dead: return
		beam_t -= get_process_delta_time()
		var to_p := G.player.pos - pos
		if to_p.length() < 460.0:
			var diff := absf(angle_difference(deg_to_rad(sweep_ang), to_p.angle()))
			if diff < 0.18:
				G.player.take_hit({"dmg": 14.0, "type": G.DamageType.PLASMA, "from": pos, "knock": 3.0, "source": self})
		# visual
		G.fx.burst(pos + Vector2.RIGHT.rotated(deg_to_rad(sweep_ang)) * G.rf(60, 440), Px.C("00E5FF"), 1, 10.0, 5.0, 0.15)
		await _wait(0.016)
	_busy = false

func _kirin_clone() -> void:
	G.audio.play("boon", 1.5, 0.5)
	for i in 2:
		var c := Enemy.spawn(EKind.SENTINEL, G.room.clamp_pos(pos + Vector2(G.rf(-120, 120), G.rf(-80, 80)), 13.0), false, 0.4, 0.7, self)
		c.actor_name = "Kirin Klonu"
		c.set_meta("add", true)
		c.base_color = Color(0.7, 0.9, 1.0, 0.8)
	G.fx.burst(pos + Vector2(0, -16), Px.C("00E5FF"), 24, 190.0, 5.0, 0.6)
	_busy = false

func _kirin_darts() -> void:
	await _wait(0.3)
	for i in 4:
		var dir := (G.player.pos - pos).normalized().rotated(deg_to_rad(G.rf(-20, 20)))
		_shoot_dir(dir, 300.0, 8.0, Px.C("00E676"), 7.0)
		await _wait(0.08)
	_busy = false

# ---------- CONSTANTIN ----------
func _const_attack() -> void:
	var roll := G.rf(0, 1)
	if roll < 0.45:
		_atk_t = 2.6
		_const_orbital()
	elif roll < 0.75:
		_atk_t = 2.2
		_const_ring()
	else:
		_atk_t = 3.0
		_const_slowzone()

func _const_orbital() -> void:
	# 4 marked strikes on/near player
	for i in 4:
		var target := G.player.pos + Vector2(G.rf(-140, 140), G.rf(-100, 100))
		var t := G.fx.tele_circle(target, 46.0, 0.9, Color(1, 0.6, 0.05, 0.35))
		_strike_later(t, target, 46.0, 15.0)
		await _wait(0.22)
	_busy = false

func _strike_later(t: Dictionary, target: Vector2, r: float, dmg: float) -> void:
	await _wait(0.9)
	G.fx.kill_tele(t)
	if dead: return
	G.audio.play("explode", 1.3, 0.5)
	G.fx.burst(target, Px.C("c9a227"), 18, 190.0, 5.0, 0.4)
	if G.player != null and not G.player.dead and target.distance_to(G.player.pos) < r + 10:
		G.player.take_hit({"dmg": dmg, "type": G.DamageType.EXPLOSION, "from": target, "knock": 6.0, "source": self})

func _const_ring() -> void:
	await _wait(0.4)
	var n := 10 if phase == 1 else 14
	for i in n:
		var dir := Vector2.RIGHT.rotated(TAU * i / n)
		_shoot_dir(dir, 170.0, 9.0, Px.C("c9a227"), 8.0)
	G.audio.play("shoot", 0.7, 0.7)
	_busy = false

func _const_slowzone() -> void:
	var target := G.player.pos
	G.room.add_slowzone(target, 90.0, 5.0)
	G.fx.burst(target, Px.C("7B1FA2"), 16, 90.0, 5.0, 0.6)
	_busy = false

# ---------- ANASI (kum kraliçesi) ----------
func _anasi_attack() -> void:
	var roll := G.rf(0, 1)
	var adds := 0
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead and e != self and not (e is Boss):
			adds += 1
	if phase == 2 and roll < 0.22:
		_atk_t = 2.2
		_anasi_storm()
	elif roll < 0.3 and adds < 4:
		_atk_t = 2.4
		_anasi_brood()
	elif dist_to_player() < 150.0 or roll < 0.62:
		_atk_t = 1.7 if phase == 1 else 1.3
		_anasi_sting()
	else:
		_atk_t = 1.9
		_anasi_spit()

func _anasi_sting() -> void:
	var dir := (G.player.pos - pos).normalized()
	var t := G.fx.tele_wedge(pos, rad_to_deg(dir.angle()), 380.0, 0.6)
	await _wait(0.6)
	G.fx.kill_tele(t)
	G.audio.play("dash", 0.6)
	for i in 15:
		if _abort(): return
		pos = G.room.clamp_pos(pos + dir * 26.0, radius)
		G.fx.burst(pos + Vector2(0, -4), Px.C("e8a050"), 3, 90.0, 3.0, 0.3)
		if dist_to_player() < radius + G.player.hit_radius + 8:
			G.player.take_hit({"dmg": touch_dmg * 1.25, "type": G.DamageType.MELEE, "from": pos, "knock": 9.0, "source": self})
		await _wait(0.016)
	_busy = false

func _anasi_brood() -> void:
	G.audio.play("roar", 1.5, 0.55)
	G.fx.burst(pos + Vector2(0, -10), Px.C("e8a050"), 20, 130.0, 5.0, 0.6)
	for i in 2:
		var off := Vector2(G.rf(-90, 90), G.rf(-70, 70))
		var e := Enemy.spawn(EKind.AKREP, G.room.clamp_pos(pos + off, 14.0), false, G.run.hp_scale(), G.run.dmg_scale(), self)
		e.set_meta("add", true)
	await _wait(0.5)
	_busy = false

func _anasi_spit() -> void:
	for i in 3:
		var target := G.player.pos + Vector2(G.rf(-80, 80), G.rf(-60, 60))
		var t := G.fx.tele_circle(target, 44.0, 0.75, Color(0.9, 0.6, 0.2, 0.3))
		await _wait(0.4)
		G.fx.kill_tele(t)
		G.room.add_hazard(target, 44.0, 7.0, 4.0, Color(0.9, 0.6, 0.2, 0.32))
		G.fx.burst(target, Px.C("e8a050"), 12, 120.0, 5.0, 0.5)
		G.audio.play("shoot", 0.8, 0.6)
	_busy = false

func _anasi_storm() -> void:
	var t := G.fx.tele_ring(pos, 70.0, 0.85, Color(0.9, 0.6, 0.2, 0.5))
	await _wait(0.85)
	G.fx.kill_tele(t)
	G.audio.play("explode", 0.9)
	for i in 14:
		var dir := Vector2.RIGHT.rotated(TAU * i / 14.0)
		_shoot_dir(dir, 210.0, 10.0, Px.C("e8a050"), 9.0)
	G.fx.shake(0.3, 0.35)
	_busy = false

# ---------- DEV (bataklık devi) ----------
func _dev_attack() -> void:
	var roll := G.rf(0, 1)
	var adds := 0
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead and e != self and not (e is Boss):
			adds += 1
	if phase == 2 and roll < 0.2:
		_atk_t = 2.4
		_dev_quake()
	elif roll < 0.3 and adds < 4:
		_atk_t = 2.6
		_dev_spill()
	elif dist_to_player() < 170.0 or roll < 0.6:
		_atk_t = 1.9 if phase == 1 else 1.4
		_dev_slam()
	else:
		_atk_t = 2.0
		_dev_spew()

func _dev_slam() -> void:
	var target := G.player.pos
	var t := G.fx.tele_circle(target, 90.0, 0.75, Color(0.3, 0.8, 0.4, 0.3))
	await _wait(0.75)
	G.fx.kill_tele(t)
	G.audio.play("explode", 0.9, 0.9)
	G.fx.shake(0.35, 0.4)
	G.fx.burst(target, Px.C("4ad06a"), 26, 230.0, 6.0, 0.6)
	if dist_to_player() < 95.0:
		G.player.take_hit({"dmg": touch_dmg * 1.3, "type": G.DamageType.EXPLOSION, "from": pos, "knock": 11.0, "source": self})
	_busy = false

func _dev_spew() -> void:
	for i in 4:
		var target := G.player.pos + Vector2(G.rf(-100, 100), G.rf(-80, 80))
		var t := G.fx.tele_circle(target, 42.0, 0.8, Color(0.2, 0.8, 0.3, 0.3))
		await _wait(0.4)
		G.fx.kill_tele(t)
		G.room.add_hazard(target, 42.0, 8.0, 4.5, Color(0.25, 0.9, 0.3, 0.35))
		G.fx.burst(target, Px.C("39ff14"), 14, 130.0, 5.0, 0.5)
		G.audio.play("shoot", 0.6, 0.6)
	_busy = false

func _dev_spill() -> void:
	G.audio.play("roar", 1.3, 0.5)
	G.fx.burst(pos + Vector2(0, -12), Px.C("4ad06a"), 22, 140.0, 5.0, 0.6)
	for i in 2:
		var off := Vector2(G.rf(-90, 90), G.rf(-70, 70))
		var e := Enemy.spawn(EKind.KONAKCI, G.room.clamp_pos(pos + off, 14.0), false, G.run.hp_scale() * 0.6, G.run.dmg_scale(), self)
		e.set_meta("add", true)
	await _wait(0.5)
	_busy = false

func _dev_quake() -> void:
	var t := G.fx.tele_ring(pos, 90.0, 0.9, Color(0.3, 0.8, 0.4, 0.5))
	await _wait(0.9)
	G.fx.kill_tele(t)
	G.audio.play("explode", 0.7)
	G.fx.shake(0.4, 0.45)
	for i in 16:
		var dir := Vector2.RIGHT.rotated(TAU * i / 16.0)
		_shoot_dir(dir, 200.0, 11.0, Px.C("4ad06a"), 9.0)
	for i in 3:
		var hp := pos + Vector2(G.rf(-160, 160), G.rf(-160, 160))
		G.room.add_hazard(hp, 36.0, 7.0, 5.0, Color(0.25, 0.9, 0.3, 0.3))
	_busy = false

# ---------- KOR (kül efendisi — menzilli caster) ----------
func _kor_attack() -> void:
	var roll := G.rf(0, 1)
	var adds := 0
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead and e != self and not (e is Boss):
			adds += 1
	if phase == 2 and roll < 0.24:
		_atk_t = 2.3
		_kor_nova()
	elif roll < 0.3 and adds < 3:
		_atk_t = 2.5
		_kor_summon()
	elif roll < 0.68:
		_atk_t = 2.0 if phase == 1 else 1.5
		_kor_meteor()
	else:
		_atk_t = 1.7
		_kor_lance()

func _kor_meteor() -> void:
	for i in 5:
		var target := G.player.pos + Vector2(G.rf(-110, 110), G.rf(-90, 90))
		var t := G.fx.tele_circle(target, 46.0, 0.85, Color(1, 0.4, 0.1, 0.3))
		await _wait(0.42)
		G.fx.kill_tele(t)
		G.fx.burst(target, Px.C("ff7722"), 18, 180.0, 6.0, 0.55)
		G.fx.shake(0.15, 0.2)
		G.audio.play("explode", 1.3, 0.5)
		G.room.add_hazard(target, 46.0, 8.0, 3.5, Color(1, 0.45, 0.1, 0.3))
	_busy = false

func _kor_lance() -> void:
	await _wait(0.25)
	for i in 3:
		var dir := (G.player.pos - pos).normalized().rotated(deg_to_rad(i * 18.0 - 18.0))
		_shoot_dir(dir, 320.0, 10.0, Px.C("ff7722"), 8.0)
		await _wait(0.09)
	G.audio.play("shoot", 1.1, 0.7)
	_busy = false

func _kor_summon() -> void:
	G.audio.play("roar", 1.1, 0.55)
	G.fx.burst(pos + Vector2(0, -14), Px.C("ff7722"), 24, 150.0, 5.0, 0.6)
	for i in 2:
		var off := Vector2(G.rf(-100, 100), G.rf(-80, 80))
		var e := Enemy.spawn(EKind.MUHFIZ, G.room.clamp_pos(pos + off, 14.0), false, G.run.hp_scale() * 0.7, G.run.dmg_scale(), self)
		e.set_meta("add", true)
	await _wait(0.5)
	_busy = false

func _kor_nova() -> void:
	var t := G.fx.tele_ring(pos, 80.0, 0.9, Color(1, 0.45, 0.1, 0.5))
	await _wait(0.9)
	G.fx.kill_tele(t)
	G.audio.play("explode", 0.8)
	G.fx.shake(0.35, 0.4)
	for i in 18:
		var dir := Vector2.RIGHT.rotated(TAU * i / 18.0)
		_shoot_dir(dir, 230.0, 12.0, Px.C("ff7722"), 9.0)
	G.room.add_hazard(pos, 55.0, 9.0, 4.0, Color(1, 0.45, 0.1, 0.32))
	_busy = false

# ---------- DAMAR (çukurun kristal kalbi — yarı-menzilli) ----------
func _damar_attack() -> void:
	var roll := G.rf(0, 1)
	var adds := 0
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead and e != self and not (e is Boss):
			adds += 1
	if phase == 2 and roll < 0.24:
		_atk_t = 2.4
		_damar_shatter()
	elif roll < 0.3 and adds < 3:
		_atk_t = 2.6
		_damar_birth()
	elif dist_to_player() < 160.0 or roll < 0.6:
		_atk_t = 1.9 if phase == 1 else 1.4
		_damar_slam()
	else:
		_atk_t = 2.1
		_damar_erupt()

func _damar_slam() -> void:
	var dir := (G.player.pos - pos).normalized()
	var t := G.fx.tele_wedge(pos, rad_to_deg(dir.angle()), 340.0, 0.65)
	await _wait(0.65)
	G.fx.kill_tele(t)
	G.audio.play("explode", 1.1, 0.8)
	G.fx.shake(0.3, 0.4)
	for i in 14:
		if _abort(): return
		pos = G.room.clamp_pos(pos + dir * 24.0, radius)
		G.fx.burst(pos + Vector2(0, -4), Px.C("4dd0e1"), 4, 100.0, 3.5, 0.3)
		if dist_to_player() < radius + G.player.hit_radius + 8:
			G.player.take_hit({"dmg": touch_dmg * 1.25, "type": G.DamageType.MELEE, "from": pos, "knock": 12.0, "source": self})
		await _wait(0.016)
	_busy = false

func _damar_erupt() -> void:
	for i in 4:
		var target := G.player.pos + Vector2(G.rf(-120, 120), G.rf(-100, 100))
		var t := G.fx.tele_circle(target, 48.0, 0.8, Color(0.3, 0.85, 0.9, 0.3))
		await _wait(0.4)
		G.fx.kill_tele(t)
		G.fx.burst(target, Px.C("4dd0e1"), 16, 160.0, 5.5, 0.5)
		G.audio.play("shoot", 1.4, 0.55)
		G.room.add_hazard(target, 48.0, 7.5, 4.0, Color(0.3, 0.85, 0.9, 0.32))
	_busy = false

func _damar_birth() -> void:
	G.audio.play("roar", 1.2, 0.5)
	G.fx.burst(pos + Vector2(0, -14), Px.C("4dd0e1"), 26, 150.0, 5.0, 0.6)
	for i in 2:
		var off := Vector2(G.rf(-100, 100), G.rf(-80, 80))
		var e := Enemy.spawn(EKind.DAMARGOL, G.room.clamp_pos(pos + off, 14.0), false, G.run.hp_scale() * 0.7, G.run.dmg_scale(), self)
		e.set_meta("add", true)
	await _wait(0.5)
	_busy = false

func _damar_shatter() -> void:
	var t := G.fx.tele_ring(pos, 85.0, 0.9, Color(0.3, 0.85, 0.9, 0.5))
	await _wait(0.9)
	G.fx.kill_tele(t)
	G.audio.play("explode", 0.7)
	G.fx.shake(0.4, 0.45)
	for i in 16:
		var dir := Vector2.RIGHT.rotated(TAU * i / 16.0)
		_shoot_dir(dir, 220.0, 11.0, Px.C("4dd0e1"), 9.0)
	G.run.drop_fragments(pos + Vector2(G.rf(-40, 40), G.rf(-40, 40)), G.ri(4, 7))
	_busy = false

# BUZ ANASI — donmuş çatlağın hanımı: kalıcı buz serer, ruh çağırır, faz-2'de kristal sağanak
func _buz_attack() -> void:
	var roll := G.rf(0, 1)
	var adds := 0
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead and e != self and not (e is Boss):
			adds += 1
	if phase == 2 and roll < 0.26:
		_atk_t = 2.3
		_buz_shatter()
	elif roll < 0.34 and adds < 4:
		_atk_t = 2.5
		_buz_birth()
	elif dist_to_player() < 170.0 or roll < 0.62:
		_atk_t = 1.8 if phase == 1 else 1.3
		_buz_slam()
	else:
		_atk_t = 2.0
		_buz_erupt()

func _buz_slam() -> void:
	var dir := (G.player.pos - pos).normalized()
	var t := G.fx.tele_wedge(pos, rad_to_deg(dir.angle()), 340.0, 0.65)
	await _wait(0.65)
	G.fx.kill_tele(t)
	G.audio.play("explode", 1.3, 0.75)
	G.fx.shake(0.3, 0.4)
	for i in 12:
		if _abort(): return
		pos = G.room.clamp_pos(pos + dir * 26.0, radius)
		G.fx.burst(pos + Vector2(0, -4), Px.C("9fd8ff"), 4, 110.0, 3.5, 0.3)
		if dist_to_player() < radius + G.player.hit_radius + 8:
			G.player.take_hit({"dmg": touch_dmg * 1.25, "type": G.DamageType.MELEE, "from": pos, "knock": 12.0, "source": self})
		await _wait(0.016)
	_busy = false

func _buz_erupt() -> void:
	# telegraflı don patlamaları — tehlike yerine altında kaygan buz kalıyor
	for i in 4:
		var target := G.player.pos + Vector2(G.rf(-130, 130), G.rf(-110, 110))
		var t := G.fx.tele_circle(target, 52.0, 0.8, Color(0.6, 0.86, 1.0, 0.3))
		await _wait(0.4)
		G.fx.kill_tele(t)
		G.fx.burst(target, Px.C("9fd8ff"), 14, 170.0, 5.5, 0.5)
		G.audio.play("shoot", 1.5, 0.5)
		G.room.add_slowzone(target, 52.0, 7.0, Color(0.55, 0.85, 1.0, 0.3))
	_busy = false

func _buz_birth() -> void:
	G.audio.play("roar", 1.3, 0.45)
	G.fx.burst(pos + Vector2(0, -14), Px.C("9fd8ff"), 24, 150.0, 5.0, 0.6)
	for i in 2:
		var off := Vector2(G.rf(-110, 110), G.rf(-90, 90))
		var e := Enemy.spawn(EKind.BUZRUH, G.room.clamp_pos(pos + off, 14.0), false, G.run.hp_scale() * 0.7, G.run.dmg_scale(), self)
		e.set_meta("add", true)
	await _wait(0.5)
	_busy = false

func _buz_shatter() -> void:
	var t := G.fx.tele_ring(pos, 90.0, 0.9, Color(0.6, 0.86, 1.0, 0.5))
	await _wait(0.9)
	G.fx.kill_tele(t)
	G.audio.play("explode", 0.8)
	G.fx.shake(0.4, 0.45)
	for i in 18:
		var dir := Vector2.RIGHT.rotated(TAU * i / 18.0)
		_shoot_dir(dir, 230.0, 11.0, Px.C("9fd8ff"), 9.0)
	G.run.drop_fragments(pos + Vector2(G.rf(-40, 40), G.rf(-40, 40)), G.ri(4, 7))
	_busy = false

# ---------- shared ----------
func dist_to_player() -> float:
	return 9999.0 if G.player == null else pos.distance_to(G.player.pos)

func _wait(sec: float) -> void:
	if is_inside_tree():
		await get_tree().create_timer(sec).timeout

func die(h: Dictionary) -> void:
	if dead:
		return
	# boss death: bigger spectacle + report to room
	G.fx.shake(0.4, 0.5)
	G.fx.hitstop(0.12)
	G.audio.play("roar", 0.8)
	G.fx.burst(pos + Vector2(0, -16), Px.C("8B0000"), 40, 280.0, 7.0, 0.9)
	G.fx.splat(pos, Color(0.4, 0.03, 0.03), 2.2)
	# ölüm hikaye kartı — ikiz bağlıysa ancak son kalanın ölümünde
	if not (is_instance_valid(link) and not link.dead):
		G.ui.boss_taunt(SPR.get(bkind, "rex"), NAMES.get(bkind, "?"), DEATH_LINES.get(bkind, "..."))
	super.die(h)
