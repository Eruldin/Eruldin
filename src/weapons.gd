class_name Weapons
extends RefCounted

# Auto-weapon system (Vampire Survivors style): the player only moves; every
# owned weapon ticks its own cooldown and fires with its own targeting rule.
# Passives are flat stat mutators. Evolution: a maxed weapon + its paired
# passive owned → elite chest transforms it into an evolved form.

const WPN_SLOTS := 6
const PSV_SLOTS := 6
const WPN_MAX := 8
const PSV_MAX := 5

# b = base stats; inc = per-level delta added for each level past 1;
# feats = {level: {key: add}} threshold unlocks; evo = required passive id;
# into = evolved weapon id (hidden = not draftable directly).
const DEFS := {
	"blade": {
		"name": "ALFA KILICI", "icon": "icn_stance_cleave", "col": "7fd4ff",
		"desc": "En yakın düşmana kavisli kesik",
		"b": {"dmg": 15.0, "cd": 1.2, "reach": 80.0, "arc": 125.0},
		"inc": {"dmg": 3.6, "reach": 4.0, "arc": 5.0, "cd": -0.045},
		"feats": {5: {"echo": 1.0}, 8: {"heavy": 1.0}},
		"evo": "greaves", "into": "blade_x",
	},
	"blade_x": {
		"name": "ALFA YEMİNİ", "icon": "icn_rhasa", "col": "ffb74d",
		"desc": "Tam daire kesiği — Rex'in hatırası",
		"b": {"dmg": 64.0, "cd": 0.8, "reach": 132.0, "arc": 360.0, "echo": 1.0, "heavy": 1.0},
		"hidden": true,
	},
	"plasma": {
		"name": "PLAZMA MIZRAĞI", "icon": "icn_rex", "col": "00E5FF",
		"desc": "En yakın hedeflere plazma mermisi",
		"b": {"dmg": 20.0, "cd": 1.55, "n": 1.0, "spd": 430.0},
		"inc": {"dmg": 6.0, "n": 0.5, "cd": -0.05},
		"evo": "coil", "into": "plasma_x",
	},
	"plasma_x": {
		"name": "SAĞANAK", "icon": "icn_rex", "col": "7fd4ff",
		"desc": "Delici, güdümlü mermi sağanağı",
		"b": {"dmg": 52.0, "cd": 1.05, "n": 7.0, "spd": 520.0, "pierce": 1.0, "home": 1.0},
		"hidden": true,
	},
	"orbit": {
		"name": "NEVA HALKASI", "icon": "icn_neva", "col": "c26bff",
		"desc": "Etrafında dönen şarapnel küreleri",
		"b": {"dmg": 11.0, "cd": 999.0, "n": 2.0, "r": 78.0, "spin": 2.6, "tk": 0.35},
		"inc": {"dmg": 3.0, "r": 5.0, "spin": 0.14},
		"feats": {4: {"n": 1.0}, 7: {"n": 1.0}},
		"evo": "magnet", "into": "orbit_x",
	},
	"orbit_x": {
		"name": "NEVA'NIN HALOSU", "icon": "icn_neva", "col": "e0b0ff",
		"desc": "Genişleyen şarapnel halkası",
		"b": {"dmg": 40.0, "cd": 999.0, "n": 6.0, "r": 124.0, "spin": 3.4, "tk": 0.3},
		"hidden": true,
	},
	"bolt": {
		"name": "ŞİMŞEK AĞI", "icon": "icn_kovan", "col": "ffe066",
		"desc": "Rastgele düşmanlara yıldırım düşürür",
		"b": {"dmg": 26.0, "cd": 2.3, "n": 2.0, "chain": 0.0},
		"inc": {"dmg": 7.0, "n": 0.5, "chain": 0.4, "cd": -0.06},
		"evo": "lens", "into": "bolt_x",
	},
	"bolt_x": {
		"name": "KAFES FIRTINASI", "icon": "icn_kovan", "col": "fff3a0",
		"desc": "Zincirleme şimşek fırtınası",
		"b": {"dmg": 60.0, "cd": 1.5, "n": 12.0, "chain": 3.0},
		"hidden": true,
	},
	"nova": {
		"name": "KOVAN NABZI", "icon": "icn_saphire", "col": "ff8866",
		"desc": "Etrafına şok dalgası salar",
		"b": {"dmg": 18.0, "cd": 3.4, "r": 110.0, "knock": 14.0},
		"inc": {"dmg": 5.0, "r": 9.0, "cd": -0.12},
		"evo": "vigor", "into": "nova_x",
	},
	"nova_x": {
		"name": "KOVAN YÜREĞİ", "icon": "icn_saphire", "col": "ff5533",
		"desc": "Devasa nabız — yavaşlatır ve savurur",
		"b": {"dmg": 70.0, "cd": 2.6, "r": 200.0, "knock": 26.0, "slow": 1.0},
		"hidden": true,
	},
	"spit": {
		"name": "ASİT SAÇMASI", "icon": "ico_heal", "col": "39ff14",
		"desc": "Düşmanlara asit birikintisi bırakır",
		"b": {"dmg": 9.0, "cd": 2.8, "n": 1.0, "r": 58.0, "dur": 3.6},
		"inc": {"dmg": 2.2, "r": 5.0, "dur": 0.3},
		"feats": {5: {"n": 1.0}},
		"evo": "core", "into": "spit_x",
		"req": {"kills": 250},
	},
	"spit_x": {
		"name": "ASİT SELİ", "icon": "ico_heal", "col": "7dff4d",
		"desc": "Kurşun yeşili asit gölleri",
		"b": {"dmg": 30.0, "cd": 2.0, "n": 4.0, "r": 92.0, "dur": 6.0},
		"hidden": true,
	},
	"dagger": {
		"name": "FİTİL BIÇAĞI", "icon": "icn_stance_duel", "col": "9fd8ff",
		"desc": "Baktığın yöne bıçak yelpazesi fırlatır",
		"b": {"dmg": 9.0, "cd": 0.95, "n": 2.0, "spd": 620.0, "fan": 0.18},
		"inc": {"dmg": 2.4, "n": 0.34, "cd": -0.03},
		"feats": {6: {"n": 1.0}},
		"evo": "plating", "into": "dagger_x",
		"req": {"kills": 800},
	},
	"dagger_x": {
		"name": "ÇELİK YAĞMURU", "icon": "icn_stance_duel", "col": "cfe8ff",
		"desc": "Delici bıçak fırtınası",
		"b": {"dmg": 26.0, "cd": 0.7, "n": 8.0, "spd": 700.0, "fan": 0.55, "pierce": 1.0},
		"hidden": true,
	},
	"ray": {
		"name": "PROTERİN HÜZMESİ", "icon": "icn_upg_dmg", "col": "ffe3a0",
		"desc": "En yakın düşmana delici hüzme",
		"b": {"dmg": 30.0, "cd": 2.1, "len": 620.0, "w": 26.0},
		"inc": {"dmg": 8.0, "len": 14.0, "w": 1.6, "cd": -0.05},
		"evo": "regen", "into": "ray_x",
		"req": {"bosses": 1},
	},
	"ray_x": {
		"name": "GAMA ERİYİĞİ", "icon": "icn_upg_dmg", "col": "fff3c0",
		"desc": "Geniş yakıcı hüzme",
		"b": {"dmg": 82.0, "cd": 1.4, "len": 780.0, "w": 46.0},
		"hidden": true,
	},
	"seeker": {
		"name": "SİNYAL MİSKETİ", "icon": "ico_exit", "col": "ffd166",
		"desc": "Etraftaki düşmanlara güdümlü misketler",
		"b": {"dmg": 13.0, "cd": 1.8, "n": 2.0, "spd": 340.0},
		"inc": {"dmg": 4.2, "n": 0.5, "cd": -0.06},
		"feats": {5: {"n": 1.0}, 8: {"n": 1.0}},
		"evo": "warp", "into": "seeker_x",
		"req": {"wins": 1},
	},
	"seeker_x": {
		"name": "KÜME SAĞANAĞI", "icon": "ico_exit", "col": "ffe9a0",
		"desc": "Delici misket sürüsü — hepsi kilitlenir",
		"b": {"dmg": 34.0, "cd": 1.2, "n": 7.0, "spd": 480.0, "pierce": 1.0},
		"hidden": true,
	},
	"glaive": {
		"name": "SIRP DİSKİ", "icon": "icn_dash", "col": "7fe0c3",
		"desc": "Gidip dönen delici disk — iki yönde de keser",
		"b": {"dmg": 15.0, "cd": 1.7, "n": 1.0, "spd": 520.0, "range": 300.0},
		"inc": {"dmg": 4.2, "cd": -0.05, "n": 0.25, "range": 8.0},
		"feats": {5: {"n": 1.0}, 8: {"n": 1.0}},
		"evo": "edge", "into": "glaive_x",
		"req": {"kills": 1500},
	},
	"glaive_x": {
		"name": "ÇİFT GİRDAP", "icon": "icn_dash", "col": "a9ffe8",
		"desc": "Üç dönen disk — gidiş ve dönüşte keser",
		"b": {"dmg": 38.0, "cd": 1.15, "n": 3.0, "spd": 640.0, "range": 360.0},
		"hidden": true,
	},
	"meteor": {
		"name": "GÖKTANIŞ", "icon": "icn_skull", "col": "ff7043",
		"desc": "Düşmanların üstüne işaretli göktaşı yağdırır",
		"b": {"dmg": 34.0, "cd": 2.6, "n": 2.0, "r": 70.0, "tel": 0.75},
		"inc": {"dmg": 8.0, "n": 0.25, "r": 3.0, "cd": -0.05},
		"feats": {8: {"n": 1.0}},
		"evo": "dup", "into": "meteor_x",
		"req": {"bosses": 2},
	},
	"meteor_x": {
		"name": "KUYRUKLU SAĞANAK", "icon": "icn_skull", "col": "ffab91",
		"desc": "Tüm sahaya göktaşı seli",
		"b": {"dmg": 68.0, "cd": 1.9, "n": 7.0, "r": 95.0, "tel": 0.65},
		"hidden": true,
	},
	"drone": {
		"name": "NÖBETÇİ DRON", "icon": "icn_saphire", "col": "00E5FF",
		"desc": "Etrafında süzülen dron — en yakın düşmana kendi mermi atar",
		"b": {"dmg": 11.0, "cd": 1.15, "n": 1.0, "drones": 1.0},
		"inc": {"dmg": 2.8, "cd": -0.04},
		"feats": {5: {"n": 1.0}, 8: {"drones": 1.0}},
		"evo": "warp", "into": "drone_x",
		"req": {"bosses": 3},
	},
	"drone_x": {
		"name": "SÜRÜ NÖBETİ", "icon": "icn_saphire", "col": "a9ffe8",
		"desc": "Üç delici dron — yörüngede doyasıya kesim",
		"b": {"dmg": 22.0, "cd": 0.72, "n": 2.0, "drones": 3.0, "pierce": 1.0},
		"hidden": true,
	},
	"sentry": {
		"name": "NÖBET KULESİ", "icon": "icn_upg_shield", "col": "ffb74d",
		"desc": "Geçici nöbet kulesi kurar — kendi hızında ateş eder",
		"b": {"dmg": 0.0, "cd": 9.0, "n": 0.0, "drones": 1.0, "shot": 9.0, "rate": 0.42, "dur": 14.0},
		"inc": {"shot": 2.4, "cd": -0.3, "dur": 0.6},
		"feats": {5: {"drones": 1.0}, 8: {"rate": -0.08}},
		"evo": "core", "into": "sentry_x",
		"req": {"wins": 1},
	},
	"sentry_x": {
		"name": "KORUMA AĞI", "icon": "icn_upg_shield", "col": "ffd54f",
		"desc": "Üç kule — hızlı delici ateş ağı",
		"b": {"dmg": 0.0, "cd": 11.0, "n": 0.0, "drones": 3.0, "shot": 16.0, "rate": 0.3, "dur": 20.0, "pierce": 1.0},
		"hidden": true,
	},
	"aura": {
		"name": "REZONANS AURASI", "icon": "icn_neva", "col": "c26bff",
		"desc": "Etrafında sürekli yakan choralim alanı",
		"b": {"dmg": 6.0, "cd": 1.1, "r": 95.0},
		"inc": {"dmg": 2.2, "r": 6.0, "cd": -0.03},
		"feats": {5: {"r": 18.0}},
		"evo": "fortune", "into": "aura_x",
		"req": {"kills": 2000},
	},
	"aura_x": {
		"name": "KORO YANKISI", "icon": "icn_neva", "col": "e066ff",
		"desc": "Geniş yankı alanı — yakar ve sersemletir",
		"b": {"dmg": 16.0, "cd": 0.8, "r": 170.0, "slow": 1.0},
		"hidden": true,
	},
	"mortar": {
		"name": "KRİSTAL MANCINIK", "icon": "ico_frag", "col": "8be9ff",
		"desc": "Düşmanların üstüne kristal yağdırır — patlama yerinde parçacık bırakır",
		"b": {"dmg": 22.0, "cd": 2.2, "n": 2.0, "r": 62.0, "tel": 0.6, "frag": 3.0},
		"inc": {"dmg": 6.0, "n": 0.25, "r": 3.0, "cd": -0.05},
		"feats": {6: {"n": 1.0}},
		"evo": "avarice", "into": "mortar_x",
		"req": {"kills": 2500},
	},
	"mortar_x": {
		"name": "HAKEDİŞ ÇARKI", "icon": "ico_frag", "col": "c9f1ff",
		"desc": "Kristal sağanağı — her patlama bol parçacık döker",
		"b": {"dmg": 56.0, "cd": 1.6, "n": 6.0, "r": 88.0, "tel": 0.55, "frag": 8.0},
		"hidden": true,
	},
	# zincir ark arketipi: öndeki ilk hedeften başlar, düşmanlar arasında sıçrar,
	# her sıçramada hasar sönümlenir (bolt'un rastgele gök vuruşundan farklı —
	# ön cepheye odaklı, kalabalıkta değerlenir)
	"volt": {
		"name": "VOLT ZİNCİRİ", "icon": "icn_kovan", "col": "7fe0ff",
		"desc": "Öndeki düşmana akım zinciri — düşmanlar arasında sıçrar",
		"b": {"dmg": 15.0, "cd": 1.35, "n": 3.0, "hop": 190.0, "falloff": 0.85},
		"inc": {"dmg": 4.0, "n": 0.35, "hop": 5.0, "cd": -0.04},
		"feats": {5: {"n": 1.0}, 8: {"falloff": -0.12}},
		"evo": "lens", "into": "volt_x",
		"req": {"kills": 3000},
	},
	"volt_x": {
		"name": "ŞEBEKE", "icon": "icn_kovan", "col": "b7f4ff",
		"desc": "Ön cepheyi dolaşan elektrik ağı",
		"b": {"dmg": 42.0, "cd": 0.95, "n": 8.0, "hop": 240.0, "falloff": 0.92},
		"hidden": true,
	},
	# iz-arketipi: oyuncunun bastığı yere yanan kalıntı düşer — kovalayan sürü
	# üstünden geçerken yanar (savunma silahı, koşu kitingi)
	"trail": {
		"name": "KOR İZİ", "icon": "icn_mine", "col": "ff8a3d",
		"desc": "Ardında yanan kalıntı bırakır — peşine düşen yanar",
		"b": {"dmg": 5.0, "cd": 0.85, "r": 46.0, "dur": 3.6},
		"inc": {"dmg": 1.6, "dur": 0.3, "r": 2.5, "cd": -0.02},
		"feats": {5: {"dur": 1.2}},
		"evo": "coil", "into": "trail_x",
		"req": {"kills": 1500},
	},
	"trail_x": {
		"name": "KOR HENDEK", "icon": "icn_mine", "col": "ffb05a",
		"desc": "Geniş yanan hendek — sürüyü arkandan sıvı koru keser",
		"b": {"dmg": 13.0, "cd": 0.55, "r": 72.0, "dur": 6.5},
		"hidden": true,
	},
	# alan kontrolü arketipi: ayak dibine çöken dondurucu sis — içindeki sürü
	# chill_t ile %50 yavaşlar ve küçük çürüme hasarı alır (kite desteği)
	"sis": {
		"name": "SİS AĞZI", "icon": "icn_upg_shield", "col": "9fd8ff",
		"desc": "Yerde çöken dondurucu sis — içindeki sürü yavaşlar ve çürür",
		"b": {"dmg": 3.0, "cd": 3.4, "r": 88.0, "dur": 3.4},
		"inc": {"dmg": 1.1, "r": 6.0, "dur": 0.25, "cd": -0.05},
		"feats": {5: {"r": 20.0}},
		"evo": "dup", "into": "sis_x",
		"req": {"kills": 2200},
	},
	"sis_x": {
		"name": "KIRAĞI HÜCRESİ", "icon": "icn_upg_shield", "col": "cfeaff",
		"desc": "Geniş donma hücresi — içinde duran sürü donakalır",
		"b": {"dmg": 9.0, "cd": 2.8, "r": 130.0, "dur": 4.6},
		"hidden": true,
	},
	# kırbaç arketipi (VS): uzun-ince ön kesik, sağ/sol dönüşümlü — geniş
	# değil derin keser; kalabalığın kenarını biçmek için
	"kirbac": {
		"name": "KOVAN KIRBACI", "icon": "icn_stance_cleave", "col": "d8b45a",
		"desc": "Öne uzun ince kesik — her vuruş sağ/sol tarafa kayar",
		"b": {"dmg": 18.0, "cd": 1.35, "reach": 200.0, "arc": 52.0},
		"inc": {"dmg": 4.4, "reach": 6.0, "cd": -0.04},
		"feats": {5: {"arc": 16.0}, 8: {"dmg": 9.0}},
		"evo": "dup", "into": "kirbac_x",
		"req": {"kills": 1800},
	},
	"kirbac_x": {
		"name": "İKİZ KAMÇI", "icon": "icn_stance_duel", "col": "ffd75f",
		"desc": "İki tarafa aynı anda — ölüm kervanı",
		"b": {"dmg": 36.0, "cd": 1.0, "reach": 265.0, "arc": 58.0},
		"hidden": true,
	},
}

const PDEFS := {
	"magnet":  {"name": "REZONANS MIKNATISI", "icon": "ico_frag",       "col": "c26bff", "desc": "+60 toplama yarıçapı"},
	"plating": {"name": "KOMPOZİT ZIRH",      "icon": "icn_upg_shield", "col": "8ea0b5", "desc": "+1 zırh"},
	"greaves": {"name": "SPRINT SERVOLARI",   "icon": "icn_upg_dash",   "col": "00E676", "desc": "+%6 hareket hızı"},
	"coil":    {"name": "SOĞUTMA BOBİNİ",     "icon": "icn_dash",       "col": "00E5FF", "desc": "-%7 silah bekleme süresi"},
	"lens":    {"name": "ALAN LENSİ",         "icon": "ico_boon",       "col": "ffb74d", "desc": "+%8 etki alanı"},
	"core":    {"name": "HEDEF İŞLEMCİ",      "icon": "icn_upg_dmg",    "col": "ff4444", "desc": "+%8 hasar"},
	"vigor":   {"name": "BİYOLAT",            "icon": "icn_upg_hp",     "col": "ff6688", "desc": "+15 azami can"},
	"regen":   {"name": "REJENERASYON",       "icon": "ico_heal",       "col": "39ff14", "desc": "+0.7 can/sn"},
	"warp":    {"name": "ROTA AKSAMI",        "icon": "icn_crown",      "col": "ffd166", "desc": "+%9 mermi hızı"},
	"edge":    {"name": "KESKİN KİLİT",       "icon": "icn_upg_frag",   "col": "ff9de2", "desc": "+%6 kritik şansı"},
	"dup":     {"name": "ÇOĞALTAN",            "icon": "icn_crown",      "col": "b388ff", "desc": "+1 mermi/gülle adedi"},
	"fortune": {"name": "TALİH MÜHRÜ",         "icon": "icn_crown",      "col": "ffd700", "desc": "+%8 şans — nadir düşüş ve lütuf kalitesini sallar"},
	"avarice": {"name": "AÇGÖZ BOBİNİ",         "icon": "ico_frag",       "col": "ffb02e", "desc": "+%12 parçacık değeri"},
}

static func def(wid: String) -> Dictionary:
	return DEFS.get(wid, {})

static func pdef(pid: String) -> Dictionary:
	return PDEFS.get(pid, {})

static func stats(wid: String, lvl: int) -> Dictionary:
	var d: Dictionary = DEFS.get(wid, {})
	var out: Dictionary = d.get("b", {}).duplicate()
	for k in d.get("inc", {}):
		out[k] = out.get(k, 0.0) + d.inc[k] * float(lvl - 1)
	for f in d.get("feats", {}):
		if lvl >= int(f):
			for k2 in d.feats[f]:
				out[k2] = out.get(k2, 0.0) + d.feats[f][k2]
	var mt := mastery_tier(wid)
	if mt > 0 and out.has("dmg"):
		out["dmg"] = float(out.dmg) * (1.0 + 0.04 * mt)
	return out

# kalıcı silah ustalığı: meta'daki kümülatif hasar her 25K'da bir kat (maks 3)
static func mastery_tier(wid: String) -> int:
	if not is_instance_valid(G.meta):
		return 0
	return mini(3, int(float(G.meta.data.get("wep_mastery", {}).get(wid, 0.0)) / 25000.0))

static func has_w(p: Player, wid: String) -> bool:
	for w in p.weapons:
		if w.id == wid:
			return true
	return false

static func w_lvl(p: Player, wid: String) -> int:
	for w in p.weapons:
		if w.id == wid:
			return int(w.lvl)
	return 0

static func has_p(p: Player, pid: String) -> bool:
	for ps in p.passives:
		if ps.id == pid:
			return true
	return false

static func apply_passive(pid: String, p: Player) -> void:
	match pid:
		"magnet": p.magnet_r += 60.0
		"plating": p.armor += 1.0
		"greaves": p.speed *= 1.06
		"coil": p.cd_mult *= 0.93
		"lens": p.area_mult *= 1.08
		"core": p.dmg_mult *= 1.08
		"vigor":
			p.max_hp += 15.0
			p.hp = minf(p.hp + 15.0, p.max_hp)
		"edge":   p.crit_ch += 0.06
		"regen":
			p.set_meta("regen", float(p.get_meta("regen", 0.0)) + 0.7)
		"warp": p.proj_spd *= 1.09
		"dup":  p.bonus_proj += 1
		"fortune": G.run.luck += 0.08
		"avarice": p.frag_mult += 0.12

# which evolutions the player can cash in right now
static func evo_ready(p: Player) -> Array:
	var out: Array = []
	for w in p.weapons:
		var d: Dictionary = DEFS.get(str(w.id), {})
		var into: String = str(d.get("into", ""))
		if into == "" or int(w.lvl) < WPN_MAX:
			continue
		if has_p(p, str(d.get("evo", ""))):
			out.append({"from": w.id, "into": into})
	return out

# ---------------------------------------------------------------- draft

# draft-card hints: weapons name their evo pair, passives name the weapons they evolve
static func _evo_hint(d: Dictionary, p: Player) -> String:
	var pid := str(d.get("evo", ""))
	var into := str(d.get("into", ""))
	if pid == "" or into == "":
		return ""
	var pn := str(PDEFS.get(pid, {}).get("name", pid))
	var en := str(DEFS.get(into, {}).get("name", into))
	return "\nevrim: %s → %s%s" % [pn, en, " ✓" if has_p(p, pid) else ""]

static func _evo_pairs(pid: String) -> String:
	var names: Array = []
	for wid in DEFS:
		var d: Dictionary = DEFS[wid]
		if str(d.get("evo", "")) == pid and not d.get("hidden", false):
			names.append(str(d.name))
	return "" if names.is_empty() else "\nevrim çifti: " + ", ".join(names)

static func _opt(kind: String, id: String, lvl: int, name: String, icon: String, col: String, desc: String, w: float, top: String = "") -> Dictionary:
	return {"kind": kind, "id": id, "lvl": lvl, "name": name, "icon": icon, "col": col, "desc": desc, "top": top, "w": w}

# VS achievement gating: gated weapons only draft once the meta goal is met
static func unlocked(wid: String) -> bool:
	if G.meta != null and Array(G.meta.data.get("wep_unlocked", [])).has(wid):
		return true
	var req: Dictionary = DEFS.get(wid, {}).get("req", {})
	if req.is_empty():
		return true
	var d: Dictionary = G.meta.data
	if int(req.get("kills", 0)) > int(d.get("kills", 0)):
		return false
	if int(req.get("wins", 0)) > int(d.get("victories", 0)):
		return false
	if int(req.get("bosses", 0)) > int(d.get("bosses", []).size()):
		return false
	return true

static func req_text(wid: String) -> String:
	var req: Dictionary = DEFS.get(wid, {}).get("req", {})
	if req.has("wins"):
		return "1 zafer gerekir"
	if req.has("bosses"):
		return "%d efendi düşür" % int(req.get("bosses", 0))
	if req.has("kills"):
		return "%d toplam kesim" % int(req.get("kills", 0))
	return ""

static func draft_opts(p: Player, luck: float) -> Array:
	var pool: Array = []
	var ban: Array = G.run.banished if G.run != null else []
	for w in p.weapons:
		var d: Dictionary = DEFS.get(str(w.id), {})
		if int(w.lvl) < WPN_MAX and not d.get("hidden", false) and not ban.has(str(w.id)):
			pool.append(_opt("wpn", w.id, int(w.lvl) + 1, "%s · Sv.%d" % [str(d.get("name", w.id)), int(w.lvl) + 1], str(d.get("icon", "ico_boon")), str(d.get("col", "ffffff")), _lvl_desc(w.id, int(w.lvl) + 1) + _evo_hint(d, p), 10.0))
	if p.weapons.size() < WPN_SLOTS:
		for wid in DEFS:
			var d: Dictionary = DEFS[wid]
			if d.get("hidden", false) or has_w(p, wid) or not unlocked(wid) or ban.has(wid):
				continue
			pool.append(_opt("wpn", wid, 1, d.name, d.icon, d.col, str(d.desc) + "  (yeni silah)" + _evo_hint(d, p), 7.0, "YENİ"))
	for ps in p.passives:
		if int(ps.lvl) < PSV_MAX and not ban.has(str(ps.id)):
			var d: Dictionary = PDEFS[str(ps.id)]
			pool.append(_opt("psv", ps.id, int(ps.lvl) + 1, "%s · Sv.%d" % [d.name, int(ps.lvl) + 1], d.icon, d.col, str(d.desc) + _evo_pairs(str(ps.id)), 9.0))
	if p.passives.size() < PSV_SLOTS:
		for pid in PDEFS:
			if has_p(p, pid) or ban.has(pid):
				continue
			var d: Dictionary = PDEFS[pid]
			pool.append(_opt("psv", pid, 1, d.name, d.icon, d.col, str(d.desc) + "  (yeni pasif)" + _evo_pairs(pid), 6.0, "YENİ"))
	for b in Boons.roll(G.run.boon_ids, luck):
		if not ban.has(str(b.id)):
			pool.append(_opt("boon", b.id, 0, b.name, "icn_" + str(b.patron).to_lower(), b.color.to_html(false), str(b.desc), 2.2, b.patron + " " + "★".repeat(int(b.rarity) + 1)))
	# azap kartı — güç bedeliyle (HoT cursed scroll); nadiren çıkar, 4'te tavan
	if G.run != null and int(G.run.curse) < 4 and int(p.level) >= 5 and not ban.has("curse"):
		pool.append(_opt("curse", "curse", 0, "KARANLIK SÖZLEŞME", "icn_skull", "ff2222", "+%25 hasar — karşılığında kovan +%12 sert ve dayanıklı olur (bu koşuda birikir)", 0.9, "AZAP"))
	var out: Array = []
	for i in 3:
		if pool.is_empty():
			break
		var total := 0.0
		for e in pool:
			total += float(e.w)
		var r := G.rf(0, total)
		var acc := 0.0
		var idx := pool.size() - 1
		for j in pool.size():
			acc += float(pool[j].w)
			if r <= acc:
				idx = j
				break
		out.append(pool[idx])
		pool.remove_at(idx)
	# limit-break: maxed-out runs still get 3 picks — stat chips + consumables
	var gifts := [
		_opt("gift", "frag", 0, "PARÇACIK ÖBÜRÜ", "ico_frag", "c26bff", "+120 choralim parçacığı", 1.0),
		_opt("gift", "heal", 0, "NANOBİYOLAT", "ico_heal", "39ff14", "+%40 can yenile", 1.0),
		_opt("gift", "dmg", 0, "KİLİT MODÜLÜ", "icn_upg_dmg", "ff5533", "+%4 hasar", 1.0),
		_opt("gift", "hp", 0, "NANOZIRH", "icn_upg_hp", "00E676", "+8 azami can", 1.0),
		_opt("gift", "spd", 0, "SÜRÜCÜ YAĞI", "icn_upg_dash", "00E5FF", "+%3 hareket hızı", 1.0),
	]
	var gi := 0
	while out.size() < 3:
		out.append(gifts[gi % gifts.size()])
		gi += 1
	return out

static func _lvl_desc(wid: String, lvl: int) -> String:
	var a := stats(wid, lvl - 1)
	var b := stats(wid, lvl)
	var labels := {"dmg": "hasar", "cd": "bekleme", "reach": "menzil", "arc": "kavis", "n": "adet", "r": "yarıçap", "spd": "hız", "spin": "dönüş", "dur": "süre", "chain": "zincir", "knock": "savurma", "hop": "sıçrama"}
	var parts: Array = []
	for k in labels:
		if absf(float(b.get(k, 0.0)) - float(a.get(k, 0.0))) > 0.01:
			var fmt := "%.1f" if k == "cd" else "%d"
			parts.append("%s %s→%s" % [labels[k], fmt % a.get(k, 0.0), fmt % b.get(k, 0.0)])
	if b.get("echo", 0.0) > a.get("echo", 0.0):
		parts.append("arka kesik")
	if b.get("heavy", 0.0) > a.get("heavy", 0.0):
		parts.append("ağır vuruş")
	return " · ".join(parts) if not parts.is_empty() else "güçlenir"

static func apply_opt(opt: Dictionary, p: Player) -> void:
	match str(opt.kind):
		"wpn":
			var wid := str(opt.id)
			var found := false
			for w in p.weapons:
				if w.id == wid:
					w.lvl = int(w.lvl) + 1
					found = true
			if not found:
				p.weapons.append({"id": wid, "lvl": 1, "t": 0.3, "orbs": [], "pools": [], "tk": 0.0})
		"psv":
			var pid := str(opt.id)
			var found := false
			for ps in p.passives:
				if ps.id == pid:
					ps.lvl = int(ps.lvl) + 1
					found = true
			if not found:
				p.passives.append({"id": pid, "lvl": 1})
			apply_passive(pid, p)
		"boon":
			for b in Boons.all():
				if b.id == opt.id:
					G.run.take_boon(b)
		"curse":
			G.run.curse += 1
			p.dmg_mult *= 1.25
			G.ui.toast("AZAP: kovan güçlendi — sözleşme %d" % int(G.run.curse))
		"gift":
			match str(opt.id):
				"frag": G.run.fragments += 120
				"skip": G.run.fragments += 15
				"dmg": p.dmg_mult *= 1.04
				"hp": p.max_hp += 8.0; p.hp += 8.0
				"spd": p.speed *= 1.03
				_: p.heal(p.max_hp * 0.4)

static func apply_evo(spec: Dictionary, p: Player) -> void:
	G.run.stats["evos"] = int(G.run.stats.get("evos", 0)) + 1
	for w in p.weapons:
		if w.id == spec.from:
			w.id = spec.into
			w.t = 0.2
			for o in w.get("orbs", []):
				if is_instance_valid(o):
					o.queue_free()
			w.orbs = []
	var into: Dictionary = DEFS.get(str(spec.into), {})
	G.ui.toast("EVRİM — %s!" % into.get("name", "?"))
	G.audio.jingle("boss")
	G.fx.flash(Px.C(str(into.get("col", "ffb74d"))), 0.35)
	G.fx.burst(p.pos + Vector2(0, -20), Px.C(str(into.get("col", "ffb74d"))), 40, 260.0, 6.0, 0.8)

# ---------------------------------------------------------------- tick / fire

static func tick(p: Player, d: float) -> void:
	for w in p.weapons:
		var wid := str(w.id)
		if wid.begins_with("orbit"):
			_tick_orbit(w, p, d)
		elif wid.begins_with("spit"):
			_tick_pools(w, p, d)
		w.t = float(w.t) - d
		if w.t <= 0.0:
			var st := stats(wid, int(w.lvl))
			w.t = maxf(0.12, float(st.get("cd", 1.0)) * p.cd_mult / maxf(p.atk_speed * (1.35 if p.boost_t > 0.0 else 1.0), 0.5))
			_fire(wid, st, p, w)

static var _fwpn := ""   # id of the weapon currently firing — stamps spawned projectiles/hits for the damage tally

static func _fire(wid: String, st: Dictionary, p: Player, w: Dictionary) -> void:
	_fwpn = wid
	match wid:
		"blade", "blade_x": _blade(st, p, wid)
		"plasma", "plasma_x": _plasma(st, p)
		"bolt", "bolt_x": _bolt(st, p)
		"nova", "nova_x": _nova(st, p)
		"spit", "spit_x": _spit(st, p, w)
		"dagger", "dagger_x": _dagger(st, p)
		"ray", "ray_x": _ray(st, p)
		"seeker", "seeker_x": _seeker(st, p)
		"glaive", "glaive_x": _glaive(st, p, w)
		"meteor", "meteor_x": _meteor(st, p, w)
		"drone", "drone_x": _drone(st, p, wid)
		"sentry", "sentry_x": _sentry(st, p, wid)
		"aura", "aura_x": _aura(st, p)
		"mortar", "mortar_x": _mortar(st, p, w)
		"volt", "volt_x": _volt(st, p)
		"trail", "trail_x": _trail(st, p, w)
		"sis", "sis_x": _sis(st, p, w)
		"kirbac", "kirbac_x": _whip(st, p, w, wid)

# pet arketipi (VS yardımcısı): drone'lar oyuncuya bağlı dünya node'ları olarak
# yaşar; silah turu sadece sayı ve statları senkronlar, ateş kendi hızında işler
static func _drone(st: Dictionary, p: Player, wid: String) -> void:
	var want := maxi(1, roundi(float(st.get("drones", 1.0))))
	var ds: Array = p.get_meta("drones") if p.has_meta("drones") else []
	ds = ds.filter(func(d): return is_instance_valid(d))
	while ds.size() < want:
		ds.append(Drone.spawn(ds.size()))
	p.set_meta("drones", ds)
	for i in ds.size():
		var dr: Drone = ds[i]
		dr.wid = wid
		dr.dmg = float(st.dmg)
		dr.cd = float(st.cd)
		dr.n = maxi(1, roundi(float(st.n)))
		dr.pierce = st.get("pierce", 0.0) > 0.0
		dr.idx = i
		dr.total = ds.size()

# nöbet kulesi arketipi: kurulduğu yere çakılı, süreli Drone varyantı
static func _sentry(st: Dictionary, p: Player, wid: String) -> void:
	var cnt := maxi(1, roundi(float(st.get("drones", 1.0))))
	for i in cnt:
		var d := Drone.spawn(0)
		d.anchor = true
		d.wid = wid
		d.dmg = float(st.get("shot", 9.0))
		d.cd = float(st.get("rate", 0.42))
		d.n = 1
		d.life = float(st.get("dur", 14.0))
		d.pierce = st.get("pierce", 0.0) > 0.0
		d.position = p.pos + Vector2(G.rf(-46.0, 46.0), G.rf(-34.0, 22.0))
		d.tint(Px.C("ffd54f"))
	G.fx.burst(p.pos, Px.C("ffb74d"), 8, 140.0, 4.0, 0.35)
	G.audio.play("plasma", 0.7, 0.5)

static func _nearest(p: Vector2, max_r: float) -> Enemy:
	var best: Enemy = null
	var bd := max_r
	for e in G.enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var dd := p.distance_to(e.pos)
		if dd < bd:
			bd = dd
			best = e
	return best

static func _blade(st: Dictionary, p: Player, wid: String) -> void:
	var tgt := _nearest(p.pos, 420.0)
	var ang := p.move_dir.angle() if tgt == null else (tgt.pos - p.pos).angle()
	if tgt == null and p.move_dir.length_squared() < 0.01:
		ang = p.aim_dir.angle()
	var arc_deg := float(st.arc) * p.area_mult
	var reach := float(st.reach) * p.area_mult
	var dmg := float(st.dmg) * p.dmg_mult * p.st_dmg * (p.melee_dmg / 14.0)
	var heavy: bool = float(st.get("heavy", 0.0)) > 0.0
	p.auto_swing(ang, reach, arc_deg, dmg, heavy, wid)
	if st.get("echo", 0.0) > 0.0:
		var p2 := p
		p.get_tree().create_timer(0.14, false).timeout.connect(func():
			if is_instance_valid(p2) and not p2.dead:
				var t2 := _nearest(p2.pos, 420.0)
				var a2 := (t2.pos - p2.pos).angle() if t2 != null else ang + PI
				p2.auto_swing(a2, reach, arc_deg, dmg, heavy, wid))

# kırbaç: blade'in uzun-ince türevi — vuruş her turda sağ/sol kayar;
# evo (İKİZ KAMÇI) iki tarafı aynı anda çalar
static func _whip(st: Dictionary, p: Player, w: Dictionary, wid: String) -> void:
	var flip := bool(w.get("flip", false))
	w["flip"] = not flip
	var tgt := _nearest(p.pos, 480.0)
	var ang := (tgt.pos - p.pos).angle() if tgt != null else (p.move_dir.angle() if p.move_dir.length_squared() > 0.01 else p.aim_dir.angle())
	var offs: Array = [deg_to_rad(26.0), deg_to_rad(-26.0)] if wid == "kirbac_x" else [deg_to_rad(26.0) * (1.0 if flip else -1.0)]
	var dmg := float(st.dmg) * p.dmg_mult * p.st_dmg * (p.melee_dmg / 14.0)
	var reach := float(st.reach) * p.area_mult
	var arc_deg := float(st.arc) * p.area_mult
	for o in offs:
		p.auto_swing(ang + float(o), reach, arc_deg, dmg, false, wid)

static func _plasma(st: Dictionary, p: Player) -> void:
	var n := maxi(1, roundi(float(st.n)) + p.bonus_proj)
	var targets: Array = []
	var sorted := G.enemies.duplicate()
	sorted.sort_custom(func(a, b): return is_instance_valid(a) and is_instance_valid(b) and p.pos.distance_squared_to(a.pos) < p.pos.distance_squared_to(b.pos))
	for e in sorted:
		if not is_instance_valid(e) or e.dead:
			continue
		targets.append(e)
		if targets.size() >= n:
			break
	for i in n:
		var dir: Vector2
		if i < targets.size():
			dir = (targets[i].pos - p.pos).normalized()
		elif targets.is_empty():
			dir = p.move_dir if p.move_dir.length_squared() > 0.01 else p.aim_dir
		else:
			dir = Vector2.from_angle((targets[i % targets.size()].pos - p.pos).angle() + G.rf(-0.5, 0.5))
		var pr := Projectile.new()
		G.game.world.add_child(pr)
		pr.setup(G.Team.PLAYER, p.pos + dir * 22.0, dir * float(st.spd) * p.proj_spd,
			float(st.dmg) * p.dmg_mult * p.plasma_mult, 9.0 * p.plasma_size, Px.C("00E5FF"), "dot")
		pr.wpn = _fwpn
		pr.homing = p.b_homing or st.get("home", 0.0) > 0.0
		pr.piercing = st.get("pierce", 0.0) > 0.0
		pr.knock = 4.0
		pr.stag = 0.25
	G.audio.play("plasma", G.rf(0.9, 1.1), 0.8)
	G.fx.directional(p.pos + Vector2(0, -12), Vector2.from_angle(0 if targets.is_empty() else (targets[0].pos - p.pos).angle()), Px.C("00E5FF"), 6, 170.0, 3.5, 0.25)

static func _bolt(st: Dictionary, p: Player) -> void:
	var n := maxi(1, roundi(float(st.n)))
	var hits := 0
	var tried := 0
	var done := {}
	while hits < n and tried < n * 6:
		tried += 1
		var e := _nearest(p.pos + Vector2(G.rf(-320, 320), G.rf(-240, 240)), 640.0)
		if e == null or done.has(e):
			continue
		done[e] = true
		_strike(e, float(st.dmg) * p.dmg_mult, p, int(st.get("chain", 0.0)))
		hits += 1
	if hits == 0:
		G.fx.burst(p.pos + Vector2(0, -30), Px.C("ffe066"), 6, 120.0, 3.0, 0.25)
	G.audio.play("zap", 1.2, 0.5)

static func _strike(e: Enemy, dmg: float, p: Player, chain: int) -> void:
	var cur: Enemy = e
	var seen := {}
	var c := 0
	while cur != null and c <= chain:
		seen[cur] = true
		var crit := G.chance(p.crit_ch)
		var h := {"dmg": dmg * (p.crit_mult if crit else 1.0), "type": G.DamageType.SHOCK, "from": cur.pos + Vector2(0, -60), "knock": 2.0, "stagger": 0.3, "source": p, "crit": crit, "wpn": _fwpn}
		cur.take_hit(h)
		p.on_dealt_damage(cur, h)
		G.fx.light_flash(cur.pos + Vector2(0, -20), Px.C("ffe066"), 1.6, 1.8, 0.12)
		G.fx.directional(cur.pos + Vector2(0, -50), Vector2.DOWN, Px.C("ffe066"), 5, 240.0, 3.0, 0.16)
		c += 1
		var nxt: Enemy = null
		var bd := 160.0
		for o in G.enemies:
			if not is_instance_valid(o) or o.dead or seen.has(o):
				continue
			var dd := cur.pos.distance_to(o.pos)
			if dd < bd:
				bd = dd
				nxt = o
		cur = nxt

# volt zinciri: ilk hedef ön yarı düzlemde aranır (aim yönü), sonra zincir
# en yakın henüz vurulmamış düşmana sıçrar; hasar her adımda falloff ile sönümlenir
static func _volt(st: Dictionary, p: Player) -> void:
	var reach := 340.0 * p.area_mult
	var aim := p.move_dir if p.move_dir.length_squared() > 0.01 else p.aim_dir
	var first: Enemy = null
	var bd := reach
	for e in G.enemies:
		if not is_instance_valid(e) or e.dead:
			continue
		var dd := p.pos.distance_to(e.pos)
		if dd < bd and aim.dot((e.pos - p.pos).normalized()) > 0.15:
			bd = dd
			first = e
	if first == null:
		first = _nearest(p.pos, reach * 0.7)
	if first == null:
		G.fx.burst(p.pos + Vector2(0, -30), Px.C("7fe0ff"), 5, 110.0, 3.0, 0.22)
		return
	var hops := maxi(1, roundi(float(st.n)))
	var fall := float(st.get("falloff", 0.85))
	var dmg := float(st.dmg) * p.dmg_mult
	var cur: Enemy = first
	var prev := p.pos + Vector2(0, -20)
	var seen := {}
	var hop_r := float(st.get("hop", 190.0)) * p.area_mult
	while cur != null and hops > 0:
		seen[cur] = true
		_zap_seg(prev, cur.pos + Vector2(0, -14))
		var crit := G.chance(p.crit_ch)
		var h := {"dmg": dmg * (p.crit_mult if crit else 1.0), "type": G.DamageType.SHOCK, "from": prev, "knock": 3.0, "stagger": 0.25, "source": p, "crit": crit, "wpn": _fwpn}
		cur.take_hit(h)
		p.on_dealt_damage(cur, h)
		G.fx.light_flash(cur.pos + Vector2(0, -18), Px.C("7fe0ff"), 1.5, 1.7, 0.14)
		dmg *= fall
		hops -= 1
		prev = cur.pos
		var nxt: Enemy = null
		var bd2 := hop_r
		for o in G.enemies:
			if not is_instance_valid(o) or o.dead or seen.has(o):
				continue
			var dd := prev.distance_to(o.pos)
			if dd < bd2:
				bd2 = dd
				nxt = o
		cur = nxt
	G.audio.play("zap", G.rf(1.0, 1.3), 0.45)

# kırıklı yıldırım segmenti — Line2D, birkaç karede söner
static func _zap_seg(a: Vector2, b: Vector2) -> void:
	var l := Line2D.new()
	l.width = 2.5
	l.default_color = Color(0.55, 0.9, 1.0, 0.9)
	l.z_index = 70
	var pts := [a]
	var segs := 3
	for i in range(1, segs):
		var t := float(i) / float(segs)
		var mid := a.lerp(b, t) + Vector2(G.rf(-9, 9), G.rf(-9, 9))
		pts.append(mid)
	pts.append(b)
	l.points = PackedVector2Array(pts)
	G.game.world.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.16)
	tw.tween_callback(l.queue_free)

static func _nova(st: Dictionary, p: Player) -> void:
	var r := float(st.r) * p.area_mult
	# expanding ring visual
	var s := Sprite2D.new()
	s.texture = Px.S("ring")
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.modulate = Color(1, 0.55, 0.35, 0.75)
	s.position = p.pos
	s.z_index = 60
	G.game.world.add_child(s)
	var target_sc := r * 2.0 / 96.0
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2.ONE * target_sc, 0.32)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.32)
	tw.tween_callback(s.queue_free)
	var dmg := float(st.dmg) * p.dmg_mult
	for e in G.enemies.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		if p.pos.distance_to(e.pos) < r + e.hit_radius:
			var crit := G.chance(p.crit_ch)
			var h := {"dmg": dmg * (p.crit_mult if crit else 1.0), "type": G.DamageType.EXPLOSION, "from": p.pos, "knock": float(st.knock), "stagger": 0.5, "source": p, "crit": crit, "wpn": _fwpn}
			e.take_hit(h)
			p.on_dealt_damage(e, h)
			if st.get("slow", 0.0) > 0.0:
				e.stagger = maxf(e.stagger, 1.1)
	G.audio.play("explode", 0.7, 0.55)
	G.fx.shake(0.14, 0.12)

# aura arketipi (VS Garlic): kalıcı hasar alanı — her nabız yakın sürüyü yakar
static func _aura(st: Dictionary, p: Player) -> void:
	var r := float(st.r) * p.area_mult
	var s := Sprite2D.new()
	s.texture = Px.S("ring")
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.modulate = Color(0.76, 0.42, 1.0, 0.55)
	s.position = p.pos
	s.scale = Vector2.ONE * (r * 1.7) / 96.0
	s.z_index = 60
	G.game.world.add_child(s)
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector2.ONE * (r * 2.0) / 96.0, 0.26)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.26)
	tw.tween_callback(s.queue_free)
	var dmg := float(st.dmg) * p.dmg_mult
	var n := 0
	for e in G.enemies.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		if p.pos.distance_to(e.pos) < r + e.hit_radius:
			var crit := G.chance(p.crit_ch)
			var h := {"dmg": dmg * (p.crit_mult if crit else 1.0), "type": G.DamageType.PURE, "from": p.pos, "knock": 0.0, "stagger": 0.0, "source": p, "crit": crit, "wpn": _fwpn}
			e.take_hit(h)
			p.on_dealt_damage(e, h)
			if st.get("slow", 0.0) > 0.0:
				e.stagger = maxf(e.stagger, 0.3)
			n += 1
	if n > 0:
		G.audio.play("boon", 1.8, 0.12)

static func _spit(st: Dictionary, p: Player, w: Dictionary) -> void:
	var n := maxi(1, roundi(float(st.n)))
	for i in n:
		var e := _nearest(p.pos + Vector2(G.rf(-260, 260), G.rf(-200, 200)), 520.0)
		var at := e.pos if e != null else p.pos + Vector2(G.rf(-160, 160), G.rf(-120, 120))
		var node := Sprite2D.new()
		node.texture = Px.S("circle")
		node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var r := float(st.r) * p.area_mult
		node.scale = Vector2.ONE * (r * 2.0) / 72.0
		node.modulate = Color(0.3, 0.9, 0.2, 0.3)
		node.position = at
		node.z_index = -1500
		if is_instance_valid(G.room):
			G.room.add_child(node)
		else:
			G.game.world.add_child(node)
		w.pools.append({"pos": at, "r": r, "dps": float(st.dmg) * p.dmg_mult, "t": float(st.dur), "node": node, "acc": 0.0, "wpn": str(w.id)})
	G.audio.play("shoot", 0.7, 0.45)

# kor izi: oyuncunun bastığı noktaya yanan kalıntı — _spit'in havuz altyapısını
# kullanır ama hedef oyuncu pozisyonudur; renk/tür yangın paleti
static func _trail(st: Dictionary, p: Player, w: Dictionary) -> void:
	var at := p.pos - p.move_dir.normalized() * 14.0 if p.move_dir.length_squared() > 0.01 else p.pos
	var node := Sprite2D.new()
	node.texture = Px.S("circle")
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var r := float(st.r) * p.area_mult
	node.scale = Vector2.ONE * (r * 2.0) / 72.0
	node.modulate = Color(1.0, 0.5, 0.12, 0.3)
	node.position = at
	node.z_index = -1500
	if is_instance_valid(G.room):
		G.room.add_child(node)
	else:
		G.game.world.add_child(node)
	w.pools.append({"pos": at, "r": r, "dps": float(st.dmg) * p.dmg_mult, "t": float(st.dur), "node": node, "acc": 0.0, "wpn": str(w.id), "type": int(G.DamageType.EXPLOSION)})
	G.audio.play("shoot", 0.5, 0.25)

# sis ağzı: oyuncunun durduğu yere çöken soğuk havuz — "chill" işaretli havuz
# _tick_pools'ta içindeki sürüye chill_t uygular (yavaşlatma + hafif çürüme)
static func _sis(st: Dictionary, p: Player, w: Dictionary) -> void:
	var at := p.pos
	var node := Sprite2D.new()
	node.texture = Px.S("circle")
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var r := float(st.r) * p.area_mult
	node.scale = Vector2.ONE * (r * 2.0) / 72.0
	node.modulate = Color(0.55, 0.8, 1.0, 0.26)
	node.position = at
	node.z_index = -1500
	if is_instance_valid(G.room):
		G.room.add_child(node)
	else:
		G.game.world.add_child(node)
	w.pools.append({"pos": at, "r": r, "dps": float(st.dmg) * p.dmg_mult, "t": float(st.dur), "node": node, "acc": 0.0, "wpn": str(w.id), "type": int(G.DamageType.POISON), "chill": true})
	G.audio.play("shoot", 0.4, 0.3)

static func _dagger(st: Dictionary, p: Player) -> void:
	var n := maxi(1, roundi(float(st.n)) + p.bonus_proj)
	var tgt := _nearest(p.pos, 500.0)
	var base_dir := (tgt.pos - p.pos).normalized() if tgt != null else (p.move_dir if p.move_dir.length_squared() > 0.01 else p.aim_dir)
	var fan := float(st.get("fan", 0.18))
	for i in n:
		var dir := Vector2.from_angle(base_dir.angle() + (i - (n - 1) * 0.5) * fan)
		var pr := Projectile.new()
		G.game.world.add_child(pr)
		pr.setup(G.Team.PLAYER, p.pos + dir * 20.0, dir * float(st.spd) * p.proj_spd,
			float(st.dmg) * p.dmg_mult, 7.0, Px.C("cfe8ff"), "spark")
		pr.wpn = _fwpn
		pr.piercing = st.get("pierce", 0.0) > 0.0
		pr.knock = 2.0
		pr.stag = 0.15
	G.audio.play("shoot", 1.3, 0.6)
	G.fx.directional(p.pos + Vector2(0, -12), base_dir, Px.C("cfe8ff"), 5, 200.0, 3.0, 0.2)

# piercing corridor beam aimed at the nearest enemy — linear AoE, not radial
static func _ray(st: Dictionary, p: Player) -> void:
	var tgt := _nearest(p.pos, 640.0)
	if tgt == null:
		return
	var dir := (tgt.pos - p.pos).normalized()
	var len := float(st.len) * p.area_mult
	var wid := float(st.w) * p.area_mult
	var a := p.pos + dir * 16.0
	var dmg := float(st.dmg) * p.dmg_mult
	for e in G.enemies.duplicate():
		if not is_instance_valid(e) or e.dead:
			continue
		var t := clampf((e.pos - a).dot(dir), 0.0, len)
		if (a + dir * t).distance_to(e.pos) < wid * 0.5 + e.hit_radius:
			var crit := G.chance(p.crit_ch)
			var h := {"dmg": dmg * (p.crit_mult if crit else 1.0), "type": G.DamageType.SHOCK, "from": a, "knock": 3.0, "stagger": 0.2, "source": p, "crit": crit, "wpn": _fwpn}
			e.take_hit(h)
			p.on_dealt_damage(e, h)
	var beam := Sprite2D.new()
	beam.texture = Px.S("bar")
	beam.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	beam.modulate = Color(1.0, 0.88, 0.55, 0.85)
	beam.position = a + dir * len * 0.5
	beam.rotation = dir.angle()
	beam.scale = Vector2(len / 4.0, wid / 4.0)
	beam.z_index = 58
	G.game.world.add_child(beam)
	var tw := beam.create_tween()
	tw.tween_property(beam, "modulate:a", 0.0, 0.28)
	tw.tween_callback(beam.queue_free)
	G.audio.play("beam", 1.0, 0.7)
	G.fx.shake(0.1, 0.06)

# rosette of homing missiles — each curves into the swarm on its own
static func _seeker(st: Dictionary, p: Player) -> void:
	var n := maxi(1, roundi(float(st.n)) + p.bonus_proj)
	var pierce: bool = st.get("pierce", 0.0) > 0.0
	for i in n:
		var dir := Vector2.from_angle(TAU * i / n + G.rf(-0.2, 0.2))
		var pr := Projectile.new()
		G.game.world.add_child(pr)
		pr.setup(G.Team.PLAYER, p.pos + dir * 20.0, dir * float(st.spd) * p.proj_spd,
			float(st.dmg) * p.dmg_mult, 7.5, Px.C("ffd166"), "spark")
		pr.wpn = _fwpn
		pr.homing = true
		pr.piercing = pierce
		pr.knock = 5.0
		pr.stag = 0.3
		pr.life = 3.2
	G.audio.play("shoot", 0.85, 0.6)
	G.fx.burst(p.pos + Vector2(0, -12), Px.C("ffd166"), 8, 140.0, 3.0, 0.25)

# out-and-back piercing discs — they cut on both legs of the trip
static func _glaive(st: Dictionary, p: Player, w: Dictionary) -> void:
	var n := maxi(1, roundi(float(st.n)) + p.bonus_proj)
	var base := p.move_dir if p.move_dir.length_squared() > 0.01 else p.aim_dir
	var spread := TAU if n > 2 else 0.35
	for i in n:
		var dir := base.rotated(-spread * 0.5 + spread * float(i) / maxf(1.0, n - 1.0)) if n > 1 else base
		var pr := Projectile.new()
		G.game.world.add_child(pr)
		var reach := float(st.get("range", 300.0)) * p.area_mult
		pr.setup(G.Team.PLAYER, p.pos + dir * 20.0, dir * float(st.spd) * p.proj_spd,
			float(st.dmg) * p.dmg_mult, 9.5 * p.area_mult, Px.C(str(DEFS.get(str(w.id), {}).get("col", "7fe0c3"))), "ring")
		pr.wpn = _fwpn
		pr.piercing = true
		pr.boomerang = true
		pr.life = 2.0 * reach / (float(st.spd) * p.proj_spd)
		pr.life0 = pr.life
		pr.knock = 4.0
	G.audio.play("shoot", 0.7, 0.6)

# telegraphed meteor strikes on random enemies — the ring marks the blast
# zone tel seconds ahead, so the swarm can still be herded into it
static func _meteor(st: Dictionary, p: Player, w: Dictionary) -> void:
	var n := maxi(1, roundi(float(st.n)))
	var r := float(st.r) * p.area_mult
	var tel := float(st.get("tel", 0.75))
	var dmg := float(st.dmg) * p.dmg_mult
	var pool := G.enemies.duplicate()
	for i in n:
		var at := Vector2.ZERO
		if pool.is_empty():
			at = p.pos + Vector2(G.rf(-260, 260), G.rf(-200, 200))
		else:
			var e: Enemy = pool[G.ri(0, pool.size() - 1)]
			pool.erase(e)
			if not is_instance_valid(e) or e.dead:
				continue
			at = e.pos
		_strike_tele(at, r, dmg, tel, p, str(w.id))

static func _mortar(st: Dictionary, p: Player, w: Dictionary) -> void:
	var n := maxi(1, roundi(float(st.n)))
	var r := float(st.r) * p.area_mult
	var tel := float(st.get("tel", 0.6))
	var dmg := float(st.dmg) * p.dmg_mult
	var frag := roundi(float(st.get("frag", 3.0)))
	var pool := G.enemies.duplicate()
	for i in n:
		var at := Vector2.ZERO
		if pool.is_empty():
			at = p.pos + Vector2(G.rf(-260, 260), G.rf(-200, 200))
		else:
			var e: Enemy = pool[G.ri(0, pool.size() - 1)]
			pool.erase(e)
			if not is_instance_valid(e) or e.dead:
				continue
			at = e.pos
		_strike_tele(at, r, dmg, tel, p, str(w.id), Color(0.55, 0.9, 1.0, 0.5), frag)

static func _strike_tele(at: Vector2, r: float, dmg: float, tel: float, p: Player, wid: String, col := Color(1.0, 0.45, 0.2, 0.5), frag := 0) -> void:
	var ring := Sprite2D.new()
	ring.texture = Px.S("ring")
	ring.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ring.modulate = col
	ring.scale = Vector2.ONE * (r * 2.0 / 96.0)
	ring.position = at
	ring.z_index = -1990
	G.game.world.add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "modulate:a", 0.9, tel * 0.8)
	p.get_tree().create_timer(tel, false).timeout.connect(func():
		if is_instance_valid(ring):
			ring.queue_free()
		if not is_instance_valid(p) or p.dead or G.state != G.State.ROOM:
			return
		for e in G.enemies.duplicate():
			if not is_instance_valid(e) or e.dead:
				continue
			if at.distance_to(e.pos) < r + e.hit_radius:
				var crit := G.chance(p.crit_ch)
				var h := {"dmg": dmg * (p.crit_mult if crit else 1.0), "type": G.DamageType.EXPLOSION, "from": at, "knock": 9.0, "stagger": 0.4, "source": p, "crit": crit, "wpn": wid}
				e.take_hit(h)
				p.on_dealt_damage(e, h)
		G.fx.burst(at, Color(col.r, col.g, col.b).lerp(Color.WHITE, 0.15), 16, 240.0, 6.0, 0.5)
		G.fx.shake(0.08, 0.1)
		if frag > 0 and is_instance_valid(G.run):
			G.run.drop_fragments(at, frag))
	G.audio.play("shoot", 0.5, 0.4)

static func _tick_orbit(w: Dictionary, p: Player, d: float) -> void:
	var st := stats(str(w.id), int(w.lvl))
	var want := maxi(1, roundi(float(st.n)) + p.bonus_proj)
	# (re)build orb sprites when the count changes
	var orbs: Array = w.get("orbs", [])
	while orbs.size() < want:
		var s := Sprite2D.new()
		s.texture = Px.S("ring")
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.modulate = Px.C(str(DEFS[w.id].get("col", "c26bff")))
		s.scale = Vector2.ONE * 0.34
		s.z_index = 45
		p.add_child(s)
		orbs.append(s)
	while orbs.size() > want:
		var s2: Sprite2D = orbs.pop_back()
		if is_instance_valid(s2):
			s2.queue_free()
	w.orbs = orbs
	var r := float(st.r) * p.area_mult
	var base := float(w.get("ang", 0.0)) + float(st.spin) * d
	w.ang = base
	for i in orbs.size():
		var off := Vector2.from_angle(base + TAU * i / orbs.size()) * r
		orbs[i].position = off
	w.tk = float(w.tk) - d
	if w.tk <= 0.0:
		w.tk = float(st.tk)
		var dmg := float(st.dmg) * p.dmg_mult
		for o in orbs:
			var op: Vector2 = p.pos + o.position
			for e in G.enemies:
				if not is_instance_valid(e) or e.dead:
					continue
				if op.distance_to(e.pos) < 24.0 + e.hit_radius:
					var crit := G.chance(p.crit_ch)
					var h := {"dmg": dmg * (p.crit_mult if crit else 1.0), "type": G.DamageType.SHOCK, "from": p.pos, "knock": 2.5, "stagger": 0.12, "source": p, "crit": crit, "wpn": str(w.id)}
					e.take_hit(h)
					p.on_dealt_damage(e, h)
					G.fx.burst(e.pos + Vector2(0, -8), Px.C("c26bff"), 2, 70.0, 2.5, 0.2)

static func _tick_pools(w: Dictionary, p: Player, d: float) -> void:
	var pools: Array = w.get("pools", [])
	for i in range(pools.size() - 1, -1, -1):
		var pl: Dictionary = pools[i]
		pl.t = float(pl.t) - d
		pl.acc = float(pl.acc) + d
		if float(pl.t) <= 0.0 or not is_instance_valid(pl.node):
			if is_instance_valid(pl.node):
				var tw: Tween = pl.node.create_tween()
				tw.tween_property(pl.node, "modulate:a", 0.0, 0.4)
				tw.tween_callback(pl.node.queue_free)
			pools.remove_at(i)
			continue
		if float(pl.acc) >= 0.35:
			var tick_dmg := float(pl.dps) * float(pl.acc)
			pl.acc = 0.0
			for e in G.enemies:
				if not is_instance_valid(e) or e.dead:
					continue
				if (pl.pos as Vector2).distance_to(e.pos) < float(pl.r) + e.hit_radius:
					var h := {"dmg": tick_dmg, "type": int(pl.get("type", G.DamageType.POISON)), "from": pl.pos, "knock": 0.0, "source": p, "wpn": str(pl.get("wpn", ""))}
					e.take_hit(h)
					p.on_dealt_damage(e, h)
					if bool(pl.get("chill", false)):
						e.chill_t = maxf(e.chill_t, 0.7)
						if is_instance_valid(e.body):
							e.body.modulate = Color(0.68, 0.88, 1.12)
	w.pools = pools
