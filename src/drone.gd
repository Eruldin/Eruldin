class_name Drone
extends Node2D
# VS pet arketipi: oyuncunun yörüngesinde süzülür, en yakın düşmana mermi yollar.
# weapons.gd `_drone` her silah turunda sayı ve statları senkronlar; ateşleme
# kendi zamanlayıcısında ilerler (silah cd'si ile bağımsız değildir).

var wid := "drone"
var dmg := 11.0
var cd := 1.15
var n := 1
var pierce := false
var idx := 0
var total := 1
var _t := 0.5
var _ang := 0.0

static func spawn(idx2: int) -> Drone:
	var d := Drone.new()
	d.idx = idx2
	G.game.world.add_child(d)
	var spr := Sprite2D.new()
	spr.texture = Px.S2("spark")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.modulate = Px.C("00E5FF")
	spr.scale = Vector2.ONE * 1.3
	d.add_child(spr)
	G.fx.mk_light(d, Vector2.ZERO, Px.C("00E5FF"), 0.5, 1.3)
	if is_instance_valid(G.player):
		d.position = G.player.pos
	return d

func _process(d: float) -> void:
	if G.state != G.State.ROOM:
		queue_free()
		return
	var p := G.player
	if p == null or p.dead:
		return
	_ang += d * 1.9
	var want := p.pos + Vector2.from_angle(_ang + TAU * float(idx) / maxf(1.0, float(total))) * 56.0 + Vector2(0, -16)
	position = position.lerp(want, minf(1.0, d * 5.5))
	z_index = int(position.y) - 8
	_t -= d
	if _t <= 0.0:
		_t = cd
		_fire(p)

func _fire(p: Player) -> void:
	var pool: Array = []
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead:
			pool.append(e)
	pool.sort_custom(func(a, b): return position.distance_squared_to(a.pos) < position.distance_squared_to(b.pos))
	if pool.is_empty():
		return
	var cnt := mini(maxi(1, n), pool.size())
	for i in cnt:
		var e: Enemy = pool[i]
		var dir := (e.pos - position).normalized()
		var pr := Projectile.new()
		G.game.world.add_child(pr)
		pr.setup(G.Team.PLAYER, position + dir * 14.0, dir * 580.0 * p.proj_spd, dmg * p.dmg_mult, 7.0, Px.C("00E5FF"), "dot")
		pr.wpn = wid
		pr.homing = p.b_homing
		pr.piercing = pierce
		pr.knock = 3.0
		pr.stag = 0.15
	G.audio.play("shoot", 1.6, 0.22)
