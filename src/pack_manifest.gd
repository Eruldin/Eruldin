class_name PackManifest
extends RefCounted

# gercek paket asset'leri — tools/build_pack_assets.py uretir

const SPRITES := {
	"cr_4": "art/pack/cr_4_0.png",
	"fx_boom": "art/pack/fx_boom.png",
	"fx_die": "art/pack/fx_die.png",
	"gr_0": "art/pack/gr_0.png",
	"gr_1": "art/pack/gr_1.png",
	"gr_2": "art/pack/gr_2.png",
	"gr_3": "art/pack/gr_3.png",
	"gr_4": "art/pack/gr_4.png",
	"gr_5": "art/pack/gr_5.png",
	"gr_6": "art/pack/gr_6.png",
	"gr_7": "art/pack/gr_7.png",
	"gr_8": "art/pack/gr_8.png",
	"hz_pool": "art/pack/hz_pool.png",
	"pk_pa_barrel": "art/pack/pk_pa_barrel.png",
	"pk_pa_barrel2": "art/pack/pk_pa_barrel2.png",
	"pk_pa_bench": "art/pack/pk_pa_bench.png",
	"pk_pa_bench2": "art/pack/pk_pa_bench2.png",
	"pk_pa_tires": "art/pack/pk_pa_tires.png",
	"pk_pa_tires2": "art/pack/pk_pa_tires2.png",
	"pk_ss_0": "art/pack/pk_ss_0.png",
	"pk_ss_1": "art/pack/pk_ss_1.png",
	"pk_ss_2": "art/pack/pk_ss_2.png",
	"pk_wc_antenna": "art/pack/pk_wc_antenna.png",
	"pk_wc_arrow": "art/pack/pk_wc_arrow.png",
	"pk_wc_banner": "art/pack/pk_wc_banner.png",
	"pk_wc_neon": "art/pack/pk_wc_neon.png",
	"pk_wt_0": "art/pack/pk_wt_0.png",
	"pk_wt_1": "art/pack/pk_wt_1.png",
	"pk_wt_2": "art/pack/pk_wt_2.png",
	"pk_wt_3": "art/pack/pk_wt_3.png",
	"w2_4": "art/pack/w2_4.png",
	"w2_5": "art/pack/w2_5.png",
	"w2_6": "art/pack/w2_6.png",
	"w2_7": "art/pack/w2_7.png",
	"w2_8": "art/pack/w2_8.png",
}

const FRAMES := {
	"atesruh_5": {
		"idle": ["art/pack/en_atesruh_5_idle_0.png", "art/pack/en_atesruh_5_idle_1.png", "art/pack/en_atesruh_5_idle_2.png", "art/pack/en_atesruh_5_idle_3.png", "art/pack/en_atesruh_5_idle_4.png", "art/pack/en_atesruh_5_idle_5.png"],
		"windup": ["art/pack/en_atesruh_5_windup_0.png", "art/pack/en_atesruh_5_windup_1.png"],
		"strike": ["art/pack/en_atesruh_5_strike_0.png", "art/pack/en_atesruh_5_strike_1.png", "art/pack/en_atesruh_5_strike_2.png", "art/pack/en_atesruh_5_strike_3.png", "art/pack/en_atesruh_5_strike_4.png", "art/pack/en_atesruh_5_strike_5.png", "art/pack/en_atesruh_5_strike_6.png", "art/pack/en_atesruh_5_strike_7.png", "art/pack/en_atesruh_5_strike_8.png", "art/pack/en_atesruh_5_strike_9.png", "art/pack/en_atesruh_5_strike_10.png", "art/pack/en_atesruh_5_strike_11.png", "art/pack/en_atesruh_5_strike_12.png", "art/pack/en_atesruh_5_strike_13.png"],
		"hurt": ["art/pack/en_atesruh_5_hurt_0.png", "art/pack/en_atesruh_5_hurt_1.png", "art/pack/en_atesruh_5_hurt_2.png", "art/pack/en_atesruh_5_hurt_3.png"],
		"die": ["art/pack/en_atesruh_5_die_0.png", "art/pack/en_atesruh_5_die_1.png", "art/pack/en_atesruh_5_die_2.png", "art/pack/en_atesruh_5_die_3.png"],
	},
	"itizpap_4": {
		"idle": ["art/pack/en_bat_i_0.png", "art/pack/en_bat_i_1.png", "art/pack/en_bat_i_2.png"],
		"windup": ["art/pack/en_bat_w_0.png", "art/pack/en_bat_w_1.png"],
		"strike": ["art/pack/en_bat_s_0.png", "art/pack/en_bat_s_1.png", "art/pack/en_bat_s_2.png"],
		"die": ["art/pack/en_bat_d_0.png"],
	},
	"korp_5": {
		"idle": ["art/pack/en_korp_5_idle_0.png", "art/pack/en_korp_5_idle_1.png", "art/pack/en_korp_5_idle_2.png", "art/pack/en_korp_5_idle_3.png", "art/pack/en_korp_5_idle_4.png", "art/pack/en_korp_5_idle_5.png"],
		"windup": ["art/pack/en_korp_5_windup_0.png", "art/pack/en_korp_5_windup_1.png"],
		"strike": ["art/pack/en_korp_5_strike_0.png", "art/pack/en_korp_5_strike_1.png", "art/pack/en_korp_5_strike_2.png", "art/pack/en_korp_5_strike_3.png", "art/pack/en_korp_5_strike_4.png", "art/pack/en_korp_5_strike_5.png", "art/pack/en_korp_5_strike_6.png", "art/pack/en_korp_5_strike_7.png"],
		"hurt": ["art/pack/en_korp_5_hurt_0.png", "art/pack/en_korp_5_hurt_1.png", "art/pack/en_korp_5_hurt_2.png", "art/pack/en_korp_5_hurt_3.png"],
		"die": ["art/pack/en_korp_5_die_0.png", "art/pack/en_korp_5_die_1.png", "art/pack/en_korp_5_die_2.png", "art/pack/en_korp_5_die_3.png"],
	},
}
