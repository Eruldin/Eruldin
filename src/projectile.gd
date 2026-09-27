class_name Projectile
extends Node2D

# Straight-moving projectile for both teams. Enemy shots can be reflected
# by a well-timed parry.

var team: int = G.Team.ENEMY
var dmg := 10.0
var radius := 8.0
var life := 4.0
var knock := 2.0
var stag := 0.0
var vel := Vector2.ZERO
var homing := false          # player shots home toward enemies
var homing_player := false   # enemy shots home toward player
var reflected := false
var piercing := false
var aoe := 0.0              # >0: lobbed shot, explodes in an area on impact/expiry
var life0 := 0.0            # lobbed shots: initial life, drives the fake arc
var boomerang := false      # returns to the player at half-life, piercing all the way
var both_sides := false     # dinamitçi fıçısı: AoE patlamada sürü de vurulur
var wpn := ""               # weapon id that fired it — feeds the per-weapon damage tally
var _boom_flip := false
var col := Color.WHITE
var dmg_type: int = G.DamageType.PROJECTILE
var source: Actor = null
var sr: Sprite2D
var _trail_t := 0.0

func setup(p_team: int, p_pos: Vector2, p_vel: Vector2, p_dmg: float, p_radius: float, p_col: Color, tex: String) -> void:
	team = p_team
	vel = p_vel
	dmg = p_dmg
	radius = p_radius
	col = p_col
	global_position = p_pos
	sr = Sprite2D.new()
	sr.texture = Px.S(tex)
	sr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sr.modulate = col
	sr.z_index = 55
	add_child(sr)
	sr.scale = Vector2.ONE * radius * 2.0 / 16.0
	if p_radius >= 9.0:
		G.fx.mk_light(self, Vector2.ZERO, p_col, 0.55, 1.1)
	G.projectiles.append(self)

func _process(_d: float) -> void:
	var d := get_process_delta_time()
	life -= d
	if life <= 0:
		if aoe > 0.0:
			_impact()
		else:
			_die()
		return
	if boomerang and team == G.Team.PLAYER:
		if not _boom_flip and life <= life0 * 0.5:
			_boom_flip = true
		if _boom_flip and is_instance_valid(G.player) and not G.player.dead:
			vel = vel.length() * (G.player.pos - global_position).normalized()
	if homing and team == G.Team.PLAYER:
		var best: Enemy = null
		var bd := 160.0
		for e in G.enemies:
			if e.dead:
				continue
			var dd := global_position.distance_to(e.pos)
			if dd < bd:
				bd = dd
				best = e
		if best != null:
			var want: Vector2 = (best.pos - global_position).normalized() * vel.length()
			vel = vel.lerp(want, d * 4.0)
	elif homing_player and team == G.Team.ENEMY and G.player != null and not G.player.dead:
		var want: Vector2 = (G.player.pos - global_position).normalized() * vel.length()
		vel = vel.lerp(want, d * 2.2)
	global_position += vel * d
	sr.rotation = vel.angle()
	_trail_t -= d
	if _trail_t <= 0:
		_trail_t = 0.03
		G.fx.burst(global_position, Color(col.r, col.g, col.b, 0.5), 1, 15.0, radius * 0.5, 0.2)
	if aoe > 0.0:
		if life0 <= 0.0:
			life0 = maxf(life, 0.01)
		var pr := clampf(1.0 - life / life0, 0.0, 1.0)
		sr.scale = Vector2.ONE * radius * 2.0 / 16.0 * (1.0 + 1.15 * sin(pr * PI))

	if is_instance_valid(G.room) and not G.room.inside(global_position, -8.0):
		_impact()
		return

	if team == G.Team.PLAYER:
		for e in G.enemies.duplicate():
			if not is_instance_valid(e) or e.dead:
				continue
			if global_position.distance_to(e.pos) < radius + e.hit_radius:
				var crit := G.chance(G.player.crit_ch)
				var h := {
					"dmg": dmg * (G.player.crit_mult if crit else 1.0),
					"type": dmg_type, "from": global_position - vel.normalized() * 4.0,
					"knock": knock, "stagger": stag,
					"source": source if source != null else G.player, "crit": crit,
					"wpn": wpn
				}
				e.take_hit(h)
				G.player.on_dealt_damage(e, h)
				G.audio.play("hit", 1.3, 0.5)
				if not piercing:
					_impact()
					return
	else:
		var p := G.player
		if p != null and not p.dead and global_position.distance_to(p.pos) < radius + p.hit_radius:
			if p.parry_active() and not reflected:
				team = G.Team.PLAYER
				reflected = true
				vel = -vel * 1.4
				dmg *= 1.6
				col = Px.C("00E5FF")
				sr.modulate = col
				G.audio.play("parryOk", 1.2)
				G.fx.burst(global_position, col, 10, 130.0, 4.0, 0.3)
				return
			p.take_hit({"dmg": dmg, "type": dmg_type, "from": global_position - vel.normalized() * 4.0, "knock": knock, "stagger": stag, "source": source})
			aoe = 0.0
			_impact()
			return

func _impact() -> void:
	if aoe > 0.0 and team == G.Team.ENEMY:
		var p := G.player
		if p != null and not p.dead and global_position.distance_to(p.pos) < aoe + p.hit_radius:
			p.take_hit({"dmg": dmg, "type": dmg_type, "from": global_position, "knock": knock + 4.0, "stagger": stag, "source": source})
		if both_sides:
			for e in G.enemies.duplicate():
				if e is Enemy and not e.dead and global_position.distance_to(e.pos) < aoe:
					e.take_hit({"dmg": dmg * 1.4, "type": dmg_type, "from": global_position, "knock": 12.0, "source": null})
		G.fx.burst(global_position, col, 22, 200.0, 6.0, 0.45)
		G.fx.shake(0.12, 0.15)
		G.audio.play("explode", 1.0, 0.5)
	else:
		G.fx.burst(global_position, col, 10, 130.0, 4.0, 0.3)
	_die()

func _die() -> void:
	G.projectiles.erase(self)
	queue_free()

func _exit_tree() -> void:
	G.projectiles.erase(self)
