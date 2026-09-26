class_name Ui
extends CanvasLayer

# All UI is built in code: HUD, boss bar, banners, toasts, dialogue panel,
# boon draft, upgrade shop (Dr. Vane), death/victory screens, title, CRT tint.

const BIOME_NAME := ["ENDUSTERRA BARRENS", "SIMITHAR MINE — 4-GAMMA", "SOL PRIMUS WRECKAGE", "AETERNA SPIRE"]

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
var _overlay: Control = null     # current modal overlay (dialogue/boon/death/etc)
var _crt: TextureRect
var _vign: TextureRect
var _xp_back: ColorRect
var _xp_bar: ColorRect
var _lvl_lbl: Label
var _time_lbl: Label
var _kills_lbl: Label
var _wpn_row: HBoxContainer
var _psv_row: HBoxContainer
var _gear_sig := ""
var _pulse := 0.0

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

func _process(d: float) -> void:
	_pulse += d
	_tick_hud()
	_tick_banner(d)
	_tick_boss_bar()
	_toast_keys()

func _tick_hud() -> void:
	if G.player == null or not is_instance_valid(G.player) or G.run == null:
		return
	var p := G.player
	_hp_bar.size.x = 256 * clampf(p.hp / p.max_hp, 0.0, 1.0)
	_hp_hi.size.x = _hp_bar.size.x
	_hp_txt.text = "%d / %d" % [maxi(0, ceili(p.hp)), ceili(p.max_hp)]
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
	_time_lbl.text = "%02d:%02d" % [tt / 60, tt % 60]
	_kills_lbl.text = "%d kesim" % int(G.run.stats.get("kills", 0))
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
		_room_lbl.text = BIOME_NAME[clampi(G.run.biome, 0, 3)]
	elif G.state == G.State.HUB:
		_room_lbl.text = "VIATOR KAMPI"
	else:
		_room_lbl.text = ""

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
	var kind: String = _overlay.get_meta("kind", "")
	match kind:
		"dialogue":
			var nid: String = _overlay.get_meta("nid")
			if nid == "vane":
				_close_overlay()
				upgrade_panel()
			elif nid == "rhasa":
				_close_overlay()
				stance_panel()
			elif nid == "david":
				_close_overlay()
				biome_panel()
			elif nid == "zirkon":
				_close_overlay()
				records_panel()
			elif nid == "ehnar":
				_close_overlay()
				contract_panel()
			else:
				_close_overlay()
		"death":
			_close_overlay()
			G.run.respawn_to_hub()
		"victory":
			_close_overlay()
			G.run.respawn_to_hub()
		"upgrade", "stance", "pause", "records", "biomesel", "contract":
			_close_overlay()
		"cine":
			var c := _overlay
			var tw := create_tween()
			tw.tween_property(c, "modulate:a", 0.0, 0.3)
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
	_show_cards("biomesel", "SAHA SEÇİMİ — David'in izleri  [1-4]", Px.C("00E5FF"), opts)

func _biome_desc(b: int) -> String:
	return ["Proterian çoraklığı — Alfa-05'in izi.",
			"Simithar damarları — kovanın kökleri.",
			"İmparatorluk enkazı — çürüyen taht.",
			"Protokolün kalbi — son masa."][b]

# Vezir: the camp's living ledger — lifetime stats + boss dossiers.
func records_panel() -> void:
	_pause(true)
	var v := _show_panel("records", "KAMP KAYITLARI — Vezir Zirkon", Px.C("c9a227"))
	var d := G.meta.data
	var rows := [
		"koşu: %d   zafer: %d   düşüş: %d" % [int(d.get("runs", 0)), int(d.get("victories", 0)), int(d.get("deaths", 0))],
		"toplam kesim: %d   ·   en derin: %d" % [int(d.get("kills", 0)), int(d.get("best_depth", 0))],
		"choralim rezervi: ◆ %d" % int(d.get("choralim", 0)),
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
	_open_draft()

func _open_draft() -> void:
	var opts := Weapons.draft_opts(G.player, G.run.luck)
	if opts.is_empty():
		return
	_pause(true)
	var all := opts.duplicate()
	if G.run.draft_reroll:
		all.append({"kind": "reroll", "id": "rr", "name": "YENİLE", "icon": "icn_dash", "col": "00E5FF", "desc": "kartları yeniden dağıt — taslak başına bir kez", "top": "ŞANS", "w": 1.0})
	all.append({"kind": "gift", "id": "skip", "name": "GEÇ", "icon": "ico_frag", "col": "9aa0b0", "desc": "+15 parçacık — hiçbirini alma", "top": "SEÇME", "w": 1.0})
	_show_cards("draft", "SEVİYE %d — güçlendirme seç  [1-%d]" % [G.player.level, all.size()], Px.C("00E5FF"), all)

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
	_close_overlay()
	if kind == "biomesel":
		G.meta.data["arena_biome"] = int(o.get("id", 0))
		G.meta.save()
		G.ui.toast("saha: %s — portal o koordinata açılıyor" % BIOME_NAME[int(o.get("id", 0))])
		G.audio.jingle("boon")
		return
	if str(o.get("kind", "")) == "reroll":
		G.run.draft_reroll = false
		_open_draft()
		return
	if str(o.get("kind", "")) == "evo":
		G.run.apply_evo({"from": o.get("from", ""), "into": o.get("id", "")})
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
	var dl := _lbl("Dayanma: %02d:%02d · Seviye %d · %d kesim" % [tt / 60, tt % 60, G.player.level if is_instance_valid(G.player) else 1, int(G.run.stats.get("kills", 0))], Vector2.ZERO, 12, Color(0.6, 0.6, 0.7))
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(dl)
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
	var t1 := _lbl("Dört mühür kırıldı. Kovan sustu.\nChoralim'in şarkısı artık senin.", Vector2.ZERO, 14, Color(0.7, 0.95, 1))
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t1)
	var vt := int(stats.get("time", 0))
	var t2 := _lbl("Süre %02d:%02d · Seviye %d · %d kesim\nChoralim saflaştırıldı: ◆ +%d\nToplam zafer: %d" % [vt / 60, vt % 60, int(stats.get("level", 1)), int(stats.get("kills", 0)), int(stats.get("gained", 0)), G.meta.data.victories], Vector2.ZERO, 12, Color(0.7, 0.7, 0.8))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t2)
	var h := _lbl("[E / tık] — kampa dön (yeni döngü)", Vector2.ZERO, 12, Color(0.5, 0.7, 0.9))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)

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
		ic.texture = Px.S2("icn_upg_" + Meta._key(key))
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
