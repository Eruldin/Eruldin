class_name Director
extends Node

# Time-scripted swarm director for the arena (Vampire Survivors style):
# minutes drive enemy composition, density and stat scaling; elites drop
# evolution chests; miniboss at 5:30, final boss at 11:00 — kill it to win,
# or outlast the collapse timer at 13:00.

const MINI_T := 330.0     # 5:30
const FINAL_T := 660.0    # 11:00
const WIN_T := 780.0      # 13:00 failsafe — swarm collapses

var t := 0.0
var biome := 0
var running := true

var _spawn_t := 0.0
var _elite_t := 95.0
var _surge_t := 85.0
var _mini := false
var _final := false
var _won := false

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
	_spawn_t = lerpf(1.6, 0.34, clampf(t / 540.0, 0.0, 1.0))
	var cap := mini(210, 60 + int(m * 13.0))
	var batch := mini(6, 2 + int(t / 140.0))
	while batch > 0 and G.enemies.size() < cap:
		_spawn(_comp(m), false)
		batch -= 1

func _tick_events(d: float) -> void:
	var m := t / 60.0
	# elites — every ~50s after 1:35; they drop chests
	_elite_t -= d
	if _elite_t <= 0.0:
		_elite_t = G.rf(44.0, 58.0)
		var kind: int = G.pick([Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER, Enemy.EKind.HUSK] if m < 4.0 else [Enemy.EKind.SENTINEL, Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER])
		var e := _spawn(kind, true)
		if e != null:
			G.ui.toast("elit — sandık taşıyor")
	# surge events — a visible ring/flood every ~75s
	_surge_t -= d
	if _surge_t <= 0.0:
		_surge_t = G.rf(62.0, 82.0)
		_surge(m)
	# miniboss
	if not _mini and t >= MINI_T:
		_mini = true
		_boss(Boss.BKind.HOST, 1.0 + m * 0.10, "PROTERIAN HOST geliyor")
	# final boss — kill it to clear the stage
	if not _final and t >= FINAL_T:
		_final = true
		_boss(Boss.BKind.REX, 1.0 + m * 0.14, "ALFA-05 — Düşmüş Kardeş geliyor")

func _comp(m: float) -> int:
	var pool: Array = [Enemy.EKind.HUSK]
	if m >= 0.8:
		pool = [Enemy.EKind.HUSK, Enemy.EKind.HUSK, Enemy.EKind.HUSK, Enemy.EKind.DRONE]
	if m >= 2.2:
		pool.append_array([Enemy.EKind.SPITTER, Enemy.EKind.HUSK])
	if m >= 4.0:
		pool.append_array([Enemy.EKind.SENTINEL, Enemy.EKind.DRONE, Enemy.EKind.SPITTER])
	if m >= 6.5:
		pool.append_array([Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER, Enemy.EKind.DRONE])
	if m >= 8.5:
		pool.append_array([Enemy.EKind.SENTINEL, Enemy.EKind.SENTINEL, Enemy.EKind.SPITTER, Enemy.EKind.DRONE])
	return G.pick(pool)

func _hp_scale() -> float:
	var m := t / 60.0
	return 1.0 + m * 0.28 + maxf(0.0, m - 8.0) * 0.12

func _dmg_scale() -> float:
	return 1.0 + (t / 60.0) * 0.11

func _spawn(kind: int, elite: bool) -> Enemy:
	if not is_instance_valid(G.room):
		return null
	var p := _ring_pos()
	if p == Vector2.INF:
		return null
	return Enemy.spawn(kind, p, elite, _hp_scale(), _dmg_scale(), G.room)

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

func _surge(m: float) -> void:
	G.ui.toast("KOVAN SÜRÜYOR!")
	G.audio.play("roar", 0.7, 0.5)
	var n := mini(34, 16 + int(m * 2.0))
	for i in n:
		var p := G.player.pos + Vector2.from_angle(TAU * i / n) * G.rf(720.0, 780.0)
		p = G.room.clamp_pos(p, 20.0)
		Enemy.spawn(Enemy.EKind.HUSK if i % 4 != 0 else Enemy.EKind.DRONE, p, false, _hp_scale() * 0.8, _dmg_scale(), G.room)

func _boss(kind: int, hs: float, ann: String) -> void:
	var p := G.player.pos + Vector2.from_angle(G.rf(0, TAU)) * 560.0
	p = G.room.clamp_pos(p, 40.0)
	var b := Boss.spawn_boss(kind, p, G.room, hs)
	if kind == Boss.BKind.REX:
		b.set_meta("final_boss", true)
	b.died.connect(_on_boss_dead)
	G.room.boss = b
	G.ui.boss_bar(true, b)
	G.ui.boss_intro(b)
	G.audio.boss_sting()
	G.ui.toast(ann)

func _on_boss_dead(b) -> void:
	if is_instance_valid(G.ui):
		G.ui.boss_bar(false, null)
	if is_instance_valid(G.room):
		G.room.boss = null
		if b.has_meta("final_boss"):
			if not _won:
				_won = true
				G.run.victory()
			return
		# miniboss loot: two chests + a fragment shower
		G.room.spawn_chest(b.pos + Vector2(-40, 0))
		G.room.spawn_chest(b.pos + Vector2(40, 0))
		G.run.drop_fragments(b.pos, 90)
		G.ui.toast("%s düştü — sandıklar yere saçıldı" % b.actor_name)
		G.audio.jingle("boss")
