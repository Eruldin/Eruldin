class_name Ui
extends CanvasLayer

# All UI is built in code: HUD, boss bar, banners, toasts, dialogue panel,
# boon draft, upgrade shop (Dr. Vane), death/victory screens, title, CRT tint.

const BIOME_NAME := ["ENDUSTERRA BARRENS", "SIMITHAR MINE — 4-GAMMA", "SOL PRIMUS WRECKAGE", "AETERNA SPIRE", "ÇÜRÜK BATAKLIK"]

const LINES := {
	"rhasa": [
		"Kampın duvarları seni korumaz, Alfa-04. Kılıcın korur.",
		"Kovan seni kovalamıyor — seni topluyor. Parça parça.",
		"Doktrin basit: telegrafı oku, içinden geç. Geri çekilen asker ölü askerdir.",
		"Rex... Alfa-05'i gördün mü? O benim askerimdi. Ona bunu yapma — bitir onu.",
	],
	"neva": [
		"Rezonans seni geri çağırır, Ely. Ama her çağrıda bir şey eksik döner.",
		"Düşmekten korkma. Korkulacak şey unutulmak.",
		"Choralim'in sesini duyuyor musun? Mor frekansta ağlıyor.",
	],
	"saphire": [
		"Venti gördün mü? Yeşil parlarsa kaç. Kural bir.",
		"Kapılara bak, simgeyi oku. Altın aptalları sever — kabile sevmez.",
		"Bir gün bu kamptan çıkıp gerçek gökyüzünü göreceğim. Sen görürsen... anlatma. Sürprizi bozma.",
	],
	"vane": [
		"Sentetik nörolojin hâlâ sağlam. Parçacıklarla yükseltme ister misin?",
	],
	"david": [
		"Dört sahada iz sürdüm, Ely. Hepsinde kovanın kokusu farklı — ama ölüm aynı.",
		"Barrens'ta toprak konuşur. Mine'da damarlar şarkı söyler. Wreckage'ta imparatorluk çürür. Spire'da... protokol bekler.",
		"İzi seç, ben açarım. Sahaya inmeden önce bana uğra.",
	],
	"zirkon": [
		"Her düşüşü yazıyorum, Alfa-04. Kovan silmeyi sever — ben sevmem.",
		"Kayıtlarım kampla yaşıyor. Ne kadar koştuğunu, kimi düşürdüğünü — hepsi burada.",
		"İsimler unutulunca ölüm iki kez kazanır. Seni unutturmayacağım.",
	],
	"ehnar": [
		"Ben de bir zamanlar protokolün kılıcıydım, çocuk. Şimdi sadece kontrat imzalıyorum.",
		"Kampa her dönüşünde yeni bir görev bulursun bende. Tutarsan choralim konuşur.",
		"Beceri ölümcüldür ama sabır sabırdır. Kontrata odaklan — kovan bekleyebilir.",
	],
	"ahusk": [
		"Kovandan kaçtım, Praetorian. Kabuk hâlâ içimde ama emirler sustu.",
		"Bir lütuf taşıyorum sana — küçük bir rezonans. Parçacık ver, savaşa hazır in.",
		"Sahada ölürsem diye verdim kendimi. Sizinkiler geri döner — bizdekiler dönmez.",
	],
	"elyb": [
		"Ben B-serisiyim — ağır çerçeve, ağır silah. Kılıç değil, dizi taşırım.",
		"Şasimi takarsan Ely-B olursun: daha az can, daha çok vuruş, biraz daha yavaş.",
		"Alfa-04 sahada ölürse ben inerim. Protokol tek bedene bağlanmaz.",
	],
}

const DEATH_LINES := [
	"NEVA: Rezonans seni yine tuttu. Ama sesin biraz daha soldu.",
	"RHASA: Öldün. Raporunu yazdım: 'yetersiz ama inatçı.'",
	"SAPHIRE: {killer} seni aldı. Parçacıkları topladım — boşa gitmedi.",
	"VANE: Kayıp %4 nöral bütünlük. Hâlâ tolere edilebilir.",
	"NEVA: {killer}. Bunu not ettim. Bir dahakine aynı şarkıyı dinlemeyiz.",
	"RHASA: Tekrar ayağa kalktın. Kovan bunu sayıyor.",
	"SAPHIRE: Kampın ateşi seni bekledi. Yine.",
	"NEVA: {depth} saniye dayandın. Her düşüşte daha derine iniyorsun.",
	"VANE: Kalibrasyon tuttu. Düşüş verisi kaydedildi.",
	"RHASA: Viator'da ölüm bir istatistik. Sen iyi bir istatistik ol.",
]

# faction tint per speaker (master-prompt art bible color-coding)
const NPC_COL := {
	"rhasa": "ff5a4d",    # İmparatorluk — mat-siyah + kızıl vizör
	"vane": "8fd4ff",    # çelik
	"neva": "c26bff",    # choralim
	"saphire": "ff9e4d", # viator kızıl-kum
	"david": "00E5FF",   # iz sürücü
	"zirkon": "c9a227",  # vezir — altın
	"ehnar": "ff9e4d",   # eski şövalye — kızıl-kum
	"ahusk": "6aa8a0",   # göçebe — soluk çelik
	"elyb": "9db4c8",    # B-serisi şasi — çelik mavisi
}

static var _font: Font

static func ui_font() -> Font:
	if _font == null:
		var sf := SystemFont.new()
		sf.font_names = ["Consolas", "Cascadia Mono", "Courier New"]
		sf.font_weight = 600
		_font = sf
	return _font

var root: Control
var _hud: Control
var _hp_bar: ColorRect
var _hp_hi: ColorRect
var _hp_back: ColorRect
var _hp_txt: Label
var _ch_back: ColorRect
var _ch_bar: ColorRect
var _dash_row: HBoxContainer
var _frag_lbl: Label
var _boon_row: HBoxContainer
var _room_lbl: Label
var _quest_lbl: Label
var _hint_lbl: Label
var _tip: PanelContainer
var _tip_lbl: Label
var _boss_wrap: Control
var _boss_bar: ColorRect
var _boss_lbl: Label
var _boss_por: TextureRect
var _boss_por2: TextureRect
var _bosses: Array = []
var _banner_lbl: Label
var _banner_t := 0.0
var _toasts: Array = []
var _flash: ColorRect
var _lowhp: ColorRect        # low-health heartbeat vignette
var _overlay: Control = null     # current modal overlay (dialogue/boon/death/etc)
var _crt: TextureRect
var _vign: TextureRect
var _xp_back: ColorRect
var _xp_bar: ColorRect
var _lvl_lbl: Label
var _time_lbl: Label
var _prog_bg: ColorRect
var _prog_fg: ColorRect
var _kills_lbl: Label
var _wpn_row: HBoxContainer
var _psv_row: HBoxContainer
var _gear_sig := ""
var _pulse := 0.0
var _edge_pool: Array = []   # ekran dışı hedef işaretleri (elit/boss/sandık/özel eşya)

func _ready() -> void:
	layer = 100
	process_mode = PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_hud()
	_build_boss_bar()
	_build_overlays()
	_crt = TextureRect.new()
	_crt.texture = Px.S("scan")
	_crt.set_anchors_preset(Control.PRESET_FULL_RECT)
	_crt.stretch_mode = TextureRect.STRETCH_TILE
	_crt.modulate = Color(1, 1, 1, 0.16)
	_crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_crt)
	_vign = TextureRect.new()
	_vign.texture = Px.S("grad")
	_vign.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vign.stretch_mode = TextureRect.STRETCH_SCALE
	_vign.rotation = PI   # gradient dark at bottom... rotate so top dark too
	_vign.modulate = Color(1, 1, 1, 0.5)
	_vign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_vign)
	_apply_settings()

func overlay_open() -> bool:
	return is_instance_valid(_overlay)

func _pause(v: bool) -> void:
	get_tree().paused = v

# ---------------------------------------------------------------- HUD

func _style_panel(bg: Color, border: Color, bw := 2, rad := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(rad)
	return s

func _build_hud() -> void:
	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hud)

	# framed health bar
	var hp_frame := PanelContainer.new()
	hp_frame.position = Vector2(16, 644)
	hp_frame.custom_minimum_size = Vector2(266, 26)
	hp_frame.add_theme_stylebox_override("panel", _style_panel(Color(0.03, 0.01, 0.04, 0.9), Px.C("8B0000").lerp(Color.WHITE, 0.2), 1, 3))
	hp_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(hp_frame)
	_hp_back = ColorRect.new()
	_hp_back.color = Color(0.10, 0.02, 0.05, 1.0)
	_hp_back.position = Vector2(21, 650)
	_hp_back.size = Vector2(256, 14)
	_hud.add_child(_hp_back)
	_hp_bar = ColorRect.new()
	_hp_bar.color = Px.C("8B0000").lerp(Color(1, 0.25, 0.3), 0.45)
	_hp_bar.position = Vector2(21, 650)
	_hp_bar.size = Vector2(256, 14)
	_hud.add_child(_hp_bar)
	_hp_hi = ColorRect.new()
	_hp_hi.color = Color(1, 0.6, 0.6, 0.35)
	_hp_hi.position = Vector2(21, 650)
	_hp_hi.size = Vector2(256, 4)
	_hud.add_child(_hp_hi)
	_hp_txt = _lbl("100", Vector2(22, 627), 12, Color(1, 0.65, 0.65))
	_hud.add_child(_hp_txt)

	# plasma charge strip (visible while charging)
	_ch_back = ColorRect.new()
	_ch_back.color = Color(0.02, 0.08, 0.12, 0.9)
	_ch_back.position = Vector2(21, 668)
	_ch_back.size = Vector2(256, 5)
	_ch_back.visible = false
	_hud.add_child(_ch_back)
	_ch_bar = ColorRect.new()
	_ch_bar.color = Px.C("00E5FF")
	_ch_bar.position = Vector2(21, 668)
	_ch_bar.size = Vector2(0, 5)
	_ch_bar.visible = false
	_hud.add_child(_ch_bar)

	_dash_row = HBoxContainer.new()
	_dash_row.position = Vector2(21, 678)
	_dash_row.add_theme_constant_override("separation", 5)
	_hud.add_child(_dash_row)

	_frag_lbl = _lbl("◆ 0", Vector2(1140, 648), 16, Px.C("c26bff"))
	_hud.add_child(_frag_lbl)

	# XP bar — full-width strip across the top
	_xp_back = ColorRect.new()
	_xp_back.color = Color(0.02, 0.05, 0.09, 0.95)
	_xp_back.position = Vector2(0, 0)
	_xp_back.size = Vector2(1280, 7)
	_hud.add_child(_xp_back)
	_xp_bar = ColorRect.new()
	_xp_bar.color = Px.C("6a3fd1")
	_xp_bar.position = Vector2(0, 0)
	_xp_bar.size = Vector2(0, 7)
	_hud.add_child(_xp_bar)

	_lvl_lbl = _lbl("SEV 1", Vector2(20, 12), 14, Px.C("00E5FF"))
	_hud.add_child(_lvl_lbl)
	_time_lbl = _lbl("00:00", Vector2(0, 12), 20, Color(0.9, 0.95, 1))
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_lbl.size = Vector2(1280, 24)
	_hud.add_child(_time_lbl)

	# zafer ilerleme barı — sürenin altında kovana kadar kalan yolu gösterir
	_prog_bg = ColorRect.new()
	_prog_bg.color = Color(0.05, 0.05, 0.1, 0.8)
	_prog_bg.position = Vector2(515, 40)
	_prog_bg.size = Vector2(250, 5)
	_prog_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_prog_bg)
	_prog_fg = ColorRect.new()
	_prog_fg.color = Px.C("00E5FF")
	_prog_fg.size = Vector2(0, 3)
	_prog_fg.position = Vector2(1, 1)
	_prog_fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prog_bg.add_child(_prog_fg)
	_kills_lbl = _lbl("0 kesim", Vector2(1150, 14), 13, Color(0.8, 0.8, 0.9))
	_kills_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_kills_lbl.size = Vector2(110, 18)
	_hud.add_child(_kills_lbl)

	_wpn_row = HBoxContainer.new()
	_wpn_row.position = Vector2(20, 40)
	_wpn_row.add_theme_constant_override("separation", 5)
	_hud.add_child(_wpn_row)
	_psv_row = HBoxContainer.new()
	_psv_row.position = Vector2(20, 76)
	_psv_row.add_theme_constant_override("separation", 4)
	_hud.add_child(_psv_row)

	_boon_row = HBoxContainer.new()
	_boon_row.position = Vector2(20, 102)
	_boon_row.add_theme_constant_override("separation", 6)
	_hud.add_child(_boon_row)

	_room_lbl = _lbl("", Vector2(20, 134), 12, Color(0.72, 0.72, 0.82))
	_hud.add_child(_room_lbl)
	# görev izleyici — koşuda aktif görevlerin ilerlemesi (BG2 journal-glance)
	_quest_lbl = _lbl("", Vector2(20, 152), 11, Color(0.82, 0.78, 0.55))
	_hud.add_child(_quest_lbl)

	_hint_lbl = _lbl("WASD hareket · SPACE dash · E etkileşim · ESC duraklat — silahlar kendiliğinden ateş eder", Vector2(18, 702), 10, Color(0.42, 0.42, 0.52))
	_hud.add_child(_hint_lbl)

	# boon tooltip
	_tip = PanelContainer.new()
	_tip.add_theme_stylebox_override("panel", _style_panel(Color(0.03, 0.02, 0.07, 0.96), Px.C("7B1FA2"), 1, 3))
	_tip.visible = false
	_tip.z_index = 300
	var tm := MarginContainer.new()
	tm.add_theme_constant_override("margin_left", 10)
	tm.add_theme_constant_override("margin_right", 10)
	tm.add_theme_constant_override("margin_top", 6)
	tm.add_theme_constant_override("margin_bottom", 6)
	_tip.add_child(tm)
	_tip_lbl = _lbl("", Vector2.ZERO, 12, Color(0.9, 0.9, 0.95))
	_tip_lbl.custom_minimum_size = Vector2(200, 0)
	_tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tm.add_child(_tip_lbl)
	root.add_child(_tip)

func _lbl(t: String, p: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = p
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_font_override("font", ui_font())
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_boss_bar() -> void:
	_boss_wrap = Control.new()
	_boss_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_wrap.visible = false
	root.add_child(_boss_wrap)
	_boss_lbl = _lbl("", Vector2(0, 16), 15, Px.C("ff3355"))
	_boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_lbl.size = Vector2(1280, 20)
	_boss_wrap.add_child(_boss_lbl)
	var frame := PanelContainer.new()
	frame.position = Vector2(388, 40)
	frame.custom_minimum_size = Vector2(504, 20)
	frame.add_theme_stylebox_override("panel", _style_panel(Color(0.03, 0.01, 0.03, 0.9), Px.C("8B0000"), 1, 3))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_wrap.add_child(frame)
	var back := ColorRect.new()
	back.color = Color(0.08, 0.01, 0.04, 1.0)
	back.position = Vector2(393, 46)
	back.size = Vector2(494, 8)
	_boss_wrap.add_child(back)
	_boss_bar = ColorRect.new()
	_boss_bar.color = Px.C("8B0000").lerp(Color(1, 0.3, 0.2), 0.5)
	_boss_bar.position = Vector2(393, 46)
	_boss_bar.size = Vector2(494, 8)
	_boss_wrap.add_child(_boss_bar)
	# phase marker at 50%
	var tick := ColorRect.new()
	tick.color = Color(1, 1, 1, 0.4)
	tick.position = Vector2(393 + 247, 44)
	tick.size = Vector2(1, 12)
	_boss_wrap.add_child(tick)
	# portraits
	_boss_por = TextureRect.new()
	_boss_por.position = Vector2(330, 30)
	_boss_por.custom_minimum_size = Vector2(44, 44)
	_boss_por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_boss_por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_boss_wrap.add_child(_boss_por)
	_boss_por2 = TextureRect.new()
	_boss_por2.position = Vector2(906, 30)
	_boss_por2.custom_minimum_size = Vector2(44, 44)
	_boss_por2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_boss_por2.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_boss_wrap.add_child(_boss_por2)

func _build_overlays() -> void:
	_banner_lbl = _lbl("", Vector2(0, 240), 34, Px.C("00E5FF"))
	_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_lbl.size = Vector2(1280, 80)
	_banner_lbl.modulate.a = 0.0
	root.add_child(_banner_lbl)

	_flash = ColorRect.new()
	_flash.color = Color(0, 0, 0, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)
	_lowhp = ColorRect.new()
	_lowhp.color = Color(0.5, 0.0, 0.04, 0)
	_lowhp.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lowhp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_lowhp)

func _process(d: float) -> void:
	_pulse += d
	_tick_hud()
	_tick_banner(d)
	_tick_boss_bar()
	_toast_keys()
	_tick_edge()

func _tick_hud() -> void:
	if G.player == null or not is_instance_valid(G.player) or G.run == null:
		return
	var p := G.player
	_hp_bar.size.x = 256 * clampf(p.hp / p.max_hp, 0.0, 1.0)
	_hp_hi.size.x = _hp_bar.size.x
	_hp_txt.text = "%d / %d" % [maxi(0, ceili(p.hp)), ceili(p.max_hp)]
	var hfrac := clampf(p.hp / maxf(p.max_hp, 1.0), 0.0, 1.0)
	if is_instance_valid(_lowhp):
		_lowhp.color.a = (0.34 - hfrac) * 0.55 * (0.55 + 0.45 * sin(_pulse * 5.6)) if hfrac < 0.34 and not p.dead else 0.0
	# plasma charge strip
	var charging: bool = p._plasma_charge >= 0.0
	_ch_back.visible = charging
	_ch_bar.visible = charging
	if charging:
		_ch_bar.size.x = 256 * p.plasma_charge()
		_ch_bar.color = Px.C("00E5FF").lerp(Color.WHITE, p.plasma_charge())
	while _dash_row.get_child_count() < p.dash_max:
		var c := TextureRect.new()
		c.texture = Px.S2("icn_dash")
		c.custom_minimum_size = Vector2(14, 14)
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_dash_row.add_child(c)
	for i in _dash_row.get_child_count():
		_dash_row.get_child(i).modulate = Px.C("00E5FF") if i < p.dash_charges else Color(0.15, 0.2, 0.28)
	_frag_lbl.text = "◆ %d  (+%d)" % [G.meta.data.choralim, int(G.run.fragments * G.meta.frag_mult())]
	_xp_bar.size.x = 1280.0 * clampf(p.xp / maxf(p.xp_next, 1.0), 0.0, 1.0)
	# choralim pulse (#6a3fd1 -> #2c9be8) per the art bible
	_xp_bar.color = Px.C("6a3fd1").lerp(Px.C("2c9be8"), 0.5 + 0.5 * sin(_pulse * 2.4))
	_lvl_lbl.text = "SEV %d" % p.level
	var tt := int(G.run.time)
	_time_lbl.text = ("%02d:%02d" % [tt / 60, tt % 60]) + ("   AZAP ×%d" % int(G.run.curse) if int(G.run.curse) > 0 else "")
	_time_lbl.add_theme_color_override("font_color", Px.C("c26bff") if G.run.endless else (Px.C("ff5533") if (G.run.hyper or G.run.dark) else Color(0.9, 0.95, 1)))
	if is_instance_valid(_prog_fg):
		_prog_fg.size.x = 248.0 * clampf(G.run.time / Director.WIN_T, 0.0, 1.0)
		_prog_fg.color = Px.C("c26bff") if G.run.endless else Px.C("00E5FF")
	_kills_lbl.text = "%d kesim" % int(G.run.stats.get("kills", 0))
	if G.run.streak >= 10:
		_kills_lbl.text += "  x%d" % G.run.streak
		_kills_lbl.add_theme_color_override("font_color", Px.C("ffb74d"))
	else:
		_kills_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	_sync_gear_rows(p)
	while _boon_row.get_child_count() < G.run.boon_ids.size():
		var idx := _boon_row.get_child_count()
		var bid: String = G.run.boon_ids[idx]
		var spec := _boon_spec(bid)
		var s := TextureRect.new()
		s.texture = Px.S2("icn_" + str(spec.get("patron", "")).to_lower())
		s.modulate = spec.get("color", Color.WHITE)
		s.custom_minimum_size = Vector2(24, 24)
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.mouse_filter = Control.MOUSE_FILTER_STOP
		_boon_row.add_child(s)
		s.mouse_entered.connect(func(): _show_tip(s, spec))
		s.mouse_exited.connect(func(): _tip.visible = false)
	if G.state == G.State.ROOM and is_instance_valid(G.room):
		_room_lbl.text = str(G.run.node_name) if str(G.run.node_name) != "" else BIOME_NAME[clampi(G.run.biome, 0, BIOME_NAME.size() - 1)]
	elif G.state == G.State.HUB:
		_room_lbl.text = "VIATOR KAMPI"
	else:
		_room_lbl.text = ""
	var qs := ""
	for q in (Quests.active() if G.state == G.State.ROOM else []):
		if qs.length() > 0:
			qs += "   "
		qs += "· %s %s" % [str(q.name).to_lower(), Quests.prog_text(q)]
		if qs.length() > 60:
			break
	_quest_lbl.text = qs

# ekran dışı hedefler için kenar işaretleri (HoT objective markers): elitler,
# boss, sandıklar ve saha özel eşyaları dünya konumundan kenara yansıtılır
func _edge_targets() -> Array:
	var out: Array = []
	if G.state != G.State.ROOM or not is_instance_valid(G.cam) or not is_instance_valid(G.room):
		return out
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead and e.elite:
			out.append({"p": e.pos, "icon": "icn_skull", "col": "ffb74d", "s": 26.0})
	if is_instance_valid(G.room.boss):
		out.append({"p": G.room.boss.pos, "icon": "icn_skull", "col": "ff5533", "s": 36.0})
	if is_instance_valid(G.room.pickups_node):
		for pk in G.room.pickups_node.get_children():
			var k := str(pk.get_meta("kind", ""))
			if k == "chest":
				out.append({"p": pk.position, "icon": "ico_boon", "col": "ffb74d", "s": 22.0})
			elif k == "vacuum" or k == "bomb" or k == "freeze" or k == "boost" or k == "guard":
				out.append({"p": pk.position, "icon": "ico_frag", "col": "00E5FF", "s": 18.0})
			elif k == "egg":
				out.append({"p": pk.position, "icon": "icn_crown", "col": "ffd700", "s": 20.0})
			elif k == "tome":
				out.append({"p": pk.position, "icon": "ico_boon", "col": "c9a227", "s": 24.0})
			elif k == "loot":
				out.append({"p": pk.position, "icon": "ico_loot", "col": "42d4f4", "s": 20.0})
		if G.room.mono_active:
			out.append({"p": G.room.mono_pos, "icon": "ico_boon", "col": "c26bff", "s": 26.0})
		if G.room.merchant_active:
			out.append({"p": G.room.merchant_pos, "icon": "ico_loot", "col": "ffd700", "s": 24.0})
		if G.room.stray_active:
			out.append({"p": G.room.stray_pos, "icon": "ico_boon", "col": "8fd4ff", "s": 22.0})
	return out

func _tick_edge() -> void:
	var i := 0
	if G.state == G.State.ROOM and is_instance_valid(G.cam):
		var zoom: float = G.cam.zoom.x
		for t in _edge_targets():
			var sp: Vector2 = ((t["p"] as Vector2) - G.cam.global_position) * zoom + Vector2(640, 360)
			if Rect2(Vector2(50, 50), Vector2(1180, 620)).has_point(sp):
				continue
			while _edge_pool.size() <= i:
				var m := TextureRect.new()
				m.mouse_filter = Control.MOUSE_FILTER_IGNORE
				m.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				m.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				root.add_child(m)
				_edge_pool.append(m)
			var mk: TextureRect = _edge_pool[i]
			mk.texture = Px.S2(str(t["icon"]))
			mk.modulate = Px.C(str(t["col"]))
			var s: float = t["s"]
			mk.size = Vector2(s, s)
			mk.position = sp.clamp(Vector2(20, 20), Vector2(1260, 700)) - Vector2(s, s) * 0.5
			mk.visible = true
			i += 1
	for j in range(i, _edge_pool.size()):
		_edge_pool[j].visible = false

func _sync_gear_rows(p: Player) -> void:
	var sig := ""
	for w in p.weapons:
		sig += "%s:%d," % [w.id, int(w.lvl)]
	sig += "|"
	for ps in p.passives:
		sig += "%s:%d," % [ps.id, int(ps.lvl)]
	if sig == _gear_sig:
		return
	_gear_sig = sig
	for c in _wpn_row.get_children():
		c.queue_free()
	for c in _psv_row.get_children():
		c.queue_free()
	for w in p.weapons:
		var d: Dictionary = Weapons.def(str(w.id))
		_wpn_row.add_child(_gear_icon(str(d.get("icon", "ico_boon")), str(d.get("col", "7fd4ff")), int(w.lvl), 30))
	for ps in p.passives:
		var d: Dictionary = Weapons.pdef(str(ps.id))
		_psv_row.add_child(_gear_icon(str(d.get("icon", "ico_frag")), str(d.get("col", "c26bff")), int(ps.lvl), 20))

# faction-colored slot frame around each gear icon (VS-style loadout slots)
func _gear_icon(icon: String, col: String, lvl: int, size: int) -> Control:
	var sc := Px.C(col)
	var slot := PanelContainer.new()
	slot.add_theme_stylebox_override("panel", _style_panel(Color(0.02, 0.02, 0.05, 0.9), sc.lerp(Color.WHITE, 0.12), 1, 2))
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tr := TextureRect.new()
	tr.texture = Px.S2(icon)
	if tr.texture == null:
		tr.texture = Px.S("ico_boon")
	tr.custom_minimum_size = Vector2(size, size)
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.modulate = sc
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(tr)
	var l := _lbl(str(lvl), Vector2(size - 12, size - 13), 10, Color.WHITE)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.add_child(l)
	return slot

# end-screen inventory: the loadout the run ended with (VS results recap)
func _build_recap(v: VBoxContainer) -> void:
	if not is_instance_valid(G.player):
		return
	var tl := _lbl("YÜKÜN", Vector2.ZERO, 11, Color(0.55, 0.55, 0.68))
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var wdtot := 0.0
	if G.run != null:
		for k in G.run.stats.keys():
			if str(k).begins_with("wdmg_"):
				wdtot += float(G.run.stats[k])
	for w in G.player.weapons:
		var d: Dictionary = Weapons.def(str(w.id))
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		cell.add_child(_gear_icon(str(d.get("icon", "ico_boon")), str(d.get("col", "7fd4ff")), int(w.lvl), 30))
		if wdtot > 0.0:
			var sh := float(G.run.stats.get("wdmg_" + str(w.id), 0.0)) / wdtot
			var sl := _lbl("%d%%" % roundi(sh * 100.0), Vector2.ZERO, 9, Color(0.95, 0.8, 0.45))
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_child(sl)
		row.add_child(cell)
	for ps in G.player.passives:
		var d: Dictionary = Weapons.pdef(str(ps.id))
		row.add_child(_gear_icon(str(d.get("icon", "ico_frag")), str(d.get("col", "c26bff")), int(ps.lvl), 22))
	v.add_child(row)

func _boon_spec(bid: String) -> Dictionary:
	for b in Boons.all():
		if b.id == bid:
			return b
	return {}

func _show_tip(anchor: Control, spec: Dictionary) -> void:
	_tip_lbl.text = "%s — %s\n%s" % [spec.get("name", "?"), spec.get("patron", ""), spec.get("desc", "")]
	_tip.position = anchor.global_position + Vector2(-10, 34)
	_tip.visible = true

func _tick_banner(d: float) -> void:
	if _banner_t > 0:
		_banner_t -= d
		_banner_lbl.modulate.a = minf(1.0, _banner_t * 1.5)
		if _banner_t <= 0:
			_banner_lbl.modulate.a = 0

func banner(title: String, sub: String) -> void:
	_banner_lbl.text = "%s\n%s" % [title, sub]
	_banner_t = 2.4
	_banner_lbl.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(_banner_lbl, "modulate:a", 1.0, 0.3)

func toast(msg: String) -> void:
	var l := _lbl(msg, Vector2(0, 560 + _toasts.size() * 22), 14, Color(0.85, 0.9, 1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, 20)
	l.set_meta("t", 2.2)
	root.add_child(l)
	_toasts.append(l)

# mid-fight boss story beat — portrait + line card at top, non-modal, auto-fades
var _taunt: Control = null

func boss_taunt(por_key: String, name_s: String, line: String) -> void:
	if is_instance_valid(_taunt):
		_taunt.queue_free()
	var p := PanelContainer.new()
	_taunt = p
	p.set_anchors_preset(Control.PRESET_TOP_WIDE)
	p.offset_top = 84.0
	p.offset_left = 330.0
	p.offset_right = -330.0
	p.modulate.a = 0.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style_panel(Color(0.06, 0.01, 0.02, 0.92), Px.C("ff5252"), 1, 3))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var pr := TextureRect.new()
	pr.texture = Px.S2("por_" + por_key)
	pr.custom_minimum_size = Vector2(46, 46)
	pr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(pr)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	v.add_child(_lbl(name_s, Vector2.ZERO, 11, Px.C("ff8a80")))
	var ll := _lbl(line, Vector2.ZERO, 13, Color(0.96, 0.92, 0.92))
	ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ll.custom_minimum_size = Vector2(540, 0)
	v.add_child(ll)
	root.add_child(p)
	var tw := create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.22)
	tw.tween_interval(2.7)
	tw.tween_property(p, "modulate:a", 0.0, 0.55)
	tw.tween_callback(func():
		if is_instance_valid(p):
			p.queue_free()
		if _taunt == p:
			_taunt = null)

func _toast_keys() -> void:
	for i in range(_toasts.size() - 1, -1, -1):
		var l: Label = _toasts[i]
		if not is_instance_valid(l):
			_toasts.remove_at(i)
			continue
		l.set_meta("t", l.get_meta("t") - get_process_delta_time())
		l.modulate.a = minf(1.0, l.get_meta("t"))
		if l.get_meta("t") <= 0:
			l.queue_free()
			_toasts.remove_at(i)

func screen_flash(col: Color, a: float) -> void:
	_flash.color = Color(col.r, col.g, col.b, a)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.5)

func hurt_flash() -> void:
	screen_flash(Color(0.6, 0.02, 0.05), 0.22)

# ---------------------------------------------------------------- cinematics

# Letterboxed still-card: painted panel + title + sub, auto-dismisses or
# skips on E/click. Pauses the game while shown.
func cinematic(tex_key: String, title: String, sub: String, dur := 2.6) -> void:
	if overlay_open():
		return
	_pause(true)
	_overlay = Control.new()
	_overlay.set_meta("kind", "cine")
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.modulate = Color(1, 1, 1, 0)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg)
	var still := TextureRect.new()
	still.texture = Px.S2(tex_key)
	still.set_anchors_preset(Control.PRESET_FULL_RECT)
	still.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	still.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(still)
	# letterbox bars
	var top := ColorRect.new()
	top.color = Color(0, 0, 0)
	top.anchor_right = 1.0; top.anchor_bottom = 0.13
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(top)
	var bot := ColorRect.new()
	bot.color = Color(0, 0, 0)
	bot.anchor_top = 0.80; bot.anchor_right = 1.0; bot.anchor_bottom = 1.0
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bot)
	var v := VBoxContainer.new()
	v.anchor_top = 0.82; v.anchor_right = 1.0; v.anchor_bottom = 0.99
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(v)
	var t := _lbl(title, Vector2.ZERO, 22, Px.C("c26bff"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := _lbl(sub, Vector2.ZERO, 12, Color(0.75, 0.72, 0.8))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	var hint := _lbl("E / tık — geç", Vector2.ZERO, 10, Color(0.4, 0.4, 0.48))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	root.add_child(_overlay)
	var tw := create_tween()
	tw.tween_property(_overlay, "modulate:a", 1.0, 0.35)
	get_tree().create_timer(dur).timeout.connect(func():
		if overlay_open() and _overlay.get_meta("kind", "") == "cine":
			_advance_overlay())

# hikaye kartı zinciri — her kart sinematik letterbox; E/tık sıradakine geçer
func cine_seq(cards: Array) -> void:
	if overlay_open() or cards.is_empty():
		return
	_cine_cards = cards.duplicate()
	_cine_play()

var _cine_cards: Array = []

func _cine_play() -> void:
	if _cine_cards.is_empty():
		return
	var c: Dictionary = _cine_cards.pop_front()
	cinematic(str(c.get("tex", "bg3")), str(c.get("title", "")), str(c.get("sub", "")), 3.2)

# ---------------------------------------------------------------- boss bar

func boss_bar(on: bool, b) -> void:
	_bosses.clear()
	if on and b != null:
		for e in G.enemies:
			if e is Boss and not e.dead:
				_bosses.append(e)
		_boss_lbl.text = b.actor_name + " — " + b.title
		# portraits: first boss left, second (twin fights) right
		_boss_por.texture = Px.S2("por_" + str(Boss.SPR[_bosses[0].bkind])) if _bosses.size() > 0 else null
		_boss_por.visible = _bosses.size() > 0
		_boss_por2.texture = Px.S2("por_" + str(Boss.SPR[_bosses[1].bkind])) if _bosses.size() > 1 else null
		_boss_por2.visible = _bosses.size() > 1
	_boss_wrap.visible = on

func boss_bar_refresh() -> void:
	_bosses = _bosses.filter(func(x): return is_instance_valid(x) and not x.dead)

func _tick_boss_bar() -> void:
	if not _boss_wrap.visible:
		return
	var hp := 0.0
	var mx := 0.0
	for b in _bosses:
		if is_instance_valid(b):
			hp += maxf(0, b.hp)
			mx += b.max_hp
	_boss_bar.size.x = 398 * (hp / mx if mx > 0 else 0.0)

func boss_intro(b: Boss) -> void:
	banner(b.actor_name, "«%s»" % b.bark)
	G.audio.play("roar", 0.85, 0.7)

# ---------------------------------------------------------------- hub

func hub_ui(_show: bool) -> void:
	if not _show:
		return
	# reset run HUD so the camp doesn't show the last run's leftovers
	_time_lbl.text = "00:00"
	_kills_lbl.text = ""
	_lvl_lbl.text = ""
	_xp_bar.size.x = 0
	if is_instance_valid(_prog_fg):
		_prog_fg.size.x = 0
	for c in _wpn_row.get_children():
		c.queue_free()
	for c in _psv_row.get_children():
		c.queue_free()
	for c in _boon_row.get_children():
		c.queue_free()
	_gear_sig = ""
	boss_bar(false, null)

# ---------------------------------------------------------------- dialogue

func dialogue(nid: String) -> void:
	if overlay_open():
		return
	_pause(true)
	_overlay = PanelContainer.new()
	_overlay.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_overlay.offset_top = -168.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ncol := Px.C(NPC_COL.get(nid, "00E5FF"))
	_overlay.add_theme_stylebox_override("panel", _style_panel(Color(0.04, 0.02, 0.08, 0.94), ncol, 2, 3))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(margin)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(h)
	# speaker portrait in a faction-colored frame
	var por_f := PanelContainer.new()
	por_f.add_theme_stylebox_override("panel", _style_panel(Color(0.02, 0.01, 0.05, 0.95), ncol, 2, 2))
	por_f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var por := TextureRect.new()
	por.texture = Px.S2("por_" + nid)
	por.custom_minimum_size = Vector2(64, 64)
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	por_f.add_child(por)
	h.add_child(por_f)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var name_l := _lbl(NPC.NAMES.get(nid, nid), Vector2.ZERO, 15, ncol)
	v.add_child(name_l)
	var body_l := _lbl("", Vector2.ZERO, 14, Color(0.9, 0.9, 0.95))
	body_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_l.custom_minimum_size = Vector2(1080, 50)
	v.add_child(body_l)
	var hint := _lbl("[E / tık] devam", Vector2.ZERO, 10, Color(0.4, 0.4, 0.5))
	v.add_child(hint)
	root.add_child(_overlay)

	var lines: Array = LINES.get(nid, ["..."]).duplicate()
	# pick a line Ely hasn't heard yet when possible
	var unseen: Array = []
	for i in lines.size():
		if not G.meta.seen_line("%s_%d" % [nid, i]):
			unseen.append(i)
	var idx := G.ri(0, lines.size() - 1)
	if not unseen.is_empty():
		idx = int(unseen[G.ri(0, unseen.size() - 1)])
	G.meta.mark_line("%s_%d" % [nid, idx])
	G.meta.save()
	body_l.text = lines[idx]
	if nid == "vane":
		hint.text = "[E / tık] yükseltme paneli"
	elif nid == "rhasa":
		hint.text = "[E / tık] doktrin seçimi"
	elif nid == "david":
		hint.text = "[E / tık] saha seçimi"
	elif nid == "zirkon":
		hint.text = "[E / tık] kamp kayıtları"
	elif nid == "ehnar":
		hint.text = "[E / tık] aktif sözleşme"
	elif nid == "ahusk":
		hint.text = "[E / tık] destek takası"
	elif nid == "elyb":
		hint.text = "[E / tık] şasi seçimi"
	_overlay.set_meta("kind", "dialogue")
	_overlay.set_meta("nid", nid)
	_overlay.set_meta("body", body_l)

func _close_overlay() -> void:
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_pause(false)

func _input(ev: InputEvent) -> void:
	if not overlay_open():
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode in [KEY_E, KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
		_advance_overlay()
		get_viewport().set_input_as_handled()

func _unhandled_input(ev: InputEvent) -> void:
	if not overlay_open():
		return
	if ev is InputEventMouseButton and ev.pressed:
		_advance_overlay()

func _advance_overlay() -> void:
	if not is_instance_valid(_overlay):
		return
	var kind: String = _overlay.get_meta("kind", "")
	match kind:
		"dialogue":
			var nid: String = _overlay.get_meta("nid")
			# görev işi olan NPC önce görev panosunu açar; panodan hizmete geçilir
			if Quests.has_business(nid):
				_close_overlay()
				quest_panel(nid)
			elif nid == "vane":
				_close_overlay()
				upgrade_panel()
			elif nid == "rhasa":
				_close_overlay()
				stance_panel()
			elif nid == "david":
				_close_overlay()
				worldmap_panel()
			elif nid == "zirkon":
				_close_overlay()
				records_panel()
			elif nid == "ehnar":
				_close_overlay()
				contract_panel()
			elif nid == "ahusk":
				_close_overlay()
				blessing_panel()
			elif nid == "elyb":
				_close_overlay()
				hero_panel()
			elif nid == "saphire":
				_close_overlay()
				inventory_panel()
			elif nid == "neva":
				_close_overlay()
				song_panel()
			else:
				_close_overlay()
		"death":
			_close_overlay()
			G.run.respawn_to_hub()
		"victory":
			_close_overlay()
			G.run.respawn_to_hub()
		"upgrade", "stance", "pause", "records", "biomesel", "contract", "blessing", "hero", "wmap", "quest", "inv", "barter", "song", "merchant", "shop", "stray":
			_close_overlay()
		"cine":
			var c := _overlay
			var tw := create_tween()
			tw.tween_property(c, "modulate:a", 0.0, 0.3)
			if not _cine_cards.is_empty():
				tw.tween_callback(func():
					_close_overlay()
					_cine_play())
			else:
				tw.tween_callback(_close_overlay)
		"title":
			_close_overlay()
			G.run.hub()
		"boon", "draft", "chest":
			pass  # cards handle their own clicks

func _show_panel(kind: String, title: String, title_col: Color) -> VBoxContainer:
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = Control.new()
	_overlay.set_meta("kind", kind)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.06, 0.96)
	style.border_color = title_col
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(v)
	var t := _lbl(title, Vector2.ZERO, 22, title_col)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size = Vector2(520, 0)
	v.add_child(t)
	root.add_child(_overlay)
	return v

# ---------------------------------------------------------------- david / zirkon

# İz Sürücü: pick which sector the portal opens to. Higher biome = painted
# backdrops/props/hazards of that sector, its own boss, harder scaling.
func biome_panel() -> void:
	_pause(true)
	var cur := int(G.meta.data.get("arena_biome", 0))
	var boss_por := ["por_rex", "por_host", "por_nahum", "por_kirin"]
	var opts: Array = []
	for i in 4:
		var tag := "◈ SEÇİLİ" if i == cur else "SAHA %d" % (i + 1)
		opts.append({"kind": "biome", "id": i, "name": "%s\n%s" % [BIOME_NAME[i], tag],
			"icon": boss_por[i], "col": ["00E5FF", "00E676", "ffb74d", "c26bff"][i],
			"desc": "%s\nzorluk %s" % [_biome_desc(i), "★".repeat(i + 1)], "top": "", "w": 1.0})
	var hyp := bool(G.meta.data.get("hyper", false))
	opts.append({"kind": "biome", "id": -1, "name": "AŞILAMA\n%s" % ("◈ AÇIK" if hyp else "MOD"),
		"icon": "icn_kovan", "col": "ff5533",
		"desc": "kovan hızlı ve kalabalık akar\nparçacık ödemesi ×1.5", "top": "", "w": 1.0})
	var drk := bool(G.meta.data.get("dark", false))
	opts.append({"kind": "biome", "id": -2, "name": "KARANLIK\n%s" % ("◈ AÇIK" if drk else "MOD"),
		"icon": "icn_skull", "col": "7c4dff",
		"desc": "şifa küresi düşmez\nparçacık ödemesi ×1.25", "top": "", "w": 1.0})
	_show_cards("biomesel", "SAHA SEÇİMİ — David'in izleri  [1-6]", Px.C("00E5FF"), opts)

func _biome_desc(b: int) -> String:
	return ["Proterian çoraklığı — Alfa-05'in izi.",
			"Simithar damarları — kovanın kökleri.",
			"İmparatorluk enkazı — çürüyen taht.",
			"Protokolün kalbi — son masa."][b]

# ---------------------------------------------------------------- açık dünya haritası (BG2 node graph)

func _service_panel_for(nid: String) -> void:
	match nid:
		"vane":    upgrade_panel()
		"rhasa":   stance_panel()
		"david":   worldmap_panel()
		"zirkon":  records_panel()
		"ehnar":   contract_panel()
		"ahusk":   blessing_panel()
		"neva":    song_panel()
		"saphire": inventory_panel()
		"elyb":    hero_panel()
		_:         pass

# David'in haritası: node-graph açık dünya — düğümler görev/boss ile açılır
func worldmap_panel() -> void:
	_pause(true)
	var v := _show_panel("wmap", "DÜNYA HARİTASI — İz Sürücü David", Px.C("00E5FF"))
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(1120, 560)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(canvas)
	var bg := TextureRect.new()
	bg.texture = Px.S2("bg_wmap")
	if bg.texture == null:
		bg.texture = Px.S2("bg3")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.modulate = Color(0.55, 0.55, 0.62, 0.5)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(bg)
	# seyahat hatları — BG2 kenar çizimleri
	var edge_c := Control.new()
	edge_c.set_anchors_preset(Control.PRESET_FULL_RECT)
	edge_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(edge_c)
	for e in Wmap.EDGES:
		var a: Dictionary = Wmap.node(str(e[0]))
		var b: Dictionary = Wmap.node(str(e[1]))
		if a.is_empty() or b.is_empty():
			continue
		var ln := Line2D.new()
		ln.points = PackedVector2Array([a.pos * 0.92 + Vector2(45, 30), b.pos * 0.92 + Vector2(45, 30)])
		ln.width = 2.0
		var ok := Wmap.can_enter(str(a.id)) and Wmap.can_enter(str(b.id))
		ln.default_color = Color(0.35, 0.75, 0.95, 0.55) if ok else Color(0.3, 0.28, 0.35, 0.3)
		edge_c.add_child(ln)
	var cur := str(G.meta.data.get("arena_node", "b0"))
	var info := _lbl("", Vector2.ZERO, 12, Color(0.8, 0.85, 0.95))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(info)
	var sel := {"id": cur}
	for n in Wmap.NODES:
		var nid := str(n.id)
		var can := Wmap.can_enter(nid)
		var is_cur := nid == cur
		var btn := PanelContainer.new()
		btn.position = n.pos * 0.92 + Vector2(45, 30) - Vector2(30, 30)
		var ncol := Px.C(str(n.col))
		var bc := ncol.lerp(Color.WHITE, 0.45) if is_cur else (ncol if can else Color(0.3, 0.3, 0.36))
		btn.add_theme_stylebox_override("panel", _style_panel(Color(0.04, 0.03, 0.07, 0.9), bc, 3 if is_cur else 2, 18))
		var bb := VBoxContainer.new()
		bb.add_theme_constant_override("separation", 2)
		btn.add_child(bb)
		var ic := TextureRect.new()
		ic.texture = Px.S2(str(n.icon))
		ic.custom_minimum_size = Vector2(30, 30)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.modulate = ncol if can else Color(0.4, 0.4, 0.45)
		var icc := CenterContainer.new()
		icc.add_child(ic)
		bb.add_child(icc)
		var vnm: Array = G.meta.data.get("visited_nodes", [])
		var ntxt := str(n.name).split(" ")[0]
		if vnm.has(nid):
			ntxt += " ✓"
		var nl := _lbl(ntxt, Vector2.ZERO, 9, (Px.C("00E676") if vnm.has(nid) else Color.WHITE) if can else Color(0.5, 0.5, 0.55))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bb.add_child(nl)
		if is_cur:
			var tag := _lbl("▼ HEDEF", Vector2.ZERO, 8, Px.C("ffd700"))
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bb.add_child(tag)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		canvas.add_child(btn)
		btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed:
				_wmap_pick(nid, info, sel))
		btn.mouse_entered.connect(func():
			info.text = "%s — %s%s" % [str(n.name), str(n.desc), "" if can else "   [%s]" % Wmap.unlock_text(nid)])
	# mutator şeridi
	var mut := HBoxContainer.new()
	mut.alignment = BoxContainer.ALIGNMENT_CENTER
	mut.add_theme_constant_override("separation", 18)
	v.add_child(mut)
	var hyp := bool(G.meta.data.get("hyper", false))
	var hb := Button.new()
	hb.text = "AŞILAMA: %s" % ("AÇIK" if hyp else "kapalı")
	hb.add_theme_font_override("font", ui_font())
	hb.custom_minimum_size = Vector2(180, 28)
	mut.add_child(hb)
	hb.pressed.connect(func():
		var nw := not bool(G.meta.data.get("hyper", false))
		G.meta.data["hyper"] = nw
		G.meta.save()
		hb.text = "AŞILAMA: %s" % ("AÇIK" if nw else "kapalı")
		G.audio.play("boon", 1.1, 0.5))
	var drk := bool(G.meta.data.get("dark", false))
	var db := Button.new()
	db.text = "KARANLIK: %s" % ("AÇIK" if drk else "kapalı")
	db.add_theme_font_override("font", ui_font())
	db.custom_minimum_size = Vector2(180, 28)
	mut.add_child(db)
	db.pressed.connect(func():
		var nw := not bool(G.meta.data.get("dark", false))
		G.meta.data["dark"] = nw
		G.meta.save()
		db.text = "KARANLIK: %s" % ("AÇIK" if nw else "kapalı")
		G.audio.play("boon", 0.9, 0.5))
	var gate := _lbl("hedef: %s — portal kampta güneyde" % str(Wmap.node(cur).get("name", "?")), Vector2.ZERO, 12, Px.C("c26bff"))
	gate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(gate)
	_overlay.set_meta("gate_lbl", gate)
	var h := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

func _wmap_pick(nid: String, info: Label, sel: Dictionary) -> void:
	if not Wmap.can_enter(nid):
		toast("kilitli: %s" % Wmap.unlock_text(nid))
		G.audio.play("die", 1.4, 0.3)
		return
	var nkind := str(Wmap.node(nid).get("kind", ""))
	if nkind == "hub":
		toast("burası kamp — zaten buradayız")
		return
	if nkind == "story":
		_story_node(nid)
		return
	sel["id"] = nid
	G.meta.data["arena_node"] = nid
	G.meta.data["arena_biome"] = int(Wmap.node(nid).get("biome", 0))
	G.meta.save()
	G.audio.jingle("boon")
	toast("rota: %s" % str(Wmap.node(nid).name))
	var gl = _overlay.get_meta("gate_lbl") if is_instance_valid(_overlay) else null
	if gl != null and is_instance_valid(gl):
		gl.text = "hedef: %s — portal kampta güneyde" % str(Wmap.node(nid).get("name", "?"))
	worldmap_panel()  # seçili çerçeveyi tazele

# savaşsız hikaye düğümü: sinematik kartlar + ödül, bir kez yaşanır
func _story_node(nid: String) -> void:
	var n := Wmap.node(nid)
	var sd: Array = G.meta.data.get("story_done", [])
	if sd.has(nid):
		toast("bu yankı sustu — bir kez dinlenir")
		return
	sd.append(nid)
	G.meta.data["story_done"] = sd
	var rew: Dictionary = n.get("rew", {})
	if int(rew.get("cho", 0)) > 0:
		G.meta.data["choralim"] = int(G.meta.data.get("choralim", 0)) + int(rew.cho)
	if str(rew.get("item", "")) != "":
		var st: Array = G.meta.data.get("stash", [])
		st.append(str(rew.item))
		G.meta.data["stash"] = st
		toast("zula: %s envantere eklendi" % str(rew.item))
	G.meta.save()
	# haritayı kapat, kartları oynat
	if overlay_open():
		_advance_overlay()
	var cards: Array = n.get("cards", [])
	if cards.is_empty():
		cards = [{"tex": "bg%d" % int(n.get("biome", 0)), "title": str(n.name), "sub": str(n.get("lore", n.get("desc", "")))}]
	cine_seq(cards)
	G.audio.jingle("boon")
	if int(rew.get("cho", 0)) > 0:
		toast("+%d ◆ choralim" % int(rew.cho))

# ---------------------------------------------------------------- görev panosu

func quest_panel(nid: String) -> void:
	_pause(true)
	var ncol := Px.C(NPC_COL.get(nid, "00E5FF"))
	var v := _show_panel("quest", "GÖREVLER — %s" % str(NPC.NAMES.get(nid, nid)), ncol)
	var any := false
	for q in Quests.claimable_for(nid):
		any = true
		v.add_child(_quest_row(q, "TESLİM AL", ncol, func():
			var rew := Quests.claim(str(q.id))
			G.audio.jingle("victory")
			toast("ödül: %s" % Quests.rew_text(rew))
			_close_overlay()
			# bölge ödülü varsa sinematik açılış kartı oynar
			if str(rew.get("node", "")) != "":
				Wmap.unlock_cine(str(rew.node))
			else:
				quest_panel(nid)))
	for q in Quests.active_for(nid):
		any = true
		v.add_child(_quest_row(q, "%s" % Quests.prog_text(q), Color(0.6, 0.6, 0.7), Callable()))
	for q in Quests.available_for(nid):
		any = true
		v.add_child(_quest_row(q, "KABUL ET", Px.C("00E676"), func():
			Quests.accept(str(q.id))
			G.audio.jingle("boon")
			_close_overlay()
			quest_panel(nid)))
	if not any:
		var l := _lbl("şimdilik iş yok — sahadan haber getir", Vector2.ZERO, 13, Color(0.6, 0.6, 0.7))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	var svc := Button.new()
	svc.text = "HİZMET / PANEL →"
	svc.add_theme_font_override("font", ui_font())
	svc.custom_minimum_size = Vector2(200, 28)
	var sc := CenterContainer.new()
	sc.add_child(svc)
	v.add_child(sc)
	svc.pressed.connect(func():
		_close_overlay()
		_service_panel_for(nid))
	var h := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

func _quest_row(q: Dictionary, btn_text: String, bcol: Color, cb: Callable) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style_panel(Color(0.05, 0.03, 0.08, 0.9), bcol.darkened(0.25), 1, 3))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.custom_minimum_size = Vector2(760, 0)
	p.add_child(h)
	var ic := TextureRect.new()
	ic.texture = Px.S2("ico_quest")
	ic.custom_minimum_size = Vector2(26, 26)
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.modulate = bcol
	h.add_child(ic)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mid)
	var t := _lbl("%s  —  %s" % [str(q.name), Quests.obj_text(q)], Vector2.ZERO, 13, Color(0.92, 0.92, 0.96))
	mid.add_child(t)
	var d := _lbl("%s   ·   ödül: %s" % [str(q.desc), Quests.rew_text(q.get("rew", {}))], Vector2.ZERO, 11, Color(0.65, 0.65, 0.75))
	mid.add_child(d)
	if cb.is_valid():
		var b := Button.new()
		b.text = btn_text
		b.add_theme_font_override("font", ui_font())
		b.custom_minimum_size = Vector2(110, 26)
		h.add_child(b)
		b.pressed.connect(cb)
	else:
		var pl := _lbl(btn_text, Vector2.ZERO, 12, bcol)
		h.add_child(pl)
	return p

# ---------------------------------------------------------------- envanter (Saphire)

func inventory_panel() -> void:
	_pause(true)
	var v := _show_panel("inv", "TEÇHİZAT — Saphire'in tezgâhı", Px.C("ff9e4d"))
	var money := _lbl("Saf Choralim: ◆ %d" % int(G.meta.data.get("choralim", 0)), Vector2.ZERO, 13, Px.C("c26bff"))
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(money)
	var eq: Dictionary = G.meta.data.get("equip", {})
	var estats := Items.equip_stats()
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	for slot in Items.SLOTS:
		var iid := str(eq.get(slot, ""))
		var d: Dictionary = Items.DEFS.get(iid, {})
		var cell := PanelContainer.new()
		var rc := Px.C(Items.RARITY_COL[int(d.get("r", 0))]) if not d.is_empty() else Color(0.3, 0.3, 0.38)
		cell.add_theme_stylebox_override("panel", _style_panel(Color(0.04, 0.03, 0.07, 0.95), rc, 2, 3))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 3)
		cell.add_child(cv)
		var sl := _lbl(Items.SLOT_NAME.get(slot, slot), Vector2.ZERO, 9, Color(0.55, 0.55, 0.62))
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(sl)
		var ic := TextureRect.new()
		ic.texture = Px.S2(str(d.get("icon", "ico_loot"))) if not d.is_empty() else null
		ic.custom_minimum_size = Vector2(34, 34)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.modulate = rc if not d.is_empty() else Color(0.2, 0.2, 0.25)
		var icc := CenterContainer.new()
		icc.add_child(ic)
		cv.add_child(icc)
		var nm := _lbl(str(d.get("name", "—")), Vector2.ZERO, 9, Color(0.85, 0.85, 0.9))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nm.custom_minimum_size = Vector2(96, 24)
		cv.add_child(nm)
		if not d.is_empty():
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed:
					Items.unequip(slot)
					toast("%s çıkarıldı" % str(d.name))
					_close_overlay()
					inventory_panel())
		top.add_child(cell)
	var stats_txt := []
	for k in ["hp", "armor", "dmg", "spd", "crit", "critmult", "ls", "mag", "xp", "dash_regen", "revive"]:
		var f := float(estats.get(k, 0))
		if f == 0.0:
			continue
		var fmt := "+%d" % int(f) if absf(f) >= 1.5 else "+%d%%" % int(f * 100)
		stats_txt.append("%s %s" % [fmt, {"hp": "can", "armor": "zırh", "dmg": "hasar", "spd": "hız", "crit": "kritik", "critmult": "kritik×", "ls": "can emme", "mag": "mıknatıs", "xp": "XP", "dash_regen": "dash yenileme", "revive": "dirilme"}[k]])
	var sl2 := _lbl("ekipman toplamı:  %s" % ("   ·   ".join(stats_txt) if not stats_txt.is_empty() else "—"), Vector2.ZERO, 11, Color(0.7, 0.8, 0.9))
	sl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sl2)
	# set bonusları: tamamlananlar parlar, eksikler soluk ilerleme gösterir
	for s in Items.set_state():
		var scol := Px.C("ffd75f") if s.active else Color(0.45, 0.45, 0.55)
		var stl := _lbl("%s  %d/%d%s" % [str(s.name), int(s.have), int(s.need), " — AKTİF" if s.active else ""], Vector2.ZERO, 10, scol)
		stl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(stl)
	var sep := _lbl("— ZULA  (seç: kuşan / tekrar seç: geri koy) —", Vector2.ZERO, 12, Px.C("ff9e4d"))
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sep)
	var stash: Array = G.meta.data.get("stash", [])
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	if stash.is_empty():
		var l := _lbl("zula boş — elitler ve boss'lar eşya düşürür", Vector2.ZERO, 12, Color(0.5, 0.5, 0.6))
		grid.add_child(l)
	for iid in stash:
		var d: Dictionary = Items.DEFS.get(str(iid), {})
		if d.is_empty():
			continue
		var cell := PanelContainer.new()
		var rc := Px.C(Items.RARITY_COL[int(d.r)])
		cell.add_theme_stylebox_override("panel", _style_panel(Color(0.05, 0.04, 0.08, 0.95), rc, 2, 3))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		cell.add_child(cv)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		cv.add_child(row)
		var ic := TextureRect.new()
		ic.texture = Px.S2(str(d.icon))
		ic.custom_minimum_size = Vector2(24, 24)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.modulate = rc
		row.add_child(ic)
		var nm := _lbl(str(d.name), Vector2.ZERO, 10, Color(0.9, 0.9, 0.94))
		row.add_child(nm)
		var md := _lbl(Items.stat_text(str(iid)), Vector2.ZERO, 9, Color(0.65, 0.75, 0.85))
		cv.add_child(md)
		var brow := HBoxContainer.new()
		brow.add_theme_constant_override("separation", 4)
		cv.add_child(brow)
		var eqb := Button.new()
		eqb.text = "KUŞAN"
		eqb.add_theme_font_override("font", ui_font())
		eqb.custom_minimum_size = Vector2(64, 20)
		brow.add_child(eqb)
		eqb.pressed.connect(func():
			Items.equip(str(iid), Items.slot_of(str(iid)))
			toast("%s kuşanıldı" % str(d.name))
			_close_overlay()
			inventory_panel())
		var slb := Button.new()
		slb.text = "SAT ◆%d" % Items.sell_price(str(iid))
		slb.add_theme_font_override("font", ui_font())
		slb.custom_minimum_size = Vector2(70, 20)
		brow.add_child(slb)
		slb.pressed.connect(func():
			var got := Items.sell(str(iid))
			G.audio.jingle("boon")
			toast("%s satıldı: ◆+%d" % [str(d.name), got])
			_close_overlay()
			inventory_panel())
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		grid.add_child(cell)
	var tb := Button.new()
	tb.text = "HURDA TAKASI →   2 eşya ver, 1 yeni al (nadirlik korunur/yükselir)"
	tb.add_theme_font_override("font", ui_font())
	tb.custom_minimum_size = Vector2(320, 28)
	var tc := CenterContainer.new()
	tc.add_child(tb)
	v.add_child(tc)
	tb.pressed.connect(func():
		_close_overlay()
		barter_panel())
	var sb := Button.new()
	sb.text = "PAZAR TEZGÂHI →   choralim ile eşya al (stok koşu başına yenilenir)"
	sb.add_theme_font_override("font", ui_font())
	sb.custom_minimum_size = Vector2(320, 28)
	var sc := CenterContainer.new()
	sc.add_child(sb)
	v.add_child(sc)
	sb.pressed.connect(func():
		_close_overlay()
		shop_panel())
	var h := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# 2 zula eşyası ↔ 1 yeni eşya; sonuç nadirliği ≥ düşük olanı
func barter_panel() -> void:
	_pause(true)
	var v := _show_panel("barter", "HURDA TAKASI — Saphire'in kefeni", Px.C("ff9e4d"))
	var stash: Array = G.meta.data.get("stash", [])
	var hint := _lbl("2 eşya seç — karşılığında yeni bir eşya gelir (nadirlik ≥ düşük olanı)", Vector2.ZERO, 12, Color(0.7, 0.7, 0.8))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	var sel: Array = []
	var trade := Button.new()
	trade.disabled = true
	trade.modulate = Color(0.5, 0.5, 0.55)
	trade.text = "2 EŞYA SEÇ"
	trade.add_theme_font_override("font", ui_font())
	trade.custom_minimum_size = Vector2(200, 30)
	if stash.size() < 2:
		var l := _lbl("takas için zulada en az 2 eşya gerekir — sahadan eşya getir", Vector2.ZERO, 12, Color(0.5, 0.5, 0.6))
		grid.add_child(l)
	for iid in stash:
		var d: Dictionary = Items.DEFS.get(str(iid), {})
		if d.is_empty():
			continue
		var cell := PanelContainer.new()
		var rc := Px.C(Items.RARITY_COL[int(d.r)])
		cell.add_theme_stylebox_override("panel", _style_panel(Color(0.05, 0.04, 0.08, 0.95), rc, 2, 3))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		cell.add_child(cv)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		cv.add_child(row)
		var ic := TextureRect.new()
		ic.texture = Px.S2(str(d.icon))
		ic.custom_minimum_size = Vector2(24, 24)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.modulate = rc
		row.add_child(ic)
		var nm := _lbl(str(d.name), Vector2.ZERO, 10, Color(0.9, 0.9, 0.94))
		row.add_child(nm)
		var md := _lbl(Items.stat_text(str(iid)), Vector2.ZERO, 9, Color(0.65, 0.75, 0.85))
		cv.add_child(md)
		var tag := _lbl("", Vector2.ZERO, 9, Px.C("ffd700"))
		cv.add_child(tag)
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		var id0 := str(iid)
		cell.gui_input.connect(func(ev: InputEvent):
			if not (ev is InputEventMouseButton and ev.pressed):
				return
			if sel.has(id0):
				sel.erase(id0)
				tag.text = ""
				cell.add_theme_stylebox_override("panel", _style_panel(Color(0.05, 0.04, 0.08, 0.95), rc, 2, 3))
			elif sel.size() < 2:
				sel.append(id0)
				tag.text = "✓ seçildi"
				cell.add_theme_stylebox_override("panel", _style_panel(Color(0.08, 0.06, 0.02, 0.95), Px.C("ffd700"), 2, 3))
			var ready := sel.size() == 2
			trade.disabled = not ready
			trade.modulate = Color(1, 1, 1) if ready else Color(0.5, 0.5, 0.55)
			trade.text = "TAKAS ET" if ready else "2 EŞYA SEÇ  (%d/2)" % sel.size())
		grid.add_child(cell)
	trade.pressed.connect(func():
		var got := Items.barter(str(sel[0]), str(sel[1]))
		if got == "full":
			toast("koleksiyon tam — takas edecek eşya kalmadı")
			return
		if got != "":
			var nd: Dictionary = Items.DEFS.get(got, {})
			G.audio.jingle("victory")
			toast("takas: %s geldi (%s)" % [str(nd.get("name", got)), Items.RARITY_NAME[int(nd.get("r", 0))]])
			_close_overlay()
			inventory_panel())
	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 12)
	row2.add_child(trade)
	var back := Button.new()
	back.text = "← TEÇHİZAT"
	back.add_theme_font_override("font", ui_font())
	back.custom_minimum_size = Vector2(140, 30)
	row2.add_child(back)
	v.add_child(row2)
	back.pressed.connect(func():
		_close_overlay()
		inventory_panel())
	var h := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# Saphire'in pazar tezgâhı — koşu başına yenilenen stok, choralim karşılığı eşya
func shop_panel() -> void:
	_pause(true)
	var v := _show_panel("shop", "PAZAR TEZGÂHI — Saphire'in malları", Px.C("ff9e4d"))
	var money := _lbl("Saf Choralim: ◆ %d" % int(G.meta.data.get("choralim", 0)), Vector2.ZERO, 13, Px.C("c26bff"))
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(money)
	var hint := _lbl("stok her koşu dönüşünde yenilenir — sahipsiz eşyalar gelir", Vector2.ZERO, 12, Color(0.7, 0.7, 0.8))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var stock := Items.shop_stock()
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	if stock.is_empty():
		var l := _lbl("stok boş — yeni koşudan sonra tezgâh yenilenir", Vector2.ZERO, 12, Color(0.5, 0.5, 0.6))
		grid.add_child(l)
	for iid in stock:
		var d: Dictionary = Items.DEFS.get(str(iid), {})
		if d.is_empty():
			continue
		var cell := PanelContainer.new()
		var rc := Px.C(Items.RARITY_COL[int(d.r)])
		cell.add_theme_stylebox_override("panel", _style_panel(Color(0.05, 0.04, 0.08, 0.95), rc, 2, 3))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		cell.add_child(cv)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		cv.add_child(row)
		var ic := TextureRect.new()
		ic.texture = Px.S2(str(d.icon))
		ic.custom_minimum_size = Vector2(24, 24)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.modulate = rc
		row.add_child(ic)
		var nm := _lbl(str(d.name), Vector2.ZERO, 10, Color(0.9, 0.9, 0.94))
		row.add_child(nm)
		var rt := _lbl(Items.RARITY_NAME[int(d.r)], Vector2.ZERO, 8, rc)
		cv.add_child(rt)
		var md := _lbl(Items.stat_text(str(iid)), Vector2.ZERO, 9, Color(0.65, 0.75, 0.85))
		cv.add_child(md)
		var price := Items.buy_price(str(iid))
		var bb := Button.new()
		bb.text = "SATIN AL ◆%d" % price
		bb.add_theme_font_override("font", ui_font())
		bb.custom_minimum_size = Vector2(120, 22)
		bb.disabled = int(G.meta.data.get("choralim", 0)) < price
		if bb.disabled:
			bb.modulate = Color(0.5, 0.5, 0.55)
		cv.add_child(bb)
		var id0 := str(iid)
		var dname := str(d.name)
		bb.pressed.connect(func():
			var paid := Items.buy(id0)
			if paid > 0:
				G.audio.jingle("boon")
				toast("%s alındı: ◆-%d" % [dname, paid])
				_close_overlay()
				shop_panel())
		grid.add_child(cell)
	var back2 := Button.new()
	back2.text = "← TEÇHİZAT"
	back2.add_theme_font_override("font", ui_font())
	back2.custom_minimum_size = Vector2(160, 26)
	var bc := CenterContainer.new()
	bc.add_child(back2)
	v.add_child(bc)
	back2.pressed.connect(func():
		_close_overlay()
		inventory_panel())
	var h2 := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h2)

# BG2 "you have been waylaid" — kampa varmadan önce yol karşılaşması.
# kind "waylay" kapatılamaz: oyuncu iki seçenekten birini seçmek zorunda.
const WAYLAY := {
	"pusu":   {"name": "PUSU", "col": "ff5252",
		"sub": "Sis perdesi aralandı — konakçı avcıları yolu kesti. Sinyal çok yakın; kuşatmadan çıkmak için ya savaş ya haraç.",
		"opts": ["SAVAŞ — arenaya kuşatılmış gir, frag bereketi ×1.35", "HARAÇ ÖDE — ◆40, yol temiz"]},
	"kervan": {"name": "YARALI KERVAN", "col": "ffd700",
		"sub": "Devrik bir kervan: sürücüler yaralı, mallar savunmasız. Viator kanunu yardımı ister — kovan kanunu yağmayı.",
		"opts": ["YARDIM ET — bedava lütuf + kalıcı şans", "YAĞMALA — ◈80 parçacık, azap +1"]},
	"harabe": {"name": "YOLKENARI HARABE", "col": "8fd4ff",
		"sub": "Çöken bir karakol kalıntısı yolu kesiyor. Molozun altında eşya olabilir — ya da sadece düşen taşlar.",
		"opts": ["ARAŞTIR — şansına: eşya ya da enkaz hasarı", "GEÇ — durmaya değmez"]},
	"gezgin": {"name": "YALNIZ GEZGİN", "col": "c26bff",
		"sub": "Bacağı tüten bir şasi yolun kenarında duruyor. Sırt çantası ağzına kadar eşya dolu: 'Kaliteli mal, düşük fiyat. Viator'a indirim yok.'",
		"opts": ["AL — ◆120, rasgele eşya", "GEÇ — yola devam"]},
}

func travel_event(wkind: String, dest: String) -> void:
	_pause(true)
	var d: Dictionary = WAYLAY.get(wkind, WAYLAY["pusu"])
	var v := _show_panel("waylay", "YOL OLAYI — " + dest, Px.C(str(d.col)))
	var nm := _lbl(str(d.name), Vector2.ZERO, 16, Px.C(str(d.col)))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	var sub := _lbl(str(d.sub), Vector2.ZERO, 13, Color(0.85, 0.85, 0.92))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(560, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var cho_lbl := _lbl("◆ %d" % int(G.meta.data.get("choralim", 0)), Vector2.ZERO, 12, Px.C("c26bff"))
	cho_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cho_lbl)
	for i in 2:
		var ob := Button.new()
		ob.text = str(d.opts[i])
		ob.add_theme_font_override("font", ui_font())
		ob.custom_minimum_size = Vector2(480, 34)
		# pusuda haraç: choralim yetmezse tek çıkış savaş
		if wkind == "pusu" and i == 1 and int(G.meta.data.get("choralim", 0)) < 40:
			ob.disabled = true
			ob.modulate = Color(0.45, 0.45, 0.5)
		if wkind == "gezgin" and i == 0 and int(G.meta.data.get("choralim", 0)) < 120:
			ob.disabled = true
			ob.modulate = Color(0.45, 0.45, 0.5)
		var oc := CenterContainer.new()
		oc.add_child(ob)
		v.add_child(oc)
		var idx := i
		ob.pressed.connect(func(): _waylay_pick(wkind, idx))

func _waylay_pick(wkind: String, idx: int) -> void:
	match wkind:
		"pusu":
			if idx == 0:
				G.run.pending_ambush = true
				G.run.frag_node *= 1.35
				toast("PUSU — kuşatılmış giriş, frag bereketi arttı")
			else:
				G.meta.data["choralim"] = int(G.meta.data.get("choralim", 0)) - 40
				G.meta.save()
				toast("haraç ödendi — avcılar geri çekildi")
		"kervan":
			if idx == 0:
				G.run.luck += 0.2
				G.run.take_boon(G.pick(Boons.all()))
				toast("kervan teşekkür etti — lütuf + şans")
			else:
				G.run.fragments += 80
				G.run.curse += 1
				toast("kervan yağmalandı — ◈+80, AZAP +1")
		"harabe":
			if idx == 0:
				if randf() < 0.6:
					Items.drop_to_run(Items.roll(G.run.luck))
					toast("molozun altında eşya buldun")
				else:
					G.run.pending_dmg = 18.0
					toast("harabe çöktü — girişte yara alacaksın")
			else:
				toast("harabe geçildi")
		"gezgin":
			if idx == 0:
				G.meta.data["choralim"] = int(G.meta.data.get("choralim", 0)) - 120
				G.meta.save()
				Items.drop_to_run(Items.roll(G.run.luck))
				toast("gezgin takası — eşya çantaya girdi")
			else:
				toast("gezgin yoluna devam etti")
	G.audio.jingle("boon")
	_close_overlay()
	G.run._enter_arena()

func records_panel() -> void:
	_pause(true)
	var v := _show_panel("records", "KAMP KAYITLARI — Vezir Zirkon", Px.C("c9a227"))
	var d := G.meta.data
	var rows := [
		"koşu: %d   zafer: %d   düşüş: %d" % [int(d.get("runs", 0)), int(d.get("victories", 0)), int(d.get("deaths", 0))],
		"toplam kesim: %d   ·   en derin: %d" % [int(d.get("kills", 0)), int(d.get("best_depth", 0))],
		"choralim rezervi: ◆ %d" % int(d.get("choralim", 0)),
		"en yüksek skor: %d" % int(d.get("best_score", 0)),
		"en uzun seri: x%d" % int(d.get("best_streak_all", 0)),
		"altın nüve: %d   (+%0.1f%% kalıcı hasar)" % [int(d.get("eggs", 0)), int(d.get("eggs", 0)) * 0.5],
	]
	for r in rows:
		var l := _lbl(r, Vector2.ZERO, 14, Color(0.85, 0.85, 0.92))
		v.add_child(l)
	var sep := _lbl("— DÜŞMÜŞ EFENDELER —", Vector2.ZERO, 12, Px.C("c9a227"))
	v.add_child(sep)
	var dn: Array = G.meta.data.get("bosses", [])
	for i in 4:
		var bid: String = Run.BOSS_IDS[i]
		var done: bool = dn.has(bid)
		var l := _lbl("%s  %s" % ["◆" if done else "◇", "%s — %s" % [BIOME_NAME[i], Run.BOSS_NAMES[i]]],
			Vector2.ZERO, 13, Color(0.95, 0.85, 0.4) if done else Color(0.5, 0.5, 0.6))
		v.add_child(l)
	var tk: Dictionary = d.get("kind_kills", {})
	var cols := HBoxContainer.new()
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_theme_constant_override("separation", 34)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 5)
	var sep2 := _lbl("— ARSENAL —", Vector2.ZERO, 12, Px.C("c9a227"))
	left.add_child(sep2)
	for wid in Weapons.DEFS:
		var wd: Dictionary = Weapons.DEFS[wid]
		if wd.get("hidden", false):
			continue
		var ok := Weapons.unlocked(wid)
		var l := _lbl("%s  %s%s" % ["◆" if ok else "◇", str(wd.name), "" if ok else "  — " + Weapons.req_text(wid)],
			Vector2.ZERO, 12, Color(0.9, 0.85, 0.6) if ok else Color(0.45, 0.45, 0.55))
		left.add_child(l)
	cols.add_child(left)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 4)
	var sep4 := _lbl("— KOVAN KAYITLARI —", Vector2.ZERO, 12, Px.C("c9a227"))
	mid.add_child(sep4)
	for k in Enemy.EKind.values():
		var kn: String = Enemy.KIND_SET.get(k, Enemy.EKind.keys()[k].to_lower())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var fr: Dictionary = Px.F(kn)
		if fr.has("idle") and not fr["idle"].is_empty():
			var tr := TextureRect.new()
			tr.texture = fr["idle"][0]
			tr.custom_minimum_size = Vector2(28, 28)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			row.add_child(tr)
		var cnt := int(tk.get(Enemy.KIND_NAME[k], 0))
		var kl := _lbl("%s  x%d" % [str(Enemy.KIND_NAME[k]), cnt], Vector2.ZERO, 11, Color(0.8, 0.8, 0.85) if cnt > 0 else Color(0.4, 0.4, 0.5))
		row.add_child(kl)
		mid.add_child(row)
	cols.add_child(mid)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 5)
	var sep3 := _lbl("— BAŞARIMLAR —", Vector2.ZERO, 12, Px.C("c9a227"))
	right.add_child(sep3)
	for a in G.meta.achievements():
		var l := _lbl("%s  %s\n        %s%s" % ["◆" if a.done else "◇", str(a.name), str(a.desc), "  · ödül ◆%d" % int(a.get("rew", 0))],
			Vector2.ZERO, 11, Color(0.95, 0.8, 0.4) if a.done else Color(0.45, 0.45, 0.55))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(240, 0)
		right.add_child(l)
	cols.add_child(right)
	# ÖYKÜ codex'i — ziyaret edilmiş node'ların lore kayıtları
	var lore_col := VBoxContainer.new()
	lore_col.add_theme_constant_override("separation", 5)
	lore_col.add_child(_lbl("— ÖYKÜ —", Vector2.ZERO, 12, Px.C("c9a227")))
	var vn: Array = G.meta.data.get("visited_nodes", [])
	var any_lore := false
	for n in Wmap.NODES:
		if str(n.id) == "kamp" or str(n.get("lore", "")) == "":
			continue
		var seen: bool = vn.has(str(n.id))
		var lt: String = str(n.lore)
		if lt.length() > 110:
			lt = lt.substr(0, 107) + "..."
		var ll := _lbl("%s\n%s" % [str(n.name), lt if seen else "— keşfedilmedi —"], Vector2.ZERO, 9,
			Color(0.85, 0.8, 0.6) if seen else Color(0.4, 0.4, 0.5))
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size = Vector2(190, 0)
		lore_col.add_child(ll)
		any_lore = true
	if any_lore:
		cols.add_child(lore_col)
	v.add_child(cols)
	# görev defteri — kabul edilen / biten / teslim edilenler
	var qsep := _lbl("— GÖREV DEFTERİ —", Vector2.ZERO, 12, Px.C("c9a227"))
	v.add_child(qsep)
	var qany := false
	for q in Quests.DEFS:
		var st := Quests.state(str(q.id))
		if st == "":
			continue
		qany = true
		var ic := "◆" if st == "claimed" else ("◈" if st == "done" else "◇")
		var col := Color(0.9, 0.85, 0.5) if st == "claimed" else (Color(0.5, 0.9, 0.6) if st == "done" else Color(0.75, 0.75, 0.85))
		var tag := "teslim edildi" if st == "claimed" else ("TAMAM — %s'a dön" % str(NPC.NAMES.get(str(q.giver), str(q.giver))) if st == "done" else Quests.prog_text(q))
		var l := _lbl("%s  %s  ·  %s  ·  %s" % [ic, str(q.name), str(NPC.NAMES.get(str(q.giver), str(q.giver))).split(" ")[-1], tag], Vector2.ZERO, 12, col)
		v.add_child(l)
	if not qany:
		var l := _lbl("henüz görev yok — NPC'lerdeki ! işaretini takip et", Vector2.ZERO, 11, Color(0.5, 0.5, 0.6))
		v.add_child(l)
	var ld: Dictionary = d.get("last_death", {})
	if not ld.is_empty() and str(ld.get("killer", "")) != "":
		var l := _lbl("son düşüş: %s @ %s" % [str(ld.get("killer")), BIOME_NAME[int(ld.get("biome", 0))]], Vector2.ZERO, 11, Color(0.6, 0.55, 0.6))
		v.add_child(l)
	var h := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	v.add_child(h)

# Ehnar: the standing field contract — met by the next run's stats at camp.
func contract_panel() -> void:
	_pause(true)
	var v := _show_panel("contract", "SAHA SÖZLEŞMESİ — Eski Şövalye Ehnar", Px.C("ff9e4d"))
	var c: Dictionary = G.meta.data.get("contract", {})
	var lr: Dictionary = G.meta.data.get("last_run", {})
	var l1 := _lbl("◈ %s" % G.run.contract_text(c), Vector2.ZERO, 16, Color(0.95, 0.9, 0.8))
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l1)
	var l2 := _lbl("ödül: ◆ %d choralim" % int(c.get("reward", 0)), Vector2.ZERO, 13, Px.C("c26bff"))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l2)
	var prog := "henüz koşu yok"
	if not lr.is_empty():
		prog = "son koşu:  %d kesim · %02d:%02d · seviye %d%s" % [
			int(lr.get("kills", 0)), int(lr.get("time", 0)) / 60, int(lr.get("time", 0)) % 60,
			int(lr.get("level", 1)), " · ZAFER" if bool(lr.get("win", false)) else ""]
	var l3 := _lbl(prog, Vector2.ZERO, 11, Color(0.6, 0.6, 0.72))
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l3)
	var h := _lbl("[E / tık] kapat — sözleşme kampa döndüğünde değerlendirilir", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# Ahusk: a deserter from the swarm sells a war boon — next run starts with a
# random boon for ◆80, buyable once per run.
func blessing_panel() -> void:
	_pause(true)
	var v := _show_panel("blessing", "GÖÇEBE AHUSK — destek takası", Px.C("6aa8a0"))
	var por := TextureRect.new()
	por.texture = Px.S2("por_ahusk")
	por.custom_minimum_size = Vector2(72, 72)
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pc := CenterContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(por)
	v.add_child(pc)
	var has := bool(G.meta.data.get("blessing", false))
	var l := _lbl("koşu bir lütufla başlar — rasgele, patronu sen seçmezsin", Vector2.ZERO, 13, Color(0.8, 0.85, 0.8))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var money := _lbl("Saf Choralim: ◆ %d" % G.meta.data.choralim, Vector2.ZERO, 12, Px.C("c26bff"))
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(money)
	var btn := Button.new()
	btn.text = "✓ HAZIR — sahaya in" if has else "◆ 80 — SATIN AL"
	btn.disabled = has or G.meta.data.choralim < 80
	btn.custom_minimum_size = Vector2(200, 30)
	btn.add_theme_font_override("font", ui_font())
	var bc := CenterContainer.new()
	bc.add_child(btn)
	v.add_child(bc)
	btn.pressed.connect(func():
		if not has and G.meta.data.choralim >= 80:
			G.meta.data["choralim"] -= 80
			G.meta.data["blessing"] = true
			G.meta.save()
			G.audio.play("boon", 1.1, 0.6)
			_close_overlay()
			blessing_panel())
	var h := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# Neva'nın şarkısı: tek koşuluk +%15 XP — choralim karşılığı
func song_panel() -> void:
	_pause(true)
	var v := _show_panel("song", "NEVA — choralim şarkısı", Px.C("c26bff"))
	var por := TextureRect.new()
	por.texture = Px.S2("por_neva")
	por.custom_minimum_size = Vector2(72, 72)
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pc := CenterContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(por)
	v.add_child(pc)
	var has := bool(G.meta.data.get("neva_song", false))
	var l := _lbl("şarkı sonraki koşuyu sarar — +%15 XP kazanımı", Vector2.ZERO, 13, Color(0.85, 0.8, 0.95))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var money := _lbl("Saf Choralim: ◆ %d" % G.meta.data.choralim, Vector2.ZERO, 12, Px.C("c26bff"))
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(money)
	var btn := Button.new()
	btn.text = "✓ HAZIR — sahaya in" if has else "◆ 60 — DİNLE"
	btn.disabled = has or G.meta.data.choralim < 60
	btn.custom_minimum_size = Vector2(200, 30)
	btn.add_theme_font_override("font", ui_font())
	var bc := CenterContainer.new()
	bc.add_child(btn)
	v.add_child(bc)
	btn.pressed.connect(func():
		if not has and G.meta.data.choralim >= 60:
			G.meta.data["choralim"] -= 60
			G.meta.data["neva_song"] = true
			G.meta.save()
			G.audio.play("boon", 1.1, 0.6)
			_close_overlay()
			song_panel())
	var h := _lbl("[E / tık] kapat", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# gezgin tüccar — koşu içi dükkân: parçacık harca, tek alışveriş, sonra kovar
func merchant_panel() -> void:
	_pause(true)
	var v := _show_panel("merchant", "GEZGİN TÜCCAR — yolda pazar", Px.C("ffd700"))
	var por := TextureRect.new()
	por.texture = Px.S2("por_ahusk")
	por.custom_minimum_size = Vector2(64, 64)
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pc := CenterContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(por)
	v.add_child(pc)
	var l := _lbl("\"Kovandan değilim, kervandanım. Tek alışveriş — sonra yola.\"", Vector2.ZERO, 12, Color(0.85, 0.8, 0.6))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var fr := _lbl("parçacık: ◈ %d   (tek alışveriş hakkın var)" % G.run.fragments, Vector2.ZERO, 13, Px.C("42d4f4"))
	fr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(fr)
	var offers := [
		{"name": "ŞİFA", "desc": "+%40 can", "cost": 150, "icon": "icn_upg_hp"},
		{"name": "LÜTUF", "desc": "rasgele lütuf kartı", "cost": 400, "icon": "ico_boon"},
		{"name": "EŞYA", "desc": "rasgele eşya — nadirlik şansa bağlı", "cost": 600, "icon": "ico_loot"},
	]
	for o in offers:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		v.add_child(row)
		var ic := TextureRect.new()
		ic.texture = Px.S2(str(o.icon))
		ic.custom_minimum_size = Vector2(26, 26)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.modulate = Px.C("ffd700")
		row.add_child(ic)
		var lb := _lbl("%s — %s" % [str(o.name), str(o.desc)], Vector2.ZERO, 13, Color(0.9, 0.9, 0.94))
		lb.custom_minimum_size = Vector2(300, 0)
		row.add_child(lb)
		var cost := int(o.cost)
		var b := Button.new()
		b.text = "◈ %d" % cost
		b.add_theme_font_override("font", ui_font())
		b.custom_minimum_size = Vector2(90, 26)
		b.disabled = G.run.fragments < cost
		if b.disabled:
			b.modulate = Color(0.5, 0.5, 0.55)
		row.add_child(b)
		var o_id := str(o.name)
		b.pressed.connect(func():
			if G.run.fragments < cost:
				return
			G.run.fragments -= cost
			match o_id:
				"ŞİFA":
					G.player.hp = minf(G.player.max_hp, G.player.hp + G.player.max_hp * 0.4)
					G.fx.burst(G.player.pos + Vector2(0, -20), Px.C("42d4f4"), 18, 140.0, 5.0, 0.6)
				"LÜTUF":
					G.run.take_boon(G.pick(Boons.all()))
				"EŞYA":
					Items.drop_to_run(Items.roll(G.run.luck))
			G.audio.jingle("victory")
			toast("tüccar: %s alındı — yoluna devam ediyor" % o_id)
			G.room.despawn_merchant()
			_close_overlay())
	var out := Button.new()
	out.text = "YOLA DEVAM — almadan çık"
	out.add_theme_font_override("font", ui_font())
	out.custom_minimum_size = Vector2(240, 28)
	var oc := CenterContainer.new()
	oc.add_child(out)
	v.add_child(oc)
	out.pressed.connect(_close_overlay)
	var h := _lbl("[E / tık] kapat — tüccar bekler", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# ---------------------------------------------------------------- stray chassis

func stray_panel() -> void:
	_pause(true)
	var v := _show_panel("stray", "KAYIP ŞASİ — enkazda unutulmuş gövde", Px.C("8fd4ff"))
	var por := TextureRect.new()
	por.texture = Px.S2("por_elyb")
	por.custom_minimum_size = Vector2(64, 64)
	por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	por.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	por.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pc := CenterContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(por)
	v.add_child(pc)
	var l := _lbl("\"...transistör parçası lazım. Sistemler kapanıyor.\nMinnetimi transistörle öderim — ya da beni hurda yap.\"", Vector2.ZERO, 12, Color(0.8, 0.88, 0.95))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var fr := _lbl("parçacık: ◈ %d" % G.run.fragments, Vector2.ZERO, 12, Px.C("42d4f4"))
	fr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(fr)
	var onar := Button.new()
	onar.text = "ONAR — ◈60 transistör, karşılığı eşya"
	onar.add_theme_font_override("font", ui_font())
	onar.custom_minimum_size = Vector2(380, 30)
	onar.disabled = G.run.fragments < 60
	if onar.disabled:
		onar.modulate = Color(0.5, 0.5, 0.55)
	var oc1 := CenterContainer.new()
	oc1.add_child(onar)
	v.add_child(oc1)
	onar.pressed.connect(func():
		if G.run.fragments < 60:
			return
		G.run.fragments -= 60
		Items.drop_to_run(Items.roll(G.run.luck + 0.15))
		G.audio.jingle("victory")
		toast("şasi gözlerini açtı — emanet eşyayı bıraktı, yola çıktı")
		G.room.despawn_stray()
		_close_overlay())
	var par := Button.new()
	par.text = "PARÇALA — ◈140 parçacık, azap +1"
	par.add_theme_font_override("font", ui_font())
	par.custom_minimum_size = Vector2(380, 30)
	var oc2 := CenterContainer.new()
	oc2.add_child(par)
	v.add_child(oc2)
	par.pressed.connect(func():
		G.run.fragments += 140
		G.run.curse += 1
		G.fx.shake(0.15, 0.2)
		G.audio.play("die", 0.8, 0.7)
		toast("şasiyi hurdaya çevirdin — kovan bunu gördü")
		G.room.despawn_stray()
		_close_overlay())
	var h := _lbl("[E / tık] kapat — şasi bekler", Vector2.ZERO, 11, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# ---------------------------------------------------------------- boon draft

func boon_choice() -> void:
	var rolled := Boons.roll(G.run.boon_ids, G.run.luck)
	if rolled.is_empty():
		return
	var cards: Array = []
	for b in rolled:
		cards.append({"kind": "boon", "id": b.id, "name": b.name, "icon": "icn_" + str(b.patron).to_lower(), "col": b.color.to_html(false), "desc": b.desc, "top": b.patron, "w": 1.0})
	_pause(true)
	_show_cards("draft", "REZONANS PROTOKOLÜ — lütuf seç  [1/2/3]", Px.C("7B1FA2"), cards)

func levelup_draft() -> void:
	if overlay_open():
		G.run.pending_drafts += 1
		return
	G.run.draft_reroll = true
	G.run.draft_banish = true
	_open_draft()

func _open_draft() -> void:
	var opts := Weapons.draft_opts(G.player, G.run.luck)
	if opts.is_empty():
		return
	_pause(true)
	var all := opts.duplicate()
	if G.run.draft_reroll:
		all.append({"kind": "reroll", "id": "rr", "name": "YENİLE", "icon": "icn_dash", "col": "00E5FF", "desc": "kartları yeniden dağıt — taslak başına bir kez", "top": "ŞANS", "w": 1.0})
	if G.run.draft_banish:
		all.append({"kind": "banish", "id": "ban", "name": "KOV", "icon": "icn_kovan", "col": "ff5533", "desc": "bir kartı bu koşudan tamamen sil — sonra normal seç", "top": "KOV", "w": 1.0})
	all.append({"kind": "gift", "id": "skip", "name": "GEÇ", "icon": "ico_frag", "col": "9aa0b0", "desc": "+15 parçacık — hiçbirini alma", "top": "SEÇME", "w": 1.0})
	_show_cards("draft", "SEVİYE %d — güçlendirme seç  [1-%d]" % [G.player.level, all.size()], Px.C("00E5FF"), all)

# koşu açılışında KOZ taslağı (VS arcana) — bir kart, koşu boyu etki
func arcana_choice() -> void:
	var pool := Boons.ARCANAS.keys()
	pool.shuffle()
	var cards: Array = []
	for aid in pool.slice(0, 3):
		var a: Dictionary = Boons.ARCANAS[aid]
		cards.append({"kind": "arcana", "id": aid, "name": str(a["name"]), "icon": "icn_crown", "col": str(a["col"]), "desc": str(a["desc"]), "top": "KOZ", "w": 1.0})
	_pause(true)
	_show_cards("boon", "KOZ KARTI — koşu boyu süren kader  [1-3]", Px.C("c9a227"), cards)

func chest_choice(evos: Array) -> void:
	_pause(true)
	var opts: Array = []
	for e in evos:
		var fd: Dictionary = Weapons.def(str(e.from))
		var td: Dictionary = Weapons.def(str(e.into))
		opts.append({"kind": "evo", "id": e.into, "from": e.from, "name": td.get("name", "?"), "icon": td.get("icon", "icn_rex"), "col": td.get("col", "ffb74d"), "desc": "%s evrimleşiyor" % fd.get("name", "?"), "top": "EVRİM", "w": 1.0})
	opts.append({"kind": "gift", "id": "frag", "name": "PARÇACIK ÖBÜRÜ", "icon": "ico_frag", "col": "c26bff", "desc": "evrimi alma — +120 parçacık", "top": "GEÇ", "w": 1.0})
	_show_cards("chest", "ELİT SANDIĞI", Px.C("ffb74d"), opts)

func _show_cards(kind: String, title: String, tcol: Color, opts: Array) -> void:
	var v := _show_panel(kind, title, tcol)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	for i in opts.size():
		var o: Dictionary = opts[i]
		var col := Px.C(str(o.get("col", "7B1FA2")))
		var card := PanelContainer.new()
		var cs := _style_panel(Color(0.06, 0.03, 0.1, 0.95), col, 2, 4)
		card.add_theme_stylebox_override("panel", cs)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		cv.custom_minimum_size = Vector2(176, 168)
		card.add_child(cv)
		var top := _lbl("[%d] %s" % [i + 1, str(o.get("top", ""))], Vector2.ZERO, 11, col)
		top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(top)
		var icon := TextureRect.new()
		icon.texture = Px.S2(str(o.get("icon", "ico_boon")))
		if icon.texture == null:
			icon.texture = Px.S("ico_boon")
		icon.custom_minimum_size = Vector2(40, 40)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.modulate = col.lerp(Color.WHITE, 0.35)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := CenterContainer.new()
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.add_child(icon)
		cv.add_child(ic)
		var nm := _lbl(str(o.get("name", "?")), Vector2.ZERO, 14, Color.WHITE)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(nm)
		var ds := _lbl(str(o.get("desc", "")), Vector2.ZERO, 11, Color(0.78, 0.78, 0.88))
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(ds)
		row.add_child(card)
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed:
				_pick_card(o))
		card.mouse_entered.connect(func():
			cs.border_color = col.lerp(Color.WHITE, 0.5)
			cs.set_border_width_all(3))
		card.mouse_exited.connect(func():
			cs.border_color = col
			cs.set_border_width_all(2))
	_overlay.set_meta("opts", opts)

func _pick_card(o: Dictionary) -> void:
	if not is_instance_valid(_overlay):
		return
	var kind := str(_overlay.get_meta("kind", ""))
	if kind != "draft" and kind != "chest" and kind != "boon" and kind != "biomesel":
		return
	# KOV akışı: önce KOV kartı seçilir, sonra kovulan kart işaretlenir
	if kind == "draft":
		if str(o.get("kind", "")) == "banish" and not bool(_overlay.get_meta("ban_mode", false)):
			_overlay.set_meta("ban_mode", true)
			toast("kovulacak kartı seç — koşunun geri kalanında çıkmaz")
			return
		if bool(_overlay.get_meta("ban_mode", false)) and str(o.get("kind", "")) == "banish":
			_overlay.set_meta("ban_mode", false)
			toast("kovma iptal — normal seçim")
			return
		if bool(_overlay.get_meta("ban_mode", false)) and str(o.get("kind", "")) in ["wpn", "psv", "boon"]:
			G.run.banished.append(str(o.get("id", "")))
			G.run.draft_banish = false
			var rem: Array = []
			for x in _overlay.get_meta("opts", []):
				if str(x.get("id", "")) != str(o.get("id", "")) and str(x.get("id", "")) != "ban":
					rem.append(x)
			_close_overlay()
			toast("kovalandı: %s" % str(o.get("name", "?")))
			_pause(true)
			_show_cards("draft", "SEVİYE %d — güçlendirme seç  [1-%d]" % [G.player.level, rem.size()], Px.C("00E5FF"), rem)
			return
	_close_overlay()
	if kind == "biomesel":
		var bid := int(o.get("id", 0))
		if bid == -1:
			var hyp := not bool(G.meta.data.get("hyper", false))
			G.meta.data["hyper"] = hyp
			G.meta.save()
			G.ui.toast("aşılama %s — kovan %s" % ["AÇILDI" if hyp else "kapatıldı", "hızlı ve kalabalık akacak" if hyp else "normal akacak"])
		elif bid == -2:
			var drk := not bool(G.meta.data.get("dark", false))
			G.meta.data["dark"] = drk
			G.meta.save()
			G.ui.toast("karanlık %s — %s" % ["AÇILDI" if drk else "kapatıldı", "şifa küresi düşmeyecek" if drk else "şifa küreleri geri döndü"])
		else:
			G.meta.data["arena_biome"] = bid
			G.meta.save()
			G.ui.toast("saha: %s — portal o koordinata açılıyor" % BIOME_NAME[bid])
		G.audio.jingle("boon")
		return
	if str(o.get("kind", "")) == "reroll":
		G.run.draft_reroll = false
		_open_draft()
		return
	if str(o.get("kind", "")) == "evo":
		G.run.apply_evo({"from": o.get("from", ""), "into": o.get("id", "")})
		return
	if str(o.get("kind", "")) == "arcana":
		G.run.arcana = str(o.get("id", ""))
		Boons.apply_arcana(G.run.arcana, G.player)
		var seen: Array = G.meta.data.get("arcanas_seen", [])
		if not seen.has(G.run.arcana):
			seen.append(G.run.arcana)
			G.meta.data["arcanas_seen"] = seen
			G.meta.save()
		G.audio.jingle("boon")
		G.ui.toast("KOZ: %s" % str(o.get("name", "?")))
		return
	Weapons.apply_opt(o, G.player)
	if is_instance_valid(G.player):
		G.fx.burst(G.player.pos + Vector2(0, -24), Px.C(str(o.get("col", "00E5FF"))), 20, 150.0, 4.0, 0.7)
	G.audio.jingle("boon")
	G.ui.toast(str(o.get("name", "?")))

func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	if overlay_open() and str(_overlay.get_meta("kind", "")) in ["boon", "draft", "chest", "biomesel"]:
		var opts: Array = _overlay.get_meta("opts", [])
		var idx := int(ev.keycode) - int(KEY_1)
		if idx >= 0 and idx < opts.size():
			_pick_card(opts[idx])
	elif ev.keycode == KEY_ESCAPE and not overlay_open() and G.state in [G.State.ROOM, G.State.HUB]:
		pause_panel()

# ---------------------------------------------------------------- death / victory

func death_screen(killer: String, gained: int) -> void:
	await get_tree().create_timer(1.1, true, false, true).timeout
	_pause(true)
	var v := _show_panel("death", "D Ü Ş Ü Ş", Px.C("8B0000"))
	var sk := TextureRect.new()
	sk.texture = Px.S2("icn_skull")
	sk.custom_minimum_size = Vector2(44, 44)
	sk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sk.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sk.modulate = Color(1, 0.4, 0.4)
	sk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var skc := CenterContainer.new()
	skc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skc.add_child(sk)
	v.add_child(skc)
	var kl := _lbl("%s tarafından düşürüldün" % killer, Vector2.ZERO, 14, Color(0.85, 0.5, 0.5))
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(kl)
	var gl := _lbl("Choralim saflaştırıldı: ◆ +%d" % gained, Vector2.ZERO, 15, Px.C("c26bff"))
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(gl)
	var tt := int(G.run.time)
	var dl := _lbl("Dayanma: %02d:%02d · Seviye %d · %d kesim · en uzun seri x%d" % [tt / 60, tt % 60, G.player.level if is_instance_valid(G.player) else 1, int(G.run.stats.get("kills", 0)), int(G.run.stats.get("best_streak", 0))], Vector2.ZERO, 12, Color(0.6, 0.6, 0.7))
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dl)
	var sc := int(G.run.stats.get("score", 0))
	var sl := _lbl("skor: %d%s" % [sc, " — YENİ REKOR!" if G.run.stats.get("new_record", false) else ""], Vector2.ZERO, 13, Px.C("c9a227") if G.run.stats.get("new_record", false) else Color(0.65, 0.65, 0.75))
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sl)
	var kname := str(G.meta.data.get("last_death", {}).get("killer", ""))
	if kname != "":
		var kl2 := _lbl("son nefes: %s" % kname, Vector2.ZERO, 12, Px.C("ff5533"))
		kl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(kl2)
	_build_recap(v)
	var h := _lbl("Neva'nın rezonansı seni geri çekiyor...\n[E / tık] — Viator Kampı'na dön", Vector2.ZERO, 12, Color(0.5, 0.7, 0.9))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	G.audio.play_music("mus_hub")

func victory_screen(stats: Dictionary) -> void:
	_pause(true)
	var v := _show_panel("victory", "PROTOKOL TAMAMLANDI", Px.C("00E5FF"))
	var cr := TextureRect.new()
	cr.texture = Px.S2("icn_crown")
	cr.custom_minimum_size = Vector2(44, 44)
	cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crc := CenterContainer.new()
	crc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crc.add_child(cr)
	v.add_child(crc)
	var sub := "Dört mühür kırıldı. Kovan sustu.\nChoralim'in şarkısı artık senin."
	var epilog := {
		"b0": "Endusterra'nın çoraklığı bir süre daha sessiz kalacak.",
		"b1": "Simithar damarları artık kovansız söylüyor.",
		"b2": "Enkazın altında imparatorluk sonunda rahatladı.",
		"b3": "Kule düştü — protokolün kalbi durdu.",
		"yol": "Puslu Geçit artık konakçılara değil, yolculara ait.",
		"tarla": "Yanık tarlalar küllerin altından nefes alıyor.",
		"pazar": "Hurda pazarın taşları kovanın artıklarından arındı.",
		"kuyu": "Derin Kuyu'nun kalbi sustu — ışık aşağı indi.",
		"yuvalar": "Kuluçka ocakları söndü; duvarların nabzı kesildi.",
		"vatika": "Sessiz Vatika arındı — karanlık bile şarkıya katıldı.",
		"mabed": "Kırık mabedin yankısı huzurla doldu.",
		"mezarlik": "Düşmüşler sonunda mezarlarında dinleniyor.",
		"batak": "Bataklık çamuru ilk kez birini geri verdi.",
	}
	var epi := str(epilog.get(str(stats.get("node_id", "")), ""))
	if epi != "":
		sub += "\n\n%s\n%s" % [str(stats.get("node_name", "")), epi]
	var t1 := _lbl(sub, Vector2.ZERO, 14, Color(0.7, 0.95, 1))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t1)
	var vt := int(stats.get("time", 0))
	var t2 := _lbl("Süre %02d:%02d · Seviye %d · %d kesim · en uzun seri x%d\nChoralim saflaştırıldı: ◆ +%d\nToplam zafer: %d\nSkor: %d%s" % [vt / 60, vt % 60, int(stats.get("level", 1)), int(stats.get("kills", 0)), int(stats.get("best_streak", 0)), int(stats.get("gained", 0)), G.meta.data.victories, int(stats.get("score", 0)), " — YENİ REKOR!" if stats.get("new_record", false) else ""], Vector2.ZERO, 12, Color(0.7, 0.7, 0.8))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t2)
	_build_recap(v)
	var h := _lbl("[E / tık] — kampa dön (yeni döngü)", Vector2.ZERO, 12, Color(0.5, 0.7, 0.9))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	# VS endless: banked the payout; the swarm comes back hotter until you fall
	var btn := Button.new()
	btn.text = "∞ SONSUZ — kovana geri dön (ölüm hâlâ öder)"
	btn.custom_minimum_size = Vector2(340, 32)
	btn.add_theme_font_override("font", ui_font())
	var bc := CenterContainer.new()
	bc.add_child(btn)
	v.add_child(bc)
	btn.pressed.connect(func():
		_close_overlay()
		G.run.continue_endless())

func death_reaction() -> void:
	var ld: Dictionary = G.meta.data.last_death
	var pool: Array = []
	# condition-priority reaction matrix — context beats random filler
	if bool(ld.get("boss", false)):
		pool = [
			"RHASA: {killer} seni durdurdu. Telegrafı ezberle — bir dahakine içinden geç.",
			"NEVA: {killer}'in şarkısını duydum. Çok gürültülü. Çok kırık.",
			"VANE: Boss kaydı güncellendi. Kalıp analizi %d%% tamam." % mini(99, 20 + int(G.meta.data.get("deaths", 0)) * 4),
		]
	elif int(ld.get("depth", 0)) <= 0 and int(ld.get("biome", 0)) == 0:
		pool = [
			"SAPHIRE: İlk odada düştün. Kamp ateşine alışkın ol — çok geleceksin.",
			"RHASA: Telegrafları izlemedin. Gözün kılıçta değil, düşmanda olsun.",
		]
	elif str(ld.get("killer", "")).to_lower().contains("zehir") or str(ld.get("killer", "")).to_lower().contains("venom"):
		pool = ["SAPHIRE: Zehir seni eritti. Venti gördün mü demiştim — yeşil parlarsa kaç."]
	elif int(ld.get("biome", 0)) >= 3:
		pool = [
			"NEVA: Aeterna'ya kadar geldin. Oranın soğuğu farklı — sterilden öte, merhametsiz.",
			"VANE: Kovan'ın merkezine yaklaştın. Sistemlerin hâlâ seninle.",
		]
	else:
		pool = DEATH_LINES.duplicate()
	var line: String = G.pick(pool)
	line = line.replace("{killer}", str(ld.get("killer", "kovan")))
	line = line.replace("{depth}", str(ld.get("depth", 0)))
	toast(line)

# ---------------------------------------------------------------- upgrades

func upgrade_panel() -> void:
	_pause(true)
	var v := _show_panel("upgrade", "DR. VANE — SİBERNETİK YÜKSELTME", Px.C("3a7a3a"))
	var money := _lbl("Saf Choralim: ◆ %d" % G.meta.data.choralim, Vector2.ZERO, 14, Px.C("c26bff"))
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(money)
	var grid := VBoxContainer.new()
	grid.add_theme_constant_override("separation", 6)
	v.add_child(grid)
	for key in Meta.UPG:
		var spec: Dictionary = Meta.UPG[key]
		var lvl := G.meta.upg(key)
		var cost := G.meta.upg_cost(key)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		grid.add_child(row)
		var ic := TextureRect.new()
		ic.texture = Px.S2(str(spec.get("icon", "icn_upg_" + Meta._key(key))))
		ic.custom_minimum_size = Vector2(26, 26)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(ic)
		var name_l := _lbl("%s  %s" % [spec.name, "▮".repeat(maxi(0, lvl)) + "▯".repeat(maxi(0, int(spec.max) - lvl))], Vector2.ZERO, 13, Color(0.9, 0.9, 0.95))
		name_l.custom_minimum_size = Vector2(280, 0)
		row.add_child(name_l)
		var ds := _lbl(spec.desc, Vector2.ZERO, 11, Color(0.6, 0.6, 0.7))
		ds.custom_minimum_size = Vector2(160, 0)
		row.add_child(ds)
		var btn := Button.new()
		btn.text = "MAX" if cost < 0 else "◆ %d" % cost
		btn.disabled = cost < 0 or G.meta.data.choralim < cost
		btn.custom_minimum_size = Vector2(90, 26)
		btn.add_theme_font_override("font", ui_font())
		row.add_child(btn)
		btn.pressed.connect(func():
			if G.meta.buy(key):
				G.audio.play("boon", 1.3, 0.6)
				_close_overlay()
				upgrade_panel())
	var h := _lbl("[E / tık dışarısı] kapat", Vector2.ZERO, 10, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# ---------------------------------------------------------------- title

# ---------------------------------------------------------------- Rhasa doctrine (stance)

const STANCES := {
	"cleave": {"name": "YIKICI DOKTRİN", "icon": "icn_stance_cleave", "col": "a8842f",
		"desc": "Geniş kavisler: +%45 saldırı yayı, +12 menzil\n— ama -%8 hasar ve %8 daha yavaş vuruş"},
	"duelist": {"name": "DÜELLOCU DOKTRİNİ", "icon": "icn_stance_duel", "col": "00E5FF",
		"desc": "Tek hedef odağı: +%16 hasar, +%14 vuruş hızı, +0.05sn parry\n— ama -%28 saldırı yayı"},
}

func stance_panel() -> void:
	_pause(true)
	var v := _show_panel("stance", "RHASA — DOKTRİN SEÇİMİ", Px.C("a8842f"))
	var cur := _lbl("Mevcut: %s" % (STANCES[str(G.meta.data.stance)].name if STANCES.has(str(G.meta.data.stance)) else "—"), Vector2.ZERO, 12, Color(0.7, 0.7, 0.8))
	cur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cur)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for key in STANCES:
		var s: Dictionary = STANCES[key]
		var card := PanelContainer.new()
		var cs := _style_panel(Color(0.07, 0.05, 0.03, 0.95), Px.C(s.col), 2, 4)
		card.add_theme_stylebox_override("panel", cs)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		cv.custom_minimum_size = Vector2(210, 150)
		card.add_child(cv)
		var ic := TextureRect.new()
		ic.texture = Px.S2(s.icon)
		ic.custom_minimum_size = Vector2(36, 36)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icc := CenterContainer.new()
		icc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icc.add_child(ic)
		cv.add_child(icc)
		var nm := _lbl(s.name, Vector2.ZERO, 14, Px.C(s.col))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(nm)
		var ds := _lbl(s.desc, Vector2.ZERO, 11, Color(0.78, 0.78, 0.85))
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(ds)
		row.add_child(card)
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed:
				_pick_stance(key))
	var h := _lbl("[E / tık dışarısı] kapat", Vector2.ZERO, 10, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

func _pick_stance(key: String) -> void:
	G.meta.data.stance = key
	G.meta.save()
	G.audio.play("stance", 1.0, 0.8)
	if is_instance_valid(G.player):
		G.player._apply_stance()
	toast("Doktrin: %s" % STANCES[key].name)
	_close_overlay()

# Ely-B's dormant chassis — chassis select is this game's hero-class pick
const HEROES := {
	"ely": {"name": "ELY — ALFA-04", "por": "por_ely", "col": "00E5FF",
		"desc": "Standart şasi. Başlangıç: Enerji Kılıcı. Dengeli gövde — kovanın ilk düşüşünden kalan."},
	"elyb": {"name": "ELY-B", "por": "por_elyb", "col": "9db4c8",
		"desc": "Ağır B-serisi. Başlangıç: Plazma Dizisi. −20 can · +%12 hasar · −%8 hız."},
	"via": {"name": "V-SERKAY", "por": "por_c_viawar", "col": "ffb74d",
		"desc": "Viator keşif kasası. Başlangıç: Fitil Bıçağı. −12 can · +%8 hız · +%8 kritik."},
}

func hero_panel() -> void:
	_pause(true)
	var v := _show_panel("hero", "ELY-B — ŞASİ SEÇİMİ", Px.C("9db4c8"))
	var cur_id := str(G.meta.data.get("hero", "ely"))
	if not HEROES.has(cur_id):
		cur_id = "ely"
	var cur := _lbl("Mevcut şasi: %s" % (HEROES[cur_id] as Dictionary).name, Vector2.ZERO, 12, Color(0.7, 0.7, 0.8))
	cur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cur)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	for key in HEROES:
		var s: Dictionary = HEROES[key]
		var active: bool = key == cur_id
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _style_panel(Color(0.07, 0.06, 0.09, 0.95), Px.C(s.col), 3 if active else 2, 4))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		cv.custom_minimum_size = Vector2(220, 190)
		card.add_child(cv)
		var ic := TextureRect.new()
		ic.texture = Px.S2(s.por)
		ic.custom_minimum_size = Vector2(64, 64)
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icc := CenterContainer.new()
		icc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icc.add_child(ic)
		cv.add_child(icc)
		var nm := _lbl(("%s\n✓ AKTİF" % s.name) if active else s.name, Vector2.ZERO, 13, Px.C(s.col))
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(nm)
		var ds := _lbl(s.desc, Vector2.ZERO, 11, Color(0.78, 0.78, 0.85))
		ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ds.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(ds)
		row.add_child(card)
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and not active:
				_pick_hero(key))
	var h := _lbl("[E / tık dışarısı] kapat", Vector2.ZERO, 10, Color(0.4, 0.4, 0.5))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

func _pick_hero(key: String) -> void:
	G.meta.data["hero"] = key
	G.meta.save()
	G.audio.play("boon", 1.1, 0.6)
	toast("Şasi: %s" % HEROES[key].name)
	_close_overlay()
	hero_panel()

# ---------------------------------------------------------------- pause / settings

func _apply_settings() -> void:
	var st: Dictionary = G.meta.data.get("settings", {})
	if is_instance_valid(_crt):
		_crt.visible = bool(st.get("crt", true))

func pause_panel() -> void:
	_pause(true)
	var v := _show_panel("pause", "DURAKLATILDI", Color(0.6, 0.6, 0.75))
	var st: Dictionary = G.meta.data.settings
	for opt in [["shake", "Ekran sarsıntısı"], ["crt", "CRT taraması"], ["mus", "Müzik"], ["sfx", "Efekt sesi"]]:
		var key: String = opt[0]
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		v.add_child(row)
		row.add_child(_lbl(opt[1], Vector2.ZERO, 13, Color(0.85, 0.85, 0.92)))
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 26)
		btn.add_theme_font_override("font", ui_font())
		var is_slider: bool = key in ["mus", "sfx"]
		if is_slider:
			btn.text = "%d%%" % roundi(float(st.get(key, 1.0)) * 100)
		else:
			btn.text = "AÇIK" if bool(st.get(key, true)) else "KAPALI"
		row.add_child(btn)
		btn.pressed.connect(func():
			if is_slider:
				st[key] = wrapf(float(st.get(key, 1.0)) - 0.25, 0.0, 1.26)
				btn.text = "%d%%" % roundi(float(st[key]) * 100)
			else:
				st[key] = not bool(st.get(key, true))
				btn.text = "AÇIK" if bool(st[key]) else "KAPALI"
			G.meta.save()
			_apply_settings()
			# live-apply music volume
			if key == "mus" and is_instance_valid(G.audio.music):
				G.audio.music.volume_db = linear_to_db(clampf(0.4 * float(st.mus), 0.001, 1.0))
			G.audio.play("ui", 1.2, 0.5))
	if G.state == G.State.ROOM:
		var p := G.player
		if is_instance_valid(p):
			var stl := _lbl("hasar ×%0.2f · hız %0.2f · krit %%%d·×%0.1f · zırh %d · çalma %%%d · KOZ: %s" % [p.dmg_mult, p.speed / 205.0, roundi(p.crit_ch * 100), p.crit_mult, roundi(p.armor), roundi(p.lifesteal * 100), str(Boons.ARCANAS.get(G.run.arcana, {}).get("name", "—"))], Vector2.ZERO, 11, Color(0.55, 0.65, 0.8))
			stl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(stl)
		_build_recap(v)
		var qb := Button.new()
		qb.text = "KAMPA DÖN (koşuyu bırak)"
		qb.custom_minimum_size = Vector2(260, 28)
		qb.add_theme_font_override("font", ui_font())
		v.add_child(qb)
		qb.pressed.connect(func():
			_close_overlay()
			G.run.abandon_to_hub())
	var h := _lbl("[ESC / E / tık] devam et", Vector2.ZERO, 11, Color(0.5, 0.5, 0.62))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

# ---------------------------------------------------------------- title

func title_screen() -> void:
	_pause(true)
	_overlay = Control.new()
	_overlay.set_meta("kind", "title")
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := TextureRect.new()
	bg.texture = Px.S2("title_bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(v)
	var t := _lbl("D Ü Ş Ü Ş", Vector2.ZERO, 46, Px.C("c26bff"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st := _lbl("— CHORALIM PROTOCOL —", Vector2.ZERO, 15, Px.C("00E5FF"))
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	var sub := _lbl("Sürü-hayatta kalma roguelite.\nKampa uyan, kapıdan geç, kovana dayan. Tekrar uyan.", Vector2.ZERO, 12, Color(0.8, 0.78, 0.88))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(_lbl("WASD hareket · SPACE dash · E etkileşim — silahlar otomatik ateş eder, sen hayatta kal", Vector2.ZERO, 11, Color(0.55, 0.55, 0.65)))
	var btn := Button.new()
	btn.text = "VIATOR'A UYAN"
	btn.custom_minimum_size = Vector2(220, 40)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_font_override("font", ui_font())
	var bc := CenterContainer.new()
	bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bc.add_child(btn)
	v.add_child(bc)
	btn.pressed.connect(func():
		_close_overlay()
		G.run.hub())
	root.add_child(_overlay)

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		return
