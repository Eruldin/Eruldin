class_name Px
extends RefCounted

# Runtime pixel-art factory. Every sprite is generated in code — no external
# art assets needed. Characters are parametric silhouettes; tiles/props/icons
# are drawn geometrically.

static var cache := {}
const OUTL := Color("0a0a10")

static func S(n: String) -> Texture2D:
	if cache.has(n) and is_instance_valid(cache[n]):
		return cache[n]
	var t: Texture2D = _ext_sprite(n)
	if t == null:
		t = _build(n)
	cache[n] = t
	return t

static func C(hex: String) -> Color:
	return Color.html(hex)

static func shade(c: Color, f: float) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, c.a)

# ---------- low level ----------
static func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)

static func _p(t: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= t.get_width() or y >= t.get_height():
		return
	t.set_pixel(x, y, c)

static func _rect(t: Image, x0: int, y0: int, w: int, h: int, c: Color) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			_p(t, x, y, c)

static func _disc(t: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			if x * x + y * y <= r * r:
				_p(t, cx + x, cy + y, c)

static func _ring(t: Image, cx: int, cy: int, r: int, th: int, c: Color) -> void:
	for y in range(-r - th, r + th + 1):
		for x in range(-r - th, r + th + 1):
			var d := sqrt(float(x * x + y * y))
			if d >= r - th and d <= r + th:
				_p(t, cx + x, cy + y, c)

static func _outline(t: Image) -> void:
	var src := t.duplicate()
	var w := t.get_width()
	var h := t.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.05:
				continue
			var near := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.05:
						near = true
			if near:
				_p(t, x, y, OUTL)

static func _tex(t: Image, outline := false) -> ImageTexture:
	if outline:
		_outline(t)
	return ImageTexture.create_from_image(t)

# ---------- humanoid builder ----------
# spec keys: armor, armor2, trim, glow, cloth, skin (Color), w,h,bulk (int),
# helm 0 visor / 1 eyes / 2 hood, cape, big_arm_l, big_arm_r (bool),
# weapon 0 none / 1 blade / 2 staff / 3 spear / 4 injector
static func _humanoid(s: Dictionary) -> Texture2D:
	var w: int = s.w
	var h: int = s.h
	var t := _img(w, h)
	var cx := w / 2
	var leg_h := int(h * 0.34)
	var torso_h := int(h * 0.34)
	var torso_w := int(w * (0.44 + s.bulk * 0.08))
	var torso_y := leg_h
	var head_y := leg_h + torso_h
	var head_h := int(h * 0.20)

	if s.get("cape", false):
		for y in range(0, head_y + head_h - 4):
			var cw := int(torso_w * 0.5 + (head_y - y) * 0.22)
			_rect(t, cx - cw, y, cw * 2, 1, shade(s.cloth, 0.85))
	# legs
	var leg_w := maxi(3, torso_w / 4)
	var gap := 2
	_rect(t, cx - gap - leg_w, 0, leg_w, leg_h, s.armor2)
	_rect(t, cx + gap, 0, leg_w, leg_h, s.armor2)
	_rect(t, cx - gap - leg_w, 0, leg_w, 3, shade(s.armor2, 0.7))
	_rect(t, cx + gap, 0, leg_w, 3, shade(s.armor2, 0.7))
	# torso
	_rect(t, cx - torso_w / 2, torso_y, torso_w, torso_h, s.armor)
	_rect(t, cx - torso_w / 2, torso_y, torso_w, 3, shade(s.armor, 0.65))
	_rect(t, cx - torso_w / 2, torso_y + torso_h - 3, torso_w, 3, shade(s.armor, 1.3))
	_disc(t, cx, torso_y + torso_h / 2, maxi(2, torso_w / 8), s.glow)
	_disc(t, cx, torso_y + torso_h / 2, maxi(1, torso_w / 14), Color.WHITE)
	_rect(t, cx - torso_w / 2, torso_y + 3, torso_w, 2, s.trim)
	# pauldrons
	var pr: int = torso_w / 2 + int(s.bulk)
	_disc(t, cx - torso_w / 2 - pr / 3, torso_y + torso_h - 2, pr, s.armor2)
	_disc(t, cx + torso_w / 2 + pr / 3, torso_y + torso_h - 2, pr, s.armor2)
	_disc(t, cx - torso_w / 2 - pr / 3, torso_y + torso_h - 1, maxi(1, pr / 3), s.trim)
	_disc(t, cx + torso_w / 2 + pr / 3, torso_y + torso_h - 1, maxi(1, pr / 3), s.trim)
	# arms
	var arm_w := maxi(3, w / 10)
	var arm_y := torso_y + 2
	var arm_h := torso_h - 2
	var l_arm_x := cx - torso_w / 2 - arm_w - pr / 4
	var r_arm_x := cx + torso_w / 2 + pr / 4
	if s.get("big_arm_l", false): arm_w = int(arm_w * 1.8)
	_rect(t, l_arm_x, arm_y, arm_w, arm_h, shade(s.armor, 1.2) if s.get("big_arm_l", false) else s.armor)
	var r_arm_w := int(w / 8.0) if s.get("big_arm_r", false) else arm_w
	_rect(t, r_arm_x, arm_y, r_arm_w, arm_h, shade(s.armor, 1.2) if s.get("big_arm_r", false) else s.armor)
	# weapons
	match int(s.get("weapon", 0)):
		1: # frequency blade
			_rect(t, l_arm_x - 1, arm_y - leg_h + 4, 3, leg_h + 2, C("cfd6dd"))
			_rect(t, l_arm_x, arm_y - leg_h + 4, 1, leg_h + 2, s.glow)
		2: # staff
			_rect(t, r_arm_x, 2, 2, head_y + head_h - 6, C("5a4632"))
			_disc(t, r_arm_x + 1, head_y + head_h - 4, 3, s.glow)
		3: # spear
			_rect(t, r_arm_x, 0, 2, head_y + head_h + 2, C("8a7a55"))
			_rect(t, r_arm_x - 1, head_y + head_h, 4, 4, C("cfd6dd"))
		4: # injector
			_rect(t, r_arm_x, arm_y - 4, 3, 8, s.glow)
			_rect(t, r_arm_x + 1, arm_y - 6, 1, 2, Color.WHITE)
	if s.get("big_arm_r", false):
		_disc(t, r_arm_x + arm_w / 2, arm_y, arm_w / 2 + 1, s.glow)
	# head
	var hw := maxi(6, int(torso_w * 0.46))
	var hx := cx - hw / 2
	if int(s.get("helm", 0)) == 2:
		_rect(t, hx - 2, head_y - 2, hw + 4, head_h + 4, s.cloth)
		_rect(t, hx + 2, head_y + 2, hw - 4, head_h - 4, shade(s.skin, 0.55))
		_p(t, cx - 2, head_y + head_h / 2, s.glow)
		_p(t, cx + 2, head_y + head_h / 2, s.glow)
	else:
		_rect(t, hx, head_y, hw, head_h, s.armor)
		_rect(t, hx, head_y + head_h - 3, hw, 3, shade(s.armor, 1.3))
		if int(s.get("helm", 0)) == 0:
			_rect(t, hx + 2, head_y + head_h / 2 - 1, hw - 4, 2, s.glow)
		else:
			for ex in [-2, 2]:
				_p(t, cx + ex, head_y + head_h / 2, s.glow)
				_p(t, cx + ex, head_y + head_h / 2 + 1, s.glow)
		_rect(t, hx + hw / 4, head_y + head_h, hw / 2, 2, s.trim)
	return _tex(t, true)

# ---------- organic builder (Proterian) ----------
static func _organic(w: int, h: int, flesh: Color, flesh2: Color, glow: Color, limbs: int, eyes: int, hunched: bool) -> Texture2D:
	var t := _img(w, h)
	var cx := w / 2
	var cy := h / 2
	_disc(t, cx, cy - 2, int(mini(w, h) * 0.38), flesh)
	_disc(t, cx - 2, cy + (0 if hunched else 4), int(mini(w, h) * 0.30), flesh2)
	for i in limbs:
		var a := -0.4 + i * (PI + 0.8) / maxf(1.0, limbs - 1.0) + PI
		var lx := cx + int(cos(a) * w * 0.34)
		var ly := cy + int(sin(a) * h * 0.30) - 2
		for k in 4:
			_rect(t, lx + int(cos(a) * k), ly + int(sin(a) * k), 2, 2, flesh)
		_rect(t, lx - 1, ly - 2, 3, 3, shade(flesh, 0.6))
	for i in eyes:
		_disc(t, cx - eyes + i * 3, cy + (2 if hunched else 6), 1, glow)
	for i in 5:
		_disc(t, cx + G.ri(-w / 4, w / 4), cy + G.ri(-h / 5, h / 5), 1, shade(glow, 0.8))
	_rect(t, cx - w / 5, 0, w / 8, cy - h / 5, flesh2)
	_rect(t, cx + w / 5 - w / 8, 0, w / 8, cy - h / 5, flesh2)
	return _tex(t, true)

# ---------- dispatcher ----------
static func _build(n: String) -> Texture2D:
	match n:
		"dot": return _soft_dot(16)
		"px1":
			var t := _img(2, 2); _rect(t, 0, 0, 2, 2, Color.WHITE); return _tex(t)
		"ring":
			var t := _img(72, 72); _ring(t, 36, 36, 30, 3, Color.WHITE); return _tex(t)
		"circle":
			var t := _img(72, 72); _disc(t, 36, 36, 34, Color.WHITE); return _tex(t)
		"disc_soft":
			var t := _img(72, 72)
			for r in range(34, 0, -1):
				_disc(t, 36, 36, r, Color(1, 1, 1, lerpf(0.05, 0.5, r / 34.0)))
			return _tex(t)
		"wedge": return _wedge(96, 96, 70)
		"splat": return _splat()
		"spark":
			var t := _img(10, 10)
			_rect(t, 4, 0, 2, 10, Color.WHITE); _rect(t, 0, 4, 10, 2, Color.WHITE)
			return _tex(t)
		"shadow": return _shadow()
		"grad": return _grad()
		"scan": return _scan()
		"bar":
			var t := _img(4, 4); _rect(t, 0, 0, 4, 4, Color.WHITE); return _tex(t)

		# icons
		"ico_boon": return _ico_boon()
		"ico_heal": return _ico_heal()
		"ico_frag": return _ico_frag()
		"ico_elite": return _ico_skull(false)
		"ico_boss": return _ico_skull(true)
		"ico_exit": return _ico_exit()

		# tiles & walls
		"tile_0": return _tile(C("6b4a2e"), C("54371f"), C("7d5a3a"), true)
		"tile_1": return _tile(C("2c2c38"), C("22222c"), C("3d3d52"), false)
		"tile_2": return _tile(C("33302e"), C("262422"), C("4a4038"), true)
		"tile_3": return _tile(C("1c1a26"), C("14121c"), C("8a7440"), false)
		"tile_hub": return _tile(C("5c4326"), C("483320"), C("6e5232"), true)
		"wall_0": return _wall(C("4a3220"), C("2e1f12"))
		"wall_1": return _wall(C("3a3a4c"), C("22222e"))
		"wall_2": return _wall(C("3e3833"), C("#252119"))
		"wall_3": return _wall(C("2a2540"), C("171320"))
		"wall_hub": return _wall(C("4f3823"), C("302014"))

		# props
		"crate": return _crate()
		"crystal": return _crystal(C("7B1FA2"), C("00E5FF"))
		"rock": return _rock()
		"bones": return _bones()
		"vent": return _vent()
		"vat": return _vat()
		"tent": return _tent()
		"campfire": return _campfire()
		"pillar": return _pillar()
		"banner": return _banner()
		"pod": return _pod()
		"wreck": return _wreck()
		"door": return _door()
		"gate": return _gate()
		"medic": return _medic()

		# characters
		"ely": return _humanoid({"w":30,"h":44,"bulk":2,"armor":C("1c1c26"),"armor2":C("12121a"),"trim":C("7B1FA2"),"glow":C("00E5FF"),"helm":0,"weapon":1,"big_arm_r":true,"skin":C("b08968"),"cloth":C("3a2c22")})
		"nahum": return _humanoid({"w":30,"h":44,"bulk":2,"armor":C("33202a"),"armor2":C("1c1218"),"trim":C("8B0000"),"glow":C("ff3355"),"helm":0,"weapon":1,"skin":C("b08968"),"cloth":C("3a2c22")})
		"tuman": return _humanoid({"w":30,"h":44,"bulk":1,"armor":C("241c33"),"armor2":C("161022"),"trim":C("7B1FA2"),"glow":C("00E676"),"helm":0,"weapon":2,"skin":C("b08968"),"cloth":C("3a2c22")})
		"rhasa": return _humanoid({"w":34,"h":48,"bulk":3,"armor":C("3a3428"),"armor2":C("26221a"),"trim":C("a8842f"),"glow":C("ffb74d"),"helm":1,"cape":true,"cloth":C("5c2e22"),"weapon":1,"skin":C("b08968")})
		"rex": return _humanoid({"w":38,"h":52,"bulk":3,"armor":C("2a1e20"),"armor2":C("181114"),"trim":C("8B0000"),"glow":C("ff2222"),"helm":1,"weapon":0,"big_arm_l":true,"big_arm_r":true,"skin":C("b08968"),"cloth":C("3a2c22")})
		"kirin": return _humanoid({"w":22,"h":44,"bulk":0,"armor":C("e8e8ee"),"armor2":C("b8b8c4"),"trim":C("8B0000"),"glow":C("00E676"),"helm":1,"cape":true,"cloth":C("e8e8ee"),"weapon":4,"skin":C("d8b090")})
		"const": return _humanoid({"w":26,"h":46,"bulk":0,"armor":C("14101c"),"armor2":C("0c0a12"),"trim":C("c9a227"),"glow":C("c9a227"),"helm":2,"cape":true,"cloth":C("14101c"),"weapon":2,"skin":C("c9b8a0")})
		"saphire": return _humanoid({"w":24,"h":42,"bulk":0,"armor":C("4a3020"),"armor2":C("2e1e12"),"trim":C("d0a040"),"glow":C("00E676"),"helm":2,"cloth":C("4a3020"),"weapon":3,"skin":C("8a5a34")})
		"neva": return _humanoid({"w":20,"h":34,"bulk":0,"armor":C("241a30"),"armor2":C("181020"),"trim":C("7B1FA2"),"glow":C("c26bff"),"helm":2,"cloth":C("241a30"),"skin":C("caa27a")})
		"vane": return _humanoid({"w":24,"h":40,"bulk":0,"armor":C("c8ccd4"),"armor2":C("9aa0ac"),"trim":C("3a7a3a"),"glow":C("00E5FF"),"helm":1,"cape":true,"cloth":C("c8ccd4"),"weapon":4,"skin":C("caa27a")})
		"ehnar": return _humanoid({"w":22,"h":40,"bulk":0,"armor":C("3a2c3e"),"armor2":C("241a28"),"trim":C("7B1FA2"),"glow":C("c26bff"),"helm":2,"cloth":C("3a2c3e"),"weapon":2,"skin":C("9a7a5a")})

		# enemies
		"husk": return _organic(30, 30, C("4a6a2e"), C("33491f"), C("00E676"), 4, 3, true)
		"spitter": return _organic(34, 34, C("5a7a2a"), C("3d5420"), C("aaff00"), 2, 4, false)
		"drone": return _drone()
		"turret": return _turret()
		"host": return _organic(44, 48, C("5e4a6a"), C("3e2e48"), C("ff3355"), 6, 6, false)
		"sentinel": return _humanoid({"w":30,"h":44,"bulk":2,"armor":C("2a2f36"),"armor2":C("1a1e24"),"trim":C("8B0000"),"glow":C("ff2222"),"helm":0,"weapon":1,"skin":C("b08968"),"cloth":C("3a2c22")})

	# fallback magenta box
	var fb := _img(8, 8)
	_rect(fb, 0, 0, 8, 8, Color.MAGENTA)
	return _tex(fb)

# ---------- fx shapes ----------
static func _soft_dot(r: int) -> Texture2D:
	var t := _img(r * 2, r * 2)
	for y in r * 2:
		for x in r * 2:
			var d := sqrt(float((x - r) * (x - r) + (y - r) * (y - r))) / r
			if d < 1:
				_p(t, x, y, Color(1, 1, 1, 1 - d))
	return _tex(t)

static func _wedge(w: int, h: int, deg: float) -> Texture2D:
	var t := _img(w, h)
	var cx := w / 2
	var half := deg * 0.5 * PI / 180.0
	for y in h:
		for x in w:
			var dx := float(x - cx)
			var dy := float(y - 4)
			var dist := sqrt(dx * dx + dy * dy)
			if dist < 2 or dist > h - 6:
				continue
			var a := atan2(dx, dy)
			if absf(a) <= half:
				_p(t, x, y, Color(1, 1, 1, 0.85))
	return _tex(t)

static func _splat() -> Texture2D:
	var t := _img(40, 40)
	for i in 12:
		_disc(t, 20 + G.ri(-14, 14), 20 + G.ri(-14, 14), G.ri(2, 7), Color(1, 1, 1, G.rf(0.5, 0.9)))
	return _tex(t)

static func _shadow() -> Texture2D:
	var t := _img(48, 24)
	for y in 24:
		for x in 48:
			var dx := (x - 24) / 24.0
			var dy := (y - 12) / 12.0
			var d := dx * dx + dy * dy
			if d < 1:
				_p(t, x, y, Color(0, 0, 0, 0.4 * (1 - d)))
	return _tex(t)

static func _grad() -> Texture2D:
	var t := _img(4, 256)
	for y in 256:
		var a := pow(1.0 - y / 255.0, 1.6) * 0.85
		for x in 4:
			_p(t, x, y, Color(0, 0, 0, a))
	return _tex(t)

static func _scan() -> Texture2D:
	var t := _img(4, 4)
	_rect(t, 0, 0, 4, 1, Color(0, 0, 0, 0.32))
	_rect(t, 0, 1, 4, 1, Color(0, 0, 0, 0.10))
	return _tex(t)

# ---------- icons ----------
static func _ico_boon() -> Texture2D:
	var t := _img(24, 24)
	_rect(t, 10, 2, 4, 20, C("c9a227"))
	_rect(t, 4, 10, 16, 4, C("c9a227"))
	_disc(t, 12, 12, 5, C("00E5FF"))
	_disc(t, 12, 12, 2, Color.WHITE)
	return _tex(t)

static func _ico_heal() -> Texture2D:
	var t := _img(24, 24)
	_rect(t, 9, 3, 6, 18, C("00E676"))
	_rect(t, 3, 9, 18, 6, C("00E676"))
	return _tex(t)

static func _ico_frag() -> Texture2D:
	var t := _img(24, 24)
	for y in 20:
		var ww := int(10 * sin((y + 2) / 22.0 * PI))
		_rect(t, 12 - ww / 2, y + 2, maxi(1, ww), 1, C("9d4edd"))
	_disc(t, 12, 12, 3, C("e0aaff"))
	return _tex(t)

static func _ico_skull(boss: bool) -> Texture2D:
	var t := _img(28, 28)
	_disc(t, 14, 16, 9, C("e8e4d8"))
	_rect(t, 9, 4, 10, 7, C("e8e4d8"))
	_disc(t, 10, 17, 3, C("101018"))
	_disc(t, 18, 17, 3, C("101018"))
	_rect(t, 11, 6, 2, 4, C("101018"))
	_rect(t, 15, 6, 2, 4, C("101018"))
	if boss:
		_rect(t, 2, 20, 5, 3, C("8B0000"))
		_rect(t, 21, 20, 5, 3, C("8B0000"))
	return _tex(t)

static func _ico_exit() -> Texture2D:
	var t := _img(24, 24)
	_rect(t, 4, 10, 12, 4, C("cfd6dd"))
	_rect(t, 14, 6, 4, 12, C("cfd6dd"))
	return _tex(t)

# ---------- tiles / walls / props ----------
static func _tile(base_c: Color, dark: Color, accent: Color, sandy: bool) -> Texture2D:
	var w := 64
	var h := 32
	var t := _img(w, h)
	for y in h:
		for x in w:
			var dx := absf(x - w / 2.0) / (w / 2.0)
			var dy := absf(y - h / 2.0) / (h / 2.0)
			if dx + dy <= 1.0:
				var c := base_c
				if dx + dy > 0.92: c = dark
				if G.chance(0.06): c = shade(base_c, 1.12 if sandy else 0.85)
				if G.chance(0.02): c = accent
				_p(t, x, y, c)
	return _tex(t)

static func _wall(top: Color, front: Color) -> Texture2D:
	var w := 64
	var h := 48
	var t := _img(w, h)
	for y in h:
		for x in w:
			var dx := absf(x - w / 2.0) / (w / 2.0)
			if y >= h - 16:
				var dyl := (y - (h - 16)) / 16.0
				if dx + absf(dyl) <= 1.0:
					_p(t, x, y, shade(top, 1.2) if G.chance(0.08) else top)
			else:
				var edge := 1.0 - (y / float(h - 16)) * 0.6
				if dx <= edge:
					_p(t, x, y, shade(front, 1.25) if G.chance(0.07) else front)
	return _tex(t)

static func _crate() -> Texture2D:
	var t := _img(26, 26)
	_rect(t, 2, 2, 22, 22, C("4a3a26"))
	_rect(t, 2, 2, 22, 3, C("2e2417"))
	_rect(t, 2, 21, 22, 3, C("6a5638"))
	_rect(t, 11, 2, 4, 22, C("2e2417"))
	_rect(t, 2, 11, 22, 4, C("2e2417"))
	return _tex(t, true)

static func _crystal(c: Color, hi: Color) -> Texture2D:
	var t := _img(28, 40)
	for y in range(6, 38):
		var ww := int(9 * sin((y - 6) / 34.0 * PI)) + 2
		_rect(t, 14 - ww / 2, y, ww, 1, c)
		if ww > 4: _rect(t, 13, y, 2, 1, hi)
	for y in range(14, 30):
		_rect(t, 6 - int(4 * sin((y - 14) / 16.0 * PI)) / 2, y, int(4 * sin((y - 14) / 16.0 * PI)), 1, shade(c, 0.8))
	for y in range(10, 26):
		_rect(t, 22 - int(4 * sin((y - 10) / 16.0 * PI)) / 2, y, int(4 * sin((y - 10) / 16.0 * PI)), 1, shade(c, 0.7))
	return _tex(t, true)

static func _rock() -> Texture2D:
	var t := _img(30, 22)
	_disc(t, 15, 8, 10, C("4a4038"))
	_disc(t, 10, 10, 5, C("5a5048"))
	_disc(t, 20, 9, 4, C("3a322c"))
	return _tex(t, true)

static func _bones() -> Texture2D:
	var t := _img(30, 18)
	_rect(t, 4, 6, 16, 3, C("cfc8b8"))
	_disc(t, 22, 8, 5, C("d8d2c2"))
	_p(t, 21, 9, C("101018")); _p(t, 24, 9, C("101018"))
	_rect(t, 6, 11, 10, 2, C("b8b0a0"))
	return _tex(t, true)

static func _vent() -> Texture2D:
	var t := _img(30, 16)
	_rect(t, 2, 2, 26, 12, C("33333e"))
	for i in 4:
		_rect(t, 4 + i * 6, 4, 3, 8, C("1a1a22"))
	_rect(t, 12, 6, 6, 4, C("ff5522"))
	return _tex(t, true)

static func _vat() -> Texture2D:
	var t := _img(34, 20)
	_disc(t, 17, 8, 13, C("22331a"))
	_disc(t, 17, 8, 10, C("39ff14"))
	for i in 4:
		_disc(t, 10 + i * 5, 8 + G.ri(-3, 3), 1, C("aaffaa"))
	return _tex(t, true)

static func _tent() -> Texture2D:
	var t := _img(40, 32)
	for y in 28:
		var ww := int(18 * (1 - y / 30.0))
		_rect(t, 20 - ww, y + 2, ww * 2, 1, C("4a3020") if y % 6 < 3 else C("3a2517"))
	_rect(t, 17, 2, 6, 10, C("1a120a"))
	_rect(t, 19, 28, 2, 4, C("2e1e12"))
	return _tex(t, true)

static func _campfire() -> Texture2D:
	var t := _img(26, 22)
	_rect(t, 6, 2, 14, 4, C("3a2a1a"))
	_rect(t, 8, 4, 10, 3, C("5a3a20"))
	_disc(t, 13, 10, 5, C("ff7722"))
	_disc(t, 13, 11, 3, C("ffcc44"))
	_disc(t, 13, 12, 1, Color.WHITE)
	return _tex(t, true)

static func _pillar() -> Texture2D:
	var t := _img(20, 48)
	_rect(t, 4, 0, 12, 44, C("2a2540"))
	_rect(t, 4, 0, 12, 4, C("1a1728"))
	_rect(t, 2, 42, 16, 6, C("3a3354"))
	_rect(t, 8, 8, 4, 30, C("8a7440"))
	return _tex(t, true)

static func _banner() -> Texture2D:
	var t := _img(18, 40)
	_rect(t, 3, 36, 12, 3, C("8a7440"))
	for y in 36:
		var ww := 10 - (y - 28 if y > 28 else 0)
		_rect(t, 9 - ww / 2, y, ww, 1, C("6a0d0d"))
	_disc(t, 9, 22, 3, C("c9a227"))
	return _tex(t, true)

static func _pod() -> Texture2D:
	var t := _img(24, 30)
	_disc(t, 12, 14, 9, C("4a6a3a"))
	_disc(t, 12, 16, 5, C("00E676"))
	_disc(t, 12, 16, 2, C("aaffcc"))
	for i in 5:
		_rect(t, 12 + int(cos(i * 1.26) * 8), 12 + int(sin(i * 1.26) * 10), 2, 4, C("33491f"))
	return _tex(t, true)

static func _wreck() -> Texture2D:
	var t := _img(44, 26)
	_rect(t, 4, 4, 30, 10, C("3a3a44"))
	_rect(t, 4, 4, 30, 3, C("22222a"))
	_rect(t, 30, 6, 10, 8, C("2a2a32"))
	_rect(t, 8, 14, 6, 4, C("ff5522"))
	for i in 6:
		_p(t, G.ri(4, 38), G.ri(4, 16), C("585868"))
	return _tex(t, true)

static func _door() -> Texture2D:
	var t := _img(40, 40)
	_rect(t, 4, 0, 32, 38, C("22222e"))
	_rect(t, 8, 0, 24, 34, C("101018"))
	_rect(t, 4, 0, 4, 38, C("3a3a4c"))
	_rect(t, 32, 0, 4, 38, C("3a3a4c"))
	_rect(t, 18, 16, 4, 6, C("8B0000"))
	return _tex(t, true)

static func _gate() -> Texture2D:
	var t := _img(56, 52)
	_rect(t, 2, 0, 8, 50, C("3a3428"))
	_rect(t, 46, 0, 8, 50, C("3a3428"))
	_rect(t, 2, 44, 52, 6, C("4a4034"))
	_rect(t, 10, 0, 36, 40, Color(0.05, 0.02, 0.08, 0.9))
	for i in 8:
		_p(t, 14 + i * 4, 20 + int(sin(i) * 8), C("7B1FA2"))
	return _tex(t, true)

static func _medic() -> Texture2D:
	var t := _img(30, 34)
	_rect(t, 2, 4, 26, 26, C("9aa0ac"))
	_rect(t, 2, 26, 26, 4, C("6a707c"))
	_rect(t, 11, 12, 8, 8, C("e8e8ee"))
	_rect(t, 14, 13, 2, 6, C("c0392b"))
	_rect(t, 12, 15, 6, 2, C("c0392b"))
	return _tex(t, true)

static func _drone() -> Texture2D:
	var t := _img(18, 16)
	_disc(t, 9, 8, 6, C("3a3a46"))
	_disc(t, 9, 8, 3, C("ff2222"))
	_rect(t, 0, 7, 4, 2, C("585868"))
	_rect(t, 14, 7, 4, 2, C("585868"))
	return _tex(t, true)

static func _turret() -> Texture2D:
	var t := _img(24, 26)
	_rect(t, 4, 0, 16, 8, C("2a2a34"))
	_rect(t, 6, 8, 12, 10, C("3a3a46"))
	_rect(t, 10, 18, 4, 6, C("22222a"))
	_disc(t, 12, 13, 3, C("ff2222"))
	return _tex(t, true)

# ======================================================================
#  V2 PRODUCTION ART
#  Layered sprites, real animation frames, portraits, biome backdrops,
#  detail tiles/walls, decals, icons, key art, light falloff texture.
#  All still code-drawn — but with detail passes (armor plates, glow
#  seams, pose variants) instead of flat primitives.
# ======================================================================

static var _c2 := {}
static var _cf := {}

static func S2(n: String) -> Texture2D:
	if _c2.has(n):
		return _c2[n]
	var t := _build2(n)
	_c2[n] = t
	return t

static func F(n: String) -> Dictionary:
	if _cf.has(n):
		return _cf[n]
	var d := _ext_frames(n)
	if d.is_empty():
		d = _mk_frames(n)
	_cf[n] = d
	return d

# ---------- external art (res://art, built from DCSS CC0 tileset) ----------

static var _ext := {}
const _AMF := preload("res://src/art_manifest.gd")
const _CMF := preload("res://src/concept_manifest.gd")
const _PMF := preload("res://src/paint_manifest.gd")
const _GMF := preload("res://src/gen_manifest.gd")

static func _ext_manifest() -> Dictionary:
	if _ext.is_empty():
		# priority: generated art > painted sprites > concept-art crops > DCSS tiles
		var sp := _AMF.SPRITES.duplicate()
		for k in _CMF.SPRITES:
			sp[k] = _CMF.SPRITES[k]
		for k in _PMF.SPRITES:
			sp[k] = _PMF.SPRITES[k]
		for k in _GMF.SPRITES:
			sp[k] = _GMF.SPRITES[k]
		var fr := _AMF.FRAMES.duplicate()
		for k in _CMF.FRAMES:
			fr[k] = _CMF.FRAMES[k]
		for k in _PMF.FRAMES:
			fr[k] = _PMF.FRAMES[k]
		for k in _GMF.frames():
			fr[k] = _GMF.frames()[k]
		_ext = {"sprites": sp, "frames": fr}
	return _ext

# Scale a body sprite so its current texture renders `px` pixels tall, and
# pick the right filter (linear for painted art, nearest for pixel tiles).
static func fit(body: Sprite2D, px: float) -> void:
	if not is_instance_valid(body) or body.texture == null:
		return
	var h := float(body.texture.get_height())
	body.scale = Vector2.ONE * (px / maxf(h, 1.0))
	body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if h > 80.0 else CanvasItem.TEXTURE_FILTER_NEAREST

static func _art_tex(path: String) -> Texture2D:
	var rp := "res://" + path
	if OS.has_feature("editor") and FileAccess.file_exists(rp):
		# dev: prefer raw bytes — the imported .ctex may be stale right
		# after art_src/build_art.py regenerates PNGs
		var img := Image.load_from_file(rp)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(rp):
		var t: Texture2D = load(rp)
		if t != null:
			return t
	return null

static func _ext_sprite(n: String) -> Texture2D:
	var m := _ext_manifest()
	var sprites: Dictionary = m.get("sprites", {})
	if sprites.has(n):
		return _art_tex(sprites[n])
	return null

static func _ext_frames(n: String) -> Dictionary:
	var out := {}
	var m := _ext_manifest()
	var frames: Dictionary = m.get("frames", {})
	if not frames.has(n):
		return out
	for anim in frames[n]:
		var arr: Array = []
		for p in frames[n][anim]:
			var t := _art_tex(p)
			if t != null:
				arr.append(t)
		if arr.size() > 0:
			out[anim] = arr
	return out

static func _build2(n: String) -> Texture2D:
	var ext := _ext_sprite(n)
	if ext != null:
		return ext
	if n.begins_with("por_"): return _portrait(n.substr(4))
	if n.begins_with("icn_"): return _icon2(n.substr(4))
	if n.begins_with("bg_"): return _backdrop(n.substr(3))
	if n.begins_with("dec_"): return _decal(n.substr(4))
	if n.begins_with("t2_"): return _tile2(n.substr(3))
	if n.begins_with("w2_"): return _wall2(n.substr(3))
	if n.begins_with("npc2_"): return _tex(_npc_fig(n.substr(5), {"bob": 0}), true)
	if n.begins_with("npcb_"): return _tex(_npc_fig(n.substr(5), {"bob": -1}), true)
	match n:
		"ico_camp": return _icon2("camp")
		"ico_run": return _icon2("run")
		"ico_loot": return _icon2("lootbag")
		"ico_quest": return _icon2("quest")
		"ico_map": return _icon2("run")
		"light": return _light_tex()
		"slash_arc": return _slash_arc()
		"title_bg": return _title_bg()
		"door2": return _door2()
		"gate2": return _gate2()
	var fb := _img(8, 8)
	_rect(fb, 0, 0, 8, 8, Color.MAGENTA)
	return _tex(fb)

# ---------- shared figure builder (humans/armored) ----------
# spec: w,h,bulk,armor,armor2,trim,glow,cloth,cape,helm,weapon,big_l,big_r,skin
# helm: 0 visor helm / 1 open eyes / 2 hood / 3 mask / 4 bare head
# weapon: 0 none / 1 blade / 2 staff / 3 spear / 4 injector / 5 claws
# pose: bob,ll,lr,lean,blade(angle|99=sheathed),blen,arm_fwd,charge,arm_up,
#       kneel,down,hurt,streak
static func _fig(s: Dictionary, p: Dictionary) -> Image:
	var w: int = s.get("w", 34)
	var h: int = s.get("h", 54)
	var t := _img(w, h)
	var cx := w / 2
	var bob: int = p.get("bob", 0)
	var ll: int = p.get("ll", 0)
	var lr: int = p.get("lr", 0)
	var ox := int(p.get("lean", 0.0) * 5.0)
	var ARM: Color = s.armor
	var ARM2: Color = s.armor2
	var TRM: Color = s.trim
	var GLW: Color = s.glow
	var CLO: Color = s.get("cloth", s.armor2)
	var feet := h - 3
	var leg_h := int(h * 0.26)
	var torso_h := int(h * 0.30)
	var torso_w := int(w * (0.40 + s.get("bulk", 1) * 0.07))
	var torso_y := feet - leg_h - torso_h + bob
	var head_h := int(h * 0.20)
	var head_y := torso_y - head_h + 2

	if p.get("down", false):
		# collapsed heap on the ground
		_rect(t, cx - 14, feet - 6, 22, 5, ARM2)
		_rect(t, cx - 12, feet - 8, 16, 3, ARM)
		_rect(t, cx + 8, feet - 7, 7, 4, ARM2)
		_rect(t, cx - 14, feet - 6, 4, 3, TRM)
		_p(t, cx + 10, feet - 6, GLW)
		return t

	# cape first (behind body)
	if s.get("cape", false):
		var cw := int(torso_w * 0.5)
		for y in range(torso_y + 2, feet - 2):
			var k := float(y - torso_y) / maxf(1.0, feet - torso_y)
			var ww := int(cw * (0.7 + k * 0.7))
			_rect(t, cx - ww - ox / 2, y, ww * 2, 1, shade(CLO, 0.75 + k * 0.15))
		# tattered hem
		for i in 3:
			_p(t, cx - cw / 2 + i * cw / 2, feet - 3 - G.ri(0, 3), shade(CLO, 0.6))

	# legs (feet plant on ground; bob does not lift them)
	var leg_w := maxi(3, torso_w / 4)
	var kneel: bool = p.get("kneel", false)
	var lh: int = int(leg_h / 2) if kneel else leg_h
	_rect(t, cx - 2 - leg_w + ll, feet - lh, leg_w, lh, ARM2)
	_rect(t, cx + 2 + lr, feet - lh, leg_w, lh, ARM2)
	_rect(t, cx - 2 - leg_w + ll, feet - 3, leg_w, 3, shade(ARM2, 0.6))
	_rect(t, cx + 2 + lr, feet - 3, leg_w, 3, shade(ARM2, 0.6))
	if kneel:
		_rect(t, cx - 2 - leg_w - 2, feet - lh - 3, leg_w + 2, 3, ARM2)

	# torso (shifts with lean/bob)
	var tx := cx - torso_w / 2 + ox
	_rect(t, tx, torso_y, torso_w, torso_h, ARM)
	_rect(t, tx, torso_y, torso_w, 2, shade(ARM, 0.6))
	_rect(t, tx + 1, torso_y + torso_h - 3, torso_w - 2, 2, shade(ARM, 1.35))
	_rect(t, tx, torso_y + 3, torso_w, 2, TRM)
	_disc(t, tx + torso_w / 2, torso_y + torso_h / 2 + 1, maxi(2, torso_w / 7), GLW)
	_p(t, tx + torso_w / 2, torso_y + torso_h / 2 + 1, Color.WHITE)
	_rect(t, tx, torso_y + torso_h - 1, torso_w, 1, TRM)
	# chest plate seam
	for yy in range(torso_y + 5, torso_y + torso_h - 4):
		_p(t, tx + torso_w / 2 - 1, yy, shade(ARM, 0.8))

	# pauldrons
	var pr: int = torso_w / 2 + s.get("bulk", 1)
	_disc(t, tx - pr / 3, torso_y + 3, pr, ARM2)
	_disc(t, tx + torso_w + pr / 3, torso_y + 3, int(pr * 1.15) if s.get("big_r", false) else pr, ARM2)
	_p(t, tx - pr / 3, torso_y + 2, TRM)
	_p(t, tx + torso_w + pr / 3, torso_y + 2, TRM)

	# arms
	var arm_w := maxi(3, w / 11)
	var arm_y := torso_y + 4
	var arm_h := torso_h - 2
	var l_arm_x := tx - arm_w - 1
	var r_arm_x := tx + torso_w + 1
	if s.get("big_l", false): arm_w = int(arm_w * 1.8)
	var r_arm_w := int(w / 7.0) if s.get("big_r", false) else arm_w
	if p.get("arm_fwd", false):
		# right arm extended forward (plasma charge pose)
		_rect(t, r_arm_x, arm_y + arm_h / 2 - 3, r_arm_w + 7, 7, shade(ARM, 1.15))
		var hx2 := r_arm_x + r_arm_w + 7
		var hy2 := arm_y + arm_h / 2
		_disc(t, hx2, hy2, 3, GLW)
		var cr := 3 + int(p.get("charge", 0.0) * 3.0)
		_disc(t, hx2, hy2, cr, Color(GLW.r, GLW.g, GLW.b, 0.5))
		_p(t, hx2, hy2, Color.WHITE)
	else:
		_rect(t, l_arm_x, arm_y, arm_w, arm_h, ARM)
		_rect(t, r_arm_x, arm_y, r_arm_w, arm_h, shade(ARM, 1.15) if s.get("big_r", false) else ARM)
		if s.get("big_r", false):
			_disc(t, r_arm_x + r_arm_w / 2, arm_y + arm_h, r_arm_w / 2, GLW)

	# weapon in left hand
	var hand := Vector2(l_arm_x + arm_w / 2, arm_y + arm_h)
	if p.get("w_front", false):
		hand = Vector2(tx + torso_w + 4, arm_y + arm_h - 6)
	var ba: float = p.get("blade", 99.0)
	match int(s.get("weapon", 0)):
		1:
			if ba > 90.0:
				_blade(t, int(hand.x), int(hand.y), -1.35, 14, GLW)
			else:
				_blade(t, int(hand.x), int(hand.y), ba, p.get("blen", 16), GLW)
		2:
			var sx := r_arm_x + r_arm_w / 2
			_rect(t, sx - 1, head_y - 4, 2, feet - head_y - 2, C("5a4632"))
			_disc(t, sx, head_y - 5, 4, GLW)
			_disc(t, sx, head_y - 5, 2, Color.WHITE)
		3:
			_blade(t, int(hand.x), int(hand.y), -1.1, 22, C("8a7a55"))
			_rect(t, int(hand.x + cos(-1.1) * 22) - 1, int(hand.y + sin(-1.1) * 22) - 1, 4, 4, C("cfd6dd"))
		4:
			_rect(t, int(hand.x) - 1, int(hand.y) - 6, 4, 8, GLW)
			_rect(t, int(hand.x), int(hand.y) - 9, 2, 3, Color.WHITE)
		5:
			for i in 3:
				_blade(t, int(hand.x) + i * 3 - 3, int(hand.y) + 2, 0.9 + i * 0.25, 6, GLW)

	if p.get("arm_up", false):
		_disc(t, tx + torso_w + 6, arm_y + 2, 5, Color(GLW.r, GLW.g, GLW.b, 0.55))
		_ring(t, tx + torso_w + 6, arm_y + 2, 6, 1, GLW)

	# head
	var hw := maxi(8, int(torso_w * 0.5))
	var hx := cx - hw / 2 + ox
	var helm := int(s.get("helm", 0))
	match helm:
		2: # hood
			_rect(t, hx - 2, head_y - 2, hw + 4, head_h + 5, CLO)
			_rect(t, hx + 1, head_y + 3, hw - 2, head_h - 3, shade(s.get("skin", C("b08968")), 0.45))
			_p(t, cx - 2 + ox, head_y + head_h / 2 + 1, GLW)
			_p(t, cx + 2 + ox, head_y + head_h / 2 + 1, GLW)
			_p(t, hx - 2, head_y - 2, shade(CLO, 1.4))
		3: # mask (Kirin)
			_rect(t, hx, head_y, hw, head_h, C("e8e8ee"))
			_rect(t, hx, head_y + head_h - 3, hw, 3, C("b8b8c4"))
			_rect(t, hx + hw / 2 - 1, head_y + 3, 2, 6, TRM)
			_p(t, hx + 2, head_y + head_h / 2, GLW)
			_p(t, hx + hw - 3, head_y + head_h / 2, GLW)
		4: # bare head
			_rect(t, hx, head_y + 2, hw, head_h - 1, s.get("skin", C("b08968")))
			_rect(t, hx, head_y, hw, 3, C("3a2c22"))
			_p(t, cx - 2 + ox, head_y + head_h / 2 + 2, C("181818"))
			_p(t, cx + 2 + ox, head_y + head_h / 2 + 2, C("181818"))
		_: # 0/1 helmet
			_rect(t, hx, head_y, hw, head_h, ARM)
			_rect(t, hx, head_y + head_h - 2, hw, 2, shade(ARM, 1.35))
			_rect(t, hx + 1, head_y - 2, hw - 2, 2, ARM2)
			if helm == 0:
				_rect(t, hx + 2, head_y + head_h / 2, hw - 4, 2, GLW)
			else:
				_p(t, cx - 2 + ox, head_y + head_h / 2, GLW)
				_p(t, cx + 2 + ox, head_y + head_h / 2, GLW)
			_rect(t, hx + hw / 4, head_y + head_h, hw / 2, 2, TRM)

	if p.get("hurt", false):
		_p(t, tx - 1, torso_y + 2, C("ff4444"))
		_p(t, tx + torso_w, torso_y + 6, C("ff4444"))
	if p.get("streak", false):
		for i in 3:
			_rect(t, cx - 16 - i * 4, torso_y + 4 + i * 6, 8, 1, Color(GLW.r, GLW.g, GLW.b, 0.5))
	return t

static func _blade(t: Image, hx: int, hy: int, ang: float, lng: int, edge: Color) -> void:
	for i in lng:
		var x := hx + int(cos(ang) * i)
		var y := hy + int(sin(ang) * i)
		_rect(t, x, y, 2, 2, C("cfd6dd"))
		if i % 3 == 0:
			_p(t, x, y - 1, edge)
		if i == lng - 1:
			_p(t, x + 1, y + 1, Color.WHITE)

static func _ft(s: Dictionary, p: Dictionary) -> Texture2D:
	return _tex(_fig(s, p), true)

# ---------- organic figure builder (proterian) ----------
# spec: w,h,flesh,flesh2,glow,limbs,eyes; pose: squash,sway,maw,lunge,gaze
static func _org(s: Dictionary, p: Dictionary) -> Image:
	var w: int = s.get("w", 34)
	var h: int = s.get("h", 40)
	var t := _img(w, h)
	var cx := w / 2
	var cy := int(h * 0.55)
	var squash: float = p.get("squash", 1.0)
	var flesh: Color = s.flesh
	var flesh2: Color = s.flesh2
	var GLW: Color = s.glow
	var R := int(mini(w, h) * 0.36)
	var ry := int(R * squash)
	# main mass (ellipse-ish via per-row width)
	for yy in range(-ry, ry + 1):
		var ww := int(R * sqrt(maxf(0.0, 1.0 - float(yy * yy) / float(ry * ry))))
		_rect(t, cx - ww, cy + yy, ww * 2, 1, flesh)
		if absi(yy) == ry / 3:
			_rect(t, cx - ww, cy + yy, ww * 2, 1, flesh2)
	# bumps / texture
	for i in 6:
		_disc(t, cx + G.ri(-R + 3, R - 3), cy + G.ri(-ry + 3, ry - 3), G.ri(1, 2), shade(flesh2, G.rf(0.7, 1.2)))
	# lower skirt (legs/roots)
	for i in 4:
		var lx := cx - R + 3 + i * int(R * 0.55)
		var lh := 4 + G.ri(0, 4)
		_rect(t, lx, cy + ry - 1, 3, lh, shade(flesh, 0.7))
	# limbs/claws
	var lunge: int = p.get("lunge", 0)
	var sway: int = p.get("sway", 0)
	for i in int(s.get("limbs", 4)):
		var a := -0.5 + i * (PI + 1.0) / maxf(1.0, s.get("limbs", 4) - 1.0) + PI
		var ext := int(w * 0.30) + (lunge if i >= s.get("limbs", 4) / 2 else 0)
		var lx := cx + int(cos(a) * ext) + sway
		var lyy := cy + int(sin(a) * ry) - 2
		for k in 4 + lunge / 2:
			_rect(t, lx + int(cos(a) * k), lyy + int(sin(a) * k), 2, 2, shade(flesh, 0.9))
		_rect(t, lx + int(cos(a) * (4 + lunge / 2)), lyy + int(sin(a) * (4 + lunge / 2)), 3, 2, C("cfc8b8"))
	# eyes cluster
	var gz: float = p.get("gaze", 1.0)
	var ey := cy - ry / 3
	for i in int(s.get("eyes", 3)):
		_disc(t, cx - s.get("eyes", 3) + i * 4, ey + (i % 2) * 2, 1 + (1 if gz > 1.2 else 0), GLW)
		if gz > 1.2:
			_p(t, cx - s.get("eyes", 3) + i * 4, ey + (i % 2) * 2, Color.WHITE)
	# maw
	if p.get("maw", 0) > 0:
		var mr := 4 + int(p.get("maw", 0)) * 2
		_disc(t, cx, cy + ry / 3, mr, C("140a10"))
		_ring(t, cx, cy + ry / 3, mr + 1, 2, shade(flesh2, 0.8))
		for i in 4:
			_p(t, cx - mr + 2 + i * int(mr * 0.5), cy + ry / 3 - mr + 1, C("e8e4d8"))
	# glow veins
	for i in 4:
		_p(t, cx + G.ri(-R + 2, R - 2), cy + G.ri(-ry + 2, ry - 2), GLW)
	return t

static func _ot(s: Dictionary, p: Dictionary) -> Texture2D:
	return _tex(_org(s, p), true)

# ---------- specs ----------
static var ELY_S := {"w":46,"h":62,"bulk":2,"armor":C("1d1d28"),"armor2":C("12121c"),"trim":C("7B1FA2"),"glow":C("00E5FF"),"cloth":C("241a2e"),"cape":true,"helm":0,"weapon":1,"big_r":true}
static var SENT_S := {"w":38,"h":56,"bulk":2,"armor":C("2a2f36"),"armor2":C("171b21"),"trim":C("8B0000"),"glow":C("ff2222"),"helm":0,"weapon":1,"big_r":false}
static var REX_S := {"w":52,"h":68,"bulk":3,"armor":C("2a1e20"),"armor2":C("181114"),"trim":C("8B0000"),"glow":C("ff2222"),"cloth":C("3a2c22"),"helm":1,"weapon":5,"big_l":true,"big_r":true}
static var REX_S2 := {"w":52,"h":68,"bulk":3,"armor":C("3a1a1a"),"armor2":C("221014"),"trim":C("ff2222"),"glow":C("ff6644"),"cloth":C("3a2c22"),"helm":1,"weapon":5,"big_l":true,"big_r":true}
static var NAHUM_S := {"w":34,"h":56,"bulk":2,"armor":C("33202a"),"armor2":C("1c1218"),"trim":C("8B0000"),"glow":C("ff3355"),"cloth":C("241418"),"cape":true,"helm":0,"weapon":1}
static var TUMAN_S := {"w":32,"h":54,"bulk":1,"armor":C("241c33"),"armor2":C("161022"),"trim":C("7B1FA2"),"glow":C("00E676"),"cloth":C("1c1428"),"cape":true,"helm":0,"weapon":2}
static var KIRIN_S := {"w":28,"h":58,"bulk":0,"armor":C("e8e8ee"),"armor2":C("b0b4c0"),"trim":C("8B0000"),"glow":C("00E676"),"cloth":C("e8e8ee"),"cape":true,"helm":3,"weapon":4}
static var CONST_S := {"w":32,"h":60,"bulk":0,"armor":C("14101c"),"armor2":C("0c0a12"),"trim":C("c9a227"),"glow":C("c9a227"),"cloth":C("14101c"),"cape":true,"helm":2,"weapon":2}
static var HUSK_S := {"w":38,"h":42,"flesh":C("4a6a2e"),"flesh2":C("33491f"),"glow":C("00E676"),"limbs":4,"eyes":3}
static var SPIT_S := {"w":38,"h":38,"flesh":C("5a7a2a"),"flesh2":C("3d5420"),"glow":C("aaff00"),"limbs":2,"eyes":4}
static var HOST_S := {"w":60,"h":64,"flesh":C("5e4a6a"),"flesh2":C("3e2e48"),"glow":C("ff3355"),"limbs":6,"eyes":6}

# ---------- animation frame sets ----------
static func _mk_frames(id: String) -> Dictionary:
	match id:
		"ely": return {
			"idle": [_ft(ELY_S, {"bob": 0}), _ft(ELY_S, {"bob": -1})],
			"run": [_ft(ELY_S, {"ll": -3, "lr": 3, "bob": 1}), _ft(ELY_S, {"ll": 0, "lr": 0, "bob": -1}),
					_ft(ELY_S, {"ll": 3, "lr": -3, "bob": 1}), _ft(ELY_S, {"ll": 0, "lr": 0, "bob": -1})],
			"atk1": [_ft(ELY_S, {"blade": -2.5, "lean": -0.15, "blen": 17}), _ft(ELY_S, {"blade": -0.35, "lean": 0.3, "ll": -2, "lr": 2, "blen": 17})],
			"atk2": [_ft(ELY_S, {"blade": 0.9, "lean": -0.15, "blen": 17}), _ft(ELY_S, {"blade": -1.35, "lean": 0.25, "ll": 2, "lr": -2, "blen": 17})],
			"atk3": [_ft(ELY_S, {"blade": -3.0, "lean": -0.2, "blen": 21}), _ft(ELY_S, {"blade": 0.95, "lean": 0.4, "ll": -3, "lr": 3, "blen": 21})],
			"dash": [_ft(ELY_S, {"lean": 0.45, "ll": -3, "lr": 4, "streak": true})],
			"parry": [_ft(ELY_S, {"blade": -1.57, "w_front": true, "blen": 18, "arm_up": true, "lean": 0.1})],
			"charge": [_ft(ELY_S, {"arm_fwd": true, "charge": 1.0, "lean": 0.15})],
			"hurt": [_ft(ELY_S, {"lean": -0.25, "bob": 2, "hurt": true})],
			"die": [_ft(ELY_S, {"kneel": true}), _ft(ELY_S, {"down": true})],
		}
		"husk": return {
			"idle": [_ot(HUSK_S, {"squash": 1.0, "sway": 0}), _ot(HUSK_S, {"squash": 0.92, "sway": 1})],
			"windup": [_ot(HUSK_S, {"squash": 0.8, "gaze": 1.4, "sway": -1})],
			"strike": [_ot(HUSK_S, {"squash": 1.15, "lunge": 5, "gaze": 1.4, "sway": 3})],
		}
		"spitter": return {
			"idle": [_ot(SPIT_S, {"squash": 1.0}), _ot(SPIT_S, {"squash": 0.94, "sway": 1})],
			"windup": [_ot(SPIT_S, {"squash": 1.1, "maw": 1, "gaze": 1.3})],
			"strike": [_ot(SPIT_S, {"squash": 0.85, "maw": 2, "lunge": 4})],
		}
		"drone": return {
			"idle": [_drone_f(0), _drone_f(1)],
			"windup": [_drone_f(2)],
			"strike": [_drone_f(2)],
		}
		"turret": return {
			"idle": [_turret_f(0), _turret_f(0)],
			"windup": [_turret_f(1)],
			"strike": [_turret_f(2)],
		}
		"sentinel": return {
			"idle": [_ft(SENT_S, {"bob": 0}), _ft(SENT_S, {"bob": -1})],
			"windup": [_ft(SENT_S, {"blade": -2.6, "lean": -0.15, "blen": 19})],
			"strike": [_ft(SENT_S, {"blade": -0.2, "lean": 0.35, "blen": 19})],
		}
		"rex": return {
			"idle": [_ft(REX_S, {"bob": 0}), _ft(REX_S, {"bob": -1})],
			"atk": [_ft(REX_S, {"lean": 0.3, "bob": 1})],
			"p2": [_ft(REX_S2, {"bob": 0, "hurt": true})],
		}
		"host": return {
			"idle": [_ot(HOST_S, {"squash": 1.0}), _ot(HOST_S, {"squash": 0.92, "sway": 2})],
			"atk": [_ot(HOST_S, {"squash": 1.12, "maw": 2, "lunge": 6, "gaze": 1.4})],
			"p2": [_ot(HOST_S, {"squash": 1.05, "maw": 1, "gaze": 1.4})],
		}
		"nahum": return {
			"idle": [_ft(NAHUM_S, {"bob": 0}), _ft(NAHUM_S, {"bob": -1})],
			"atk": [_ft(NAHUM_S, {"blade": -0.2, "lean": 0.35, "blen": 18})],
			"p2": [_ft(NAHUM_S, {"bob": 0, "hurt": true, "lean": 0.1})],
		}
		"tuman": return {
			"idle": [_ft(TUMAN_S, {"bob": 0}), _ft(TUMAN_S, {"bob": -1})],
			"atk": [_ft(TUMAN_S, {"lean": 0.2, "arm_fwd": true, "charge": 0.8})],
			"p2": [_ft(TUMAN_S, {"bob": 0, "hurt": true})],
		}
		"kirin": return {
			"idle": [_ft(KIRIN_S, {"bob": 0}), _ft(KIRIN_S, {"bob": -1})],
			"atk": [_ft(KIRIN_S, {"lean": 0.2, "arm_fwd": true, "charge": 0.7})],
			"p2": [_ft(KIRIN_S, {"bob": 0, "hurt": true})],
		}
		"const": return {
			"idle": [_ft(CONST_S, {"bob": 0}), _ft(CONST_S, {"bob": -1})],
			"atk": [_ft(CONST_S, {"lean": 0.2, "arm_fwd": true, "charge": 0.9})],
			"p2": [_ft(CONST_S, {"bob": 0, "hurt": true})],
		}
	return {"idle": [S("dot")]}

static func _drone_f(f: int) -> Texture2D:
	var t := _img(24, 22)
	var body_c := C("3a3a46") if f < 2 else C("5a2a2a")
	_disc(t, 12, 11, 7, body_c)
	_disc(t, 12, 11, 4, C("24242e"))
	var eye := C("ff2222") if f == 2 else C("ff5522")
	_disc(t, 12, 11, 3 if f == 2 else 2, eye)
	# rotor blur
	_rect(t, 2, 4 + f, 8, 2, C("585868"))
	_rect(t, 14, 6 - f, 8, 2, C("585868"))
	_p(t, 12, 2, C("00E5FF"))
	return _tex(t, true)

static func _turret_f(f: int) -> Texture2D:
	var t := _img(28, 32)
	_rect(t, 4, 26, 20, 4, C("22222a"))
	_rect(t, 6, 18, 16, 8, C("3a3a46"))
	_rect(t, 8, 20, 12, 2, C("24242e"))
	# barrel
	var by := 8 if f >= 1 else 12
	_rect(t, 12, by, 4, 18 - by, C("2a2a34"))
	_disc(t, 14, by, 3, C("ff2222") if f >= 1 else C("662222"))
	if f == 2:
		_disc(t, 14, by - 2, 4, Color(1, 0.4, 0.2, 0.7))
	# core
	_disc(t, 14, 22, 3, C("ff2222") if f >= 1 else C("7a3333"))
	_rect(t, 4, 18, 2, 8, C("4a4a58"))
	_rect(t, 22, 18, 2, 8, C("4a4a58"))
	return _tex(t, true)

# ---------- NPC figures (idle pose only, bigger & detailed) ----------
static func _npc_fig(id: String, p: Dictionary) -> Image:
	match id:
		"rhasa": return _fig({"w":44,"h":60,"bulk":3,"armor":C("3a3428"),"armor2":C("26221a"),"trim":C("a8842f"),"glow":C("ffb74d"),"cloth":C("5c2e22"),"cape":true,"helm":4,"weapon":1,"skin":C("8a5a3a")}, p)
		"neva": return _fig({"w":28,"h":50,"bulk":0,"armor":C("241a30"),"armor2":C("181020"),"trim":C("7B1FA2"),"glow":C("c26bff"),"cloth":C("241a30"),"helm":2,"weapon":2,"skin":C("caa27a")}, p)
		"saphire": return _fig({"w":32,"h":52,"bulk":0,"armor":C("4a3020"),"armor2":C("2e1e12"),"trim":C("d0a040"),"glow":C("00E676"),"cloth":C("4a3020"),"helm":4,"weapon":3,"skin":C("8a5a34")}, p)
		"vane": return _fig({"w":32,"h":54,"bulk":0,"armor":C("c8ccd4"),"armor2":C("9aa0ac"),"trim":C("3a7a3a"),"glow":C("00E5FF"),"cloth":C("c8ccd4"),"cape":true,"helm":4,"weapon":4,"skin":C("caa27a")}, p)
	return _img(8, 8)

# ---------- light falloff ----------
static func _light_tex() -> Texture2D:
	var t := _img(128, 128)
	for y in 128:
		for x in 128:
			var dx := float(x - 64)
			var dy := float(y - 64)
			var d := sqrt(dx * dx + dy * dy) / 64.0
			if d < 1.0:
				_p(t, x, y, Color(1, 1, 1, pow(1.0 - d, 1.7)))
	return _tex(t)

# ---------- slash arc (blade trail) ----------
static func _slash_arc() -> Texture2D:
	var t := _img(96, 96)
	for y in 96:
		for x in 96:
			var dx := float(x - 48)
			var dy := float(y - 48)
			var r := sqrt(dx * dx + dy * dy)
			if r < 26.0 or r > 46.0:
				continue
			var a := atan2(dy, dx)
			if absf(a) > 1.25:
				continue
			var edge := (1.25 - absf(a)) / 1.25
			var rad := 1.0 - absf(r - 36.0) / 10.0
			_p(t, x, y, Color(1, 1, 1, clampf(edge * rad * 0.9, 0.0, 1.0)))
	return _tex(t)

# ---------- doors v2 ----------
static func _door2() -> Texture2D:
	var t := _img(56, 64)
	# pillars
	_rect(t, 2, 8, 10, 54, C("2e2e3c"))
	_rect(t, 44, 8, 10, 54, C("2e2e3c"))
	_rect(t, 2, 8, 10, 4, C("4a4a5c"))
	_rect(t, 44, 8, 10, 4, C("4a4a5c"))
	# lintel arch
	_rect(t, 2, 0, 52, 10, C("3a3a4c"))
	_rect(t, 8, 4, 40, 6, C("2e2e3c"))
	# inner darkness
	_rect(t, 12, 10, 32, 52, C("0a0a12"))
	for y in range(14, 60, 6):
		_rect(t, 14, y, 28, 1, C("12121c"))
	# frame rivets
	for i in 4:
		_p(t, 6, 14 + i * 12, C("585868"))
		_p(t, 48, 14 + i * 12, C("585868"))
	# lock slit
	_rect(t, 26, 30, 4, 8, C("8B0000"))
	return _tex(t, true)

static func _gate2() -> Texture2D:
	var t := _img(72, 80)
	# obsidian pillars with choralim engravings
	_rect(t, 2, 6, 12, 72, C("1c1626"))
	_rect(t, 58, 6, 12, 72, C("1c1626"))
	_rect(t, 2, 6, 12, 4, C("342a44"))
	_rect(t, 58, 6, 12, 4, C("342a44"))
	for i in 5:
		_rect(t, 6, 16 + i * 12, 4, 6, C("7B1FA2"))
		_rect(t, 62, 16 + i * 12, 4, 6, C("7B1FA2"))
	# arch
	_rect(t, 2, 0, 68, 8, C("241c33"))
	_rect(t, 10, 8, 52, 6, C("1c1626"))
	# portal void
	_rect(t, 14, 14, 44, 64, Color(0.03, 0.01, 0.06, 0.96))
	for i in 14:
		var px := 18 + G.ri(0, 36)
		var py := 18 + G.ri(0, 56)
		_p(t, px, py, C("7B1FA2") if i % 3 else C("00E5FF"))
		if i % 4 == 0:
			_p(t, px + 1, py, C("c26bff"))
	# top glyph
	_disc(t, 36, 4, 3, C("c26bff"))
	return _tex(t, true)

# ---------- detail tiles (64x32 iso, 3 variants per biome) ----------
static func _tile2(key: String) -> Texture2D:
	var parts := key.split("_")
	var b := parts[0]
	var v := int(parts[1]) if parts.size() > 1 else 0
	var base: Color
	var dark: Color
	var acc: Color
	match b:
		"0": base = C("6b4a2e"); dark = C("4a3018"); acc = C("8a6a3a")
		"1": base = C("2e2e3c"); dark = C("1e1e28"); acc = C("3d3d52")
		"2": base = C("36322e"); dark = C("262220"); acc = C("4a4038")
		"3": base = C("1e1c2a"); dark = C("12101c"); acc = C("8a7440")
		_: base = C("5c4326"); dark = C("42301c"); acc = C("6e5232")  # hub
	var t := _img(64, 32)
	for y in 32:
		for x in 64:
			var dx := absf(x - 32.0) / 32.0
			var dy := absf(y - 16.0) / 16.0
			if dx + dy <= 1.0:
				var c := base
				if dx + dy > 0.9: c = dark
				elif G.chance(0.07): c = shade(base, 1.1)
				elif G.chance(0.04): c = shade(base, 0.82)
				_p(t, x, y, c)
	# variant detail
	match v:
		1: # cracks / seams
			for i in 3:
				var sx := 32 + G.ri(-18, 18)
				var sy := 16 + G.ri(-6, 6)
				for k in G.ri(4, 9):
					sx += G.ri(-2, 2); sy += G.ri(-1, 1)
					_p(t, sx, sy, shade(dark, 0.7))
		2: # biome feature accents
			match b:
				"0":
					for i in 6: _p(t, 32 + G.ri(-20, 20), 16 + G.ri(-8, 8), C("c9a227"))
					_p(t, 30, 14, C("d8d2c2")); _p(t, 34, 18, C("d8d2c2"))
				"1":
					_rect(t, 20, 14, 24, 1, shade(dark, 0.8))
					_rect(t, 20, 18, 24, 1, shade(dark, 0.8))
					for i in 4: _p(t, 22 + i * 6, 15, C("585868")); _p(t, 22 + i * 6, 19, C("585868"))
				"2":
					_rect(t, 18, 15, 28, 1, C("6a3a20"))
					_rect(t, 18, 19, 28, 1, C("6a3a20"))
					for i in 3: _p(t, 24 + i * 8, 17, C("ff7722"))
				"3":
					for i in 4:
						_p(t, 32 + G.ri(-16, 16), 16 + G.ri(-6, 6), acc)
					_ring(t, 32, 16, 6, 1, shade(acc, 0.7))
				_:
					_rect(t, 20, 12, 2, 10, shade(dark, 0.9))
					_rect(t, 40, 12, 2, 10, shade(dark, 0.9))
	return _tex(t)

# ---------- walls v2 (64x56, per-biome detail) ----------
static func _wall2(key: String) -> Texture2D:
	var top: Color
	var front: Color
	var acc: Color
	match key:
		"0": top = C("5a3e24"); front = C("3a2818"); acc = C("8a6a3a")
		"1": top = C("3c3c50"); front = C("262633"); acc = C("00E676")
		"2": top = C("4a4440"); front = C("2e2926"); acc = C("ff7722")
		"3": top = C("322c4a"); front = C("1c1830"); acc = C("c9a227")
		"4": top = C("2e4432"); front = C("16251c"); acc = C("66bb6a")
		"6": top = C("7a4a2e"); front = C("4a2c1c"); acc = C("ff9944")
		_: top = C("5f452a"); front = C("3a2818"); acc = C("a8842f")
	var t := _img(64, 56)
	for y in 56:
		for x in 64:
			var dx := absf(x - 32.0) / 32.0
			if y >= 40:
				var dyl := (y - 40) / 16.0
				if dx + absf(dyl) <= 1.0:
					_p(t, x, y, shade(top, 1.15) if G.chance(0.08) else top)
			else:
				var edge := 1.0 - (y / 40.0) * 0.55
				if dx <= edge:
					_p(t, x, y, shade(front, 1.2) if G.chance(0.06) else front)
	# per-biome face detail
	match key:
		"0", "hub":
			for i in 3:
				_rect(t, 8 + i * 4, 16 + i * 8, 40 - i * 8, 2, shade(front, 0.75))
			_p(t, 18, 22, acc); _p(t, 44, 30, acc)
		"1":
			for i in 2:
				_rect(t, 12 + i * 22, 10, 18, 22, shade(front, 0.85))
				_rect(t, 12 + i * 22, 10, 18, 2, shade(front, 1.3))
				for r in 4: _p(t, 14 + i * 22 + r * 4, 28, C("585868"))
			_rect(t, 12, 34, 40, 2, acc)
		"2":
			for i in 2:
				_rect(t, 10 + i * 24, 8, 20, 26, shade(front, 0.9))
				_rect(t, 10 + i * 24, 8, 20, 2, shade(front, 1.35))
			_rect(t, 14, 36, 36, 2, shade(acc, 0.6))
			_p(t, 30, 20, acc); _p(t, 46, 14, acc)
		"3":
			for i in 3:
				_rect(t, 14 + i * 12, 12, 6, 16, shade(front, 0.8))
				_p(t, 16 + i * 12, 16, acc)
				_p(t, 17 + i * 12, 22, acc)
			_rect(t, 10, 32, 44, 2, shade(acc, 0.5))
		"6":
			for i in 2:
				_rect(t, 8 + i * 24, 10, 20, 26, shade(front, 0.9))
				_rect(t, 8 + i * 24, 10, 20, 2, shade(top, 1.35))
			_rect(t, 10, 34, 44, 2, shade(acc, 0.6))
			_p(t, 22, 18, acc); _p(t, 48, 24, acc)
	return _tex(t)

# ---------- biome backdrops (1180x200 silhouette strip) ----------
static func _backdrop(key: String) -> Texture2D:
	var t := _img(1180, 200)
	var sky1: Color
	var sky2: Color
	var sil: Color
	var glow: Color
	match key:
		"0": sky1 = Color(0.10, 0.05, 0.14); sky2 = Color(0.22, 0.10, 0.22); sil = C("1a1020"); glow = C("7B1FA2")
		"1": sky1 = Color(0.04, 0.08, 0.08); sky2 = Color(0.08, 0.16, 0.12); sil = C("0e1a14"); glow = C("00E676")
		"2": sky1 = Color(0.10, 0.06, 0.05); sky2 = Color(0.20, 0.10, 0.06); sil = C("1c1210"); glow = C("ff7722")
		"3": sky1 = Color(0.06, 0.04, 0.12); sky2 = Color(0.14, 0.10, 0.24); sil = C("120e20"); glow = C("c9a227")
		"6": sky1 = Color(0.14, 0.06, 0.03); sky2 = Color(0.30, 0.12, 0.06); sil = C("22120c"); glow = C("ff9944")
		_: sky1 = Color(0.10, 0.06, 0.10); sky2 = Color(0.20, 0.12, 0.14); sil = C("1a1210"); glow = C("ffb74d")
	# sky gradient (alpha fades toward bottom so it blends with the dark)
	for y in 200:
		var k := y / 200.0
		for x in 1180:
			var c := sky1.lerp(sky2, k)
			c.a = clampf(1.2 - k * 1.6, 0.0, 0.9)
			_p(t, x, y, c)
	# horizon glow band
	for y in range(90, 130):
		for x in 1180:
			var a := (1.0 - absf(y - 110.0) / 20.0) * 0.16
			var px := t.get_pixel(x, y)
			_p(t, x, y, Color(glow.r, glow.g, glow.b, maxf(px.a, a)))
	# silhouettes per biome
	match key:
		"0":
			for i in 7: # dune ridges
				var bx := i * 190 + G.ri(-30, 30)
				for x2 in 200:
					var hh := int(30 + sin((x2 + bx) * 0.02) * 18)
					for y2 in range(160 - hh, 200):
						_p(t, bx + x2, y2, sil)
			for i in 5: # wreck ribs
				var bx := 100 + i * 240
				_rect(t, bx, 120, 4, 40 + G.ri(0, 20), sil)
				_rect(t, bx - 8, 126 + G.ri(0, 8), 20, 4, sil)
			for i in 8:
				_p(t, G.ri(0, 1179), G.ri(95, 125), glow)
		"1":
			for i in 6: # rock pillars
				var bx := i * 210 + G.ri(-20, 40)
				var pw := G.ri(20, 42)
				_rect(t, bx, 60 + G.ri(0, 40), pw, 200, sil)
				_rect(t, bx - 4, 60 + G.ri(0, 30), pw + 8, 8, sil)
			for i in 4: # hanging cables
				var sx := G.ri(60, 1100)
				for x2 in 90:
					var yy := 40 + int(sin(x2 * 0.06 + i) * 10) + x2 / 3
					_p(t, sx + x2, yy, sil)
			for i in 10:
				_p(t, G.ri(0, 1179), G.ri(80, 140), glow)
		"2":
			for i in 4: # massive hull plates
				var bx := i * 300 + G.ri(-40, 40)
				for x2 in 240:
					var hh := int(60 + x2 * 0.35 + sin(i * 2.0) * 20)
					for y2 in range(maxi(0, 170 - hh), 200):
						_p(t, bx + x2, y2, sil)
			for i in 3: # engine rings
				_ring(t, 200 + i * 380, 120, 24, 5, sil)
			for i in 8:
				_p(t, G.ri(0, 1179), G.ri(100, 150), glow)
		"3":
			for i in 5: # spires
				var bx := 90 + i * 250 + G.ri(-30, 30)
				var pw := G.ri(14, 26)
				var ph := G.ri(90, 170)
				for y2 in range(200 - ph, 200):
					var ww := int(pw * (1.0 - (y2 - (200 - ph)) / float(ph) * 0.7))
					_rect(t, bx - ww / 2, y2, ww, 1, sil)
				_disc(t, bx, 200 - ph - 4, 3, glow)
			for i in 2: # halo arcs
				_ring(t, 400 + i * 400, 90, 40 + i * 16, 2, shade(sil, 1.4))
			for i in 12:
				_p(t, G.ri(0, 1179), G.ri(60, 140), glow)
		_:
			# hub: camp wall + watchtower + gate
			_rect(t, 0, 150, 1180, 50, sil)
			for x2 in range(0, 1180, 60):
				_rect(t, x2, 142, 30, 10, sil)
			_rect(t, 200, 90, 30, 70, sil)
			_rect(t, 192, 82, 46, 12, sil)
			_rect(t, 560, 110, 60, 50, sil)
			_rect(t, 576, 96, 28, 16, sil)
			for i in 10:
				_p(t, G.ri(0, 1179), G.ri(120, 150), glow)
	return _tex(t)

# ---------- floor decals ----------
static func _decal(key: String) -> Texture2D:
	var parts := key.split("_")
	var kind := parts[0]
	var t: Image
	match kind:
		"crack":
			t = _img(26, 16)
			var x := 12; var y := 2
			for i in 10:
				_p(t, x, y, Color(0, 0, 0, 0.5))
				x += G.ri(-3, 3); y += G.ri(0, 2)
				if i % 3 == 0:
					_p(t, x + G.ri(-3, 3), y, Color(0, 0, 0, 0.35))
		"stain":
			t = _img(30, 20)
			for i in 6:
				_disc(t, 15 + G.ri(-8, 8), 10 + G.ri(-5, 5), G.ri(2, 5), Color(0, 0, 0, 0.28))
		"scrap":
			t = _img(24, 14)
			_rect(t, 4, 6, 10, 4, C("3a3a44"))
			_rect(t, 16, 4, 6, 3, C("2e2e38"))
			_p(t, 8, 5, C("585868")); _p(t, 18, 8, C("585868"))
		"tuft":
			t = _img(20, 16)
			for i in 5:
				var bx := 4 + i * 3
				var hh := G.ri(6, 12)
				for yy in hh:
					_p(t, bx + int(sin(yy * 0.5 + i) * 1.5), 15 - yy, C("4a6a2e") if i % 2 else C("5a7a2a"))
		"vein":
			t = _img(30, 12)
			var x2 := 2; var y2 := 6
			for i in 12:
				_p(t, x2, y2, C("8a7440")); x2 += 2; y2 += G.ri(-2, 2)
				if i % 4 == 0: _p(t, x2, y2 - 1, C("c9a227"))
		"rubble":
			t = _img(22, 12)
			for i in 7:
				_disc(t, 4 + G.ri(0, 14), 8 + G.ri(-3, 3), G.ri(1, 2), C("4a4038") if i % 2 else C("5a5048"))
		_:
			t = _img(8, 8)
	return _tex(t)

# ---------- icons (22px glyphs) ----------
static func _icon2(key: String) -> Texture2D:
	var t := _img(22, 22)
	match key:
		"rhasa":
			_blade(t, 5, 16, -0.8, 12, C("a8842f"))
			_rect(t, 4, 4, 3, 3, C("a8842f")); _rect(t, 15, 4, 3, 3, C("a8842f"))
			_rect(t, 8, 6, 6, 2, C("a8842f"))
		"neva":
			_disc(t, 11, 11, 6, C("7B1FA2"))
			_ring(t, 11, 11, 8, 1, C("c26bff"))
			_p(t, 11, 11, Color.WHITE)
		"saphire":
			for i in 3:
				_blade(t, 4 + i * 6, 18, -1.2, 12, C("00E676"))
		"rex":
			_rect(t, 10, 2, 4, 8, C("ff4444"))
			_rect(t, 8, 8, 6, 4, C("ff4444"))
			_rect(t, 10, 12, 4, 8, C("ff4444"))
			_p(t, 9, 9, C("ffcccc"))
		"kovan":
			for i in 6:
				var a := i * TAU / 6.0
				_disc(t, 11 + int(cos(a) * 7), 11 + int(sin(a) * 7), 2, C("39ff14"))
			_disc(t, 11, 11, 3, C("39ff14"))
		"upg_hp":
			_disc(t, 8, 9, 4, C("ff5566")); _disc(t, 14, 9, 4, C("ff5566"))
			_rect(t, 6, 10, 10, 6, C("ff5566"))
		"upg_dmg":
			_blade(t, 5, 17, -0.8, 14, C("ff8844"))
		"upg_dash":
			_rect(t, 3, 10, 12, 3, C("00E5FF"))
			_rect(t, 11, 6, 8, 3, C("00E5FF"))
			_rect(t, 11, 14, 8, 3, C("00E5FF"))
		"upg_revive":
			_ring(t, 11, 11, 7, 2, C("c26bff"))
			_blade(t, 11, 17, -1.57, 8, C("c26bff"))
		"upg_frag":
			_rect(t, 8, 4, 6, 6, C("9d4edd"))
			_rect(t, 6, 8, 10, 6, C("9d4edd"))
			_rect(t, 9, 14, 4, 4, C("9d4edd"))
		"upg_shield":
			_rect(t, 6, 4, 10, 10, C("8899aa"))
			_rect(t, 8, 14, 6, 4, C("8899aa"))
			_rect(t, 10, 6, 2, 8, C("c9d4dd"))
		"dash":
			for y in 10:
				var ww := int(7 * sin((y + 1) / 11.0 * PI))
				_rect(t, 11 - ww, y + 6, ww * 2, 1, Color.WHITE)
		"plasma":
			_disc(t, 11, 11, 6, C("00E5FF"))
			_disc(t, 11, 11, 3, Color.WHITE)
		"stance_cleave":
			_blade(t, 4, 16, -0.9, 15, C("a8842f"))
			_rect(t, 14, 4, 4, 12, C("a8842f"))
		"stance_duel":
			_blade(t, 6, 16, -1.1, 16, C("00E5FF"))
			_p(t, 6, 16, C("cfd6dd"))
		"skull":
			_disc(t, 11, 12, 7, C("e8e4d8"))
			_rect(t, 7, 4, 8, 6, C("e8e4d8"))
			_disc(t, 8, 12, 2, C("101018")); _disc(t, 14, 12, 2, C("101018"))
		"crown":
			_rect(t, 5, 14, 12, 4, C("c9a227"))
			for i in 3:
				_rect(t, 5 + i * 5, 6, 3, 8, C("c9a227"))
			_disc(t, 11, 12, 2, C("00E5FF"))
		"dagger":
			_blade(t, 6, 18, -0.6, 14, C("cfd6dd"))
			_rect(t, 4, 16, 5, 3, C("5a4632"))
		"sword":
			_blade(t, 5, 17, -0.7, 15, C("cfd6dd"))
			_rect(t, 3, 15, 7, 3, C("a8842f"))
			_rect(t, 5, 18, 2, 3, C("5a4632"))
		"zap":
			_blade(t, 13, 3, 0.6, 9, C("ffe066"))
			_blade(t, 9, 12, 0.6, 9, C("ffe066"))
		"mine":
			_disc(t, 11, 13, 6, C("00E676"))
			_blade(t, 11, 4, 0.0, 6, C("5a4632"))
			_blade(t, 11, 4, 1.2, 6, C("5a4632"))
			_blade(t, 11, 4, -1.2, 6, C("5a4632"))
		"camp":
			_disc(t, 11, 14, 6, C("ff9e4d"))
			_rect(t, 9, 10, 4, 4, C("ffe066"))
			_rect(t, 5, 16, 12, 2, C("5a4632"))
		"run":
			_rect(t, 4, 4, 4, 8, C("00E5FF"))
			_blade(t, 8, 8, 0.6, 10, C("00E5FF"))
		"lootbag":
			_disc(t, 11, 14, 7, C("8a6a3a"))
			_rect(t, 8, 4, 6, 4, C("6a4a26"))
			_disc(t, 11, 14, 3, C("ffd700"))
		"quest":
			_rect(t, 5, 3, 12, 16, C("e8dcc0"))
			_rect(t, 7, 6, 8, 1, C("4a3220"))
			_rect(t, 7, 9, 8, 1, C("4a3220"))
			_rect(t, 7, 12, 5, 1, C("4a3220"))
			_disc(t, 15, 16, 2, C("8B0000"))
		_:
			_disc(t, 11, 11, 6, C("7B1FA2"))
			_disc(t, 11, 11, 3, C("00E5FF"))
	return _tex(t, true)

# ---------- portraits (56x56 busts) ----------
static func _portrait(id: String) -> Texture2D:
	var t := _img(56, 56)
	# dark backdrop glow
	_disc(t, 28, 30, 24, Color(0.10, 0.06, 0.14))
	_disc(t, 28, 30, 20, Color(0.05, 0.03, 0.08))
	var skin := C("b08968")
	var armor := C("1c1c26")
	var trim := C("7B1FA2")
	var glow := C("00E5FF")
	var hood := false
	var mask := 0  # 0 face / 1 visor / 2 full mask / 3 organic
	match id:
		"rhasa": skin = C("8a5a3a"); armor = C("3a3428"); trim = C("a8842f"); glow = C("ffb74d")
		"neva": skin = C("caa27a"); armor = C("241a30"); trim = C("7B1FA2"); glow = C("c26bff"); hood = true
		"saphire": skin = C("8a5a34"); armor = C("4a3020"); trim = C("d0a040"); glow = C("00E676")
		"vane": skin = C("caa27a"); armor = C("c8ccd4"); trim = C("3a7a3a"); glow = C("00E5FF"); mask = 2
		"rex": skin = C("7a5a4a"); armor = C("2a1e20"); trim = C("8B0000"); glow = C("ff2222"); mask = 1
		"host": mask = 3; armor = C("5e4a6a"); trim = C("3e2e48"); glow = C("ff3355")
		"nahum": skin = C("9a7a5a"); armor = C("33202a"); trim = C("8B0000"); glow = C("ff3355"); mask = 1
		"tuman": skin = C("9a7a5a"); armor = C("241c33"); trim = C("7B1FA2"); glow = C("00E676"); mask = 1
		"kirin": skin = C("d8b090"); armor = C("e8e8ee"); trim = C("8B0000"); glow = C("00E676"); mask = 2
		"const": skin = C("c9b8a0"); armor = C("14101c"); trim = C("c9a227"); glow = C("c9a227"); mask = 1
		"ely": armor = C("1d1d28"); trim = C("7B1FA2"); glow = C("00E5FF"); mask = 1
	# shoulders
	_rect(t, 12, 42, 32, 14, armor)
	_rect(t, 12, 42, 32, 3, trim)
	_disc(t, 14, 44, 6, shade(armor, 0.8))
	_disc(t, 42, 44, 6, shade(armor, 0.8))
	if mask == 3:
		# organic maw bust
		_disc(t, 28, 26, 16, armor)
		_disc(t, 28, 30, 10, trim)
		for i in 5:
			_disc(t, 20 + i * 4, 20 + (i % 2) * 3, 2, glow)
		_disc(t, 28, 32, 6, C("140a10"))
		for i in 3:
			_p(t, 24 + i * 4, 28, C("e8e4d8"))
		return _tex(t, true)
	# neck + head
	_rect(t, 24, 34, 8, 9, shade(skin, 0.8))
	if hood:
		_rect(t, 12, 4, 32, 38, armor)
		_rect(t, 18, 12, 20, 24, shade(skin, 0.5))
		_disc(t, 28, 24, 8, shade(skin, 0.55))
		_p(t, 24, 24, glow); _p(t, 32, 24, glow)
		_p(t, 24, 25, glow); _p(t, 32, 25, glow)
		_rect(t, 12, 4, 32, 4, shade(armor, 1.3))
	else:
		_disc(t, 28, 22, 13, skin)
		_rect(t, 16, 12, 24, 10, armor)   # helm/hair top
		_rect(t, 16, 12, 24, 3, shade(armor, 1.3))
		match mask:
			0:
				_p(t, 23, 22, C("181818")); _p(t, 33, 22, C("181818"))
				_p(t, 23, 21, C("181818")); _p(t, 33, 21, C("181818"))
				_rect(t, 25, 30, 6, 1, shade(skin, 0.7))
				if id == "rhasa":
					_rect(t, 20, 18, 2, 10, shade(skin, 0.6))   # scar
					_rect(t, 15, 20, 6, 3, trim)              # eyepatch strap
					_p(t, 21, 21, C("101018"))
				if id == "saphire":
					_rect(t, 20, 16, 16, 3, C("2e1e12"))      # goggles up
					_p(t, 23, 17, glow); _p(t, 33, 17, glow)
					_p(t, 19, 26, glow)                        # warpaint
					_p(t, 37, 26, glow)
			1:
				_rect(t, 17, 19, 22, 6, armor)
				_rect(t, 19, 20, 18, 3, glow)
				_rect(t, 26, 26, 4, 8, shade(armor, 0.8))
				if id == "rex":
					for i in 4:
						_p(t, 36 + G.ri(0, 4), 14 + i * 6, trim)  # corruption scars
			2:
				_rect(t, 19, 16, 18, 16, armor)
				_rect(t, 19, 16, 18, 4, shade(armor, 0.85))
				if id == "vane":
					_disc(t, 23, 21, 3, shade(armor, 0.6))    # round lenses
					_disc(t, 33, 21, 3, shade(armor, 0.6))
					_p(t, 23, 21, glow); _p(t, 33, 21, glow)
					_rect(t, 24, 28, 8, 3, C("e8e8ee"))       # surgical mask
					_rect(t, 15, 8, 26, 5, C("9aa0ac"))       # hair
				else:
					_p(t, 23, 22, glow); _p(t, 33, 22, glow)
					_rect(t, 26, 20, 4, 8, trim)
	return _tex(t, true)

# ---------- title key art (1280x720) ----------
static func _title_bg() -> Texture2D:
	var t := _img(1280, 720)
	# sky: near-black violet to deep purple horizon
	for y in 720:
		var k := y / 720.0
		for x in 1280:
			var c: Color
			if k < 0.55:
				c = Color(0.02, 0.01, 0.05).lerp(Color(0.16, 0.06, 0.22), k / 0.55)
			else:
				c = Color(0.16, 0.06, 0.22).lerp(Color(0.05, 0.02, 0.08), (k - 0.55) / 0.45)
			_p(t, x, y, c)
	# choralim halo
	for r in range(150, 40, -1):
		var a := 0.05 + (150 - r) / 150.0 * 0.12
		_ring(t, 640, 380, r, 1, Color(0.48, 0.12, 0.63, a))
	# crater rim silhouettes
	for x in 420:
		var hh := int(70 + sin(x * 0.02) * 26 + sin(x * 0.05) * 12)
		for y in range(470 - hh, 720):
			_p(t, x, y, C("120a18"))
			_p(t, 1279 - x, y, C("120a18"))
	# gate structure silhouette (center)
	_rect(t, 590, 300, 22, 160, C("0c0712"))
	_rect(t, 668, 300, 22, 160, C("0c0712"))
	_rect(t, 586, 288, 108, 18, C("0c0712"))
	# portal glow inside
	for y in range(310, 455):
		var ww := int(36 * sin((y - 310) / 145.0 * PI)) + 6
		var a := 0.25 + sin((y - 310) / 145.0 * PI) * 0.4
		_rect(t, 640 - ww / 2, y, ww, 1, Color(0.35, 0.12, 0.5, a))
	for i in 26:
		_p(t, 640 + G.ri(-20, 20), 330 + G.ri(0, 120), C("c26bff"))
	# floor: dark ground with faint iso sheen
	for y in range(455, 720):
		var k := (y - 455) / 265.0
		for x in 1280:
			var px := t.get_pixel(x, y)
			_p(t, x, y, px.lerp(Color(0.04, 0.02, 0.07), 0.55 + k * 0.3))
	# walking figure silhouette + cyan visor dot
	_rect(t, 634, 500, 12, 26, C("080510"))
	_rect(t, 632, 524, 6, 18, C("080510"))
	_rect(t, 640, 524, 6, 18, C("080510"))
	_p(t, 640, 512, C("00E5FF")); _p(t, 641, 512, C("00E5FF"))
	# fog bands
	for i in 3:
		for x in 1280:
			var yy := 430 + i * 60 + int(sin(x * 0.008 + i * 2.0) * 12)
			_p(t, x, yy, Color(0.3, 0.15, 0.4, 0.10))
			_p(t, x, yy + 1, Color(0.3, 0.15, 0.4, 0.06))
	# embers
	for i in 90:
		var c := C("c26bff") if i % 3 else C("00E5FF")
		c.a = G.rf(0.25, 0.8)
		_p(t, G.ri(0, 1279), G.ri(300, 700), c)
	# vignette
	for y in 720:
		for x in 1280:
			var dx := (x - 640) / 640.0
			var dy := (y - 360) / 360.0
			var d := dx * dx + dy * dy
			if d > 0.55:
				var px := t.get_pixel(x, y)
				_p(t, x, y, px.lerp(Color.BLACK, clampf((d - 0.55) * 0.9, 0.0, 0.75)))
	return _tex(t)
