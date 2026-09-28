class_name Room
extends Node2D

# One room: iso diamond-tile floor, walls, props (obstacles), hazards,
# locked doors that unlock on clear. Combat rooms spawn waves; boss rooms
# spawn a boss; hub is a special camp layout.

enum Type { COMBAT, ELITE, BOSS }
enum Reward { BOON, HEAL, FRAGMENTS }

var W := 1180.0
var H := 660.0
var BOUNDS := Rect2(-540, -290, 1080, 580)

const BIOME_NAME := ["ENDUSTERRA BARRENS", "SIMITHAR MINE — 4-GAMMA", "SOL PRIMUS WRECKAGE", "AETERNA SPIRE", "ÇÜRÜK BATAKLIK", "KÜL OVASI", "KIZIL ÇÖL", "KRİSTAL ÇUKUR", "DONMUŞ ÇATLAK"]
# biome'a ozgu uretilmis prop setleri (prop_<key>_<i>) — BG2 tarzi scatter
const PROP_SPR := {
	"0": ["prop_0_0", "prop_0_1", "prop_0_2", "prop_0_3", "prop_0_4", "prop_0_5"],
	"1": ["prop_1_0", "prop_1_1", "prop_1_2", "prop_1_3", "prop_1_4", "prop_1_5"],
	"2": ["prop_2_0", "prop_2_1", "prop_2_2", "prop_2_3", "prop_2_4", "prop_2_5"],
	"3": ["prop_3_0", "prop_3_1", "prop_3_2", "prop_3_3", "prop_3_4", "prop_3_5"],
	# Çürük Bataklik: Simithar'in mantar/kristal setini ödünç alır — fungal örtü
	"4": ["prop_1_0", "prop_1_1", "prop_1_2", "prop_1_3", "prop_1_4", "prop_1_5"],
	# Kül Ovası: obsidiyan/bazalt/kor seti
	"5": ["prop_5_0", "prop_5_1", "prop_5_2", "prop_5_3", "prop_5_4", "prop_5_5"],
	# Kızıl Çöl: kaktüs/kafes kemik/kuru çalı/taş anıt/bazalt/kemik totem
	"6": ["prop_6_0", "prop_6_1", "prop_6_2", "prop_6_3", "prop_6_4", "prop_6_5"],
	# Kristal Çukur: Simithar'in kristal/mantar seti çukura da uyar
	"7": ["prop_1_0", "prop_1_1", "prop_1_2", "prop_1_3", "prop_1_4", "prop_1_5"],
	# Donmuş Çatlak: kendi buz seti — sarkıt/monolit/aurora kristali/kar yığını/kaburga/totem
	"8": ["prop_8_0", "prop_8_1", "prop_8_2", "prop_8_3", "prop_8_4", "prop_8_5"],
	"hub": ["prop_hub_0", "prop_hub_1", "prop_hub_2", "prop_hub_3", "prop_hub_4", "prop_hub_5"],
}
# isik veren prop'lar (kristal, mantar, fener, turbin, obelisk, ateslik)
const PROP_LIGHT := {
	"prop_1_0": Color(0.3, 0.9, 1.0), "prop_1_2": Color(0.7, 0.5, 1.0), "prop_1_5": Color(1.0, 0.7, 0.3),
	"prop_2_3": Color(1.0, 0.5, 0.2),
	"prop_3_3": Color(0.6, 0.4, 1.0), "prop_3_4": Color(1.0, 0.65, 0.25),
	"prop_5_0": Color(1.0, 0.45, 0.12), "prop_5_2": Color(1.0, 0.55, 0.15), "prop_5_4": Color(1.0, 0.5, 0.1),
	"prop_6_0": Color(0.4, 0.95, 0.9), "prop_6_3": Color(0.4, 0.9, 1.0),
	"prop_8_0": Color(0.45, 0.85, 1.0), "prop_8_2": Color(0.4, 0.95, 0.9), "prop_8_5": Color(0.5, 0.7, 1.0),
}
# atmosfer motes: renk + yon egilimi (biome basina)
const MOTE_COL := {
	"0": Color(0.85, 0.65, 0.4, 0.35),
	"1": Color(0.4, 0.9, 1.0, 0.4),
	"2": Color(1.0, 0.55, 0.25, 0.45),
	"3": Color(0.7, 0.5, 1.0, 0.35),
	"4": Color(0.45, 0.9, 0.5, 0.4),
	"5": Color(1.0, 0.5, 0.2, 0.4),
	"6": Color(1.0, 0.72, 0.4, 0.4),
	"7": Color(0.35, 0.9, 1.0, 0.4),
	"8": Color(0.78, 0.9, 1.0, 0.42),
	"hub": Color(1.0, 0.75, 0.45, 0.35),
}
var motes: Array = []   # [{s, vel}] atmosfer parcaciklari

# seviye evrimi: oyuncu 15/25/30/35/40. seviyeyi geçtikçe saha görsel olarak
# derinleşir — zemin mora kararır, mor koro damarları sızar, moteler kızıllaşır
func apply_corruption(e: int) -> void:
	var g := get_node_or_null("ground") as Sprite2D
	if g != null:
		var target := Color(1, 1, 1).lerp(Color(0.62, 0.5, 0.88), minf(0.6, e * 0.15))
		var tw := create_tween()
		tw.tween_property(g, "modulate", target, 2.5)
	for i in 8 + e * 4:
		var s := Sprite2D.new()
		s.texture = Px.S2("dec_vein_0")
		if s.texture == null:
			s.texture = Px.S("splat")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(G.rf(BOUNDS.position.x, BOUNDS.end.x), G.rf(BOUNDS.position.y, BOUNDS.end.y))
		s.rotation = G.rf(0, TAU)
		s.scale = Vector2.ONE * G.rf(1.8, 3.0)
		s.modulate = Color(0.55, 0.25, 0.95, 0.0)
		s.z_index = -1890
		add_child(s)
		var tw2 := create_tween()
		tw2.tween_property(s, "modulate:a", 0.55, G.rf(1.5, 3.5))
	# moteler mor/kızıl koroya döner — saha "kirlendi" hissi
	for m in motes:
		var s2: Sprite2D = m.get("s")
		if is_instance_valid(s2):
			var tw3 := create_tween()
			tw3.tween_property(s2, "modulate", s2.modulate.lerp(Color(0.8, 0.35, 0.95, s2.modulate.a), 0.75), 2.0)
# KUM FIRTINASI (biome 6): periyodik ruzgar dalgasi — herkesi iter
var storm_t := 0.0
var storm_cd := 0.0
var storm_dir := Vector2.RIGHT
var sarkit_cd := 9.0            # maden tavan çökmesi aralığı
const REWARD_ICON := ["ico_boon", "ico_heal", "ico_frag"]

var biome := 0
var rtype: int = Type.COMBAT
var is_hub := false
var rng := RandomNumberGenerator.new()
var props: Array = []          # [{pos, r}]
var hazards: Array = []        # [{pos, r, dps, node, kind, t, tele, erupt}]
var slows: Array = []          # [{pos, r, t?}]
var doors: Array = []          # [{pos, node, icon, reward, locked, gate, descend}]
var pickups_node: Node2D
var mono: Dictionary = {}      # rezonans kümesi: {pos,t,need,node,ring} — yakınında durarak şarj edilir
var mono_pos := Vector2.ZERO   # kenar işareti okur
var mono_active := false
var geo: Dictionary = {}       # damar jeotu: {pos,t,need,node,ring} — çukurda kırılan kristal yumru
var geo_pos := Vector2.ZERO
var geo_active := false
var _geo_g1 := false           # yarı kanalda bir kez bekçi çağırır
var merchant: Dictionary = {}  # gezgin tüccar: {node,tag} — tek alışverişlik koşu içi dükkân
var merchant_pos := Vector2.ZERO
var merchant_active := false
var _merch_armed := true
var stray: Dictionary = {}      # kayip sasi: {node,tag} — koşu içi karşılaşma (onar ya da parçala)
var stray_pos := Vector2.ZERO
var stray_active := false
var _stray_armed := true
var _merge_t := 80.0            # kristal konsolidasyonu sayacı
var critters: Array = []        # [{s, vel}] — zararsiz yaban hayatı; üstüne koşarsan yakalanır
var caches: Array = []          # gizli gömülü sandıklar — işaretlenmez, yaklaşınca açılır
var veins: Array = []           # CHORALİM DAMARI — yanında durup kazılan parçacık madeni {node,t,pos}
var decals: Node2D
var pending_reward: int = Reward.FRAGMENTS
var cleared := false
var waves: Array = []
var wave_idx := -1
var alive := 0
var boss: Boss = null
var _door_cd := 0.0

func _ready() -> void:
	G.room = self
	decals = Node2D.new()
	decals.name = "decals"
	decals.z_index = -1900
	add_child(decals)
	pickups_node = Node2D.new()
	pickups_node.name = "pickups"
	add_child(pickups_node)

# ---------------------------------------------------------------- build

const DARK := [
	Color(0.62, 0.56, 0.50),   # Endusterra — dusty warm dark
	Color(0.64, 0.68, 0.76),   # Simithar — cold cavern
	Color(0.60, 0.53, 0.46),   # Sol Primus — rusted gloom
	Color(0.55, 0.51, 0.66),   # Aeterna — imperial night
	Color(0.44, 0.52, 0.42),   # Çürük Bataklık — murky fungal gloom
	Color(0.50, 0.42, 0.38),   # Kül Ovası — kor altında koyu kül
	Color(0.62, 0.44, 0.32),   # Kızıl Çöl — sıcak kum akşamı
	Color(0.45, 0.48, 0.62),   # Kristal Çukur — mor-gece kristal ışığı
]
const HUB_DARK := Color(0.62, 0.56, 0.47)

func _biome_key() -> String:
	return "hub" if is_hub else str(biome)

func build_hub() -> void:
	is_hub = true
	biome = -1
	G.game.set_dark(HUB_DARK)
	_backdrop()
	_build_floor_named("hub")
	_build_walls_named("hub")
	_scatter_decals()
	_prop(Vector2(-300, -140), 30, "prop_hub_0")
	_prop(Vector2(300, -100), 30, "prop_hub_0")
	_prop(Vector2(-420, 60), 20, "prop_hub_1")
	_prop(Vector2(400, 140), 20, "prop_hub_1")
	_prop(Vector2(-150, -220), 16, "prop_hub_2")
	_prop(Vector2(190, -200), 14, "prop_hub_3")
	_prop(Vector2(-350, 200), 12, "prop_hub_5")
	_prop(Vector2(430, -180), 12, "prop_hub_4")
	_prop(Vector2(60, -190), 12, "medic")
	_fire(Vector2(0, -60))
	# kamp ateşi çevresinde sıcak moteler (ateş böcekleri)
	for i in 12:
		var f := Sprite2D.new()
		f.texture = Px.S("dot")
		f.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		f.scale = Vector2.ONE * rng.randf_range(0.4, 0.9)
		f.modulate = Color(1.0, 0.72, 0.28, rng.randf_range(0.35, 0.7))
		f.position = Vector2(rng.randf_range(-260, 260), rng.randf_range(-180, 100))
		f.z_index = 1500
		add_child(f)
		motes.append({"s": f, "vel": Vector2(rng.randf_range(-8, 8), rng.randf_range(-10, -3)), "ph": rng.randf() * TAU})
	# Resonance Gate — south edge, starts the run
	var gate := _door_node("portal")
	gate.position = Vector2(0, H * 0.5 - 26)
	add_child(gate)
	var ic := _icon("ico_exit", gate.position + Vector2(0, -56))
	add_child(ic)
	G.fx.mk_light(self, gate.position + Vector2(0, -34), Px.C("7B1FA2"), 0.9, 2.6)
	doors.append({"pos": gate.position, "node": gate, "icon": ic, "reward": -1, "locked": false, "gate": true})
	# hub NPCs
	NPC.make("rhasa", Vector2(-240, -60), self)
	NPC.make("neva", Vector2(140, -140), self)
	NPC.make("saphire", Vector2(-90, 120), self)
	NPC.make("vane", Vector2(230, 30), self)
	NPC.make("david", Vector2(-380, 90), self)
	NPC.make("zirkon", Vector2(360, -220), self)
	NPC.make("ehnar", Vector2(60, -300), self)
	NPC.make("ahusk", Vector2(-140, -260), self)
	NPC.make("elyb", Vector2(320, -120), self)
	# kurtarılmış yolcu: sahada kafesi kırılan Mina kampta mutfağını kurar
	if bool(G.meta.data.get("rescued_mina", false)):
		NPC.make("mina", Vector2(-300, 200), self)
	# kampın kenarında bahis masası kuran gezgin simsar — bahsi koşu sonunda çözülür
	NPC.make("tegan", Vector2(-460, 170), self)
	if bool(G.meta.data.get("rescued_lena", false)):
		NPC.make("lena", Vector2(300, 210), self)
	if bool(G.meta.data.get("rescued_orun", false)):
		NPC.make("orun", Vector2(-60, 300), self)
	# efendi kupaları: düşürülen her boss kamp ateşinin kuzeyinde kafatası bırakır
	var tb := 0
	for bid in (G.meta.data.get("bosses", []) as Array):
		_prop(Vector2(-60 + tb * 44, -330), 7, "icn_skull")
		tb += 1
	# kamp büyür: talep edilen görevler kampa düzen getirir (çevre → sancaklar → güney konağı)
	var done_n := 0
	for qid in (G.meta.data.get("quests", {}) as Dictionary):
		if str(G.meta.data["quests"][qid].get("st", "")) == "claimed":
			done_n += 1
	var tier := 0
	if done_n >= 6: tier = 1
	if done_n >= 14: tier = 2
	if done_n >= 24: tier = 3
	if tier >= 1:
		for pp in [Vector2(-520, 40), Vector2(-500, 130), Vector2(520, 60), Vector2(490, -60)]:
			_prop(pp, 18, "prop_hub_1")
		_prop(Vector2(-540, -90), 24, "prop_hub_0")
	if tier >= 2:
		for pp in [Vector2(-260, -280), Vector2(-40, -340), Vector2(200, -290)]:
			_prop(pp, 15, "prop_hub_3")
		G.fx.mk_light(self, Vector2(-260, -280), Px.C("ffd75f"), 0.55, 2.0)
	if tier >= 3:
		for pp in [Vector2(-120, 300), Vector2(120, 310), Vector2(0, 340)]:
			_prop(pp, 16, "prop_hub_5")
		_fire(Vector2(-160, H * 0.5 - 90))
	# kamp inşaatı görünür olur: yuva → mutfak çadırı, atölye → tezgâh, kule → gözcü direği
	if is_instance_valid(G.meta):
		if G.meta.has_build("yuva"):
			_prop(Vector2(-380, 240), 15, "prop_hub_1")
			_prop(Vector2(-420, 200), 12, "prop_hub_1")
			_fire(Vector2(-340, 260))
		if G.meta.has_build("atolye"):
			_prop(Vector2(-40, 180), 16, "prop_hub_4")
			_prop(Vector2(-140, 170), 12, "prop_hub_5")
			G.fx.mk_light(self, Vector2(-40, 180), Px.C("8fd4ff"), 0.5, 1.8)
		if G.meta.has_build("kule"):
			_prop(Vector2(-500, -240), 30, "prop_hub_2")
			_prop(Vector2(-480, -200), 12, "prop_hub_3")
			G.fx.mk_light(self, Vector2(-500, -260), Px.C("ffd75f"), 0.6, 2.2)
		if G.meta.has_build("kuyu"):
			_prop(Vector2(40, 60), 14, "prop_hub_4")
			_prop(Vector2(20, 90), 10, "prop_hub_5")
		if G.meta.has_build("sur"):
			for sp in [Vector2(-560, 300), Vector2(-280, 360), Vector2(0, 380), Vector2(280, 360), Vector2(560, 300)]:
				_prop(sp, 16, "prop_hub_0")
		if G.meta.has_build("ahir"):
			_prop(Vector2(240, 300), 15, "prop_hub_3")
			_prop(Vector2(280, 330), 11, "prop_hub_5")
		if G.meta.has_build("kehne"):
			_prop(Vector2(-560, -140), 18, "prop_hub_0")
			G.fx.mk_light(self, Vector2(-560, -160), Px.C("c9a227"), 0.55, 2.0)
			_fire(Vector2(-560, -120))
		if G.meta.has_build("talim"):
			_prop(Vector2(140, -140), 15, "prop_hub_2")
			_prop(Vector2(180, -120), 12, "prop_hub_5")
		if G.meta.has_build("umbar"):
			_prop(Vector2(-320, 330), 14, "prop_hub_4")
			_prop(Vector2(-360, 350), 12, "prop_hub_4")
			_prop(Vector2(-280, 355), 10, "prop_hub_5")
		if G.meta.has_build("ahir"):
			# ağıldaki sürüngenler kampta gezinir (yakalanmaz — pet işaretli)
			var fpet: Array = Px.F("c_varl").get("idle", [])
			for i in mini(int(G.meta.data.get("pets", 0)), 8):
				var ps := Sprite2D.new()
				ps.texture = fpet[0] if not fpet.is_empty() else Px.S("dot")
				ps.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				Px.fit(ps, 18.0)
				ps.modulate = Color(0.95, 0.9, 0.6, 0.9)
				ps.position = Vector2(rng.randf_range(140, 380), rng.randf_range(240, 380))
				ps.z_index = 30
				add_child(ps)
				critters.append({"s": ps, "vel": Vector2(rng.randf_range(-20, 20), rng.randf_range(-20, 20)), "pet": true})
	if tier > int(G.meta.data.get("camp_tier", 0)):
		G.meta.data["camp_tier"] = tier
		G.meta.save()
		G.ui.toast("kamp büyüyor — halk sana güveniyor")
	G.audio.play_music("mus_hub")
	G.ui.banner("VIATOR KAMPI", "son güvenli toprak — konuşmak için E, kapıya yürü")

func build(biome_idx: int, rt: int, promise: int, depth: int, seed_val: int) -> void:
	biome = biome_idx
	rtype = rt
	pending_reward = promise
	is_hub = false
	rng.seed = seed_val
	G.game.set_dark(DARK[clampi(biome, 0, DARK.size() - 1)])
	_backdrop()
	_build_floor_named(str(biome))
	_build_walls_named(str(biome))
	_scatter_decals()
	_scatter_props()
	_scatter_critters()
	_scatter_caches()
	_scatter_veins()
	_place_hazards(depth)
	_make_doors()
	G.audio.play_music("mus_boss" if rt == Type.BOSS else "mus_%d" % biome)
	G.ui.banner(BIOME_NAME[clampi(biome, 0, BIOME_NAME.size() - 1)], _room_subtitle(depth))
	if rt == Type.BOSS:
		_start_boss_fight()
	else:
		_plan_waves(depth)

func _room_subtitle(depth: int) -> String:
	if rtype == Type.BOSS:
		return "derinlik — bir şey bekliyor"
	if rtype == Type.ELITE:
		return "elit müfreze — dikkat"
	return "oda %d" % (depth + 1)

func _backdrop() -> void:
	# BG2 tarzi: oyun alani boyanmis zemine gomulur, disariya karanliga kayar
	var void_s := Sprite2D.new()
	void_s.texture = Px.S("px1")
	void_s.scale = Vector2(5200, 4200)
	void_s.modulate = Color(0.02, 0.02, 0.035)
	void_s.z_index = -2200
	add_child(void_s)
	_vignette()
	_atmos()

func _vignette() -> void:
	# kenar karartmasi: zemin disariya yumusak bir karalikla kaybolur
	var t := 260.0
	var ov := 150.0
	var edges := [
		[Vector2(0, -H * 0.5 - t * 0.5 + ov), Vector2((W + 560.0) / 4.0, t / 256.0), 0.0],
		[Vector2(0, H * 0.5 + t * 0.5 - ov), Vector2((W + 560.0) / 4.0, t / 256.0), PI],
		[Vector2(-W * 0.5 - t * 0.5 + ov, 0), Vector2((H + 560.0) / 4.0, t / 256.0), -PI * 0.5],
		[Vector2(W * 0.5 + t * 0.5 - ov, 0), Vector2((H + 560.0) / 4.0, t / 256.0), PI * 0.5],
	]
	for e in edges:
		var s := Sprite2D.new()
		s.texture = Px.S("grad")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.position = e[0]
		s.scale = e[1]
		s.rotation = e[2]
		s.modulate = Color(0.01, 0.01, 0.02, 0.92)
		s.z_index = -1880
		add_child(s)

func _atmos() -> void:
	# ortam motesleri: biome'a ozel renk, yavas suzulme
	var col: Color = MOTE_COL.get(_biome_key(), Color(0.8, 0.7, 0.5, 0.3))
	for i in 18:
		var s := Sprite2D.new()
		s.texture = Px.S("dot")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		s.scale = Vector2.ONE * rng.randf_range(0.5, 1.4)
		s.modulate = col
		s.modulate.a *= rng.randf_range(0.5, 1.0)
		s.position = Vector2(rng.randf_range(-W * 0.5, W * 0.5), rng.randf_range(-H * 0.5, H * 0.5))
		s.z_index = 1500
		add_child(s)
		var base := Vector2(rng.randf_range(-6, 10), rng.randf_range(-14, -4))
		if _biome_key() == "2": base = Vector2(rng.randf_range(-4, 4), rng.randf_range(-26, -12))
		if _biome_key() == "4": base = Vector2(rng.randf_range(-8, 8), rng.randf_range(-18, -6))
		if _biome_key() == "8": base = Vector2(rng.randf_range(-7, 7), rng.randf_range(16, 32))
		motes.append({"s": s, "vel": base, "ph": rng.randf() * TAU})

func _build_floor_named(key: String) -> void:
	# tam-sahne boyanmis zemin (kenarlari karanliga gomulu)
	var s := Sprite2D.new()
	s.texture = Px.S2("gr_" + key)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var sc := maxf((W + 320.0) / s.texture.get_width(), (H + 300.0) / s.texture.get_height())
	s.scale = Vector2.ONE * sc
	s.position = Vector2.ZERO
	s.z_index = -2000
	add_child(s)

func _build_walls_named(key: String) -> void:
	var tex := Px.S2("w2_" + key)
	var x := -W * 0.5 - 64
	var lamp_col: Color = [Px.C("ffb74d"), Px.C("00E676"), Px.C("ff7722"), Px.C("c9a227"), Px.C("66bb6a"), Px.C("ff5522"), Px.C("ffaa55"), Px.C("4dd0e1"), Px.C("9fd8ff")][clampi(biome, 0, 8)]
	var xi := 0
	while x <= W * 0.5 + 64:
		for off in [Vector2(0, 0), Vector2(0, -64)]:
			var s := Sprite2D.new()
			s.texture = tex
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.scale = Vector2.ONE * 2.0
			s.position = Vector2(x + off.x, -H * 0.5 - 26 + off.y)
			s.z_index = int(s.position.y)
			if off.y != 0:
				s.modulate = Color(0.55, 0.55, 0.62)
			add_child(s)
		# wall fixtures every ~5 tiles — local light breaks the flat band
		if xi % 5 == 2:
			G.fx.mk_light(self, Vector2(x + 16, -H * 0.5 - 30), lamp_col, 0.55, 1.7)
		x += 64
		xi += 1

const DEC_NVAR := {"stain": 4, "bones": 3, "crack": 1, "tuft": 1, "vein": 1}

func _scatter_decals() -> void:
	var kinds := ["stain", "stain", "bones", "bones", "crack"]
	match _biome_key():
		"0", "hub": kinds.append("tuft")
		"3": kinds.append("vein")
	var n := 14 + (6 if is_hub else 0)
	for i in n:
		var k: String = kinds[G.ri(0, kinds.size() - 1)]
		var s := Sprite2D.new()
		s.texture = Px.S2("dec_%s_%d" % [k, G.ri(0, DEC_NVAR.get(k, 1) - 1)])
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = Vector2(G.rf(BOUNDS.position.x + 30, BOUNDS.end.x - 30), G.rf(BOUNDS.position.y + 30, BOUNDS.end.y - 30))
		s.rotation = G.rf(0, TAU)
		s.scale = Vector2.ONE * 1.6
		s.z_index = -1890
		add_child(s)

func _prop(p: Vector2, r: float, spr: String) -> void:
	var sh := Sprite2D.new()
	sh.texture = Px.S("shadow")
	sh.position = p + Vector2(0, 4)
	sh.scale = Vector2.ONE * r * 2.6 / 48.0
	sh.z_index = -1890
	add_child(sh)
	var s := Sprite2D.new()
	s.texture = Px.S(spr)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	s.position = p
	s.scale = Vector2.ONE * r * 4.2 / 120.0
	s.offset = Vector2(0, -s.texture.get_height() * 0.5)
	s.z_index = int(p.y)
	add_child(s)
	props.append({"pos": p, "r": r})
	if PROP_LIGHT.has(spr):
		G.fx.mk_light(self, p + Vector2(0, -r * 1.4), PROP_LIGHT[spr], 0.55, 1.6)

func _scatter_props() -> void:
	var n := 8 + biome * 2 + (6 if rtype == Type.ELITE else 0)
	var tries := 0
	while props.size() < n and tries < 200:
		tries += 1
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 40, BOUNDS.end.x - 40), rng.randf_range(BOUNDS.position.y + 40, BOUNDS.end.y - 40))
		if p.distance_to(Vector2.ZERO) < 160 or p.distance_to(spawn_point()) < 160:
			continue
		var ok := true
		for d in DOOR_POS():
			if p.distance_to(d) < 110: ok = false
		for q in props:
			if p.distance_to(q.pos) < 90: ok = false
		if not ok:
			continue
		var set: Array = PROP_SPR[_biome_key()]
		_prop(p, rng.randf_range(10, 20), set[rng.randi() % set.size()])

func DOOR_POS() -> Array:
	return [Vector2(0, -H * 0.5 + 24), Vector2(-W * 0.5 + 44, -60), Vector2(W * 0.5 - 44, -60)]

func _place_hazards(depth: int) -> void:
	var count := 1 + (1 if biome >= 1 else 0) + (1 if depth >= 2 else 0)
	var i := 0
	var tries := 0
	while i < count and tries < 14:
		tries += 1
		var p := Vector2(rng.randf_range(-380, 380), rng.randf_range(-180, 180))
		if p.distance_to(spawn_point()) < 200 or p.distance_to(Vector2.ZERO) < 120:
			continue
		match biome:
			0:
				# Endusterra: volatile spore vents — telegraphed periodic eruption
				var t := G.fx.tele_circle(p, 52, 9999.0, Color(0.2, 0.9, 0.1, 0.25))
				t.sr.modulate.a = 0.12
				G.fx.mk_light(self, p, Px.C("00E676"), 0.4, 1.5)
				hazards.append({"pos": p, "r": 52.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(2, 6), "tele": t, "erupt": 0.0})
			1:
				add_hazard(p, 46.0, 16.0, -1.0, Color(1, 0.4, 0.1, 0.3))    # lava pool
			2:
				if i % 2 == 0:
					add_slowzone(p, 52.0, -1.0)                                # radiation field
				else:
					# ark sizintisi: enkaz kablolari telegraph'li zincir yildirim atar — iki tarafi vurur
					var t2 := G.fx.tele_circle(p, 70.0, 9999.0, Color(0.4, 0.8, 1.0, 0.22))
					t2.sr.modulate.a = 0.12
					G.fx.mk_light(self, p, Px.C("6fd8ff"), 0.4, 1.5)
					hazards.append({"pos": p, "r": 70.0, "dps": 0.0, "kind": "ark", "t": rng.randf_range(2.0, 4.0), "tele": t2})
			4:
				if i == 0:
					add_slowzone(p, 60.0, -1.0)                            # batak çamuru — çeken balçık
				else:
					# zehir fiskiyesi: iki tarafi da yakan yesil gaz havuzu — suruyu icine cek
					add_hazard(p, 50.0, 10.0, -1.0, Color(0.55, 0.9, 0.3, 0.22))
					hazards[hazards.size() - 1]["kind"] = "toxic"
			5:
				# Kül Ovası: lav fışkırtıcı — turuncu telegraph'lı püskürme
				var t5 := G.fx.tele_circle(p, 52, 9999.0, Color(1.0, 0.45, 0.1, 0.25))
				t5.sr.modulate.a = 0.12
				G.fx.mk_light(self, p, Px.C("ff7722"), 0.4, 1.5)
				hazards.append({"pos": p, "r": 52.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(2, 6), "tele": t5, "erupt": 0.0, "col": "ff7722"})
			6:
				if i == 0:
					# ilk nokta sabit: amber telegraph'lı hortum patlaması
					var t6 := G.fx.tele_circle(p, 56, 9999.0, Color(1.0, 0.68, 0.3, 0.25))
					t6.sr.modulate.a = 0.12
					G.fx.mk_light(self, p, Px.C("ffaa55"), 0.4, 1.5)
					hazards.append({"pos": p, "r": 56.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(2, 6), "tele": t6, "erupt": 0.0, "col": "ffaa55"})
				else:
					# gerisi gezici: sürüklenen kum hortumu — alanı dolaşır, içindeyken iter
					var tt := G.fx.tele_circle(p, 62, 9999.0, Color(1.0, 0.7, 0.35, 0.22))
					tt.sr.modulate.a = 0.16
					hazards.append({"pos": p, "r": 62.0, "dps": 8.0, "kind": "surgun", "t": -1.0, "tele": tt, "vel": Vector2.from_angle(rng.randf() * TAU) * 36.0, "sway": rng.randf() * TAU})
			8:
				if i % 3 == 0:
					# kalıcı buzul zemini — üstünde kayarsın, hasar vermez
					add_slowzone(p, 58.0, -1.0)
				else:
					# buzul çatlağı — buz-beyaz telegraph'lı don patlaması
					var t8 := G.fx.tele_circle(p, 54, 9999.0, Color(0.6, 0.86, 1.0, 0.25))
					t8.sr.modulate.a = 0.12
					G.fx.mk_light(self, p, Px.C("9fd8ff"), 0.4, 1.5)
					hazards.append({"pos": p, "r": 54.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(3, 7), "tele": t8, "erupt": 0.0, "col": "9fd8ff"})
			3:
				# Aeterna: çan alanı — halkanın içindeki sürü nabızla hızlanır; düşmanı içinden geçirme
				var t3 := G.fx.tele_circle(p, 74, 9999.0, Color(0.76, 0.63, 0.16, 0.2))
				t3.sr.modulate.a = 0.10
				G.fx.mk_light(self, p, Px.C("c9a227"), 0.35, 1.4)
				hazards.append({"pos": p, "r": 74.0, "dps": 0.0, "kind": "coro", "t": rng.randf_range(1.5, 3.5), "tele": t3})
			7:
				# Kristal Çukur: damar fışkını — telegraph'lı püskürme kristal saçar ama içinde duranı da vurur
				var t7 := G.fx.tele_circle(p, 56, 9999.0, Color(0.3, 0.82, 0.88, 0.25))
				t7.sr.modulate.a = 0.12
				G.fx.mk_light(self, p, Px.C("4dd0e1"), 0.4, 1.5)
				hazards.append({"pos": p, "r": 56.0, "dps": 0.0, "kind": "vent", "t": rng.randf_range(2, 6), "tele": t7, "erupt": 0.0, "col": "4dd0e1", "gusher": true})
			_:
				add_hazard(p, 48.0, 14.0, -1.0, Color(0.5, 0.2, 0.8, 0.3))   # void pool
		i += 1

func add_hazard(p: Vector2, r: float, dps: float, dur: float, col: Color) -> void:
	var s := Sprite2D.new()
	s.texture = Px.S("circle")
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * (r * 2.0) / 72.0
	s.modulate = col
	s.position = p
	s.z_index = -1950
	add_child(s)
	var l := G.fx.mk_light(self, p, col, 0.5, 1.6)
	hazards.append({"pos": p, "r": r, "dps": dps, "kind": "pool", "node": s, "t": dur, "light": l})

func add_slowzone(p: Vector2, r: float, dur: float, col := Color(0.4, 0.9, 0.6, 0.22)) -> void:
	var s := Sprite2D.new()
	s.texture = Px.S("circle")
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2.ONE * (r * 2.0) / 72.0
	s.modulate = col
	s.position = p
	s.z_index = -1950
	add_child(s)
	slows.append({"pos": p, "r": r, "node": s, "t": dur})

func _fire(p: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = Px.S("campfire")
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = p
	s.scale = Vector2.ONE * 1.6
	s.z_index = int(p.y)
	add_child(s)
	props.append({"pos": p, "r": 14.0})
	set_meta("fire", s)
	var l := G.fx.mk_light(self, p + Vector2(0, -12), Px.C("ff9a3d"), 1.0, 2.4)
	set_meta("fire_light", l)

# ---------------------------------------------------------------- doors

func _door_node(kind: String) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Px.S2({"door": "door2", "gate": "gate2", "portal": "portal"}.get(kind, "door2"))
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.offset = Vector2(0, -s.texture.get_height() * 0.5)
	s.z_index = -320  # wall-band height; _make_doors re-sorts by door y
	return s

func _door_frame(p: Vector2, side: bool) -> void:
	# dark recess behind the door so it reads as an opening
	var sh := Sprite2D.new()
	sh.texture = Px.S("shadow")
	sh.position = p + Vector2(0, -12)
	sh.scale = Vector2(4.4, 3.0)
	sh.modulate = Color(0, 0, 0, 0.65)
	sh.z_index = -1890
	add_child(sh)
	if not side:
		return
	# side doors get a short wall stub so they don't float in the void
	var tex := Px.S2("w2_" + _biome_key())
	for dx in [-48, -16, 16, 48]:
		for dy in [-96, -32, 32]:
			var ws := Sprite2D.new()
			ws.texture = tex
			ws.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ws.scale = Vector2.ONE * 2.0
			ws.position = p + Vector2(dx, dy - 12)
			ws.z_index = int(ws.position.y)
			add_child(ws)

func _icon(spr: String, p: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Px.S(spr)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.position = p
	s.z_index = 400
	return s

func _make_doors() -> void:
	var positions := DOOR_POS()
	# north door always exists; pick west or east as second exit
	var idxs := [0, 1 if rng.randf() < 0.5 else 2]
	var rewards := [Reward.BOON, Reward.FRAGMENTS]
	if rng.randf() < 0.4:
		rewards[1] = Reward.HEAL
	rewards.shuffle()
	for i in idxs.size():
		var d := _door_node("door")
		d.position = positions[idxs[i]]
		d.z_index = int(positions[idxs[i]].y)
		d.modulate = Color(0.55, 0.55, 0.62)
		add_child(d)
		_door_frame(positions[idxs[i]], idxs[i] != 0)
		var rew: int = rewards[i]
		var ic := _icon(REWARD_ICON[rew], positions[idxs[i]] + Vector2(0, -56))
		ic.modulate.a = 0.0
		add_child(ic)
		doors.append({"pos": positions[idxs[i]], "node": d, "icon": ic, "reward": rew, "locked": true, "gate": false})
	if rtype == Type.BOSS:
		doors.clear()
		var d := _door_node("gate")
		d.position = positions[0]
		d.z_index = int(positions[0].y)
		d.modulate = Color(0.55, 0.55, 0.62)
		add_child(d)
		_door_frame(positions[0], false)
		var ic := _icon("ico_exit", positions[0] + Vector2(0, -58))
		ic.modulate.a = 0.0
		add_child(ic)
		doors.append({"pos": positions[0], "node": d, "icon": ic, "reward": -1, "locked": true, "gate": true, "descend": true})

func unlock_doors() -> void:
	var reward_col := {Reward.BOON: Px.C("7B1FA2"), Reward.HEAL: Px.C("00E676"), Reward.FRAGMENTS: Px.C("c26bff")}
	for d in doors:
		d.locked = false
		if d.get("gate", false):
			d.node.texture = Px.S2("gate_open")
			d.node.modulate = Color.WHITE
		else:
			d.node.modulate = Color(1.5, 1.5, 1.8)  # runes flare when the seal breaks
		var tw := create_tween()
		tw.tween_property(d.icon, "modulate:a", 1.0, 0.4)
		var lc: Color = reward_col.get(d.reward, Px.C("7B1FA2"))
		d["light"] = G.fx.mk_light(self, d.pos + Vector2(0, -30), lc, 0.7, 1.8)

# ---------------------------------------------------------------- waves

func _wave_comp(widx: int, depth: int) -> Array:
	var table: Array = [
		[["husk", "husk", "husk"], ["drone", "husk", "husk", "husk"], ["husk", "husk", "drone", "drone"]],
		[["husk", "husk", "spitter"], ["husk", "turret", "husk", "drone"], ["spitter", "husk", "husk", "turret"]],
		[["drone", "sentinel", "husk"], ["sentinel", "turret", "drone"], ["sentinel", "sentinel", "spitter"]],
		[["sentinel", "spitter", "drone"], ["sentinel", "turret", "turret"], ["sentinel", "sentinel", "spitter", "drone"]],
	][biome]
	var comp: Array = table[mini(widx, table.size() - 1)]
	var out: Array = []
	for k in comp:
		out.append({"kind": k, "elite": false})
	for i in floori(depth / 2.0):
		out.append({"kind": comp[rng.randi() % comp.size()], "elite": false})
	if rtype == Type.ELITE:
		out.append({"kind": comp[rng.randi() % comp.size()], "elite": true})
	return out

func _plan_waves(depth: int) -> void:
	var wc := 2 + (1 if depth >= 2 or rtype == Type.ELITE else 0)
	for w in wc:
		waves.append(_wave_comp(w, depth))
	_begin_waves()

func _begin_waves() -> void:
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(self) or cleared:
		return
	_next_wave()

func _next_wave() -> void:
	wave_idx += 1
	if wave_idx >= waves.size():
		return
	var hs := G.run.hp_scale() * (1.0 + wave_idx * 0.15) * (1.5 if rtype == Type.ELITE else 1.0)
	var ds := G.run.dmg_scale()
	for spec in waves[wave_idx]:
		var k: int = Enemy.EKind.get(str(spec.kind).to_upper(), Enemy.EKind.HUSK)
		Enemy.spawn(k, _spawn_pos(), spec.elite, hs, ds, self)
		alive += 1
	G.audio.play("ui", 0.8, 0.4)
	if wave_idx > 0:
		G.ui.toast("dalga %d" % (wave_idx + 1))

func _spawn_pos() -> Vector2:
	for i in 40:
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 60, BOUNDS.end.x - 60), rng.randf_range(BOUNDS.position.y + 60, BOUNDS.end.y - 60))
		if G.player != null and p.distance_to(G.player.pos) < 190:
			continue
		var ok := true
		for q in props:
			if p.distance_to(q.pos) < q.r + 30:
				ok = false
		if ok:
			return p
	return Vector2(rng.randf_range(-300, 300), rng.randf_range(-200, 100))

func spawn_point() -> Vector2:
	return Vector2(0, H * 0.5 - 90)

var _bosses_left := 0

func _start_boss_fight() -> void:
	await get_tree().create_timer(1.2).timeout
	if not is_instance_valid(self):
		return
	var pair: Array = []
	match biome:
		0: pair = [Boss.BKind.REX]
		1: pair = [Boss.BKind.HOST]
		2: pair = [Boss.BKind.NAHUM, Boss.BKind.TUMAN]
		_: pair = [Boss.BKind.KIRIN, Boss.BKind.CONST]
	var first: Boss = null
	var offs := [Vector2(0, -80)] if pair.size() == 1 else [Vector2(-140, -80), Vector2(140, -80)]
	var boss_scale := 1.0 if pair.size() == 1 else (0.8 if biome == 2 else 0.9)
	for i in pair.size():
		var b := Boss.spawn_boss(pair[i], offs[i], self, boss_scale)
		b.died.connect(_on_one_boss_dead)
		if first != null:
			first.link = b
			b.link = first
		if first == null:
			first = b
		_bosses_left += 1
	boss = first
	G.ui.boss_bar(true, boss)
	G.ui.boss_intro(boss)

func _on_one_boss_dead(_b) -> void:
	_bosses_left -= 1
	if is_instance_valid(G.ui):
		G.ui.boss_bar_refresh()
	if _bosses_left <= 0:
		on_boss_dead(_b)

# ---------------------------------------------------------------- runtime

func _process(d: float) -> void:
	_door_cd = maxf(0, _door_cd - d)
	_tick_hazards(d)
	_tick_pickups(d)
	_tick_monolith(d)
	_tick_geode(d)
	_tick_trial()
	_tick_fener()
	_tick_merchant(d)
	_tick_stray(d)
	_tick_critters(d)
	_tick_caches()
	_tick_veins(d)
	_tick_doors()
	_tick_motes(d)
	_tick_storm(d)
	_tick_sarkit(d)
	_sort_children()
	# campfire flicker
	if has_meta("fire_light") and is_instance_valid(get_meta("fire_light")):
		var l: PointLight2D = get_meta("fire_light")
		l.energy = 1.0 + sin(Time.get_ticks_msec() * 0.013) * 0.16 + sin(Time.get_ticks_msec() * 0.041) * 0.07

var _trial_elites: Array = []
var _trial_pos := Vector2.ZERO
var _fener_champs: Array = []
var _fener_pos := Vector2.ZERO

# DENEME TOTEMİ: iki elit doğar — ikisi de düşünce sandık+eşya öder
func _tick_trial() -> void:
	if _trial_elites.is_empty():
		return
	_trial_elites = _trial_elites.filter(func(e): return is_instance_valid(e) and not e.dead)
	if _trial_elites.is_empty():
		G.ui.toast("DENEME TAMAM — sandık düştü")
		G.audio.jingle("boon")
		Quests.tick("totem")
		spawn_chest(_trial_pos)
		var tiid := Items.roll(G.run.luck + 0.2)
		if tiid != "":
			spawn_loot(tiid, _trial_pos + Vector2(40, 0))

# SİNYAL FENERİ: üstüne basınca ikiz şampiyon yankı uyanır — ikisi de düşerse
# çift sandık + eşya + ağır parçacık öder (istençli yüksek-risk yan savaşı)
func _tick_fener() -> void:
	if _fener_champs.is_empty():
		return
	_fener_champs = _fener_champs.filter(func(e): return is_instance_valid(e) and not e.dead)
	if _fener_champs.is_empty():
		G.ui.toast("SİNYAL KIRILDI — yankı hazinesi düştü")
		G.audio.jingle("boss")
		Quests.tick("fener")
		spawn_chest(_fener_pos)
		spawn_chest(_fener_pos + Vector2(46, 6))
		G.run.drop_fragments(_fener_pos, G.ri(40, 60))
		var fiid := Items.roll(G.run.luck + 0.35)
		if fiid != "":
			spawn_loot(fiid, _fener_pos + Vector2(-46, 6))

func _tick_motes(d: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for m in motes:
		var s: Sprite2D = m.s
		s.position += m.vel * d
		s.position.x += sin(t + m.ph) * 6.0 * d
		if s.position.x < -W * 0.5 - 40: s.position.x = W * 0.5 + 40
		if s.position.x > W * 0.5 + 40: s.position.x = -W * 0.5 - 40
		if s.position.y < -H * 0.5 - 40: s.position.y = H * 0.5 + 40
		if s.position.y > H * 0.5 + 40: s.position.y = -H * 0.5 - 40

# Kizil Col: ara ara kum firtinasi eser — tum sahayi tek yone iter.
# Donmus Catlak: ayni ritimde DONMUS BORA iner — daha zayif iter ama
# boranin altindaki suru chill alir (yaris yariya yavaslar); pencereyi
# kesim icin kullanmak bolgenin taktiigidir.
func _tick_storm(d: float) -> void:
	if is_hub or (biome != 6 and biome != 8):
		return
	if storm_t > 0.0:
		storm_t -= d
		var push := storm_dir * (46.0 if biome == 6 else 30.0) * d
		if G.player != null and not G.player.dead:
			G.player.pos += push
		for e in G.enemies:
			if is_instance_valid(e) and not e.dead:
				e.pos += push * 1.25
				if biome == 8:
					e.chill_t = maxf(e.chill_t, 0.5)
		for m in motes:
			m.s.position += storm_dir * 200.0 * d
		if storm_t <= 0.0:
			storm_cd = rng.randf_range(36.0, 55.0)
		return
	storm_cd -= d
	if storm_cd <= 0.0:
		storm_t = 7.0
		storm_dir = Vector2.RIGHT.rotated(rng.randf_range(-0.45, 0.45) + (PI if rng.randf() < 0.5 else 0.0))
		if biome == 8:
			G.ui.toast("DONMUS BORA — suru donakalir")
		else:
			G.ui.toast("KUM FIRTINASI — ruzgara karsi koy")
		G.audio.play("dash", 0.5, 0.8)

# HoT-style side objective: stand by the resonance cluster to charge it;
# a full charge cracks it open into two chests. Progress persists.
func spawn_monolith(p: Vector2) -> void:
	if mono_active:
		return
	mono_active = true
	mono_pos = p
	var node := Sprite2D.new()
	node.texture = Px.S("crystal")
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.modulate = Px.C("c26bff")
	node.scale = Vector2.ONE * 1.8
	node.position = p
	node.z_index = int(p.y)
	add_child(node)
	var ring := Sprite2D.new()
	ring.texture = Px.S("ring")
	ring.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ring.modulate = Color(0.76, 0.42, 1.0, 0.35)
	ring.scale = Vector2.ONE * (140.0 * 2.0 / 96.0)
	ring.position = p
	ring.z_index = -2000
	add_child(ring)
	G.fx.mk_light(node, Vector2(0, -10), Px.C("c26bff"), 0.9, 2.2)
	mono = {"pos": p, "t": 0.0, "need": 14.0, "node": node, "ring": ring}
	G.audio.jingle("boon")
	G.ui.toast("REZONANS KÜMESİ doğdu — yakınında dur, şarj et")

func _tick_sarkit(d: float) -> void:
	# Simithar (biome 1): tavan sarkıtları rastgele telegraph'la düşer — iki tarafı da vurur
	if is_hub or biome != 1:
		return
	sarkit_cd -= d
	if sarkit_cd > 0.0:
		return
	sarkit_cd = rng.randf_range(6.5, 10.5)
	var base: Vector2 = G.player.pos if (G.player != null and not G.player.dead) else Vector2.ZERO
	var p := base + Vector2(rng.randf_range(-260.0, 260.0), rng.randf_range(-260.0, 260.0))
	p.x = clampf(p.x, -W * 0.5 + 70.0, W * 0.5 - 70.0)
	p.y = clampf(p.y, -H * 0.5 + 70.0, H * 0.5 - 70.0)
	hazards.append({"pos": p, "r": 90.0, "dps": 0.0, "kind": "sarkit", "t": 1.4, "tele": G.fx.tele_circle(p, 90.0, 1.4, Color(0.85, 0.68, 0.35, 0.26))})

func _tick_monolith(d: float) -> void:
	if not mono_active or G.player == null or G.player.dead:
		return
	var p: Vector2 = mono.pos
	if G.player.pos.distance_to(p) < 140.0:
		mono.t = float(mono.t) + d
		mono.node.scale = Vector2.ONE * (1.8 + 0.4 * (float(mono.t) / float(mono.need)))
		mono.ring.modulate.a = 0.2 + 0.6 * (float(mono.t) / float(mono.need))
		if float(mono.t) >= float(mono.need):
			mono_active = false
			mono_pos = Vector2.ZERO
			mono.node.queue_free()
			mono.ring.queue_free()
			mono = {}
			spawn_chest(p + Vector2(-40, 0))
			spawn_chest(p + Vector2(40, 0))
			G.fx.burst(p + Vector2(0, -20), Px.C("c26bff"), 30, 260.0, 6.0, 0.7)
			G.fx.flash(Px.C("7B1FA2"), 0.35)
			G.audio.jingle("boss")
			G.ui.toast("küme çözüldü — çift sandık")

# DAMAR JEOTU: çukurda beliren çatlak kristal yumru — yanında durup
# kanal verince kırılır ve parçacık saçar; ama yarı yolda ve kırılımda
# damar golemleri üstüne çöker (risk/ödül)
func spawn_geode(p: Vector2) -> void:
	if geo_active:
		return
	geo_active = true
	geo_pos = p
	_geo_g1 = false
	var node := Sprite2D.new()
	node.texture = Px.S("crystal")
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.modulate = Px.C("4dd0e1")
	node.scale = Vector2.ONE * 2.4
	node.position = p
	node.z_index = int(p.y)
	add_child(node)
	var ring := Sprite2D.new()
	ring.texture = Px.S("ring")
	ring.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ring.modulate = Color(0.3, 0.85, 0.9, 0.35)
	ring.scale = Vector2.ONE * (150.0 * 2.0 / 96.0)
	ring.position = p
	ring.z_index = -2000
	add_child(ring)
	G.fx.mk_light(node, Vector2(0, -12), Px.C("4dd0e1"), 1.0, 2.6)
	geo = {"pos": p, "t": 0.0, "need": 10.0, "node": node, "ring": ring}
	G.audio.jingle("boon")
	G.ui.toast("DAMAR JEOTU açıldı — çatlak parlıyor; kırmak için yanında dur")

func _tick_geode(d: float) -> void:
	if not geo_active or G.player == null or G.player.dead:
		return
	var p: Vector2 = geo.pos
	if G.player.pos.distance_to(p) < 150.0:
		geo.t = float(geo.t) + d
		geo.node.scale = Vector2.ONE * (2.4 + 0.5 * (float(geo.t) / float(geo.need)))
		geo.node.modulate = Px.C("4dd0e1").lerp(Color(1, 1, 1), 0.35 * (float(geo.t) / float(geo.need)))
		geo.ring.modulate.a = 0.2 + 0.6 * (float(geo.t) / float(geo.need))
		if not _geo_g1 and float(geo.t) >= float(geo.need) * 0.5:
			_geo_g1 = true
			G.ui.toast("jeot bağırıyor — damarın bekçileri duydu")
			G.audio.play("door", 0.8, 0.4)
			for i in 2:
				var sp := p + Vector2(G.rf(-130, 130), G.rf(-130, 130))
				var e := Enemy.spawn(Enemy.EKind.DAMARGOL, clamp_pos(sp, 30.0), false, G.director._hp_scale(), G.director._dmg_scale(), self)
				e.set_meta("add", true)
		if float(geo.t) >= float(geo.need):
			geo_active = false
			geo_pos = Vector2.ZERO
			geo.node.queue_free()
			geo.ring.queue_free()
			geo = {}
			G.run.drop_fragments(p, 70)
			G.meta.data["geodes"] = int(G.meta.data.get("geodes", 0)) + 1
			G.meta.save()
			G.fx.burst(p + Vector2(0, -16), Px.C("4dd0e1"), 36, 300.0, 7.0, 0.7)
			G.fx.flash(Px.C("4dd0e1"), 0.4)
			G.fx.shake(0.4, 0.35)
			G.audio.jingle("boss")
			for i in 2:
				var sp := p + Vector2(G.rf(-150, 150), G.rf(-150, 150))
				var e := Enemy.spawn(Enemy.EKind.DAMARGOL, clamp_pos(sp, 30.0), true, G.director._hp_scale() * 1.05, G.director._dmg_scale(), self)
				e.set_meta("add", true)
			G.ui.toast("jeot kırıldı — damar saçıldı; bekçiler öfkeli")

# Gezgin Tüccar: koşu ortasında beliren tek-alışverişlik dükkân. Yanına
# yürümek paneli açar; satın alınca kovar, almadan çıkarsan geri dönebilirsin.
func spawn_merchant(p: Vector2) -> void:
	if merchant_active:
		return
	merchant_active = true
	merchant_pos = p
	_merch_armed = true
	var node := Sprite2D.new()
	var wrap := Node2D.new()   # karşı-eğim: tüccar ve etiketi eğik zeminde dik durur
	wrap.transform = Transform2D(0.0, p) * G.SHEAR_INV
	wrap.z_index = int(p.y)
	add_child(wrap)
	node.texture = Px.S2("npc2_ahusk")
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.offset = Vector2(0, -node.texture.get_height() * 0.5)
	Px.fit(node, 72.0)
	wrap.add_child(node)
	var tag := Label.new()
	tag.text = "GEZGİN TÜCCAR"
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_font_override("font", Ui.ui_font())
	tag.add_theme_color_override("font_color", Px.C("ffd700"))
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 3)
	tag.position = Vector2(-52, -88)
	tag.z_index = 500
	wrap.add_child(tag)
	G.fx.mk_light(node, Vector2(0, -18), Px.C("ffd700"), 0.8, 2.0)
	merchant = {"node": wrap, "tag": tag}
	G.audio.jingle("boon")
	G.ui.toast("GEZGİN TÜCCAR sahada — yanına git")

func despawn_merchant() -> void:
	merchant_active = false
	merchant_pos = Vector2.ZERO
	if is_instance_valid(merchant.get("node")):
		merchant.node.queue_free()
	if is_instance_valid(merchant.get("tag")):
		merchant.tag.queue_free()
	merchant = {}

# Kayıp Şasi: koşu ortasında beliren devre dışı gövde. Onarmak ◈60 harcar ve
# minnetle bir eşya bırakır; parçalamak ◈140 verir ama azap yazar.
func spawn_stray(p: Vector2) -> void:
	if stray_active:
		return
	stray_active = true
	stray_pos = p
	_stray_armed = true
	var node := Sprite2D.new()
	var wrap := Node2D.new()
	wrap.transform = Transform2D(0.0, p) * G.SHEAR_INV
	wrap.z_index = int(p.y)
	add_child(wrap)
	node.texture = Px.S2("npc2_elyb")
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.offset = Vector2(0, -node.texture.get_height() * 0.5)
	node.modulate = Color(0.75, 0.85, 0.95)
	Px.fit(node, 68.0)
	wrap.add_child(node)
	var tag := Label.new()
	tag.text = "KAYIP ŞASİ"
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_font_override("font", Ui.ui_font())
	tag.add_theme_color_override("font_color", Px.C("8fd4ff"))
	tag.add_theme_color_override("font_outline_color", Color.BLACK)
	tag.add_theme_constant_override("outline_size", 3)
	tag.position = Vector2(-42, -84)
	tag.z_index = 500
	wrap.add_child(tag)
	G.fx.mk_light(node, Vector2(0, -14), Px.C("8fd4ff"), 0.6, 1.6)
	stray = {"node": wrap, "tag": tag}
	G.audio.play("door", 0.7, 0.5)
	G.ui.toast("KAYIP ŞASİ sahada — yanına git")

func despawn_stray() -> void:
	stray_active = false
	stray_pos = Vector2.ZERO
	if is_instance_valid(stray.get("node")):
		stray.node.queue_free()
	if is_instance_valid(stray.get("tag")):
		stray.tag.queue_free()
	stray = {}

# zararsiz saha yasami: arena basina birkac sürüngen gezer; oyuncudan kaçar,
# yakalanirsa ufak parçacık bırakır (BG2 yaban hayatı — dünyayı canlı tutar)
func _scatter_critters() -> void:
	var ft: Array = Px.F("c_varl").get("idle", [])
	for i in 6:
		var s := Sprite2D.new()
		s.texture = ft[0] if not ft.is_empty() else Px.S("dot")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		Px.fit(s, 20.0)
		s.modulate = Color(0.95, 0.85, 0.5, 0.85)
		s.position = Vector2(rng.randf_range(BOUNDS.position.x + 90, BOUNDS.end.x - 90), rng.randf_range(BOUNDS.position.y + 90, BOUNDS.end.y - 90))
		s.z_index = 30
		add_child(s)
		critters.append({"s": s, "vel": Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 30))})

func _tick_critters(d: float) -> void:
	if critters.is_empty() or G.player == null or G.player.dead:
		return
	for i in range(critters.size() - 1, -1, -1):
		var c: Dictionary = critters[i]
		var s: Sprite2D = c.s
		if not is_instance_valid(s):
			critters.remove_at(i)
			continue
		var to_p: Vector2 = s.position - G.player.pos
		var dist := to_p.length()
		if dist < 24.0 and not bool(c.get("pet", false)):
			critters.remove_at(i)
			# Ağıl binası: yakalanan sürüngen kampın hayvanı olur, koşu başına öder
			if is_instance_valid(G.meta) and G.meta.has_build("ahir") and int(G.meta.data.get("pets", 0)) < 12 and not is_hub:
				G.meta.data["pets"] = int(G.meta.data.get("pets", 0)) + 1
				G.meta.save()
				G.ui.toast("sürüngen ağıla döndü (%d/12)" % int(G.meta.data.get("pets", 0)))
			else:
				G.run.drop_fragments(s.position, 3)
			G.fx.burst(s.position, Px.C("e8c468"), 8, 90.0, 3.0, 0.4)
			G.audio.play("pickup", G.rf(1.2, 1.4), 0.35)
			s.queue_free()
			continue
		if dist < 110.0:
			c.vel = to_p.normalized() * 130.0
		elif rng.randf() < 0.02:
			c.vel = Vector2(rng.randf_range(-40, 40), rng.randf_range(-40, 40))
		s.position += c.vel * d
		if not inside(s.position, 30.0):
			c.vel = -c.vel
			s.position = clamp_pos(s.position, 30.0)
		s.flip_h = c.vel.x < 0

# gizli zulalar: arena basina 2 gömülü sandık — toprağa gömülü görünür,
# kenar işareti yok; üstüne yürüyen keşfeder (açık dünya keşif teşviki)
func _scatter_caches() -> void:
	for i in 2:
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 120, BOUNDS.end.x - 120), rng.randf_range(BOUNDS.position.y + 120, BOUNDS.end.y - 120))
		var s := Sprite2D.new()
		s.texture = Px.S("crate")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.modulate = Color(0.30, 0.26, 0.21, 0.95)
		s.scale = Vector2.ONE * 0.68
		s.position = p
		s.z_index = int(p.y) - 1
		add_child(s)
		caches.append(s)

# grind yakıtı: altın damar düğümü — 90px içinde 2.6sn kazınca parçacık saçar
func _scatter_veins() -> void:
	if rtype == Type.BOSS:
		return
	for i in 2:
		var p := Vector2(rng.randf_range(BOUNDS.position.x + 140, BOUNDS.end.x - 140), rng.randf_range(BOUNDS.position.y + 140, BOUNDS.end.y - 140))
		var s := Sprite2D.new()
		s.texture = Px.S("crystal")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.modulate = Px.C("ffd75f")
		s.scale = Vector2.ONE * 1.25
		s.position = p
		s.z_index = int(p.y)
		add_child(s)
		G.fx.mk_light(s, Vector2(0, -12), Px.C("ffd75f"), 0.8, 1.8)
		veins.append({"node": s, "pos": p, "t": 0.0, "need": 2.6})

func _tick_veins(d: float) -> void:
	if veins.is_empty() or G.player == null or G.player.dead:
		return
	for i in range(veins.size() - 1, -1, -1):
		var v: Dictionary = veins[i]
		var s: Sprite2D = v["node"]
		if not is_instance_valid(s):
			veins.remove_at(i)
			continue
		if G.player.pos.distance_to(v["pos"]) < 90.0:
			v["t"] = float(v["t"]) + d
			var pr := float(v["t"]) / float(v["need"])
			s.scale = Vector2.ONE * (1.25 + 0.5 * pr)
			s.rotation = sin(Time.get_ticks_msec() * 0.02) * 0.08 * pr
			if float(v["t"]) >= float(v["need"]):
				veins.remove_at(i)
				var p: Vector2 = v["pos"]
				s.queue_free()
				G.fx.burst(p, Px.C("ffd75f"), 26, 240.0, 6.0, 0.7)
				G.fx.light_flash(p, Px.C("ffd75f"), 1.8, 2.6, 0.35)
				G.fx.shake(0.14, 0.22)
				G.audio.jingle("boon")
				G.ui.toast("CHORALİM DAMARI kırıldı — parçacık saçıldı")
				G.run.drop_fragments(p, G.ri(16, 26))
				Quests.tick("vein")
				G.run.stats["veins"] = int(G.run.stats.get("veins", 0)) + 1
				if G.chance(0.3):
					spawn_special(G.pick(["heal", "boost", "guard", "iksir"]), p + Vector2(0, -14))

func _tick_caches() -> void:
	if caches.is_empty() or G.player == null or G.player.dead:
		return
	for i in range(caches.size() - 1, -1, -1):
		var s: Sprite2D = caches[i]
		if not is_instance_valid(s):
			caches.remove_at(i)
			continue
		if s.position.distance_to(G.player.pos) < 46.0:
			caches.remove_at(i)
			var p := s.position
			s.queue_free()
			G.fx.burst(p, Px.C("c9a227"), 20, 160.0, 5.0, 0.6)
			G.fx.light_flash(p, Px.C("ffd75f"), 1.4, 2.2, 0.3)
			G.audio.jingle("boon")
			G.ui.toast("GÖMÜLÜ SANDIK — eski bir zula buldun")
			G.run.drop_fragments(p, G.ri(10, 18))
			if G.chance(0.5):
				var iid := Items.roll(G.run.luck)
				if iid != "":
					spawn_loot(iid, p + Vector2(0, -12))

func _tick_stray(_d: float) -> void:
	if not stray_active or G.player == null or G.player.dead:
		return
	var dist := G.player.pos.distance_to(stray_pos)
	if dist > 160.0:
		_stray_armed = true
	if not _stray_armed or G.ui.overlay_open():
		return
	if dist < 50.0:
		_stray_armed = false
		G.ui.stray_panel()

func _tick_merchant(_d: float) -> void:
	if not merchant_active or G.player == null or G.player.dead:
		return
	var dist := G.player.pos.distance_to(merchant_pos)
	# panel ancak oyuncu uzaklaşınca tekrar kurulur — dibinde kapanıp-açılma yok
	if dist > 160.0:
		_merch_armed = true
	if not _merch_armed or G.ui.overlay_open():
		return
	if dist < 52.0:
		_merch_armed = false
		G.ui.merchant_panel()

func _tick_doors() -> void:
	if G.player == null or G.player.dead or _door_cd > 0:
		return
	for d in doors:
		if d.locked:
			continue
		# door pos sits inside the wall band; the player can't reach it, so
		# test a forgiving box instead of a point distance
		if absf(G.player.pos.x - d.pos.x) < 58.0 and absf(G.player.pos.y - d.pos.y) < 46.0:
			_door_cd = 1.0
			G.audio.play("door", 1.0, 0.7)
			if d.get("gate", false) and is_hub:
				G.run.start_run()
			elif d.get("descend", false):
				G.run.descend()
			else:
				G.run.next_room(d.reward)
			return

func _tick_hazards(d: float) -> void:
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]
		if h.has("node") and h.get("t", -1.0) > 0:
			h.t -= d
			if h.t <= 0:
				if is_instance_valid(h.node):
					h.node.queue_free()
				if is_instance_valid(h.get("light")):
					h.light.queue_free()
				hazards.remove_at(i)
				continue
		if G.player == null or G.player.dead:
			continue
		var dist: float = G.player.pos.distance_to(h.pos)
		if h.kind == "vent":
			h.t -= d
			if h.erupt > 0:
				h.erupt -= d
				if dist < h.r:
					G.player.take_hit({"dmg": 42.0 * d, "type": G.DamageType.HAZARD, "from": h.pos, "source": self})
			elif h.t <= 0:
				if h.t <= -1.0:
					h.erupt = 0.6
					h.t = rng.randf_range(4.0, 7.0)
					if is_instance_valid(h.tele.sr):
						h.tele.sr.modulate.a = 0.12
					G.fx.burst(h.pos, Px.C(str(h.get("col", "00E676"))), 14, 130.0, 4.0, 0.4)
					if bool(h.get("gusher", false)):
						for g in 5:
							spawn_gem(h.pos + Vector2(rng.randf_range(-60, 60), rng.randf_range(-60, 60)), float(rng.randi_range(2, 5)))
					G.audio.play("explode", 1.6, 0.3)
				elif is_instance_valid(h.tele.sr):
					h.tele.sr.modulate.a = 0.5  # warning flare
		elif h.kind == "coro":
			# Aeterna çan alanı: nabız attığında içindeki düşmanlar kısa süre hızlanır
			h.t -= d
			if h.t <= 0.0:
				h.t = rng.randf_range(3.0, 4.5)
				if is_instance_valid(h.tele.sr):
					h.tele.sr.modulate.a = 0.4
				for e in G.enemies:
					if is_instance_valid(e) and e.pos.distance_to(h.pos) < h.r:
						e.lead_t = maxf(e.lead_t, 1.4)
				G.fx.burst(h.pos, Px.C("c9a227"), 10, 90.0, 3.0, 0.35)
				G.audio.play("boon", 1.2, 0.2)
			elif is_instance_valid(h.get("tele", {}).get("sr")) and h.tele.sr.modulate.a > 0.12:
				h.tele.sr.modulate.a = maxf(0.12, h.tele.sr.modulate.a - d * 0.4)
		elif h.kind == "ark":
			# Sol Primus ark sizintisi: nabiz attikca alandan suruye zincirleme yildirim atlar
			h.t -= d
			if h.t <= 0.0:
				h.t = rng.randf_range(3.2, 4.8)
				if is_instance_valid(h.tele.sr):
					h.tele.sr.modulate.a = 0.42
				var prev: Vector2 = h.pos
				var hit_ids := {}
				for hop in 4:
					var best: Enemy = null
					var bd := 1e9
					for e in G.enemies:
						if not is_instance_valid(e) or e.dead or hit_ids.has(e.get_instance_id()):
							continue
						var ed: float = e.pos.distance_to(prev)
						if (hop == 0 and ed < float(h.r)) or (hop > 0 and ed < 240.0 and ed < bd):
							best = e
							bd = ed
					if best == null:
						break
					hit_ids[best.get_instance_id()] = true
					_ark_bolt(prev, best.pos)
					best.take_hit({"dmg": 30.0 * (1.0 + biome * 0.15), "type": G.DamageType.HAZARD, "from": prev, "source": self, "ark": true})
					prev = best.pos
				if dist < h.r:
					G.player.take_hit({"dmg": 14.0, "type": G.DamageType.HAZARD, "from": h.pos, "source": self})
				G.audio.play("zap", 1.3, 0.4)
			elif is_instance_valid(h.get("tele", {}).get("sr")) and h.tele.sr.modulate.a > 0.12:
				h.tele.sr.modulate.a = maxf(0.12, h.tele.sr.modulate.a - d * 0.4)
		elif h.kind == "sarkit":
			h.t -= d
			if h.t <= 0.0:
				if h.has("tele"):
					G.fx.kill_tele(h.tele)
				G.fx.burst(h.pos, Px.C("c8a860"), 18, 210.0, 5.0, 0.5)
				G.fx.shake(0.22, 0.3)
				G.audio.play("hitHeavy", 0.9, 0.6)
				for e in G.enemies:
					if is_instance_valid(e) and not e.dead and e.pos.distance_to(h.pos) < float(h.r):
						e.take_hit({"dmg": 46.0 * (1.0 + biome * 0.1), "type": G.DamageType.HAZARD, "from": h.pos, "source": self, "sarkit": true})
				if dist < h.r:
					G.player.take_hit({"dmg": 24.0, "type": G.DamageType.HAZARD, "from": h.pos, "source": self})
				hazards.remove_at(i)
				continue
		elif h.kind == "surgun":
			# gezici kum hortumu: alanı süpürür, içindekini döndürerek iter
			# t>0 ise fırtına hortumu — süresi dolunca tele'i temizleyip düşer
			if float(h.get("t", -1.0)) > 0.0:
				h.t -= d
				if h.t <= 0.0:
					if h.has("tele"):
						G.fx.kill_tele(h.tele)
					G.fx.burst(h.pos, Px.C("e8a050"), 16, 110.0, 4.0, 0.5)
					hazards.remove_at(i)
					continue
			h.sway = float(h.get("sway", 0.0)) + d
			var v: Vector2 = h.get("vel", Vector2.ZERO)
			v = v.rotated(sin(float(h.sway) * 0.7) * d * 1.5)
			h.pos += v * d
			var b: Rect2 = BOUNDS.grow(-h.r)
			if h.pos.x < b.position.x or h.pos.x > b.end.x:
				v.x = -v.x
				h.pos.x = clampf(h.pos.x, b.position.x, b.end.x)
			if h.pos.y < b.position.y or h.pos.y > b.end.y:
				v.y = -v.y
				h.pos.y = clampf(h.pos.y, b.position.y, b.end.y)
			h.vel = v
			if is_instance_valid(h.tele.sr):
				h.tele.sr.global_position = h.pos
				h.tele.sr.rotation += d * 1.4
				h.tele.sr2.global_position = h.pos
				h.tele.sr2.rotation -= d * 0.9
			if dist < h.r:
				G.player.take_hit({"dmg": h.dps * d, "type": G.DamageType.HAZARD, "from": h.pos, "source": self})
				var away: Vector2 = (G.player.pos - h.pos).normalized()
				G.player.pos += (away.rotated(PI * 0.5) * 70.0 + away * 30.0) * d
		elif h.kind == "toxic":
			# iki tarafli gaz: oyuncuya hafif, suruye agir — cekerek kullanilir
			if dist < h.r:
				G.player.take_hit({"dmg": h.dps * d, "type": G.DamageType.HAZARD, "from": h.pos, "source": self})
			for e in G.enemies:
				if is_instance_valid(e) and not e.dead and e.pos.distance_to(h.pos) < h.r:
					e.take_hit({"dmg": h.dps * 1.7 * d, "type": G.DamageType.HAZARD, "from": h.pos, "source": self})
		elif h.dps > 0 and dist < h.r:
			G.player.take_hit({"dmg": h.dps * d, "type": G.DamageType.HAZARD, "from": h.pos, "source": self})
	for i in range(slows.size() - 1, -1, -1):
		var s: Dictionary = slows[i]
		if s.get("t", -1.0) > 0:
			s.t -= d
			if s.t <= 0:
				if is_instance_valid(s.node):
					s.node.queue_free()
				slows.remove_at(i)

# ark sizintisi zincir cizgisi: bir karenin onda biri kadar yanip soner
func _ark_bolt(a: Vector2, b: Vector2) -> void:
	var ln := Line2D.new()
	var pts := PackedVector2Array()
	pts.append(a)
	for j in range(1, 4):
		pts.append(a.lerp(b, float(j) / 4.0) + Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-14.0, 14.0)))
	pts.append(b)
	ln.points = pts
	ln.width = 3.0
	ln.default_color = Px.C("9fe4ff")
	ln.z_index = 90
	add_child(ln)
	var tw := create_tween()
	tw.tween_property(ln, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func(): if is_instance_valid(ln): ln.queue_free())

func _tick_pickups(d: float) -> void:
	if G.player == null:
		return
	_merge_t -= d
	if _merge_t <= 0.0:
		_merge_t = 80.0
		_merge_gems()
	var magnet := 90.0
	if G.player is Player:
		magnet = G.player.magnet_r
	for pk in pickups_node.get_children():
		var dist: float = pk.position.distance_to(G.player.pos)
		if str(pk.get_meta("kind", "")) == "tome" and G.ui.overlay_open():
			continue   # tom draft açıkken tetiklenmesin — yerinde bekler
		if int(pk.get_meta("vac", 0)) == 1 or dist < magnet:
			pk.position = pk.position.move_toward(G.player.pos, (340.0 + (magnet - dist) * 4.0) * d)
		if str(pk.get_meta("kind", "")) == "xp":
			var tw := float(pk.get_meta("tw", G.rf(0.0, TAU)))
			pk.set_meta("tw", tw + d)
			pk.modulate.a = 0.8 + sin(tw * 3.0) * 0.2
		if dist < 16:
			_collect(pk)

# VS-style consolidation: saçılan kristaller periyodik olarak tek dev kristalde
# birleşir — saha kırıntısı çürümeden değerini korur, magnet turları anlamlı kalır
func _merge_gems() -> void:
	var gems := []
	var total := 0.0
	var cen := Vector2.ZERO
	for pk in pickups_node.get_children():
		if str(pk.get_meta("kind", "")) != "xp":
			continue
		gems.append(pk)
		total += float(pk.get_meta("val", 0.0))
		cen += pk.position
	if gems.size() < 6:
		return
	cen /= gems.size()
	for pk in gems:
		pk.queue_free()
	spawn_gem(cen, total)
	G.fx.burst(cen, Px.C("c26bff"), 12, 140.0, 4.0, 0.4)
	G.audio.play("pickup", 1.8, 0.5)

func _collect(pk: Node) -> void:
	match str(pk.get_meta("kind", "frag")):
		"xp":
			var xv := float(pk.get_meta("val"))
			G.player.add_xp(xv)
			G.fx.burst(pk.position, Px.C("7fd4ff"), 4, 100.0, 2.5, 0.22)
			if xv >= 25.0:
				G.fx.float_text(pk.position + Vector2(0, -18), "+%d" % roundi(xv), Px.C("7fd4ff"), 0.85)
			G.audio.play("pickup", G.rf(1.2, 1.4), 0.35)
		"heal":
			G.player.heal(24.0 * (1.5 if G.player.has_meta("heal_plus") else 1.0))
			G.audio.play("heal", 1.0, 0.5)
			Quests.tick("sifa")
		"tome":
			G.fx.burst(pk.position, Px.C("c9a227"), 16, 160.0, 5.0, 0.5)
			G.ui.boon_choice()
		"vacuum":
			for g2 in pickups_node.get_children():
				if str(g2.get_meta("kind", "")) == "xp":
					g2.set_meta("vac", 1)
			G.audio.play("boon", 1.1, 0.5)
			G.ui.toast("rezonans dalgası — kristaller çekiliyor")
		"bomb":
			var boom_n := 0
			for e in G.enemies.duplicate():
				if e is Enemy and not e.dead:
					e.take_hit({"dmg": 55.0, "type": G.DamageType.EXPLOSION, "from": pk.position, "knock": 15.0, "stagger": 0.7, "source": G.player})
					boom_n += 1
			G.fx.burst(pk.position, Color(1, 0.55, 0.15), 30, 300.0, 7.0, 0.6)
			G.fx.light_flash(pk.position, Color(1, 0.7, 0.25), 2.6, 3.6, 0.3)
			G.fx.shake(0.22, 0.3)
			G.audio.play("explode", 0.8, 0.8)
			G.ui.toast("şok dalgası — %d kovan üyesi" % boom_n)
		"freeze":
			for e in G.enemies.duplicate():
				if e is Enemy and not e.dead:
					e.take_hit({"dmg": 1.0, "type": G.DamageType.SHOCK, "from": pk.position, "stagger": 4.5, "source": G.player})
					if is_instance_valid(e.body):
						e.body.modulate = Px.C("8fd4ff")
			G.audio.play("dash", 0.7, 0.6)
			G.ui.toast("durdurucu alan — kovan donuyor")
		"boost":
			G.player.boost_t = 10.0
			G.audio.play("dash", 1.2, 0.5)
			G.ui.toast("yükleme kalıntısı — saldırılar %35 hızlanıyor")
		"guard":
			G.player.invuln = maxf(G.player.invuln, 3.0)
			G.audio.play("parry", 1.0, 0.6)
			G.ui.toast("koruyucu zarf — 3sn dokunulmaz")
		"iksir":
			if G.player.iksir_n >= (3 if not is_instance_valid(G.meta) or not G.meta.has_build("umbar") else 4):
				G.run.drop_fragments(pk.position, 5)
				G.ui.toast("iksir karnen dolu — parçacığa döndü")
			else:
				G.player.iksir_n += 1
				G.ui.toast("CHORALİM İKSİRİ +1 — R ile içilir")
			G.audio.play("pickup", 1.5, 0.45)
		"sarap":
			if G.player.sarap_n >= (2 if not is_instance_valid(G.meta) or not G.meta.has_build("umbar") else 3):
				G.run.drop_fragments(pk.position, 5)
				G.ui.toast("şarap karnen dolu — parçacığa döndü")
			else:
				G.player.sarap_n += 1
				G.ui.toast("KOR ŞARABI +1 — T ile içilir")
			G.audio.play("pickup", 1.6, 0.45)
		"egg":
			G.meta.data["eggs"] = int(G.meta.data.get("eggs", 0)) + 1
			G.meta.save()
			G.player.dmg_mult *= 1.005
			G.audio.play("boon", 1.4, 0.7)
			G.ui.toast("ALTIN NÜVE — kalıcı +%%0.5 hasar (toplam %d)" % int(G.meta.data["eggs"]))
		"lore":
			# veri kütüğü: bulunmamış ilk kaydı ÖYKÜ codex'ine yazar
			var found: Array = G.meta.data.get("lore", [])
			var nxt := ""
			for le in Quests.LORE:
				if not found.has(str(le.id)):
					nxt = str(le.id)
					break
			if nxt == "":
				G.meta.data["choralim"] = int(G.meta.data.get("choralim", 0)) + 20
				G.ui.toast("kütük zaten kayıtlı — ◆20")
			else:
				found.append(nxt)
				G.meta.data["lore"] = found
				for le in Quests.LORE:
					if str(le.id) == nxt:
						G.ui.toast("VERİ KÜTÜĞÜ — %s (Zirkon'da oku)" % str(le.name))
						break
			G.meta.save()
			G.audio.play("boon", 1.3, 0.6)
		"cursed":
			G.ui.toast("LANETLİ SANDIK — pusu!")
			G.audio.play("alarm", 0.9, 0.6)
			G.fx.shake(6.0, 0.4)
			for i in 9:
				var ang := TAU * float(i) / 9.0 + G.rf(-0.2, 0.2)
				var sp := clamp_pos(pk.position + Vector2.from_angle(ang) * G.rf(240.0, 320.0), 40.0)
				var ek: int = G.pick([Enemy.EKind.VARL, Enemy.EKind.HUSK, Enemy.EKind.DRONE, Enemy.EKind.SENTINEL])
				Enemy.spawn(ek, sp, G.chance(0.25), G.director._hp_scale(), G.director._dmg_scale(), self)
			spawn_chest(pk.position + Vector2(-30, 10))
			var ciid := Items.roll(G.run.luck + 0.15)
			if ciid != "":
				spawn_loot(ciid, pk.position + Vector2(30, 10))
			Quests.tick("cursed")
		"ceset":
			var cv := int(pk.get_meta("val", 0))
			G.run.fragments += cv
			G.ui.toast("eski cesedini buldun — +%d parçacık" % cv)
			G.audio.jingle("boon")
			G.fx.light_flash(pk.position, Px.C("9be8ff"), 1.8, 2.4, 0.4)
			Quests.tick("ceset")
		"totem":
			if not _trial_elites.is_empty():
				return
			_trial_pos = pk.position
			G.ui.toast("DENEME TOTEMİ — iki elit doğuyor; ikisini de kes")
			G.audio.play("alarm", 1.1, 0.6)
			G.fx.tele_ring(pk.position, 220.0, 0.9, Color(1.0, 0.4, 0.2, 0.45))
			for i in 2:
				var ang := TAU * float(i) / 2.0 + G.rf(0.0, 0.5)
				var sp := clamp_pos(pk.position + Vector2.from_angle(ang) * 220.0, 40.0)
				var ek: int = G.pick([Enemy.EKind.ALFA, Enemy.EKind.SENTINEL, Enemy.EKind.KONAKCI])
				_trial_elites.append(Enemy.spawn(ek, sp, true, G.director._hp_scale() * 1.1, G.director._dmg_scale(), self))
		"fener":
			if not _fener_champs.is_empty():
				return
			_fener_pos = pk.position
			G.ui.toast("SİNYAL FENERİ — ikiz yankı uyandı")
			G.audio.play("alarm", 0.9, 0.7)
			G.fx.tele_ring(pk.position, 240.0, 1.0, Color(1.0, 0.2, 0.3, 0.5))
			for i in 2:
				var ang := TAU * float(i) / 2.0 + G.rf(0.0, 0.5)
				var sp := clamp_pos(pk.position + Vector2.from_angle(ang) * 230.0, 40.0)
				var ek: int = G.pick([Enemy.EKind.ALFA, Enemy.EKind.KONAKCI])
				var e := Enemy.spawn(ek, sp, true, G.director._hp_scale() * 1.2, G.director._dmg_scale() * 1.1, self)
				e.promote_champ()
				_fener_champs.append(e)
		"mahkum":
			# kafesteki yolcu: kır, serbest bırak — Aşçı Mina kampa katılır
			if bool(G.meta.data.get("rescued_mina", false)):
				return
			G.meta.data["rescued_mina"] = true
			G.meta.save()
			G.fx.burst(pk.position + Vector2(0, -20), Px.C("d4a017"), 22, 200.0, 5.0, 0.6)
			G.fx.float_text(pk.position + Vector2(0, -50), "KURTARILDI", Px.C("ffd700"), 1.2)
			G.fx.flash(Px.C("d4a017"), 0.2)
			G.audio.jingle("boss")
			G.ui.toast("bir yolcu serbest kaldı — Aşçı Mina kampa katılacak")
			for i in 3:
				spawn_heal(pk.position + Vector2(G.rf(-50, 50), G.rf(-36, 36)))
			G.run.drop_fragments(pk.position, G.ri(15, 25))
		"mahkum2":
			# ikinci kafes: Kartograf Lena — kampa katılır
			if bool(G.meta.data.get("rescued_lena", false)):
				return
			G.meta.data["rescued_lena"] = true
			G.meta.save()
			G.fx.burst(pk.position + Vector2(0, -20), Px.C("7fb3c9"), 22, 200.0, 5.0, 0.6)
			G.fx.float_text(pk.position + Vector2(0, -50), "KURTARILDI", Px.C("ffd700"), 1.2)
			G.fx.flash(Px.C("7fb3c9"), 0.2)
			G.audio.jingle("boss")
			G.ui.toast("bir yolcu serbest kaldı — Kartograf Lena kampa katılacak")
			for i in 3:
				spawn_heal(pk.position + Vector2(G.rf(-50, 50), G.rf(-36, 36)))
			G.run.drop_fragments(pk.position, G.ri(15, 25))
		"mahkum3":
			# üçüncü kafes: İhbarcı Orun — eski Koro sözcüsü, kampa katılır
			if bool(G.meta.data.get("rescued_orun", false)):
				return
			G.meta.data["rescued_orun"] = true
			G.meta.save()
			G.fx.burst(pk.position + Vector2(0, -20), Px.C("3ec8b8"), 22, 200.0, 5.0, 0.6)
			G.fx.float_text(pk.position + Vector2(0, -50), "KURTARILDI", Px.C("ffd700"), 1.2)
			G.fx.flash(Px.C("3ec8b8"), 0.2)
			G.audio.jingle("boss")
			G.ui.toast("bir yolcu serbest kaldı — İhbarcı Orun kampa katılacak")
			for i in 3:
				spawn_heal(pk.position + Vector2(G.rf(-50, 50), G.rf(-36, 36)))
			G.run.drop_fragments(pk.position, G.ri(15, 25))
		"sunak":
			# koro sunagi: can verirsin, kader kartlari acilir — kan yetmezse tapinak sessiz kalir
			if G.player == null or G.player.dead:
				return
			var scost := maxf(10.0, G.player.hp * 0.15)
			if G.player.hp <= scost + 1.0:
				G.ui.toast("KORO SUNAĞI sessiz — kanın yetmiyor")
				return
			G.player.hp -= scost
			G.player.set_flash()
			G.fx.burst(pk.position, Px.C("b39ddb"), 22, 200.0, 5.0, 0.55)
			G.fx.light_flash(pk.position, Px.C("b39ddb"), 2.0, 2.6, 0.35)
			G.audio.play("roar", 1.4, 0.35)
			G.ui.toast("KORO SUNAĞI — kan ödendi, kader konuşuyor")
			Quests.tick("sunak")
			G.ui.boon_choice()
		"chest":
			G.run.open_chest()
		"loot":
			var ld: Dictionary = Items.DEFS.get(str(pk.get_meta("item", "")), {})
			var lcol := Px.C(Items.RARITY_COL[int(ld.get("r", 0))]) if not ld.is_empty() else Px.C("c9a227")
			G.fx.burst(pk.position, lcol, 18, 170.0, 4.5, 0.45)
			G.fx.light_flash(pk.position, lcol, 1.8, 2.6, 0.3)
			G.audio.play("boon", 1.2, 0.55)
			Items.drop_to_run(str(pk.get_meta("item", "")))
			Quests.tick("loot")
		_:
			var fm: float = G.player.frag_mult if is_instance_valid(G.player) else 1.0
			G.run.fragments += int(int(pk.get_meta("val")) * fm)
			G.audio.play("pickup", G.rf(0.9, 1.1), 0.4)
	G.fx.burst(pk.position, pk.modulate if pk.modulate.a > 0.5 else Px.C("7B1FA2"), 4, 80.0, 3.0, 0.3)
	pk.queue_free()

func spawn_gem(p: Vector2, val: float) -> void:
	var pk := Sprite2D.new()
	var tex := Px.S2("crystal")
	if tex == null:
		tex = Px.S("dot")
	pk.texture = tex
	pk.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	pk.modulate = Px.C("00E5FF") if val < 3.0 else (Px.C("c26bff") if val < 10.0 else Px.C("ffb74d"))
	pk.scale = Vector2.ONE * (0.5 + minf(val, 12.0) * 0.035)
	pk.position = p + Vector2(G.rf(-26, 26), G.rf(-20, 20))
	pk.z_index = int(pk.position.y) - 1
	pk.set_meta("kind", "xp")
	pk.set_meta("val", val)
	pickups_node.add_child(pk)
	if val >= 10.0:
		G.fx.mk_light(pk, Vector2.ZERO, pk.modulate, 0.5, 1.1)

func spawn_chest(p: Vector2, _twin := false) -> void:
	var pk := Sprite2D.new()
	pk.texture = Px.S("crate")
	pk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pk.modulate = Px.C("ffb74d")
	pk.scale = Vector2.ONE * 0.85
	pk.position = p
	pk.z_index = int(p.y)
	pk.set_meta("kind", "chest")
	pickups_node.add_child(pk)
	G.fx.mk_light(pk, Vector2(0, -14), Px.C("ffb74d"), 0.7, 1.6)
	G.fx.float_text(p + Vector2(0, -34), "SANDIK!", Px.C("ffb74d"), 1.1)
	# İKİZ SANDIK kozu: her sandık yanına bir eş doğar
	if G.run != null and G.run.twin_chest and not _twin:
		var _to := Vector2(G.rf(34.0, 60.0) * (1.0 if randf() < 0.5 else -1.0), G.rf(-22.0, 22.0))
		spawn_chest(clamp_pos(p + _to, 60.0), true)

# rare field items (VS floor pickups): vacuum draws every gem in, bomb hits
# the whole swarm, freeze staggers it for a few seconds
func spawn_special(kind: String, p: Vector2) -> Sprite2D:
	var pk := Sprite2D.new()
	var col := "ffffff"
	match kind:
		"vacuum":
			pk.texture = Px.S("crystal")
			col = "00E5FF"
		"bomb":
			pk.texture = Px.S("spark")
			col = "ff5533"
		"freeze":
			pk.texture = Px.S("ring")
			col = "8fd4ff"
		"boost":
			pk.texture = Px.S("icn_dash")
			col = "ffb74d"
		"guard":
			pk.texture = Px.S("icn_upg_shield")
			col = "00E5FF"
		"iksir":
			pk.texture = Px.S2("icn_upg_hp") if Px.S2("icn_upg_hp") != null else Px.S("dot")
			col = "8affc9"
		"sarap":
			pk.texture = Px.S2("icn_dash") if Px.S2("icn_dash") != null else Px.S("dot")
			col = "ff7722"
		"egg":
			pk.texture = Px.S("icn_crown")
			col = "ffd700"
		"lore":
			pk.texture = Px.S2("ico_quest") if Px.S2("ico_quest") != null else Px.S("dot")
			col = "8fd4ff"
		"cursed":
			pk.texture = Px.S("crate")
			col = "ff3355"
		"ceset":
			pk.texture = Px.S2("por_rex") if Px.S2("por_rex") != null else Px.S("dot")
			col = "9be8ff"
		"totem":
			pk.texture = Px.S2("icn_skull") if Px.S2("icn_skull") != null else Px.S("dot")
			col = "ff6d3d"
		"sunak":
			pk.texture = Px.S2("icn_skull") if Px.S2("icn_skull") != null else Px.S("dot")
			col = "b39ddb"
		"fener":
			pk.texture = Px.S2("icn_crown") if Px.S2("icn_crown") != null else Px.S("dot")
			col = "ff3355"
		"mahkum":
			pk.texture = Px.S2("prop_mahkum") if Px.S2("prop_mahkum") != null else Px.S("dot")
			col = "d4a017"
		"mahkum2":
			pk.texture = Px.S2("prop_mahkum2") if Px.S2("prop_mahkum2") != null else Px.S("dot")
			col = "7fb3c9"
		"mahkum3":
			pk.texture = Px.S2("prop_mahkum3") if Px.S2("prop_mahkum3") != null else Px.S("dot")
			col = "3ec8b8"
	pk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pk.scale = Vector2.ONE * (0.95 if kind == "cursed" else (0.9 if kind in ["mahkum", "mahkum2", "mahkum3"] else 0.8))
	pk.modulate = Px.C(col)
	pk.position = p
	pk.z_index = int(p.y)
	pk.set_meta("kind", kind)
	pk.set_meta("val", 0)
	pickups_node.add_child(pk)
	G.fx.mk_light(pk, Vector2.ZERO, Px.C(col), 0.6, 1.4)
	return pk

# eşya düşüşü (HoT gear): elitlerden/bosslardan çıkar — üstüne bas, çantaya gir
func spawn_loot(iid: String, p: Vector2) -> void:
	var d: Dictionary = Items.DEFS.get(iid, {})
	if d.is_empty():
		return
	var pk := Sprite2D.new()
	pk.texture = Px.S2(str(d.get("icon", "ico_loot")))
	pk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pk.scale = Vector2.ONE * 1.5
	var col := Px.C(Items.RARITY_COL[int(d.get("r", 0))])
	pk.modulate = col
	pk.position = clamp_pos(p, 30.0)
	pk.z_index = int(p.y)
	pk.set_meta("kind", "loot")
	pk.set_meta("item", iid)
	pk.set_meta("val", 0)
	pickups_node.add_child(pk)
	G.fx.mk_light(pk, Vector2(0, -8), col, 0.8, 1.8)
	# loot beam: nadirliğe boyalı ışık sütunu — uzaktan okunur (BG2 ground-item glow)
	var beam := Polygon2D.new()
	beam.polygon = PackedVector2Array([Vector2(-5, -110), Vector2(5, -110), Vector2(2, -10), Vector2(-2, -10)])
	beam.color = Color(col.r, col.g, col.b, 0.3)
	pk.add_child(beam)
	var btw := pk.create_tween().set_loops()
	btw.set_trans(Tween.TRANS_SINE)
	btw.tween_property(beam, "color:a", 0.6, 0.9)
	btw.tween_property(beam, "color:a", 0.22, 0.9)
	G.fx.float_text(p + Vector2(0, -36), "%s!" % str(d.name), col, 0.95)

# HoT ability tome: üstüne basınca bedava lütuf taslağı açan saha kalıntısı
func spawn_tome(p: Vector2) -> void:
	var pk := Sprite2D.new()
	pk.texture = Px.S2("ico_boon")
	pk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pk.scale = Vector2.ONE * 1.7
	pk.modulate = Px.C("c9a227")
	pk.position = clamp_pos(p, 40.0)
	pk.z_index = int(pk.position.y)
	pk.set_meta("kind", "tome")
	pickups_node.add_child(pk)
	G.fx.mk_light(pk, Vector2(0, -8), Px.C("c9a227"), 0.7, 2.0)
	G.ui.toast("BİLGELİK TOMU belirdi — üstüne bas, lütuf seç")
	G.audio.jingle("boon")

func spawn_heal(p: Vector2) -> void:
	var pk := Sprite2D.new()
	pk.texture = Px.S("ico_heal")
	pk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pk.position = p + Vector2(G.rf(-30, 30), G.rf(-24, 24))
	pk.z_index = int(pk.position.y)
	pk.set_meta("kind", "heal")
	pickups_node.add_child(pk)

func spawn_fragments(p: Vector2, total: int) -> void:
	var n := clampi(int(total / 2.0), 3, 10)
	for i in n:
		var pk := Sprite2D.new()
		pk.texture = Px.S("ico_frag")
		pk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		pk.scale = Vector2.ONE * 0.7
		pk.position = p + Vector2(G.rf(-60, 60), G.rf(-40, 40))
		pk.z_index = int(pk.position.y)
		pk.set_meta("kind", "frag")
		pk.set_meta("val", int(ceilf(total / float(n))))
		pickups_node.add_child(pk)

func blood(p: Vector2, col: Color) -> void:
	var s := Sprite2D.new()
	s.texture = Px.S("splat")
	s.modulate = Color(col.r, col.g, col.b, 0.55)
	s.scale = Vector2.ONE * G.rf(0.3, 0.7)
	s.rotation = G.rf(0, TAU)
	s.position = p + Vector2(G.rf(-8, 8), G.rf(-4, 4))
	decals.add_child(s)
	if decals.get_child_count() > 30:
		decals.get_child(0).queue_free()
	# izler solup temizlenir — haritada kalıcı kan birikimi kalmaz
	var tw := create_tween()
	tw.tween_interval(Fx.SPLAT_LIFE * G.rf(0.7, 1.2))
	tw.tween_property(s, "modulate:a", 0.0, 3.0)
	var wr: WeakRef = weakref(s)
	tw.tween_callback(func():
		var _s: Sprite2D = wr.get_ref()
		if _s:
			_s.queue_free()
	)

func on_enemy_dead(e) -> void:
	if is_hub or e is Boss or e.has_meta("add"):
		return
	alive = maxi(0, alive - 1)
	if alive <= 0 and not cleared:
		if wave_idx < waves.size() - 1:
			await get_tree().create_timer(0.9).timeout
			if is_instance_valid(self) and not cleared:
				_next_wave()
		else:
			_clear()

func on_boss_dead(_b) -> void:
	# kill remaining adds, open the descend gate
	for e in G.enemies.duplicate():
		if is_instance_valid(e) and not e.dead and not (e is Boss):
			e.take_hit({"dmg": 9999.0, "type": G.DamageType.PURE, "from": e.pos, "source": self})
	G.ui.boss_bar(false, null)
	G.run.on_boss_dead()
	unlock_doors()
	# efendilerin ganimeti: garantili eşya + parçacık yağmuru
	if is_instance_valid(_b):
		var bp: Vector2 = _b.pos
		var iid := Items.roll(G.run.luck + 0.15)
		if iid != "":
			spawn_loot(iid, bp + Vector2(0, -10))
		G.run.drop_fragments(bp, G.ri(20, 32))
	G.audio.jingle("boss")

func _clear() -> void:
	cleared = true
	G.run.on_room_cleared()
	unlock_doors()
	G.audio.jingle("clear")
	G.fx.flash(Color(0, 0.9, 1, 0.05), 0.4)

func slow_at(p: Vector2) -> float:
	for s in slows:
		if p.distance_to(s.pos) < s.r:
			return 0.55
	return 1.0

func inside(p: Vector2, margin: float) -> bool:
	return BOUNDS.grow(-margin).has_point(p)

func clamp_pos(p: Vector2, r: float) -> Vector2:
	var out := Vector2(clampf(p.x, BOUNDS.position.x + r, BOUNDS.end.x - r), clampf(p.y, BOUNDS.position.y + r, BOUNDS.end.y - r))
	for q in props:
		var d := out.distance_to(q.pos)
		if d < q.r + r and d > 0.01:
			out = q.pos + (out - q.pos).normalized() * (q.r + r)
	return out

func _sort_children() -> void:
	for c in get_children():
		if c is Actor:
			c.z_index = int(c.pos.y)
