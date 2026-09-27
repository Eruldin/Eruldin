extends RefCounted
# AI-uretilmis pixel-art setleri (tools/pix_proc.gd ile dilimlendi).
# _ext_manifest icinde en son birlesir = en yuksek oncelik.
#
# Poz haritasi:
#   kahraman sheet (8): 0 idleA 1 idleB 2 runA 3 runB 4 slash 5 thrust 6 dash 7 die
#   dusman sheet  (6): 0 idleA 1 idleB 2 windup 3 strike 4 hurt 5 die
#   boss sheet    (4): 0 idle 1 windup 2 strike 3 die
#   npc sheet     (4): npca = rhasa neva saphire vane | npcb = david zirkon ehnar ahusk
const SPRITES := {
	"npc2_rhasa": "art/gen/g_npca_0.png", "npcb_rhasa": "art/gen/g_npca_0.png",
	"npc2_neva": "art/gen/g_npca_1.png", "npcb_neva": "art/gen/g_npca_1.png",
	"npc2_saphire": "art/gen/g_npca_2.png", "npcb_saphire": "art/gen/g_npca_2.png",
	"npc2_vane": "art/gen/g_npca_3.png", "npcb_vane": "art/gen/g_npca_3.png",
	"npc2_david": "art/gen/g_npcb_0.png", "npcb_david": "art/gen/g_npcb_0.png",
	"npc2_zirkon": "art/gen/g_npcb_1.png", "npcb_zirkon": "art/gen/g_npcb_1.png",
	"npc2_ehnar": "art/gen/g_npcb_2.png", "npcb_ehnar": "art/gen/g_npcb_2.png",
	"npc2_ahusk": "art/gen/g_npcb_3.png", "npcb_ahusk": "art/gen/g_npcb_3.png",
	"npc2_elyb": "art/gen/g_elyb_0.png", "npcb_elyb": "art/gen/g_elyb_1.png",
	"npc2_mina": "art/c_mina_idle_0.png", "npcb_mina": "art/c_mina_idle_1.png",
	"por_mina": "art/por_mina.png",
	"prop_mahkum": "art/prop_mahkum.png",
	"npc2_lena": "art/c_lena_idle_0.png", "npcb_lena": "art/c_lena_idle_1.png",
	"por_lena": "art/por_lena.png",
	"por_anasi": "art/por_anasi.png",
	"por_dev": "art/por_dev.png",
	"por_kor": "art/por_kor.png",
	"por_h9": "art/por_h9.png",
	"prop_mahkum2": "art/prop_mahkum2.png",
	# sahne vistalari (uretilmis): backdrop katmanlari + arena ufku
	"bg_0": "art/gen/g_bg_0.png", "bg_1": "art/gen/g_bg_1.png",
	"bg_2": "art/gen/g_bg_2.png", "bg_3": "art/gen/g_bg_3.png",
	"bg_hub": "art/gen/g_bg_hub.png",
	"bg_wmap": "art/gen/g_wmap.png",
	"cbv_0_0": "art/gen/g_bg_0.png", "cbg_0_0": "art/gen/g_bg_0.png",
	"cbv_1_0": "art/gen/g_bg_1.png", "cbg_1_0": "art/gen/g_bg_1.png",
	"cbv_2_0": "art/gen/g_bg_2.png", "cbg_2_0": "art/gen/g_bg_2.png",
	"cbv_3_0": "art/gen/g_bg_3.png", "cbg_3_0": "art/gen/g_bg_3.png",
	"cbv_hub": "art/gen/g_bg_hub.png", "cbg_hub": "art/gen/g_bg_hub.png",
	# boyanmis zemin resimleri (BG2 tarzi tam-sahne zemin)
	"gr_0": "art/gen/g_gr_0.png", "gr_1": "art/gen/g_gr_1.png",
	"gr_2": "art/gen/g_gr_2.png", "gr_3": "art/gen/g_gr_3.png",
	"gr_4": "art/gen/g_gr_4.png",
	"gr_5": "art/gen/g_gr_5.png",
	"gr_6": "art/gen/g_gr_6.png",
	"gr_hub": "art/gen/g_gr_hub.png",
	# Kızıl Çöl (biome 6): sinematik kart olarak da zemin resmi kullanılır
	"cine_6_0": "art/gen/g_gr_6.png",
	# Çürük Bataklık (biome 4): sinematik kart olarak da zemin resmi kullanılır
	"cine_4_0": "art/gen/g_gr_4.png",
	# Kül Ovası (biome 5): sinematik kart olarak da zemin resmi kullanılır
	"cine_5_0": "art/gen/g_gr_5.png",
	# biome prop'lari: prop_<biome>_<i> (0..5), hub icin prop_hub_<i>
	"prop_0_0": "art/gen/g_prop_0__0.png", "prop_0_1": "art/gen/g_prop_0__1.png",
	"prop_0_2": "art/gen/g_prop_0__2.png", "prop_0_3": "art/gen/g_prop_0__3.png",
	"prop_0_4": "art/gen/g_prop_0__4.png", "prop_0_5": "art/gen/g_prop_0__5.png",
	"prop_1_0": "art/gen/g_prop_1__0.png", "prop_1_1": "art/gen/g_prop_1__1.png",
	"prop_1_2": "art/gen/g_prop_1__2.png", "prop_1_3": "art/gen/g_prop_1__3.png",
	"prop_1_4": "art/gen/g_prop_1__4.png", "prop_1_5": "art/gen/g_prop_1__5.png",
	"prop_2_0": "art/gen/g_prop_2__0.png", "prop_2_1": "art/gen/g_prop_2__1.png",
	"prop_2_2": "art/gen/g_prop_2__2.png", "prop_2_3": "art/gen/g_prop_2__3.png",
	"prop_2_4": "art/gen/g_prop_2__4.png", "prop_2_5": "art/gen/g_prop_2__5.png",
	"prop_3_0": "art/gen/g_prop_3__0.png", "prop_3_1": "art/gen/g_prop_3__1.png",
	"prop_3_2": "art/gen/g_prop_3__2.png", "prop_3_3": "art/gen/g_prop_3__3.png",
	"prop_3_4": "art/gen/g_prop_3__4.png", "prop_3_5": "art/gen/g_prop_3__5.png",
	"prop_hub_0": "art/gen/g_prop_hub__0.png", "prop_hub_1": "art/gen/g_prop_hub__1.png",
	"prop_hub_2": "art/gen/g_prop_hub__2.png", "prop_hub_3": "art/gen/g_prop_hub__3.png",
	"prop_hub_4": "art/gen/g_prop_hub__4.png", "prop_hub_5": "art/gen/g_prop_hub__5.png",
	"prop_5_0": "art/gen/g_prop_5__0.png", "prop_5_1": "art/gen/g_prop_5__1.png",
	"prop_5_2": "art/gen/g_prop_5__2.png", "prop_5_3": "art/gen/g_prop_5__3.png",
	"prop_5_4": "art/gen/g_prop_5__4.png", "prop_5_5": "art/gen/g_prop_5__5.png",
	"prop_6_0": "art/gen/g_prop_6__0.png", "prop_6_1": "art/gen/g_prop_6__1.png",
	"prop_6_2": "art/gen/g_prop_6__2.png", "prop_6_3": "art/gen/g_prop_6__3.png",
	"prop_6_4": "art/gen/g_prop_6__4.png", "prop_6_5": "art/gen/g_prop_6__5.png",
	# efekt kareleri (renkleri pikselde — modulate beyaz kullan)
	"fx_boom": "art/gen/g_fx_0.png", "fx_zap": "art/gen/g_fx_1.png",
	"fx_slash": "art/gen/g_fx_2.png", "fx_heal": "art/gen/g_fx_3.png",
	"fx_void": "art/gen/g_fx_4.png", "fx_shine": "art/gen/g_fx_5.png",
}

static func _hero(prefix: String) -> Dictionary:
	return {
		"idle": ["art/gen/%s_0.png" % prefix, "art/gen/%s_1.png" % prefix],
		"run": ["art/gen/%s_2.png" % prefix, "art/gen/%s_3.png" % prefix],
		"atk1": ["art/gen/%s_4.png" % prefix],
		"atk2": ["art/gen/%s_5.png" % prefix],
		"atk3": ["art/gen/%s_4.png" % prefix],
		"dash": ["art/gen/%s_6.png" % prefix],
		"parry": ["art/gen/%s_0.png" % prefix],
		"charge": ["art/gen/%s_5.png" % prefix],
		"hurt": ["art/gen/%s_7.png" % prefix],
		"die": ["art/gen/%s_7.png" % prefix],
	}

static func _en(prefix: String) -> Dictionary:
	return {
		"idle": ["art/gen/%s_0.png" % prefix, "art/gen/%s_1.png" % prefix],
		"windup": ["art/gen/%s_2.png" % prefix],
		"strike": ["art/gen/%s_3.png" % prefix],
		"atk": ["art/gen/%s_3.png" % prefix],
		"hurt": ["art/gen/%s_4.png" % prefix],
		"die": ["art/gen/%s_5.png" % prefix],
	}

static func _bs(prefix: String) -> Dictionary:
	return {
		"idle": ["art/gen/%s_0.png" % prefix],
		"windup": ["art/gen/%s_1.png" % prefix],
		"strike": ["art/gen/%s_2.png" % prefix],
		"atk": ["art/gen/%s_2.png" % prefix],
		"p2": ["art/gen/%s_1.png" % prefix],
		"hurt": ["art/gen/%s_0.png" % prefix],
		"die": ["art/gen/%s_3.png" % prefix],
	}

const FRAMES := {
	"ely": {
		"idle": ["art/gen/g_ely_0.png", "art/gen/g_ely_1.png"],
		"run": ["art/gen/g_ely_2.png", "art/gen/g_ely_3.png"],
		"atk1": ["art/gen/g_ely_4.png"],
		"atk2": ["art/gen/g_ely_5.png"],
		"atk3": ["art/gen/g_ely_4.png"],
		"dash": ["art/gen/g_ely_6.png"],
		"parry": ["art/gen/g_ely_0.png"],
		"charge": ["art/gen/g_ely_5.png"],
		"hurt": ["art/gen/g_ely_7.png"],
		"die": ["art/gen/g_ely_7.png"],
	},
	"c_elyb": {
		"idle": ["art/gen/g_elyb_0.png", "art/gen/g_elyb_1.png"],
		"run": ["art/gen/g_elyb_2.png", "art/gen/g_elyb_3.png"],
		"atk1": ["art/gen/g_elyb_4.png"],
		"atk2": ["art/gen/g_elyb_5.png"],
		"atk3": ["art/gen/g_elyb_4.png"],
		"dash": ["art/gen/g_elyb_6.png"],
		"parry": ["art/gen/g_elyb_0.png"],
		"charge": ["art/gen/g_elyb_5.png"],
		"hurt": ["art/gen/g_elyb_7.png"],
		"die": ["art/gen/g_elyb_7.png"],
	},
	"c_viawar": {
		"idle": ["art/gen/g_viawar_0.png", "art/gen/g_viawar_1.png"],
		"run": ["art/gen/g_viawar_2.png", "art/gen/g_viawar_3.png"],
		"atk1": ["art/gen/g_viawar_4.png"],
		"atk2": ["art/gen/g_viawar_5.png"],
		"atk3": ["art/gen/g_viawar_4.png"],
		"dash": ["art/gen/g_viawar_6.png"],
		"parry": ["art/gen/g_viawar_0.png"],
		"charge": ["art/gen/g_viawar_5.png"],
		"hurt": ["art/gen/g_viawar_7.png"],
		"die": ["art/gen/g_viawar_7.png"],
	},
	"c_h9": {},
	"husk": {}, "sentinel": {}, "spitter": {}, "turret": {}, "drone": {},
	"c_varl": {}, "c_cereb": {}, "c_konakci": {}, "c_alfa": {}, "c_carrier": {}, "c_herald": {}, "c_akrep": {}, "c_balcik": {}, "c_gozetmen": {}, "c_copcu": {}, "c_dinamitci": {},
	"rex": {}, "host": {}, "nahum": {}, "tuman": {}, "kirin": {}, "const": {},
	"anasi": {}, "dev": {}, "kor": {},
}

static func frames() -> Dictionary:
	var d := FRAMES.duplicate()
	for k in ["husk", "sentinel", "spitter", "turret", "drone"]:
		d[k] = _en("g_" + k)
	for k in ["c_varl", "c_cereb", "c_konakci", "c_alfa", "c_herald", "c_akrep", "c_balcik", "c_gozetmen", "c_copcu", "c_dinamitci"]:
		d[k] = _en("g_" + k.trim_prefix("c_"))
	d["c_carrier"] = _en("g_carrier")
	for k in ["rex", "host", "nahum", "tuman", "kirin", "const", "anasi", "dev", "kor"]:
		d[k] = _bs("g_" + k)
	d["c_h9"] = _hero("g_h9")
	return d
