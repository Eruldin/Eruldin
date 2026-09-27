class_name Director
extends Node

# Time-scripted swarm director for the arena (Vampire Survivors style):
# minutes drive enemy composition, density and stat scaling; elites drop
# evolution chests; miniboss at 5:30, final boss at 11:00 — kill it to win,
# or outlast the collapse timer at 13:00.

const MINI_T := 330.0     # 5:30
const FINAL_T := 660.0    # 11:00
const WIN_T := 780.0      # 13:00 failsafe — swarm collapses

# per-sector bosses: miniboss is the previous sector's efendi (biome 0 keeps
# the Host); the final is that sector's own boss — twins/Aeterna spawn as pairs
const MINI_KIND := [Boss.BKind.HOST, Boss.BKind.REX, Boss.BKind.HOST, Boss.BKind.NAHUM, Boss.BKind.TUMAN, Boss.BKind.TUMAN, Boss.BKind.KIRIN, Boss.BKind.KOR, Boss.BKind.DAMAR]
const FINAL_KIND := [
	[Boss.BKind.REX],
	[Boss.BKind.HOST],
	[Boss.BKind.NAHUM, Boss.BKind.TUMAN],
	[Boss.BKind.KIRIN, Boss.BKind.CONST],
	[Boss.BKind.DEV],
	[Boss.BKind.KOR],
	[Boss.BKind.ANASI],
	[Boss.BKind.DAMAR],
	[Boss.BKind.BUZ],
]

var t := 0.0
var biome := 0
var running := true

var _spawn_t := 0.0
var _elite_t := 95.0
var _tut_step := 0
# EFENDİ AVLISI: node_mods.rush — altı efendi arka arkaya; zafer zincirin sonunda
var _rush_order := [Boss.BKind.HOST, Boss.BKind.REX, Boss.BKind.NAHUM, Boss.BKind.TUMAN, Boss.BKind.KIRIN, Boss.BKind.CONST]
var _rush_idx := 0
var _rush_next := 8.0
var _surge_t := 85.0
var _mono_fired := false   # resonance cluster side objective — once per run
var _tome_t := 275.0       # bilgelik tomu — ~4:35'te ilki, sonra ~4dk'da bir
var _rain_t := 130.0       # ortam tehlikesi — oyuncu çevresine telegraph'lı alan vuruşları

# ortam tehlikesi saha başına değişir — hepsi telegraph'lı, iki tarafı da vurur:
# barrens göktaşı / mine kaya sağanağı / wreckage ark fırtınası / aeterna ışık hüzmesi
const RAIN_CFG := [
	{"t": "GÖKTAŞI YAĞMURU — işaretli alanlardan kaç!", "col": "ff6626", "r": 95.0, "n": 7, "pdmg": 24.0, "ptype": "EXPLOSION"},
	{"t": "KAYA SAĞANAĞI — madenin tavanı çözülüyor!", "col": "b08850", "r": 105.0, "n": 6, "pdmg": 30.0, "ptype": "MELEE"},
	{"t": "ARK FIRTINASI — enkaz elektrik boşalıyor!", "col": "42d4f4", "r": 70.0, "n": 10, "pdmg": 18.0, "ptype": "SHOCK"},
	{"t": "IŞIK HÜZMESİ — kubbe odaklanıyor!", "col": "ffe9a8", "r": 62.0, "n": 9, "pdmg": 22.0, "ptype": "PURE"},
	{"t": "SPOR PATLAMASI — şişkin mantarlar doluyor!", "col": "66bb6a", "r": 80.0, "n": 8, "pdmg": 20.0, "ptype": "EXPLOSION"},
	{"t": "KOR YAĞMURU — gökyüzü kül kusuyor!", "col": "ff7722", "r": 90.0, "n": 8, "pdmg": 26.0, "ptype": "EXPLOSION"},
	{"t": "KUM FIRTINASI — sürüklenen kumlar kabarır!", "col": "ffaa55", "r": 105.0, "n": 6, "pdmg": 18.0, "ptype": "SHOCK"},
	{"t": "KRİSTAL YAĞMURU — çukurun tavanı düşüyor!", "col": "4dd0e1", "r": 75.0, "n": 9, "pdmg": 22.0, "ptype": "PURE"},
	{"t": "TIPİ — donmuş hava çöküyor!", "col": "9fd8ff", "r": 85.0, "n": 8, "pdmg": 22.0, "ptype": "PURE"},
]
var _min_ann := 0          # son duyurulan dakika kilometre taşı
var _mini := false
var _final := false
var _won := false
var _final_alive := 0     # final-boss count still standing (pairs need both down)
var _merch_fired := false # gezgin tüccar — koşuda bir kez
var _stray_fired := false  # kayıp şasi — koşuda bir kez
var _geo_fired := false    # damar jeotu — çukur koşusunda bir kez
var _harvest_t := 30.0    # endless-mode reaper cadence
var _quest_t := 0.0       # 1sn'lik görev tick'i
var _koz2_fired := false  # 7. dakikada ikinci KOZ taslağı (VS arcana chest)

func _process(d: float) -> void:
	if not running or G.state != G.State.ROOM or G.player == null or G.player.dead:
		return
	t += d
	G.run.time = t
	# melee attack tokens scale with minutes so hordes stay readable, not fair
	G.MELEE_TOKENS_MAX = 2 + mini(10, int(t / 75.0))
	_tick_spawn(d)
	_tick_events(d)
	_quest_t += d
	if _quest_t >= 1.0:
		_quest_t = 0.0
		Quests.tick("time")
	# ikinci kader kartı — 7:00'de (elinde ilk kart varsa)
	if not _koz2_fired and t >= 420.0 and G.run.arcana != "" and G.run.arcana2 == "" and is_instance_valid(G.ui) and not G.ui.overlay_open():
		_koz2_fired = true
		G.ui.arcana_choice()
	if t >= WIN_T and not _won:
		_won = true
		G.ui.banner("KOVAN DAĞILIYOR", "dayanma süresi doldu")
		G.run.victory()

func _tick_spawn(d: float) -> void:
	_spawn_t -= d
	if _spawn_t > 0.0:
		return
	var m := t / 60.0
	var hyp: bool = G.run.hyper
	var inf: bool = G.run.endless
	_spawn_t = lerpf(1.6, 0.34, clampf(t / 540.0, 0.0, 1.0)) * (0.72 if hyp else 1.0) * (0.7 if inf else 1.0)
	_spawn_t /= float(G.run.node_mods.get("spawn", 1.0))
	if _rush():
		_spawn_t *= 1.8  # boss-rush: hafif sürü basıncı, odak zincirde
	var cap := mini(230, int((60 + m * 13.0) * (1.4 if hyp else 1.0) * (1.3 if inf else 1.0)))
	var batch := mini(6, 2 + int(t / 140.0)) + (1 if hyp else 0)
	while batch > 0 and G.enemies.size() < cap:
		_spawn(_comp(m), false)
		batch -= 1

func _tick_events(d: float) -> void:
	var m := t / 60.0
	# ilk koşu yönlendirmesi — tek seferlik ipucu dizisi (meta "tut" işaretlenir)
	if not bool(G.meta.data.get("tut", false)):
		match _tut_step:
			0:
				if t >= 2.0:
					_tut_step = 1
					G.ui.toast("WASD / ok tuşları — hareket")
			1:
				if t >= 9.0:
					_tut_step = 2
					G.ui.toast("SPACE — kaçış hamlesi: sürünün arasından geç")
			2:
				if t >= 18.0:
					_tut_step = 3
					G.ui.toast("kristalleri topla — seviye taslağı açılır")
			3:
				if t >= 32.0:
					_tut_step = 4
					G.ui.toast("silahların kendi ateş eder — sen sadece hayatta kal")
			4:
				if t >= 48.0:
					_tut_step = 5
					G.meta.data["tut"] = true
					G.meta.save()
					G.ui.toast("hedef: süre dolana dek yaşa — sonra efendi gelir")
	# YOL OLAYI pusu: arenaya kuşatılmış giriş (ilk yarım saniyede çözülür)
	if G.run.pending_ambush and t > 0.5:
		G.run.pending_ambush = false
		_ambush()
	# dakika kilometre taşı duyurusu
	if int(m) > _min_ann:
		_min_ann = int(m)
		G.ui.toast("%d. dakika — sürü kalınlaşıyor" % _min_ann)
	# elites — every ~50s after 1:35; they drop chests
	_elite_t -= d
	if _elite_t <= 0.0:
		_elite_t = G.rf(44.0, 58.0) * (0.8 if G.run.hyper else 1.0) * (0.8 if G.run.elite_fever else 1.0) * float(G.run.node_mods.get("elite_t", 1.0))
		var kind: int = G.pick([Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER, Enemy.EKind.HUSK] if m < 4.0 else ([Enemy.EKind.SENTINEL, Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER] if m < 6.5 else [Enemy.EKind.SENTINEL, Enemy.EKind.KONAKCI, Enemy.EKind.ALFA, Enemy.EKind.SPITTER]))
		var e := _spawn(kind, true)
		if e != null:
			# geç dakika nadirliği: altın ŞAMPİYON — öldürünce garanti eşya
			if m >= 8.0 and G.chance(0.09):
				e.promote_champ()
			G.ui.toast("%s — sandık taşıyor" % e.actor_name)
	# surge events — a visible ring/flood every ~75s
	_surge_t -= d
	if _surge_t <= 0.0:
		_surge_t = G.rf(62.0, 82.0) * (0.8 if G.run.hyper else 1.0) * (0.75 if is_instance_valid(G.player) and G.player.has_meta("surge_up") else 1.0)
		_surge(m)
	# HoT-style side objective: a resonance cluster spawns once around 3:30
	if not _mono_fired and m >= 3.5 and is_instance_valid(G.room) and G.player != null and not G.player.dead:
		_mono_fired = true
		var pp := Vector2.ZERO
		for i in 8:
			var cand := G.player.pos + Vector2(G.rf(-620, 620), G.rf(-420, 420))
			if G.room.inside(cand, 90.0) and cand.distance_to(G.player.pos) > 260.0:
				pp = cand
				break
		if pp == Vector2.ZERO:
			pp = G.room.clamp_pos(G.player.pos + Vector2(400, 0), 40.0)
		G.room.spawn_monolith(pp)
	# gezgin tüccar: tek sefer, ~4:12'de oyuncudan uzak bir noktada belirir
	if not _merch_fired and m >= 4.2 and is_instance_valid(G.room) and G.player != null and not G.player.dead:
		_merch_fired = true
		var mp := Vector2.ZERO
		for i in 8:
			var cand := G.player.pos + Vector2(G.rf(-560, 560), G.rf(-380, 380))
			if G.room.inside(cand, 90.0) and cand.distance_to(G.player.pos) > 300.0:
				mp = cand
				break
		if mp == Vector2.ZERO:
			mp = G.room.clamp_pos(G.player.pos + Vector2(-380, 0), 40.0)
		G.room.spawn_merchant(mp)
	# kayıp şasi: ~7:30'da koşu içi karşılaşma — onar ya da parçala
	if not _stray_fired and m >= 7.5 and is_instance_valid(G.room) and G.player != null and not G.player.dead:
		_stray_fired = true
		var sp := Vector2.ZERO
		for i in 8:
			var cand := G.player.pos + Vector2(G.rf(-560, 560), G.rf(-380, 380))
			if G.room.inside(cand, 90.0) and cand.distance_to(G.player.pos) > 280.0:
				sp = cand
				break
		if sp == Vector2.ZERO:
			sp = G.room.clamp_pos(G.player.pos + Vector2(380, 0), 40.0)
		G.room.spawn_stray(sp)
	# damar jeotu: ~8:50'de çukur koşularında — kırılabilir kristal yumru
	if not _geo_fired and m >= 8.8 and is_instance_valid(G.room) and G.room.biome == 7 and G.player != null and not G.player.dead:
		_geo_fired = true
		var gp := Vector2.ZERO
		for i in 8:
			var cand := G.player.pos + Vector2(G.rf(-540, 540), G.rf(-360, 360))
			if G.room.inside(cand, 90.0) and cand.distance_to(G.player.pos) > 300.0:
				gp = cand
				break
		if gp == Vector2.ZERO:
			gp = G.room.clamp_pos(G.player.pos + Vector2(360, 0), 40.0)
		G.room.spawn_geode(gp)
	# HoT ability tome: saha kalıntısı — üstüne basan bedava lütuf taslağı açar
	_tome_t -= d
	if _tome_t <= 0.0 and is_instance_valid(G.room):
		_tome_t = G.rf(230.0, 285.0)
		var tp := Vector2(G.rf(G.room.BOUNDS.position.x + 140, G.room.BOUNDS.end.x - 140), G.rf(G.room.BOUNDS.position.y + 120, G.room.BOUNDS.end.y - 120))
		G.room.spawn_tome(tp)
	# göktaşı yağmuru: işaretli alanlara iki tarafı da vuran vuruşlar yağar
	_rain_t -= d
	if _rain_t <= 0.0 and is_instance_valid(G.player) and not G.player.dead:
		_rain_t = G.rf(85.0, 110.0) * (0.75 if G.run.hyper else 1.0)
		_rain()
	# endless reaper — a scaling HASATÇI hunter every ~100s
	if G.run.endless:
		_harvest_t -= d
		if _harvest_t <= 0.0:
			_harvest_t = 100.0
			var e := _spawn(Enemy.EKind.ALFA, true)
			if e != null:
				var n := 1.0 + maxf(0.0, (t - WIN_T) / 60.0) * 0.8
				e.max_hp *= 6.0 * n
				e.hp = e.max_hp
				e.touch_dmg *= 1.6 * n
				e.actor_name = "HASATÇI"
				e.affix = "volatile"
				G.fx.mk_light(e, Vector2(0, -18), Px.C("ff2222"), 0.8, 2.4)
				G.ui.toast("HASATÇI peşine düştü — kaç ya da öldür")
				G.audio.jingle("boss")
	# boss-rush: zamanlı mini/final yerine zincir — önceki düşünce 16sn sonra sıradaki
	if _rush():
		if not _won and _rush_idx < _rush_order.size() and t >= _rush_next and not _boss_alive():
			var bk := int(_rush_order[_rush_idx])
			var rb := _boss(bk, 1.7 + _rush_idx * 0.5 + biome * 0.15, "EFENDİ %d/6 — %s" % [_rush_idx + 1, Boss.NAMES[bk]])
			if rb != null:
				rb.set_meta("rush_boss", true)
				_rush_next = INF
	# miniboss
	if not _rush() and not _mini and t >= MINI_T:
		_mini = true
		var mk := int(MINI_KIND[clampi(biome, 0, MINI_KIND.size() - 1)])
		_boss(mk, 1.0 + m * 0.10 + biome * 0.35, "%s geliyor" % Boss.NAMES[mk])
	# final boss — kill it to clear the stage
	if not _rush() and not _final and t >= FINAL_T:
		_final = true
		var kinds: Array = FINAL_KIND[clampi(biome, 0, FINAL_KIND.size() - 1)]
		if is_instance_valid(G.run) and G.run.node_id == "beyazufuk":
			kinds = [Boss.BKind.NUR]   # Beyaz Ufuk'un kendi efendisi — Buz Anası değil, fener
		var first: Boss = null
		for i in kinds.size():
			var off := Vector2((i - float(kinds.size() - 1) * 0.5) * 140.0, 0)
			var b := _boss(int(kinds[i]), 1.0 + m * 0.14 + biome * 0.4, "%s geliyor" % Boss.NAMES[int(kinds[i])], off, false)
			if b != null:
				b.set_meta("final_boss", true)
				_final_alive += 1
				if first == null:
					first = b
		if first != null:
			G.room.boss = first
			G.ui.boss_bar(true, first)
			G.ui.boss_intro(first)
			G.audio.boss_sting()

func _comp(m: float) -> int:
	var pool: Array = [Enemy.EKind.HUSK]
	if m >= 0.8:
		pool = [Enemy.EKind.HUSK, Enemy.EKind.HUSK, Enemy.EKind.HUSK, Enemy.EKind.DRONE]
	if m >= 1.4:
		pool.append_array([Enemy.EKind.VARL, Enemy.EKind.VARL])
	if m >= 2.2:
		pool.append_array([Enemy.EKind.SPITTER, Enemy.EKind.HUSK])
	if m >= 3.2:
		pool.append_array([Enemy.EKind.CEREB])
	if m >= 4.0:
		pool.append_array([Enemy.EKind.SENTINEL, Enemy.EKind.DRONE, Enemy.EKind.SPITTER])
	if m >= 5.0:
		pool.append_array([Enemy.EKind.KONAKCI, Enemy.EKind.VARL])
	if m >= 6.5:
		pool.append_array([Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER, Enemy.EKind.DRONE])
	if m >= 7.5:
		pool.append_array([Enemy.EKind.ALFA, Enemy.EKind.CEREB])
	if m >= 8.5:
		pool.append_array([Enemy.EKind.SENTINEL, Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER, Enemy.EKind.DRONE, Enemy.EKind.KONAKCI])
	# kalkan muhafızı: geç dalga zırhlı öncü — cepheyi tutar
	if m >= 6.0:
		pool.append(Enemy.EKind.MUHFIZ)
	# hamal taşıyıcı: nadir yük düşürücü — 4:30'dan sonra havuza sızar
	if m >= 4.5:
		pool.append(Enemy.EKind.CARRIER)
	# koro sözcüsü: 5:30'dan sonra destek caster'ı — çanı sürüyü hızlandırır
	if m >= 5.5:
		pool.append(Enemy.EKind.HERALD)
	# each sector leans on its own brood: Simithar rains fire (spitters/drones),
	# Wreckage swarms with husks/varls, Aeterna fields its elite dead
	if m >= 2.0:
		match biome:
			0: pool.append_array([Enemy.EKind.KUZGUN, Enemy.EKind.KUZGUN, Enemy.EKind.DRONE, Enemy.EKind.KOCBASI])   # tarla: dalışa geçen kuzgunlar + şarjlı koçbaşları
			1: pool.append_array([Enemy.EKind.SPITTER, Enemy.EKind.DRONE, Enemy.EKind.DINAMITCI, Enemy.EKind.DINAMITCI])   # maden: barutçu tayfler
			2: pool.append_array([Enemy.EKind.VARL, Enemy.EKind.HUSK, Enemy.EKind.COPCU, Enemy.EKind.COPCU])   # enkaz: kristal yutan çöpçüler
			3: pool.append_array([Enemy.EKind.CEREB, Enemy.EKind.ALFA, Enemy.EKind.GOZETMEN])   # kule: keskin nişancı gözetmenler
			4: pool.append_array([Enemy.EKind.KONAKCI, Enemy.EKind.CEREB, Enemy.EKind.BALCIK, Enemy.EKind.BALCIK, Enemy.EKind.SIVRI, Enemy.EKind.SIVRI])   # bataklık: konakçılar + kistler + balçıklar + sivri bulutları
			5: pool.append_array([Enemy.EKind.ALFA, Enemy.EKind.SENTINEL, Enemy.EKind.MUHFIZ, Enemy.EKind.KORP, Enemy.EKind.KORP]) # kül ovası: ateşi seven sert öncüler + kor hortlakları
			6: pool.append_array([Enemy.EKind.VARL, Enemy.EKind.AKREP, Enemy.EKind.AKREP, Enemy.EKind.DRONE, Enemy.EKind.KOCBASI])   # kızıl çöl: koşucular + gömülü akrepler + koçbaşları
			7: pool.append_array([Enemy.EKind.GOZETMEN, Enemy.EKind.GOZETMEN, Enemy.EKind.CEREB, Enemy.EKind.DAMARGOL, Enemy.EKind.DAMARGOL, Enemy.EKind.SENTINEL, Enemy.EKind.TURRET, Enemy.EKind.FISILTI, Enemy.EKind.FISILTI, Enemy.EKind.FISILTI])   # kristal çukur: gözler + kistler + damar golemleri + fısıltı sürüleri
			8: pool.append_array([Enemy.EKind.MUHFIZ, Enemy.EKind.KONAKCI, Enemy.EKind.SENTINEL, Enemy.EKind.GOZETMEN, Enemy.EKind.FISILTI, Enemy.EKind.BUZRUH, Enemy.EKind.BUZRUH, Enemy.EKind.TAYF, Enemy.EKind.TAYF])   # donmuş çatlak: ağır sürü + buz serenler + ufuk tayfları
	return G.pick(pool)

func _hp_scale() -> float:
	var m := t / 60.0
	return (1.0 + m * 0.28 + maxf(0.0, m - 8.0) * 0.12) * (1.0 + biome * 0.30) * (1.15 if G.run.hyper else 1.0) * float(G.run.node_mods.get("hp", 1.0)) * (1.0 + 0.12 * float(G.meta.data.get("ng", 0)))

func _dmg_scale() -> float:
	return (1.0 + (t / 60.0) * 0.11) * (1.0 + biome * 0.15) * (1.2 if G.run.hyper else 1.0) * float(G.run.node_mods.get("dmg", 1.0)) * (1.0 + 0.08 * float(G.meta.data.get("ng", 0)))

func _spawn(kind: int, elite: bool) -> Enemy:
	if not is_instance_valid(G.room):
		return null
	var p := _ring_pos()
	if p == Vector2.INF:
		return null
	var e := Enemy.spawn(kind, p, elite, _hp_scale(), _dmg_scale(), G.room)
	if e != null and G.run.hyper:
		e.speed *= 1.08
	# sivri bulutu tek doğmaz — bulut halinde akar
	if e != null and (kind == Enemy.EKind.SIVRI or kind == Enemy.EKind.FISILTI) and not elite:
		for i in 3:
			Enemy.spawn(kind, p + Vector2(G.rf(-46, 46), G.rf(-46, 46)), false, _hp_scale(), _dmg_scale(), G.room)
	return e

func _ring_pos() -> Vector2:
	for i in 30:
		var p := G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * G.rf(760.0, 900.0)
		if not G.room.BOUNDS.grow(-50.0).has_point(p):
			continue
		var ok := true
		for q in G.room.props:
			if p.distance_to(q.pos) < q.r + 30.0:
				ok = false
				break
		if ok:
			return p
	return Vector2.INF

# YOL OLAYI pusu karşılaşması: yakın çember kuşatma + başlarında bir elit
func _ambush() -> void:
	G.audio.play("roar", 0.9, 0.4)
	G.fx.shake(0.35, 0.7)
	G.ui.banner("PUSU!", "konakçı avcıları yolu kesti")
	var e := _spawn(Enemy.EKind.ALFA, true)
	if e != null:
		G.ui.toast("%s — pusunun başı" % e.actor_name)
	for i in 12:
		var p := G.player.pos + Vector2.from_angle(TAU * i / 12.0) * G.rf(280.0, 400.0)
		if G.room.BOUNDS.grow(-40.0).has_point(p):
			Enemy.spawn(Enemy.EKind.HUSK, p, false, _hp_scale(), _dmg_scale(), G.room)

# surge şekilleri: halka (VS klasik), duvar (bir yönden akan hat), pusu (yakın çember)
func _surge(m: float) -> void:
	G.audio.play("roar", 0.7, 0.5)
	var n := mini(34, 16 + int(m * 2.0))
	var shapes := ["ring", "wall", "hunt", "twins"]
	if m >= 4.5:
		shapes.append("alay")
	match shapes[randi() % shapes.size()]:
		"alay":
			G.ui.toast("KORO ALAYI — sözcüler önde!")
			var hn := 1 if m < 7.0 else 2
			for i in hn:
				var hp2 := G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * G.rf(300.0, 380.0)
				Enemy.spawn(Enemy.EKind.HERALD, G.room.clamp_pos(hp2, 20.0), false, _hp_scale(), _dmg_scale(), G.room)
			var cang := G.rf(0.0, TAU)
			for i in n:
				var p := G.player.pos + Vector2.from_angle(cang + G.rf(-0.9, 0.9)) * G.rf(560.0, 720.0)
				p = G.room.clamp_pos(p, 20.0)
				var sk := Enemy.EKind.VARL if i % 4 == 0 else Enemy.EKind.HUSK
				Enemy.spawn(sk, p, false, _hp_scale() * 0.8, _dmg_scale(), G.room)
		"twins":
			G.ui.toast("İKİZ ELİTLER!")
			for i in 2:
				var e := _spawn(_elite_kind_for(m), true)
				if e != null and i == 1:
					e.affix = ["vampir", "mender", "caller"][randi() % 3]
		"wall":
			G.ui.toast("DUVAR AKIŞI!")
			var ang := G.rf(0.0, TAU)
			var base := G.player.pos + Vector2.from_angle(ang) * 780.0
			var perp := Vector2.from_angle(ang + PI * 0.5)
			for i in n:
				var p := base + perp * G.rf(-420.0, 420.0)
				p = G.room.clamp_pos(p, 20.0)
				var sk := Enemy.EKind.VARL if i % 3 == 0 else Enemy.EKind.HUSK
				Enemy.spawn(sk, p, false, _hp_scale() * 0.8, _dmg_scale(), G.room)
		"hunt":
			G.ui.toast("PUSU!")
			for i in n:
				var p := G.player.pos + Vector2.from_angle(TAU * i / n) * G.rf(360.0, 480.0)
				p = G.room.clamp_pos(p, 20.0)
				var sk := Enemy.EKind.VARL if i % 5 == 0 else Enemy.EKind.HUSK
				Enemy.spawn(sk, p, false, _hp_scale() * 0.8, _dmg_scale(), G.room)
		_:
			G.ui.toast("KOVAN SÜRÜYOR!")
			for i in n:
				var p := G.player.pos + Vector2.from_angle(TAU * i / n) * G.rf(720.0, 780.0)
				p = G.room.clamp_pos(p, 20.0)
				var sk := Enemy.EKind.VARL if i % 4 == 0 else (Enemy.EKind.DRONE if i % 7 == 0 else Enemy.EKind.HUSK)
				Enemy.spawn(sk, p, false, _hp_scale() * 0.8, _dmg_scale(), G.room)

# surge "twins" varyantının elit türü dakikaya göre seçilir
func _elite_kind_for(m: float) -> int:
	return G.pick([Enemy.EKind.SENTINEL, Enemy.EKind.HUSK] if m < 4.0 else [Enemy.EKind.ALFA, Enemy.EKind.KONAKCI, Enemy.EKind.SENTINEL])

func _boss(kind: int, hs: float, ann: String, off := Vector2.ZERO, show_ui := true) -> Boss:
	var p := G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * 560.0 + off
	p = G.room.clamp_pos(p, 40.0)
	var b := Boss.spawn_boss(kind, p, G.room, hs)
	b.died.connect(_on_boss_dead)
	if show_ui:
		G.room.boss = b
		G.ui.boss_bar(true, b)
		G.audio.boss_sting()
		# ilk karşılaşma sinematik kartla açılır; sonrakilerde sadece pankart
		var seen: Array = G.meta.data.get("boss_seen", [])
		if seen.has(b.bkind) or G.ui.overlay_open():
			G.ui.boss_intro(b)
		else:
			seen.append(b.bkind)
			G.meta.save()
			G.ui.cine_seq([{"tex": "por_" + str(Boss.SPR[b.bkind]), "title": "%s — %s" % [b.actor_name, b.title], "sub": "«%s»" % b.bark}])
	G.ui.toast(ann)
	return b

func _on_boss_dead(b) -> void:
	if is_instance_valid(G.ui):
		G.ui.boss_bar(false, null)
	if is_instance_valid(G.meta):
		var bid := "final"
		match int(b.bkind):
			Boss.BKind.REX: bid = "rex"
			Boss.BKind.HOST: bid = "host"
			Boss.BKind.NAHUM, Boss.BKind.TUMAN: bid = "twins"
			Boss.BKind.ANASI: bid = "anasi"
			Boss.BKind.DEV: bid = "dev"
			Boss.BKind.KOR: bid = "kor"
			Boss.BKind.DAMAR: bid = "damar"
			Boss.BKind.BUZ: bid = "buz"
			Boss.BKind.NUR: bid = "nur"
		G.meta.boss_down(bid)
		Quests.tick("boss", bid)
	if is_instance_valid(G.room):
		G.room.boss = null
		if b.has_meta("final_boss"):
			_final_alive -= 1
			if _final_alive <= 0 and not _won:
				_won = true
				G.run.victory()
			return
		# miniboss loot: two chests + a fragment shower + garanti eşya
		G.room.spawn_chest(b.pos + Vector2(-40, 0))
		G.room.spawn_chest(b.pos + Vector2(40, 0))
		G.run.drop_fragments(b.pos, 90)
		var miid := Items.roll(G.run.luck + 0.2)
		if miid != "":
			G.room.spawn_loot(miid, b.pos + Vector2(0, -50))
		G.ui.toast("%s düştü — sandıklar yere saçıldı" % b.actor_name)
		G.audio.jingle("boss")
		if int(b.bkind) == Boss.BKind.DAMAR and str(G.meta.data.get("hero", "ely")) != "dg":
			G.ui.toast("kalp kalıntıları dövüldü — yeni şasi: G-1 DAMARGÜÇ (kampta Ely-B)")
		if b.has_meta("rush_boss"):
			_rush_idx += 1
			if _rush_idx >= _rush_order.size():
				if not _won:
					_won = true
					G.ui.banner("ZİNCİR KIRILDI", "altı efendi tek koşuda düştü")
					G.run.victory()
			else:
				_rush_next = t + 16.0
				G.ui.toast("EFENDİ %d/6 düştü — sıradaki yaklaşıyor" % _rush_idx)

func _rush() -> bool:
	return G.run != null and float(G.run.node_mods.get("rush", 0.0)) > 0.0

func _boss_alive() -> bool:
	for e in G.enemies:
		if e is Boss and not e.dead:
			return true
	return false

# göktaşı yağmuru olayı: oyuncu çevresine telegraph'lı vuruşlar — iki tarafı da vurur
func _rain() -> void:
	var cfg: Dictionary = RAIN_CFG[clampi(biome, 0, RAIN_CFG.size() - 1)]
	G.ui.toast(str(cfg.t))
	G.audio.play("alarm", 0.9, 0.55)
	for i in int(cfg.n):
		var p := G.player.pos + Vector2(G.rf(-430.0, 430.0), G.rf(-310.0, 310.0))
		if is_instance_valid(G.room):
			p = G.room.clamp_pos(p, 60.0)
		_rain_strike(p, cfg)
	# Kızıl Çöl: fırtına üç gezici hortum sürükler — ~24sn sahada kalırlar
	if biome == 6 and is_instance_valid(G.room):
		for j in 3:
			var p2 := G.room.clamp_pos(G.player.pos + Vector2.from_angle(G.rf(0.0, TAU)) * G.rf(240.0, 340.0), 60.0)
			var tt := G.fx.tele_circle(p2, 62.0, 9999.0, Color(1.0, 0.7, 0.35, 0.22))
			tt.sr.modulate.a = 0.16
			G.room.hazards.append({"pos": p2, "r": 62.0, "dps": 8.0, "kind": "surgun", "t": 24.0, "tele": tt, "vel": Vector2.from_angle(G.rf(0.0, TAU)) * 46.0, "sway": G.rf(0.0, TAU)})

func _rain_strike(p: Vector2, cfg: Dictionary) -> void:
	var r: float = cfg.r
	var col := Px.C(str(cfg.col))
	var tc := col
	tc.a = 0.5
	G.fx.tele_circle(p, r, 0.9, tc)
	var pp := p
	var pt: int = G.DamageType[str(cfg.ptype)]
	get_tree().create_timer(0.9, false).timeout.connect(func():
		if is_instance_valid(G.player) and not G.player.dead and G.player.pos.distance_to(pp) < r:
			G.player.take_hit({"dmg": float(cfg.pdmg) + G.run.depth * 2.0, "type": pt, "from": pp, "knock": 8.0, "source": null})
		for e in G.enemies.duplicate():
			if e is Enemy and not e.dead and e.pos.distance_to(pp) < r:
				e.take_hit({"dmg": 70.0 + G.run.depth * 8.0, "type": pt, "from": pp, "knock": 10.0, "source": G.player})
		G.fx.burst(pp, col, 18, 240.0, 6.0, 0.4)
		G.fx.boom(pp, col, r)
		G.fx.splat(pp, col.darkened(0.62), r / 52.0)   # yanık izi — vuruş yerleri zeminde kalır
		G.fx.light_flash(pp, col, 1.6, 2.6, 0.16)
		G.audio.play("explode", 1.1, 0.3))
