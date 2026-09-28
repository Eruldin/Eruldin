class_name NPC
extends Node2D

# Hub NPC — shows a prompt when Ely is near; E opens their dialogue.

static var NAMES := {
	"rhasa": "GENEL RHASA", "neva": "NEVA", "saphire": "SAPHIRE", "vane": "DR. VANE",
	"david": "İZ SÜRÜCÜ DAVID", "zirkon": "VEZİR ZİRKON", "ehnar": "ESKİ ŞÖVALYE EHNAR",
	"ahusk": "GÖÇEBE AHUSK", "elyb": "ELY-B", "mina": "AŞÇI MINA", "lena": "KARTOGRAF LENA",
	"tegan": "SİMSAR TEGAN", "orun": "İHBARCI ORUN"
}

# BG2 ortam replikleri — oyuncu yakınken NPC ara sıra mırıldanır
static var BARKS := {
	"rhasa":   ["kayıt tutuluyor.", "kovan sessiz değil.", "seni izliyorlar, ely."],
	"neva":    ["şarkı hâlâ sürüyor...", "geri döneceksin — hep dönersin.", "rezonans bugün temiz."],
	"saphire": ["tezgâh açık, al geç.", "hurda mı? getir.", "bu kristal saf değil."],
	"vane":    ["deney planı hazır.", "şasi senkronu iyi durumda.", "ölçüm bekliyorum."],
	"david":   ["harita güncel.", "kuzey sınırı temiz — şimdilik.", "efendiler bekliyor."],
	"zirkon":  ["kayıtlar senin lehine.", "arşiv büyüyor.", "savaş efendileri not edildi."],
	"ehnar":   ["sözleşme masada.", "sınır hâlâ sıcak.", "kılıç paslanmamalı."],
	"ahusk":   ["kovan kokusu...", "sis bugün kalın.", "geçit hâlâ açık."],
	"elyb":    ["uyku modu: %60.", "şasi sinyali stabil.", "hazırım."],
	"mina":    ["kazan sıcak.", "tarhana varsa her şey geçer.", "seni o kafesten çıkardılar — borç ödenmez."],
	"lena":    ["pusula hâlâ doğru — kovanın manyetik alanı dağıtamadı.", "her düğümün kokusu var; harita hafızadır.", "kafes günleri saydım, rotaları ezberledim."],
	"tegan":   ["zarlar sıcak.", "ev her zaman kazanmaz — ama sende farklı bir hava var.", "bir tur daha? kovan şansı sever."],
	"orun":    ["koronun nabzını duyarım — kulaklarımı onlara kaptırdım.", "her baskının bir davulu var; dinle.", "sus. çanı şimdi de çalıyor."],
}

var nid := ""
var body: Sprite2D
var prompt: Label
var mark: Label       # "!" — görev işi var (yeni teklif / teslim / ilerleme)
var _e_held := false
var _bob := 0.0
var _bark_t := 0.0      # ortam repliği sayacı

static func make(id: String, p: Vector2, parent: Node) -> NPC:
	var n := NPC.new()
	n.nid = id
	parent.add_child(n)
	n.position = p
	return n

var _fr: Array = []
var _fr_i := 0
var _fr_t := 0.0
var _anchor := Vector2.ZERO   # kamp konumu — gezinme bunun etrafında
var _wtarget := Vector2.ZERO
var _wt := 0.0

func _ready() -> void:
	var sh := Sprite2D.new()
	sh.texture = Px.S("shadow")
	sh.scale = Vector2.ONE * 0.9
	sh.z_index = -45
	add_child(sh)
	var up := G.upright(self)   # eğik dünyada NPC ve üst yazıları dik durur
	body = Sprite2D.new()
	body.texture = Px.S2("npc2_" + nid)
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.offset = Vector2(0, -body.texture.get_height() * 0.5)
	Px.fit(body, 80.0)
	up.add_child(body)
	_fr = [Px.S2("npc2_" + nid), Px.S2("npcb_" + nid)]
	if nid == "neva":
		G.fx.mk_light(self, Vector2(0, -24), Px.C("c26bff"), 0.6, 1.8)
	prompt = Label.new()
	prompt.text = "E · " + NAMES.get(nid, nid)
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_font_override("font", Ui.ui_font())
	prompt.add_theme_color_override("font_color", Px.C("00E5FF"))
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 3)
	prompt.position = Vector2(-52, -body.texture.get_height() * body.scale.y - 34)
	prompt.visible = false
	prompt.z_index = 500
	up.add_child(prompt)
	mark = Label.new()
	mark.text = "!"
	mark.add_theme_font_size_override("font_size", 22)
	mark.add_theme_font_override("font", Ui.ui_font())
	mark.add_theme_color_override("font_color", Px.C("ffd700"))
	mark.add_theme_color_override("font_outline_color", Color.BLACK)
	mark.add_theme_constant_override("outline_size", 4)
	mark.position = Vector2(-6, -body.texture.get_height() * body.scale.y - 16)
	mark.visible = false
	mark.z_index = 500
	up.add_child(mark)
	_bob = G.rf(0, TAU)
	_anchor = position
	_wtarget = _anchor
	_wt = G.rf(2.0, 7.0)
	_bark_t = G.rf(8.0, 24.0)

func _process(d: float) -> void:
	z_index = int(position.y)
	_bob += d
	_fr_t += d
	if _fr_t > 0.5:
		_fr_t = 0.0
		_fr_i = (_fr_i + 1) % _fr.size()
		if is_instance_valid(body):
			body.texture = _fr[_fr_i]
	# nefes: kareler arası yumuşak salınım — NPC'ler durgun durmasın
	if is_instance_valid(body):
		body.offset = Vector2(0, -body.texture.get_height() * 0.5 + sin(_bob * 2.2) * 1.3)
	# BG2 "!" — bu NPC'de görev işi varsa başının üstünde yanar (sektirmede hafif zıplar)
	if is_instance_valid(mark):
		mark.visible = G.state == G.State.HUB and Quests.has_business(nid)
		if mark.visible:
			mark.position.y = -body.texture.get_height() * body.scale.y - 16 - absf(sin(_bob * 3.0)) * 5.0
	if G.player == null or G.player.dead or G.state != G.State.HUB or G.ui.overlay_open():
		if is_instance_valid(prompt):
			prompt.visible = false
		return
	# yakın NPC mırıldanır — kamp canlı hissetsin
	_bark_t -= d
	if _bark_t <= 0.0:
		_bark_t = G.rf(16.0, 30.0)
		if position.distance_to(G.player.pos) < 190.0 and G.fx != null:
			var bk: Array = BARKS.get(nid, [])
			if not bk.is_empty():
				G.fx.float_text(position + Vector2(0, -body.texture.get_height() * body.scale.y - 30), G.pick(bk), Color(0.75, 0.75, 0.85), 0.85)
	var near := position.distance_to(G.player.pos) < 58.0
	prompt.visible = near
	if near and is_instance_valid(body):
		body.flip_h = G.player.pos.x < position.x
	# kamp içi gezinme: NPC'ler dayanak etrafında usulca dolaşır (BG2 boşta-yürüme)
	elif is_instance_valid(body):
		_wt -= d
		if _wt <= 0.0:
			_wt = G.rf(4.0, 9.0)
			_wtarget = _anchor + Vector2(G.rf(-1.0, 1.0) * 34.0, G.rf(-1.0, 1.0) * 18.0)
		if position.distance_to(_wtarget) > 2.0:
			position = position.move_toward(_wtarget, 12.0 * d)
			body.flip_h = _wtarget.x < position.x
	var e := Input.is_key_pressed(KEY_E)
	if near and e and not _e_held:
		G.ui.dialogue(nid)
	_e_held = e
