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
	# dünya-haritası düğümü modları: alacakaranlık düğümler daha koyu atmosfer
	if G.run != null and bool(G.run.node_mods.get("dusk", false)):
		G.game.set_dark(DARK[biome] * Color(0.78, 0.78, 0.78))
	_field_floor()
	_edge_walls()
	_scatter_decals_big()
	_scatter_props_big()
	_vignette_arena()
	_atmos()
	_place_hazards_arena()
	# a few field items scattered like VS floor pickups; KERVAN GÖZÜ kozu +3 ekler
	var n_pick := 6 + (3 if G.run != null and G.run.arcana == "kervan" else 0)
	for i in n_pick:
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 140, BOUNDS.end.x - 140), rng.randf_range(BOUNDS.position.y + 140, BOUNDS.end.y - 140))
		if p.distance_to(Vector2.ZERO) < 280.0:
			continue
		spawn_special(["vacuum", "bomb", "freeze", "boost", "guard", "iksir"][i % 6], p)
	# deneme totemi: üstüne basınca iki elit doğar — ikisi de düşerse ödül (isteğe bağlı yan savaş)
	var tp := Vector2(rng.randf_range(BOUNDS.position.x + 180, BOUNDS.end.x - 180), rng.randf_range(BOUNDS.position.y + 180, BOUNDS.end.y - 180))
	if tp.distance_to(Vector2.ZERO) > 320.0:
		spawn_special("totem", tp)
	# kor şarabı: çöl pazarından kaçak mal — %45 sahada bir şişe
	if rng.randf() < 0.45:
		var wp := Vector2(rng.randf_range(BOUNDS.position.x + 160, BOUNDS.end.x - 160), rng.randf_range(BOUNDS.position.y + 160, BOUNDS.end.y - 160))
		if wp.distance_to(Vector2.ZERO) > 300.0:
			spawn_special("sarap", wp)
	# sinyal feneri: isteğe bağlı ikiz şampiyon savaşı — boss-rush node'unda yok
	if G.run == null or int(G.run.node_mods.get("rush", 0)) == 0:
		var fp := Vector2(rng.randf_range(BOUNDS.position.x + 180, BOUNDS.end.x - 180), rng.randf_range(BOUNDS.position.y + 180, BOUNDS.end.y - 180))
		if fp.distance_to(Vector2.ZERO) > 360.0 and fp.distance_to(tp) > 420.0:
			spawn_special("fener", fp)
	# mahkum kafesi: kurtarılmamış yolcu sahalarda %70 ihtimalle belirir (önce Mina, sonra Lena)
	var rp := Vector2(rng.randf_range(BOUNDS.position.x + 200, BOUNDS.end.x - 200), rng.randf_range(BOUNDS.position.y + 200, BOUNDS.end.y - 200))
	if rp.distance_to(Vector2.ZERO) > 380.0 and is_instance_valid(G.meta) and rng.randf() < 0.7:
		if not bool(G.meta.data.get("rescued_mina", false)):
			spawn_special("mahkum", rp)
		elif not bool(G.meta.data.get("rescued_lena", false)):
			spawn_special("mahkum2", rp)
	# Lena'nın keşif güzergâhı: işaretli koşuda ekstra sandık + kalıntı
	if G.run != null and G.run.route_mark:
		var cp2 := Vector2(rng.randf_range(BOUNDS.position.x + 160, BOUNDS.end.x - 160), rng.randf_range(BOUNDS.position.y + 160, BOUNDS.end.y - 160))
		if cp2.distance_to(Vector2.ZERO) > 300.0:
			spawn_chest(cp2)
		for i in 4:
			var p2 := Vector2(rng.randf_range(BOUNDS.position.x + 140, BOUNDS.end.x - 140), rng.randf_range(BOUNDS.position.y + 140, BOUNDS.end.y - 140))
			if p2.distance_to(Vector2.ZERO) < 280.0:
				continue
			spawn_special(["vacuum", "bomb", "freeze", "boost", "guard", "iksir"][i % 6], p2)
	# ceset koşusu: önceki ölüm bu sahadaysa eski ceset parçacık iadesi taşır (BG2 corpse run)
	var ld: Dictionary = G.meta.data.get("last_death", {}) if is_instance_valid(G.meta) else {}
	if int(ld.get("biome", -1)) == biome and int(ld.get("depth", 0)) > 0:
		var cp := Vector2(rng.randf_range(BOUNDS.position.x + 160, BOUNDS.end.x - 160), rng.randf_range(BOUNDS.position.y + 160, BOUNDS.end.y - 160))
		var ck := spawn_special("ceset", cp)
		ck.set_meta("val", int(clampf(float(ld.get("depth", 0)) * 0.4, 40.0, 400.0)))
		G.ui.toast("bu sahada eski cesedin yatıyor — parçacıkların orada")
	G.audio.play_music("mus_%d" % biome)
	var nn := str(G.run.node_name) if G.run != null else ""
	G.ui.banner(nn if nn != "" else BIOME_NAME[biome], "kovan akıyor — hayatta kal")

func spawn_point() -> Vector2:
	return Vector2.ZERO

func _field_floor() -> void:
	# BG2 tarzi: tek buyuk boyanmis zemin resmi sahayi kaplar; kenarlari
	# karanliga gomulur, disarida kalan alanlar saf karanlik (vista yok)
	var bg := Sprite2D.new()
	bg.texture = Px.S2("gr_%d" % biome)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.scale = Vector2.ONE * maxf(
		(W + 2000.0) / maxf(float(bg.texture.get_width()), 1.0),
		(H + 2000.0) / maxf(float(bg.texture.get_height()), 1.0))
	bg.modulate = Color(1.0, 0.98, 1.0)
	bg.z_index = -2100
	add_child(bg)
	var ground := Sprite2D.new()
	ground.name = "ground"
	ground.texture = Px.S2("gr_%d" % biome)
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.scale = Vector2.ONE * maxf(
		(W + 340.0) / maxf(float(ground.texture.get_width()), 1.0),
		(H + 340.0) / maxf(float(ground.texture.get_height()), 1.0))
	ground.z_index = -2000
	add_child(ground)

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
	var n := 46
	var tries := 0
	while props.size() < n and tries < 500:
		tries += 1
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 60, BOUNDS.end.x - 60), rng.randf_range(BOUNDS.position.y + 60, BOUNDS.end.y - 60))
		if p.distance_to(Vector2.ZERO) < 260.0:
			continue
		var ok := true
		for q in props:
			if p.distance_to(q.pos) < 130.0:
				ok = false
		if ok:
			var set: Array = PROP_SPR[str(biome)]
			_prop(p, rng.randf_range(12, 24), set[rng.randi() % set.size()])

func _vignette_arena() -> void:
	# buyuk saha icin kenar karartmasi: duvar bandinin disi + ic kenar yumusatma
	var t := 320.0
	var ov := 170.0
	var edges := [
		[Vector2(0, -H * 0.5 - t * 0.5 + ov), Vector2((W + 700.0) / 4.0, t / 256.0), 0.0],
		[Vector2(0, H * 0.5 + t * 0.5 - ov), Vector2((W + 700.0) / 4.0, t / 256.0), PI],
		[Vector2(-W * 0.5 - t * 0.5 + ov, 0), Vector2((H + 700.0) / 4.0, t / 256.0), -PI * 0.5],
		[Vector2(W * 0.5 + t * 0.5 - ov, 0), Vector2((H + 700.0) / 4.0, t / 256.0), PI * 0.5],
	]
	for e in edges:
		var s := Sprite2D.new()
		s.texture = Px.S("grad")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.position = e[0]
		s.scale = e[1]
		s.rotation = e[2]
		s.modulate = Color(0.01, 0.01, 0.02, 0.9)
		s.z_index = -1850
		add_child(s)

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
			5:
				# Kül Ovası: lav fışkırtıcı — turuncu telegraph'lı püskürme
				var t5 := G.fx.tele_circle(p, 52.0, 9999.0, Color(1.0, 0.45, 0.1, 0.25))
				t5.sr.modulate.a = 0.12
				G.fx.mk_light(self, p, Px.C("ff7722"), 0.4, 1.5)
				hazards.append({"pos": p, "r": 52.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(2, 6), "tele": t5, "erupt": 0.0, "col": "ff7722"})
			6:
				if i < 3:
					# üç sabit hortum patlaması
					var t6 := G.fx.tele_circle(p, 56.0, 9999.0, Color(1.0, 0.68, 0.3, 0.25))
					t6.sr.modulate.a = 0.12
					G.fx.mk_light(self, p, Px.C("ffaa55"), 0.4, 1.5)
					hazards.append({"pos": p, "r": 56.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(2, 6), "tele": t6, "erupt": 0.0, "col": "ffaa55"})
				else:
					# Kızıl Çöl: sürüklenen kum hortumu — sahayı dolaşır, içindekini döndürerek iter
					var tt := G.fx.tele_circle(p, 62.0, 9999.0, Color(1.0, 0.7, 0.35, 0.22))
					tt.sr.modulate.a = 0.16
					hazards.append({"pos": p, "r": 62.0, "dps": 8.0, "kind": "surgun", "t": -1.0, "tele": tt, "vel": Vector2.from_angle(rng.randf() * TAU) * 40.0, "sway": rng.randf() * TAU})
			_:
				add_hazard(p, 48.0, 14.0, -1.0, Color(0.5, 0.2, 0.8, 0.3))

# no wave bookkeeping — kills are counted in Enemy.die, drops there too
func on_enemy_dead(_e) -> void:
	pass
