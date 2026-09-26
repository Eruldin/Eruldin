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
const MINI_KIND := [Boss.BKind.HOST, Boss.BKind.REX, Boss.BKind.HOST, Boss.BKind.NAHUM]
const FINAL_KIND := [
	[Boss.BKind.REX],
	[Boss.BKind.HOST],
	[Boss.BKind.NAHUM, Boss.BKind.TUMAN],
	[Boss.BKind.KIRIN, Boss.BKind.CONST],
]

var t := 0.0
var biome := 0
var running := true

var _spawn_t := 0.0
var _elite_t := 95.0
var _surge_t := 85.0
var _mono_fired := false   # resonance cluster side objective — once per run
var _tome_t := 275.0       # bilgelik tomu — ~4:35'te ilki, sonra ~4dk'da bir
var _mini := false
var _final := false
var _won := false
var _final_alive := 0     # final-boss count still standing (pairs need both down)
var _harvest_t := 30.0    # endless-mode reaper cadence

func _process(d: float) -> void:
	if not running or G.state != G.State.ROOM or G.player == null or G.player.dead:
		return
	t += d
	G.run.time = t
	# melee attack tokens scale with minutes so hordes stay readable, not fair
	G.MELEE_TOKENS_MAX = 2 + mini(10, int(t / 75.0))
	_tick_spawn(d)
	_tick_events(d)
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
	var cap := mini(230, int((60 + m * 13.0) * (1.4 if hyp else 1.0) * (1.3 if inf else 1.0)))
	var batch := mini(6, 2 + int(t / 140.0)) + (1 if hyp else 0)
	while batch > 0 and G.enemies.size() < cap:
		_spawn(_comp(m), false)
		batch -= 1

func _tick_events(d: float) -> void:
	var m := t / 60.0
	# elites — every ~50s after 1:35; they drop chests
	_elite_t -= d
	if _elite_t <= 0.0:
		_elite_t = G.rf(44.0, 58.0) * (0.8 if G.run.hyper else 1.0) * (0.8 if G.run.elite_fever else 1.0)
		var kind: int = G.pick([Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER, Enemy.EKind.HUSK] if m < 4.0 else ([Enemy.EKind.SENTINEL, Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER] if m < 6.5 else [Enemy.EKind.SENTINEL, Enemy.EKind.KONAKCI, Enemy.EKind.ALFA, Enemy.EKind.SPITTER]))
		var e := _spawn(kind, true)
		if e != null:
			G.ui.toast("%s — sandık taşıyor" % e.actor_name)
	# surge events — a visible ring/flood every ~75s
	_surge_t -= d
	if _surge_t <= 0.0:
		_surge_t = G.rf(62.0, 82.0) * (0.8 if G.run.hyper else 1.0)
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
	# HoT ability tome: saha kalıntısı — üstüne basan bedava lütuf taslağı açar
	_tome_t -= d
	if _tome_t <= 0.0 and is_instance_valid(G.room):
		_tome_t = G.rf(230.0, 285.0)
		var tp := Vector2(G.rf(G.room.BOUNDS.position.x + 140, G.room.BOUNDS.end.x - 140), G.rf(G.room.BOUNDS.position.y + 120, G.room.BOUNDS.end.y - 120))
		G.room.spawn_tome(tp)
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
	# miniboss
	if not _mini and t >= MINI_T:
		_mini = true
		_boss(MINI_KIND[biome], 1.0 + m * 0.10 + biome * 0.35, "%s geliyor" % Boss.NAMES[MINI_KIND[biome]])
	# final boss — kill it to clear the stage
	if not _final and t >= FINAL_T:
		_final = true
		var kinds: Array = FINAL_KIND[clampi(biome, 0, FINAL_KIND.size() - 1)]
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
	# each sector leans on its own brood: Simithar rains fire (spitters/drones),
	# Wreckage swarms with husks/varls, Aeterna fields its elite dead
	if m >= 2.0:
		match biome:
			1: pool.append_array([Enemy.EKind.SPITTER, Enemy.EKind.DRONE])
			2: pool.append_array([Enemy.EKind.VARL, Enemy.EKind.HUSK])
			3: pool.append_array([Enemy.EKind.CEREB, Enemy.EKind.ALFA])
	return G.pick(pool)

func _hp_scale() -> float:
	var m := t / 60.0
	return (1.0 + m * 0.28 + maxf(0.0, m - 8.0) * 0.12) * (1.0 + biome * 0.30) * (1.15 if G.run.hyper else 1.0)

func _dmg_scale() -> float:
	return (1.0 + (t / 60.0) * 0.11) * (1.0 + biome * 0.15) * (1.2 if G.run.hyper else 1.0)

func _spawn(kind: int, elite: bool) -> Enemy:
	if not is_instance_valid(G.room):
		return null
	var p := _ring_pos()
	if p == Vector2.INF:
		return null
	var e := Enemy.spawn(kind, p, elite, _hp_scale(), _dmg_scale(), G.room)
	if e != null and G.run.hyper:
		e.speed *= 1.08
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

# surge şekilleri: halka (VS klasik), duvar (bir yönden akan hat), pusu (yakın çember)
func _surge(m: float) -> void:
	G.audio.play("roar", 0.7, 0.5)
	var n := mini(34, 16 + int(m * 2.0))
	match ["ring", "wall", "hunt"][randi() % 3]:
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

func _boss(kind: int, hs: float, ann: String, off := Vector2.ZERO, show_ui := true) -> Boss:
	var p := G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * 560.0 + off
	p = G.room.clamp_pos(p, 40.0)
	var b := Boss.spawn_boss(kind, p, G.room, hs)
	b.died.connect(_on_boss_dead)
	if show_ui:
		G.room.boss = b
		G.ui.boss_bar(true, b)
		G.ui.boss_intro(b)
		G.audio.boss_sting()
	G.ui.toast(ann)
	return b

func _on_boss_dead(b) -> void:
	if is_instance_valid(G.ui):
		G.ui.boss_bar(false, null)
	if is_instance_valid(G.meta):
		match int(b.bkind):
			Boss.BKind.REX: G.meta.boss_down("rex")
			Boss.BKind.HOST: G.meta.boss_down("host")
			Boss.BKind.NAHUM, Boss.BKind.TUMAN: G.meta.boss_down("twins")
			_: G.meta.boss_down("final")
	if is_instance_valid(G.room):
		G.room.boss = null
		if b.has_meta("final_boss"):
			_final_alive -= 1
			if _final_alive <= 0 and not _won:
				_won = true
				G.run.victory()
			return
		# miniboss loot: two chests + a fragment shower
		G.room.spawn_chest(b.pos + Vector2(-40, 0))
		G.room.spawn_chest(b.pos + Vector2(40, 0))
		G.run.drop_fragments(b.pos, 90)
		G.ui.toast("%s düştü — sandıklar yere saçıldı" % b.actor_name)
		G.audio.jingle("boss")
