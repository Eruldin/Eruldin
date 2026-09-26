class_name Actor
extends Node2D

# Base class for damageable entities. Positions are world pixels on the XY
# plane; y doubles as depth for y-sorting.

var team: int = G.Team.ENEMY
var max_hp := 30.0
var hp := 30.0
var armor := 0.0
var radius := 14.0       # body collision radius (px)
var hit_radius := 16.0   # damageable radius (px)
var knock_resist := 1.0
var stagger := 0.0       # >0: stunned
var invuln := 0.0        # >0: cannot be hit
var dead := false
var actor_name := "?"
var ext_vel := Vector2.ZERO
var body: Sprite2D
var base_color := Color.WHITE
var poison_t := 0.0
var poison_dps := 0.0
var on_death: Callable
signal died(actor)

var _flash_t := 0.0

var pos: Vector2:
	get: return global_position
	set(v): global_position = v

# ---------- sprite-frame animation ----------
# _frames: {state: [Texture2D,...]} from Px.F(); _anim = current state.
var _frames: Dictionary = {}
var _anim := ""
var _anim_i := 0
var _anim_t := 0.0
var _anim_fps := 8.0
var _anim_off := -30.0

func _set_anim(state: String, fps := 8.0) -> void:
	if _anim == state or not _frames.has(state):
		return
	_anim = state
	_anim_i = 0
	_anim_t = 0.0
	_anim_fps = fps
	_apply_frame()

func _tick_anim(d: float) -> void:
	if _anim == "" or not _frames.has(_anim):
		return
	var arr: Array = _frames[_anim]
	if arr.size() <= 1:
		return
	_anim_t += d
	if _anim_t >= 1.0 / _anim_fps:
		_anim_t = 0.0
		_anim_i = (_anim_i + 1) % arr.size()
		_apply_frame()

func _apply_frame() -> void:
	if not is_instance_valid(body) or not _frames.has(_anim):
		return
	var arr: Array = _frames[_anim]
	body.texture = arr[_anim_i % arr.size()]
	body.offset = Vector2(0, _anim_off)

func _load_frames(set_id: String, fps := 8.0) -> void:
	_frames = Px.F(set_id)
	if _frames.has("idle") and _frames["idle"].size() > 0:
		var t0: Texture2D = _frames["idle"][0]
		_anim_off = -t0.get_height() * 0.5
	_anim_fps = fps
	_anim = ""
	_set_anim("idle", fps)

func init() -> void:
	# soft shadow under the entity
	var sh := Sprite2D.new()
	sh.texture = Px.S("shadow")
	sh.z_index = -45
	sh.scale = Vector2.ONE * radius * 2.4 / 48.0
	add_child(sh)

func take_hit(h: Dictionary) -> void:
	if dead or invuln > 0:
		return
	var dmg: float = maxf(1.0, h.get("dmg", 1.0) - (0.0 if h.get("shred", false) else armor))
	hp -= dmg
	stagger = maxf(stagger, h.get("stagger", 0.0))
	var from: Vector2 = h.get("from", pos)
	var dir := (pos - from).normalized()
	ext_vel += dir * h.get("knock", 0.0) * 30.0 / maxf(0.2, knock_resist)
	_flash_t = 0.09
	var blood := Color(0.6, 0.05, 0.05) if team == G.Team.ENEMY else Color(0.8, 0.1, 0.2)
	G.fx.impact(pos + Vector2(0, -12), dir, blood.lightened(0.35), h.get("crit", false))
	G.fx.burst(pos + Vector2(0, -12), blood, 14 if h.get("crit", false) else 7, 130.0, 3.0, 0.35, 6.0)
	if h.get("crit", false):
		G.audio.play("crit", G.rf(0.95, 1.1), 0.55)
	G.fx.float_text(pos + Vector2(0, -30), str(roundi(dmg)), Color(1, 0.85, 0.2) if h.get("crit", false) else Color.WHITE, 1.3 if h.get("crit", false) else 0.9)
	if team == G.Team.ENEMY:
		G.fx.splat(pos + Vector2(0, 4), Color(0.35, 0.02, 0.02), 0.5)
	if hp <= 0:
		die(h)

func die(_h: Dictionary) -> void:
	if dead:
		return
	dead = true
	died.emit(self)
	if on_death.is_valid():
		on_death.call(self)

func tick(d: float) -> void:
	if _flash_t > 0:
		_flash_t -= d
		if _flash_t <= 0 and is_instance_valid(body):
			body.modulate = base_color
	if stagger > 0: stagger -= d
	if invuln > 0: invuln -= d
	if poison_t > 0:
		poison_t -= d
		hp -= poison_dps * d
		if G.chance(d * 8):
			G.fx.burst(pos + Vector2(0, -10), Px.C("00E676"), 1, 40.0, 2.5, 0.4)
		if hp <= 0 and not dead:
			die({"dmg": 1.0, "type": G.DamageType.POISON, "from": pos, "source": G.player})
	ext_vel = ext_vel.lerp(Vector2.ZERO, d * 8.0)
	pos += ext_vel * d

func set_flash() -> void:
	_flash_t = 0.09
	if is_instance_valid(body):
		body.modulate = Color(3, 3, 3, 1)

func dist_to(o: Actor) -> float:
	return pos.distance_to(o.pos)
