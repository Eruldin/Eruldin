class_name Arena
extends Room

# One open field for a whole run — survivors-style. No doors, no waves:
# the Director pours the swarm in from off-screen; BOUNDS fences the far edge.

func build_arena(biome_idx: int) -> void:
	W = 3400.0
	H = 2300.0
	BOUNDS = Rect2(-W * 0.5 + 70.0, -H * 0.5 + 70.0, W - 140.0, H - 140.0)
	biome = biome_idx
	rtype = Type.COMBAT
	is_hub = false
	rng.randomize()
	G.game.set_dark(DARK[biome])
	_field_floor()
	_edge_walls()
	_scatter_decals_big()
	_scatter_props_big()
	_place_hazards_arena()
	# a few field items scattered like VS floor pickups
	for i in 5:
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 140, BOUNDS.end.x - 140), rng.randf_range(BOUNDS.position.y + 140, BOUNDS.end.y - 140))
		if p.distance_to(Vector2.ZERO) < 280.0:
			continue
		spawn_special(["vacuum", "bomb", "freeze"][i % 3], p)
	G.audio.play_music("mus_%d" % biome)
	G.ui.banner(BIOME_NAME[biome], "kovan akıyor — hayatta kal")

func spawn_point() -> Vector2:
	return Vector2.ZERO

func _field_floor() -> void:
	# painted biome vista fills the void around the field
	var bg_tex := Px.S2("bg_%d" % biome)
	if bg_tex != null:
		var bg := Sprite2D.new()
		bg.texture = bg_tex
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		bg.scale = Vector2.ONE * maxf(
			(W + 2400.0) / maxf(float(bg_tex.get_width()), 1.0),
			(H + 2400.0) / maxf(float(bg_tex.get_height()), 1.0))
		bg.modulate = Color(0.85, 0.82, 0.9)
		bg.z_index = -4000
		add_child(bg)
	# one tiled TextureRect instead of ~1000 tile sprites — confined to the
	# field itself so the vista reads beyond the walls
	var ground := TextureRect.new()
	ground.name = "ground"
	ground.texture = Px.S2("t2_%s_0" % str(biome))
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.scale = Vector2.ONE * 2.0
	ground.size = Vector2((W + 160.0) / 2.0, (H + 160.0) / 2.0)
	ground.position = -ground.size
	ground.modulate = Color(0.72, 0.7, 0.78)
	ground.z_index = -2000
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ground)
	# a second sparse layer of variant tiles for texture break-up
	for i in 90:
		var s := Sprite2D.new()
		s.texture = Px.S2("t2_%s_%d" % [str(biome), G.ri(1, 2)])
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2.ONE * 2.0
		s.position = Vector2(G.rf(-W * 0.5, W * 0.5), G.rf(-H * 0.5, H * 0.5))
		s.modulate = Color(0.6, 0.58, 0.66)
		s.z_index = -1999
		add_child(s)

func _edge_walls() -> void:
	# visual fence around BOUNDS: wall band on top/bottom, pillars on the sides
	var tex := Px.S2("w2_" + str(biome))
	if tex != null:
		var x := -W * 0.5 - 64.0
		while x <= W * 0.5 + 64.0:
			for dy in [-H * 0.5 - 40.0, -H * 0.5 - 104.0, H * 0.5 + 24.0]:
				var s := Sprite2D.new()
				s.texture = tex
				s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s.scale = Vector2.ONE * 2.0
				s.position = Vector2(x, dy)
				s.z_index = int(dy) - 40
				if dy < -H * 0.5 - 60.0:
					s.modulate = Color(0.5, 0.5, 0.58)
				add_child(s)
			x += 64.0
		var y := -H * 0.5
		while y <= H * 0.5:
			for dx in [-W * 0.5 - 30.0, W * 0.5 + 30.0]:
				var s2 := Sprite2D.new()
				s2.texture = tex
				s2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				s2.scale = Vector2.ONE * 2.0
				s2.position = Vector2(dx, y)
				s2.z_index = int(y) - 40
				s2.modulate = Color(0.45, 0.45, 0.53)
				add_child(s2)
			y += 96.0

func _scatter_decals_big() -> void:
	var kinds := ["stain", "stain", "bones", "bones", "crack"]
	if biome == 0:
		kinds.append("tuft")
	if biome == 3:
		kinds.append("vein")
	for i in 110:
		var k: String = kinds[G.ri(0, kinds.size() - 1)]
		var s := Sprite2D.new()
		s.texture = Px.S2("dec_%s_%d" % [k, G.ri(0, DEC_NVAR.get(k, 1) - 1)])
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(G.rf(BOUNDS.position.x, BOUNDS.end.x), G.rf(BOUNDS.position.y, BOUNDS.end.y))
		s.rotation = G.rf(0, TAU)
		s.scale = Vector2.ONE * 1.6
		s.z_index = -1890
		add_child(s)

func _scatter_props_big() -> void:
	var n := 26
	var tries := 0
	while props.size() < n and tries < 400:
		tries += 1
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 60, BOUNDS.end.x - 60), rng.randf_range(BOUNDS.position.y + 60, BOUNDS.end.y - 60))
		if p.distance_to(Vector2.ZERO) < 260.0:
			continue
		var ok := true
		for q in props:
			if p.distance_to(q.pos) < 120.0:
				ok = false
		if ok:
			_prop(p, rng.randf_range(10, 22), PROP_SPR[biome][rng.randi() % PROP_SPR[biome].size()])

func _place_hazards_arena() -> void:
	for i in 9:
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 120, BOUNDS.end.x - 120), rng.randf_range(BOUNDS.position.y + 120, BOUNDS.end.y - 120))
		if p.distance_to(Vector2.ZERO) < 320.0:
			continue
		match biome:
			0:
				var t := G.fx.tele_circle(p, 52.0, 9999.0, Color(0.2, 0.9, 0.1, 0.25))
				t.sr.modulate.a = 0.12
				G.fx.mk_light(self, p, Px.C("00E676"), 0.4, 1.5)
				hazards.append({"pos": p, "r": 52.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(2, 6), "tele": t, "erupt": 0.0})
			1:
				add_hazard(p, 46.0, 16.0, -1.0, Color(1, 0.4, 0.1, 0.3))
			2:
				add_slowzone(p, 52.0, -1.0)
			_:
				add_hazard(p, 48.0, 14.0, -1.0, Color(0.5, 0.2, 0.8, 0.3))

# no wave bookkeeping — kills are counted in Enemy.die, drops there too
func on_enemy_dead(_e) -> void:
	pass
