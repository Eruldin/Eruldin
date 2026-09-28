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
	"npc2_tegan": "art/gen/g_tegan_0.png", "npcb_tegan": "art/gen/g_tegan_1.png",
	"por_tegan": "art/por_tegan.png",
	"por_k7": "art/por_k7.png",
	"por_anasi": "art/por/por_anasi.png",
	"por_dev": "art/por_dev.png",
	"por_kor": "art/por_kor.png",
	"por_damar": "art/por_damar.png",
	"por_buz": "art/por/por_buz.png",
	"por_h9": "art/por_h9.png",
	"prop_mahkum2": "art/prop_mahkum2.png",
	"npc2_orun": "art/gen/g_orun_0.png", "npcb_orun": "art/gen/g_orun_1.png",
	"por_orun": "art/por_orun.png",
	"prop_mahkum3": "art/prop_mahkum3.png",
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
	"gr_7": "art/gen/g_gr_7.png",
	"gr_8": "art/gen/g_gr_8.png",
	"gr_hub": "art/gen/g_gr_hub.png",
	# boyanmis sinematik kartlar (metinsiz temiz vistalar — art/cine/)
	# tum cine_<biome>_<v> varyantlari biome'un boyanmis vistasina bakar;
	# intro kartlari cine_i0..i2 (kovan / kapi / Alfa-04)
	"cine_0_0": "art/cine/cine_0.png", "cine_0_1": "art/cine/cine_0.png",
	"cine_0_2": "art/cine/cine_0.png", "cine_0_3": "art/cine/cine_0.png",
	"cine_1_0": "art/cine/cine_1.png", "cine_1_1": "art/cine/cine_1.png",
	"cine_1_2": "art/cine/cine_1.png", "cine_1_3": "art/cine/cine_1.png",
	"cine_2_0": "art/cine/cine_2.png", "cine_2_1": "art/cine/cine_2.png",
	"cine_2_2": "art/cine/cine_2.png", "cine_2_3": "art/cine/cine_2.png",
	"cine_3_0": "art/cine/cine_3.png", "cine_3_1": "art/cine/cine_3.png",
	"cine_3_2": "art/cine/cine_3.png", "cine_3_3": "art/cine/cine_3.png",
	"cine_4_0": "art/cine/cine_4.png",
	"cine_5_0": "art/cine/cine_5.png",
	"cine_6_0": "art/cine/cine_6.png",
	"cine_7_0": "art/cine/cine_7.png",
	"cine_8_0": "art/cine/cine_8.png",
	"cine_hazine": "art/cine/cine_hazine.png",
	"cine_i0": "art/cine/cine_i0.png", "cine_i1": "art/cine/cine_i1.png",
	"cine_i2": "art/cine/cine_i2.png",
	"por_nur": "art/por/por_nur.png",
	# birlesik portre seti (boyalı strip'lerden dilimlendi, ortak tema)
	"por_neva": "art/por/por_neva.png", "por_david": "art/por/por_david.png",
	"por_rhasa": "art/por/por_rhasa.png", "por_saphire": "art/por/por_saphire.png",
	"por_vane": "art/por/por_vane.png", "por_zirkon": "art/por/por_zirkon.png",
	"por_ehnar": "art/por/por_ehnar.png", "por_ahusk": "art/por/por_ahusk.png",
	"por_elyb": "art/por/por_elyb.png", "por_viawar": "art/por/por_viawar.png",
	"por_rex": "art/por/por_rex.png", "por_host": "art/por/por_host.png",
	"por_nahum": "art/por/por_nahum.png", "por_kirin": "art/por/por_kirin.png",
	"por_tuman": "art/por/por_tuman.png", "por_const": "art/por/por_const.png",
	"por_ely": "art/por/por_ely.png",
	"por_c_ely": "art/por/por_ely.png", "por_c_elyb": "art/por/por_elyb.png",
	"por_c_viawar": "art/por/por_viawar.png",
	# birlesik ikon seti (obsidian amblem + teal-mor parıltı)
	"icn_sword": "art/icn/icn_sword.png", "icn_dagger": "art/icn/icn_dagger.png",
	"icn_zap": "art/icn/icn_zap.png", "icn_skull": "art/icn/icn_skull.png",
	"icn_crown": "art/icn/icn_crown.png", "icn_dash": "art/icn/icn_dash.png",
	"icn_kovan": "art/icn/icn_kovan.png", "icn_mine": "art/icn/icn_mine.png",
	"icn_stance_cleave": "art/icn/icn_stance_cleave.png", "icn_stance_duel": "art/icn/icn_stance_duel.png",
	"icn_upg_dash": "art/icn/icn_upg_dash.png", "icn_upg_dmg": "art/icn/icn_upg_dmg.png",
	"icn_upg_frag": "art/icn/icn_upg_frag.png", "icn_upg_hp": "art/icn/icn_upg_hp.png",
	"icn_upg_mag": "art/icn/icn_upg_mag.png", "icn_upg_shield": "art/icn/icn_upg_shield.png",
	"icn_upg_revive": "art/icn/icn_upg_revive.png",
	"icn_neva": "art/icn/icn_neva.png", "icn_rex": "art/icn/icn_rex.png",
	"icn_rhasa": "art/icn/icn_rhasa.png", "icn_saphire": "art/icn/icn_saphire.png",
	"ico_boon": "art/icn/ico_boon.png", "ico_boss": "art/icn/ico_boss.png",
	"ico_camp": "art/icn/ico_camp.png", "ico_elite": "art/icn/ico_elite.png",
	"ico_exit": "art/icn/ico_exit.png", "ico_frag": "art/icn/ico_frag.png",
	"ico_heal": "art/icn/ico_heal.png", "ico_loot": "art/icn/ico_loot.png",
	"ico_map": "art/icn/ico_map.png", "ico_quest": "art/icn/ico_quest.png",
	"ico_run": "art/icn/ico_run.png",
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
	# Donmuş Çatlak: buz sarkıtı / donmuş monolit / aurora kristali / kar yığını / kaburga / rün totemi
	"prop_8_0": "art/gen/g_prop_8__0.png", "prop_8_1": "art/gen/g_prop_8__1.png",
	"prop_8_2": "art/gen/g_prop_8__2.png", "prop_8_3": "art/gen/g_prop_8__3.png",
	"prop_8_4": "art/gen/g_prop_8__4.png", "prop_8_5": "art/gen/g_prop_8__5.png",
	# efekt kareleri (renkleri pikselde — modulate beyaz kullan)
	"fx_boom": "art/gen/g_fx_0.png", "fx_zap": "art/gen/g_fx_1.png",
	"fx_slash": "art/gen/g_fx_2.png", "fx_heal": "art/gen/g_fx_3.png",
	"fx_void": "art/gen/g_fx_4.png", "fx_shine": "art/gen/g_fx_5.png",
	# Kenney particle pack (CC0) — tintable real smoke/flame/spark sprites
	"fx_smoke_0": "art/fx_smoke_03.png", "fx_smoke_1": "art/fx_smoke_07.png", "fx_smoke_2": "art/fx_smoke_10.png",
	"fx_flame_0": "art/fx_flame_01.png", "fx_flame_1": "art/fx_flame_05.png",
	"fx_spark_0": "art/fx_spark_01.png", "fx_spark_1": "art/fx_spark_05.png", "fx_spark_2": "art/fx_spark_07.png",
	"fx_star": "art/fx_star.png", "fx_magic": "art/fx_magic.png",
	"fx_trace_0": "art/fx_trace1.png", "fx_trace_1": "art/fx_trace2.png",
	"fx_twirl": "art/fx_twirl.png", "fx_muzzle": "art/fx_muzzle.png", "fx_dirt": "art/fx_dirt.png",
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
	"c_k7": {},
	"c_dg": {},
	"husk": {}, "sentinel": {}, "spitter": {}, "turret": {}, "drone": {},
	"c_varl": {}, "c_cereb": {}, "c_konakci": {}, "c_alfa": {}, "c_carrier": {}, "c_herald": {}, "c_akrep": {}, "c_balcik": {}, "c_gozetmen": {}, "c_copcu": {}, "c_dinamitci": {}, "c_kuzgun": {}, "c_sivri": {}, "c_koc": {}, "c_gol": {}, "c_fisilti": {}, "c_pence": {}, "c_tayf": {}, "c_emici": {}, "c_dol": {},
	"rex": {}, "host": {}, "nahum": {}, "tuman": {}, "kirin": {}, "const": {},
	"anasi": {}, "dev": {}, "kor": {}, "damar": {}, "buz": {}, "nur": {},
}

static func frames() -> Dictionary:
	var d := FRAMES.duplicate()
	for k in ["husk", "sentinel", "spitter", "turret", "drone"]:
		d[k] = _en("g_" + k)
	for k in ["c_varl", "c_cereb", "c_konakci", "c_alfa", "c_herald", "c_akrep", "c_balcik", "c_gozetmen", "c_copcu", "c_dinamitci", "c_kuzgun", "c_sivri", "c_koc", "c_gol", "c_fisilti", "c_pence", "c_tayf", "c_emici", "c_dol"]:
		d[k] = _en("g_" + k.trim_prefix("c_"))
	d["c_carrier"] = _en("g_carrier")
	for k in ["rex", "host", "nahum", "tuman", "kirin", "const", "anasi", "dev", "kor", "damar", "buz", "nur"]:
		d[k] = _bs("g_" + k)
	d["c_h9"] = _hero("g_h9")
	d["c_k7"] = _hero("g_k7")
	d["c_dg"] = _hero("g_dg")
	return d
