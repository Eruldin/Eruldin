class_name Items
extends RefCounted

# HoT-style equipment: items drop during runs into the run bag, then move to
# the permanent stash (meta) on run end — win or lose. Equip at camp via
# Saphire's EŞYA panel; equipped stat mods apply at run start.
#
# slots: bas govde eldiven cizme kolye yuzuk1 yuzuk2 kemer  (8 slots)
const SLOTS := ["bas", "govde", "eldiven", "cizme", "kolye", "yuzuk1", "yuzuk2", "kemer"]
const SLOT_NAME := {
	"bas": "BAŞLIK", "govde": "GÖVDE", "eldiven": "ELDİVEN", "cizme": "ÇİZME",
	"kolye": "KOLYE", "yuzuk1": "YÜZÜK I", "yuzuk2": "YÜZÜK II", "kemer": "KEMER",
}

# mods keys applied in Player.reset_for_run / stats():
#   hp, armor, dmg (%), spd (%), crit (flat add), critmult, ls (lifesteal %),
#   mag (magnet radius), xp (%), frag (%), dash_regen (%), revive
# rarity: 0 ortak (gri) / 1 nadir (cyan) / 2 efsane (altın)
const DEFS := {
	"i_migfer":   {"name": "Savaş Miğferi",    "slot": "bas",     "r": 0, "icon": "icn_upg_hp",     "mods": {"hp": 25}},
	"i_maske":    {"name": "Avcı Maskesi",     "slot": "bas",     "r": 1, "icon": "icn_skull",      "mods": {"crit": 0.06}},
	"i_halo":     {"name": "Rezonans Tacı",    "slot": "bas",     "r": 2, "icon": "icn_crown",      "mods": {"hp": 15, "xp": 0.10}},
	"i_zirh":     {"name": "Plaka Zırh",       "slot": "govde",   "r": 0, "icon": "icn_upg_shield", "mods": {"armor": 1.5}},
	"i_palto":    {"name": "Gezgin Paltosu",   "slot": "govde",   "r": 0, "icon": "icn_dash",       "mods": {"spd": 0.06}},
	"i_aegis":    {"name": "Aeterna Gömleği",  "slot": "govde",   "r": 2, "icon": "icn_upg_shield", "mods": {"armor": 1.0, "hp": 30}},
	"i_pel":      {"name": "Plazma Eldiveni",  "slot": "eldiven", "r": 0, "icon": "icn_dagger",     "mods": {"dmg": 0.07}},
	"i_hirsiz":   {"name": "Hırsız Eldiveni",  "slot": "eldiven", "r": 1, "icon": "ico_frag",       "mods": {"mag": 55.0}},
	"i_yumruk":   {"name": "Şövalye Yumruğu",  "slot": "eldiven", "r": 2, "icon": "icn_sword",      "mods": {"dmg": 0.12, "critmult": 0.3}},
	"i_cizme":    {"name": "Yürüyüş Çizmesi",  "slot": "cizme",   "r": 0, "icon": "icn_dash",       "mods": {"spd": 0.05}},
	"i_ruzgar":   {"name": "Rüzgar Patikleri", "slot": "cizme",   "r": 1, "icon": "icn_dash",       "mods": {"spd": 0.07, "dash_regen": 0.15}},
	"i_merdiven": {"name": "Abis Çivileri",    "slot": "cizme",   "r": 2, "icon": "icn_dash",       "mods": {"spd": 0.10, "armor": 0.5}},
	"i_kolye":    {"name": "Choralim Kolyesi", "slot": "kolye",   "r": 0, "icon": "ico_frag",       "mods": {"xp": 0.08}},
	"i_kantas":   {"name": "Kan Taşı",         "slot": "kolye",   "r": 1, "icon": "icn_skull",      "mods": {"ls": 0.02}},
	"i_neva":     {"name": "Neva'nın Damlası", "slot": "kolye",   "r": 2, "icon": "icn_crown",      "mods": {"xp": 0.12, "revive": 1}},
	"i_halka1":   {"name": "Şimşek Halkası",   "slot": "yuzuk",   "r": 0, "icon": "icn_zap",        "mods": {"dmg": 0.05}},
	"i_halka2":   {"name": "Cüruf Halkası",    "slot": "yuzuk",   "r": 0, "icon": "icn_mine",       "mods": {"frag": 0.10}},
	"i_ikiz":     {"name": "İkiz Halka",       "slot": "yuzuk",   "r": 1, "icon": "icn_kovan",      "mods": {"dmg": 0.06, "spd": 0.04}},
	"i_final":    {"name": "Son Mühür",        "slot": "yuzuk",   "r": 2, "icon": "icn_crown",      "mods": {"dmg": 0.10, "crit": 0.05}},
	# derinlik dalgası — her slota r1/r2 kapağı
	"i_gocek":    {"name": "Gözcü Vizörü",     "slot": "bas",     "r": 1, "icon": "icn_zap",        "mods": {"mag": 45.0, "xp": 0.05}},
	"i_ormek":    {"name": "Örümcek Ağı",      "slot": "govde",   "r": 1, "icon": "icn_kovan",      "mods": {"spd": 0.05, "ls": 0.01}},
	"i_bilek":    {"name": "Keskin Bileklik",  "slot": "eldiven", "r": 1, "icon": "icn_dagger",     "mods": {"crit": 0.08}},
	"i_atlama":   {"name": "Atlayıcı Çivisi",  "slot": "cizme",   "r": 1, "icon": "icn_dash",       "mods": {"armor": 1.0, "spd": 0.03}},
	"i_koro":     {"name": "Koro Madalyonu",   "slot": "kolye",   "r": 1, "icon": "ico_frag",       "mods": {"frag": 0.12}},
	"i_bosluk":   {"name": "Boşluk Halkası",   "slot": "yuzuk",   "r": 2, "icon": "icn_skull",      "mods": {"ls": 0.03, "crit": 0.04}},
	# üçüncü dalga — boş stat kovalarını dolduran orta katman
	"i_firis":    {"name": "Feragat Başlığı",  "slot": "bas",     "r": 0, "icon": "icn_upg_dash",   "mods": {"dash_regen": 0.12}},
	"i_hisar":    {"name": "Hisar Kalkanı",    "slot": "govde",   "r": 1, "icon": "icn_upg_shield", "mods": {"armor": 2.0, "spd": -0.02}},
	"i_cevher":   {"name": "Cevher Yüzüğü",    "slot": "yuzuk",   "r": 0, "icon": "ico_frag",       "mods": {"frag": 0.08, "xp": 0.04}},
	"i_sivriasi": {"name": "Sivri Aşısı",      "slot": "kolye",   "r": 1, "icon": "icn_zap",        "mods": {"spd": 0.04, "ls": 0.01}},
	"i_cengel":   {"name": "Av Çengeli",       "slot": "eldiven", "r": 2, "icon": "icn_sword",      "mods": {"dmg": 0.08, "ls": 0.015}},
	"i_pusula":   {"name": "Kuzey Pusulası",   "slot": "kolye",   "r": 2, "icon": "icn_dash",       "mods": {"xp": 0.10, "mag": 50.0}},
	"i_buzkalp":  {"name": "Buz Kalbi",        "slot": "kolye",   "r": 1, "icon": "icn_upg_shield", "mods": {"hp": 20, "armor": 0.5}},
	"i_kiragi":   {"name": "Kırağı Kıskacı",   "slot": "yuzuk2",  "r": 2, "icon": "icn_sword",      "mods": {"dmg": 0.10, "crit": 0.05}},
	"i_nabiz":    {"name": "Nabız Söndürücü",  "slot": "kolye",   "r": 2, "icon": "icn_zap",        "mods": {"skill": -0.16}},
	"i_igne":     {"name": "İğne Kını",        "slot": "kemer",   "r": 2, "icon": "icn_dagger",     "mods": {"crit": 0.08, "dmg": 0.08}},
	"i_gozcu":    {"name": "Gözcü Merceği",    "slot": "kolye",   "r": 2, "icon": "icn_zap",        "mods": {"critmult": 0.25, "dmg": 0.05}},
	"i_kurtdis":  {"name": "Kurt Dişi Dizi",   "slot": "kolye",   "r": 1, "icon": "ico_frag",       "mods": {"frag": 0.10, "spd": 0.03}},
	"i_sarj":     {"name": "Şarj Kayışı",      "slot": "kemer",   "r": 2, "icon": "icn_zap",        "mods": {"skill": -0.10, "spd": 0.04}},
	"i_fitil":    {"name": "Fitil Yüzüğü",     "slot": "yuzuk2",  "r": 1, "icon": "icn_mine",      "mods": {"dmg": 0.05, "crit": 0.04}},
	"i_tuy":      {"name": "Kuzgun Tüyü Dizi", "slot": "kolye",   "r": 1, "icon": "icn_dash",      "mods": {"spd": 0.04, "crit": 0.03}},
	"i_boynuz":   {"name": "Kocboynuz Pencesi","slot": "kolye",   "r": 2, "icon": "icn_upg_dmg",   "mods": {"dmg": 0.06, "hp": 10}},
	"i_korkul":   {"name": "Kor Külü Kolyesi","slot": "kolye",   "r": 2, "icon": "icn_mine",      "mods": {"dmg": 0.05, "crit": 0.04}},
	"i_firtina":  {"name": "Fırtına Gözü",   "slot": "kolye",   "r": 2, "icon": "icn_dash",       "mods": {"spd": 0.08, "crit": 0.05}},
	"i_zehir":    {"name": "Zehir Bezi",      "slot": "kolye",   "r": 2, "icon": "icn_mine",       "mods": {"hp": 18, "ls": 0.02}},
	"i_hayalet":  {"name": "Hayalet Pelerini","slot": "govde",   "r": 3, "icon": "icn_dash",       "mods": {"spd": 0.08, "armor": 1.5, "ls": 0.02}},
	"i_sunak":    {"name": "Sunak Damarı",    "slot": "yuzuk2",  "r": 2, "icon": "icn_skull",      "mods": {"ls": 0.03, "dmg": 0.04}},
	"i_efendin":  {"name": "Efendi Nişanı",   "slot": "kolye",   "r": 3, "icon": "icn_crown",      "mods": {"dmg": 0.06, "armor": 1.0}},
	"i_duel":     {"name": "Düello Yankısı",  "slot": "kemer",   "r": 3, "icon": "icn_dagger",     "mods": {"dmg": 0.05, "crit": 0.06}},
	"i_devriye":  {"name": "Devriye Nişanı",  "slot": "kemer",   "r": 3, "icon": "icn_upg_mag",    "mods": {"dmg": 0.04, "frag": 0.14, "mag": 20.0}},
	"i_konvoy":   {"name": "Konvoy Pusulası", "slot": "kolye",   "r": 2, "icon": "ico_frag",       "mods": {"frag": 0.15, "mag": 35.0}},
	"i_kaos":     {"name": "Kararsız Çekirdek","slot": "kemer",  "r": 3, "icon": "icn_skull",      "mods": {"dmg": 0.08, "crit": 0.05, "hp": -10}},
	"i_ritim":    {"name": "Ritim Bileziği",  "slot": "yuzuk2",  "r": 2, "icon": "icn_dagger",     "mods": {"crit": 0.05, "skill": -0.04}},
	"i_kacakkordon": {"name": "Kese Kordonu", "slot": "kemer",   "r": 2, "icon": "ico_frag",       "mods": {"frag": 0.10, "spd": 0.05}},
	"i_yanki":   {"name": "Yankı Taşı",      "slot": "yuzuk2",  "r": 2, "icon": "ico_frag",       "mods": {"mag": 50.0, "frag": 0.08}},
	"i_manset":  {"name": "Muhafız Manşeti", "slot": "eldiven", "r": 3, "icon": "icn_upg_shield", "mods": {"armor": 0.7, "dmg": 0.06, "hp": 10}},
	"i_nara":    {"name": "Nara Boynuzu",    "slot": "bas",     "r": 3, "icon": "icn_skull",      "mods": {"dmg": 0.08, "ls": 0.02}},
	"i_arkhalka": {"name": "Ark Bileziği",    "slot": "yuzuk1",  "r": 2, "icon": "icn_zap",        "mods": {"skill": -0.06, "dmg": 0.04}},
	"i_bora":     {"name": "Bora Zili",       "slot": "kemer",   "r": 2, "icon": "icn_dash",       "mods": {"spd": 0.05, "armor": 0.5}},
	"i_ayin":     {"name": "Ayin Mumusu",     "slot": "eldiven", "r": 2, "icon": "icn_skull",      "mods": {"dmg": 0.05, "crit": 0.03}},
	"i_vahde":    {"name": "Vahde Miğferi",   "slot": "bas",     "r": 2, "icon": "icn_crown",      "mods": {"dmg": 0.06, "hp": 10}},
	"i_ocak":     {"name": "Ocak Çivisi",     "slot": "bas",     "r": 2, "icon": "icn_mine",       "mods": {"dmg": 0.05, "armor": 0.8}},
	"i_ocakmohur":{"name": "Ocak Mührü",      "slot": "kolye",   "r": 2, "icon": "ico_frag",       "mods": {"hp": 10, "frag": 0.05}},
	"i_zar":      {"name": "Tegan'ın Zarı",    "slot": "kolye",   "r": 2, "icon": "ico_frag",       "mods": {"frag": 0.08, "crit": 0.04}},
	"i_barut":    {"name": "Barut Başlığı",    "slot": "bas",     "r": 1, "icon": "icn_mine",      "mods": {"dmg": 0.04, "hp": 12}},
	"i_vurgu":    {"name": "Vurgu Halkası",    "slot": "yuzuk",   "r": 1, "icon": "icn_dagger",     "mods": {"skill": -0.09, "dmg": 0.03}},
	"i_anasi_igne": {"name": "Kraliçe İğnesi", "slot": "yuzuk",   "r": 3, "icon": "icn_dagger",     "mods": {"crit": 0.10, "ls": 0.02}},
	# EFSANEVİ (r4) — düşmez, sadece altın şampiyonlardan/orta efendilerden kopar
	"i_koroses": {"name": "Koro'nun Sesi",    "slot": "kemer",   "r": 4, "icon": "icn_zap",        "mods": {"dmg": 0.12, "skill": -0.12}},
	"i_praetoryuz":{"name": "Praetor Yüzüğü",  "slot": "yuzuk2",  "r": 4, "icon": "icn_dagger",     "mods": {"crit": 0.08, "critmult": 0.40}},
	"i_hanimzil": {"name": "Hanım'ın Zili",   "slot": "kolye",   "r": 4, "icon": "icn_crown",      "mods": {"xp": 0.15, "ls": 0.03, "hp": 20}},
	"i_vahdettir":{"name": "Vahdet Tırnağı",  "slot": "eldiven", "r": 4, "icon": "icn_sword",      "mods": {"dmg": 0.15, "spd": -0.03}},
	"i_ufukcizme":{"name": "Ufuk Çizmeleri",  "slot": "cizme",  "r": 4, "icon": "icn_dash",       "mods": {"spd": 0.12, "dash_regen": 0.25}},
	"i_kalpgoz": {"name": "Kalp Gözü",        "slot": "bas",    "r": 4, "icon": "icn_crown",      "mods": {"crit": 0.10, "mag": 60.0, "xp": 0.10}},
	"i_devkalp": {"name": "Batak Kalbi",     "slot": "kolye",   "r": 3, "icon": "icn_kovan",      "mods": {"hp": 40, "armor": 0.8}},
	"i_kortac":  {"name": "Kor Tacı",        "slot": "bas",     "r": 3, "icon": "icn_crown",      "mods": {"dmg": 0.08, "skill": -0.10}},
	"i_balcikkalp": {"name": "Balçık Kalbi", "slot": "kolye",   "r": 3, "icon": "icn_kovan",      "mods": {"hp": 30, "ls": 0.02}},
	"i_praetorian": {"name": "Praetorian Gövdesi", "slot": "govde", "r": 3, "icon": "icn_upg_shield", "mods": {"hp": 60, "armor": 1.2}},
	"i_soykemer": {"name": "Soy Kemeri",      "slot": "kemer",   "r": 3, "icon": "icn_crown",      "mods": {"dmg": 0.07, "xp": 0.10}},
	"i_efendipence": {"name": "Efendi Pencesi", "slot": "eldiven", "r": 3, "icon": "icn_dagger",   "mods": {"dmg": 0.10, "crit": 0.05}},
	"i_kozcizme": {"name": "Koz Çizmesi",     "slot": "cizme",   "r": 3, "icon": "icn_dash",       "mods": {"spd": 0.05, "dash_regen": 0.20}},
	"i_nuve":     {"name": "Nüve Halkası",    "slot": "yuzuk",   "r": 3, "icon": "ico_frag",       "mods": {"frag": 0.18, "mag": 45.0}},
	"i_damar":    {"name": "Damar Mührü",     "slot": "yuzuk2",  "r": 3, "icon": "icn_mine",       "mods": {"mag": 60.0, "xp": 0.12}},
	"i_golkalp":  {"name": "Golem Yumruğu",   "slot": "eldiven", "r": 2, "icon": "icn_sword",      "mods": {"dmg": 0.09, "hp": 8}},
	"i_kalpparca":{"name": "Kalp Parçası",    "slot": "yuzuk",   "r": 3, "icon": "icn_mine",       "mods": {"dmg": 0.08, "mag": 40.0}},
	"i_nabizcek":{"name": "Nabız Kemeri",     "slot": "kemer",   "r": 3, "icon": "icn_zap",        "mods": {"hp": 25, "armor": 0.8, "skill": -0.08}},
	"i_jeotgoz": {"name": "Jeot Gözü",        "slot": "kolye",   "r": 2, "icon": "icn_mine",       "mods": {"mag": 35.0, "frag": 0.08}},
	"i_fisilti": {"name": "Fısıltı Küpesi",   "slot": "yuzuk2",  "r": 1, "icon": "icn_mine",       "mods": {"xp": 0.10, "spd": 0.03}},
	# kemer slotu — 8. ekipman yuvası
	"i_kemer_kum": {"name": "Kum Kemeri",      "slot": "kemer",   "r": 0, "icon": "icn_dash",       "mods": {"spd": 0.04, "mag": 25.0}},
	"i_kemer_par": {"name": "Parazit Kemeri",  "slot": "kemer",   "r": 1, "icon": "icn_kovan",      "mods": {"hp": 18, "ls": 0.015}},
	"i_kemer_ef":  {"name": "Efendi Tokası",   "slot": "kemer",   "r": 2, "icon": "icn_crown",      "mods": {"skill": -0.12, "armor": 0.6}},
	"i_duvar":     {"name": "Yemin Plakası",   "slot": "govde",   "r": 3, "icon": "icn_upg_shield", "mods": {"hp": 45, "armor": 1.0, "spd": -0.03}},
	"i_pelerin":   {"name": "İhbarcı Pelerini","slot": "govde",   "r": 2, "icon": "icn_dash",       "mods": {"spd": 0.06, "hp": 12}},
	"i_onluk":     {"name": "Ocak Önlüğü",     "slot": "govde",   "r": 2, "icon": "icn_upg_shield", "mods": {"hp": 22, "armor": 0.6}},
	"i_tayfperde": {"name": "Tayf Pelerini",   "slot": "govde",   "r": 3, "icon": "icn_dash",       "mods": {"spd": 0.06, "dash_regen": 0.18, "skill": -0.06}},
	"i_nurfener": {"name": "Ufuk Feneri",     "slot": "kolye",   "r": 3, "icon": "icn_crown",      "mods": {"skill": -0.12, "xp": 0.12, "ls": 0.02, "frag": 0.1}},
	# yansıtma (thorns): alınan yakın dövüş hasarının bir kısmı saldırana döner
	"i_dikenman": {"name": "Dikenli Manşon",  "slot": "eldiven", "r": 2, "icon": "icn_upg_shield", "mods": {"armor": 0.8, "thorns": 0.18}},
	"i_kirpikemer":{"name": "Kirpi Kuşağı",   "slot": "kemer",   "r": 2, "icon": "icn_kovan",      "mods": {"hp": 14, "thorns": 0.15}},
	"i_dikenyuzuk":{"name": "Diken Yüzüğü",   "slot": "yuzuk",   "r": 3, "icon": "icn_dagger",     "mods": {"thorns": 0.25, "crit": 0.03}},
	# özel eklentiler: kuşanılınca Q özeli değişir (sp_* modu)
	"i_goktas":   {"name": "Gök Parçası",     "slot": "kolye",   "r": 3, "icon": "icn_mine",      "mods": {"sp_meteor": 1, "dmg": 0.05}},
	"i_simges":   {"name": "Şimşek Simgesi",  "slot": "yuzuk2",  "r": 3, "icon": "icn_zap",       "mods": {"sp_firtina": 1, "crit": 0.05}},
	"i_dagances": {"name": "Dağanç Esi",      "slot": "kemer",   "r": 3, "icon": "icn_sword",     "mods": {"sp_daganc": 1, "hp": 15}},
	"i_nabiztas": {"name": "Nabız Taşı",      "slot": "kolye",   "r": 2, "icon": "icn_zap",       "mods": {"mangain": 0.35, "hp": 8}},
}

const RARITY_COL := ["9aa0b0", "42d4f4", "ffd700", "ff4fd8", "f5f5f5"]
const RARITY_NAME := ["ORTAK", "NADİR", "EFSANE", "DESTANSI", "EFSANEVİ"]

# drop table weights per rarity; nadir/efsane need luck to matter
static func roll(luck: float) -> String:
	var w0 := 70.0
	var w1 := 26.0 + luck * 30.0
	var w2 := 4.0 + luck * 14.0
	var r := G.rf(0.0, w0 + w1 + w2)
	var rar := 0
	if r > w0 + w1:
		rar = 2
	elif r > w0:
		rar = 1
	var pool: Array = []
	for id in DEFS:
		if int(DEFS[id].r) == rar and not _in_stash(id):
			pool.append(id)
	if pool.is_empty():
		# already own everything at that rarity — fall back to any unowned drop-tier item
		for id in DEFS:
			if not _in_stash(id) and int(DEFS[id].r) < 3:
				pool.append(id)
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]

static func _in_stash(id: String) -> bool:
	var st: Array = G.meta.data.get("stash", [])
	var eq: Dictionary = G.meta.data.get("equip", {})
	return st.has(id) or eq.values().has(id)

# drop during a run → into the run's loot bag
# efsanevi havuzu: sahip olunmayan r4 parçaları (şampiyon düşüşüne ayrık)
static func legendary_ids() -> Array:
	var pool: Array = []
	for id in DEFS:
		if int(DEFS[id].r) == 4 and not _in_stash(id):
			pool.append(id)
	return pool

static func drop_to_run(id: String) -> void:
	if id == "" or not DEFS.has(id):
		return
	var bag: Array = G.run.stats.get("loot", [])
	bag.append(id)
	G.run.stats["loot"] = bag
	# koleksiyon: görülen her farklı eşya kalıcı kayda geçer
	var seen: Array = G.meta.data.get("items_seen", [])
	if not seen.has(id):
		seen.append(id)
		G.meta.data["items_seen"] = seen
	var d: Dictionary = DEFS[id]
	G.ui.toast("%s bulundu: %s" % [RARITY_NAME[int(d.r)], str(d.name)])
	if int(d.r) >= 3:
		# destansi+ alım anı: dopamin patlaması
		G.fx.flash(Px.C(RARITY_COL[int(d.r)]), 0.25)
		G.fx.shake(0.18, 0.25)
		G.ui.banner(str(d.name), "%s — zulana katıldı" % RARITY_NAME[int(d.r)])
		G.audio.jingle("legendary")
	else:
		G.audio.jingle("boon")

# end of run: bag moves into the permanent stash
static func bank_bag() -> int:
	var bag: Array = G.run.stats.get("loot", [])
	if bag.is_empty():
		return 0
	var st: Array = G.meta.data.get("stash", [])
	for id in bag:
		if not st.has(id):
			st.append(id)
	G.meta.data["stash"] = st
	G.meta.data["loot_found"] = int(G.meta.data.get("loot_found", 0)) + bag.size()
	G.meta.save()
	G.run.stats["loot"] = []
	return bag.size()

static func equip(id: String, slot: String) -> void:
	var eq: Dictionary = G.meta.data.get("equip", {})
	var st: Array = G.meta.data.get("stash", [])
	# rings: either ring slot
	if slot == "yuzuk":
		slot = "yuzuk1" if str(eq.get("yuzuk1", "")) == "" else "yuzuk2"
	# unequip whatever sat there back into stash
	var old := str(eq.get(slot, ""))
	if old != "":
		st.append(old)
	eq[slot] = id
	st.erase(id)
	G.meta.data["equip"] = eq
	G.meta.data["stash"] = st
	G.meta.save()

static func unequip(slot: String) -> void:
	var eq: Dictionary = G.meta.data.get("equip", {})
	var st: Array = G.meta.data.get("stash", [])
	var old := str(eq.get(slot, ""))
	if old == "":
		return
	eq.erase(slot)
	st.append(old)
	G.meta.data["equip"] = eq
	G.meta.data["stash"] = st
	G.meta.save()

# aggregate all equipped mods into one dict of multipliers/adds
# set bonusları (BG2 tarzı): listenin tüm parçaları kuşanılınca ekstra mod
const SETS := {
	"avci":     {"name": "AVCI SETİ",     "ids": ["i_maske", "i_bilek"],          "mods": {"dmg": 0.10, "crit": 0.03}},
	"gezgin":   {"name": "GEZGİN SETİ",   "ids": ["i_palto", "i_ruzgar"],         "mods": {"spd": 0.08, "dash_regen": 0.10}},
	"rezonans": {"name": "REZONANS SETİ", "ids": ["i_halo", "i_neva", "i_koro"],  "mods": {"xp": 0.15, "frag": 0.10}},
	"bosluk":   {"name": "BOŞLUK SETİ",   "ids": ["i_bosluk", "i_final"],         "mods": {"ls": 0.04, "dmg": 0.05}},
	"sovalye":  {"name": "ŞÖVALYE SETİ",  "ids": ["i_duvar", "i_hayalet", "i_efendin", "i_duel"], "mods": {"hp": 40, "armor": 2.0}},
}

# tamamı kuşanılmış mı — başarım kontrolü için
static func set_active(sid: String) -> bool:
	if not SETS.has(sid):
		return false
	var eq: Dictionary = G.meta.data.get("equip", {})
	var worn: Array = eq.values()
	for iid in SETS[sid].ids:
		if not worn.has(iid):
			return false
	return true

static func equip_stats() -> Dictionary:
	var out := {"hp": 0.0, "armor": 0.0, "dmg": 0.0, "spd": 0.0, "crit": 0.0,
		"critmult": 0.0, "ls": 0.0, "mag": 0.0, "xp": 0.0, "frag": 0.0,
		"dash_regen": 0.0, "revive": 0, "skill": 0.0}
	var eq: Dictionary = G.meta.data.get("equip", {})
	var worn: Array = eq.values()
	for slot in eq:
		var id := str(eq[slot])
		if not DEFS.has(id):
			continue
		for k in DEFS[id].mods:
			var m := float(DEFS[id].mods[k])
			out[k] = float(out.get(k, 0.0)) + (m if k == "revive" else m * _lscale(id))
	for sid in SETS:
		var s: Dictionary = SETS[sid]
		var ok := true
		for iid in s.ids:
			if not worn.has(iid):
				ok = false
				break
		if ok:
			for k in s.mods:
				out[k] = float(out.get(k, 0.0)) + float(s.mods[k])
	return out

# envanter paneline ilerleme satırları: {name, have, need, active}
static func set_state() -> Array:
	var eq: Dictionary = G.meta.data.get("equip", {})
	var worn: Array = eq.values()
	var out := []
	for sid in SETS:
		var s: Dictionary = SETS[sid]
		var have := 0
		for iid in s.ids:
			if worn.has(iid):
				have += 1
		out.append({"name": str(s.name), "have": have, "need": (s.ids as Array).size(), "active": have == (s.ids as Array).size()})
	return out

# sasi gelistirme — ELY-B panelinde choralim ile alinan kalici perkler
# (sasi basina 2; mod anahtarlari equip_stats ile ayni sozluk)
const PERKS := {
	"ely":  [{"id": "ely_p1",  "name": "Keskin Geometri",    "desc": "+%6 hasar",          "cost": 300, "mods": {"dmg": 0.06}},
	          {"id": "ely_p2",  "name": "Nova Sogutucu",      "desc": "Q bekleme -%12",     "cost": 400, "mods": {"skill": -0.12}}],
	"elyb": [{"id": "elyb_p1", "name": "Agir Balistik",      "desc": "+%8 hasar",          "cost": 350, "mods": {"dmg": 0.08}},
	          {"id": "elyb_p2", "name": "Reaksiyon Zirhi",    "desc": "+1.0 zirh",          "cost": 350, "mods": {"armor": 1.0}}],
	"via":  [{"id": "via_p1",  "name": "Kesif Rotorlari",    "desc": "+%6 hiz",            "cost": 300, "mods": {"spd": 0.06}},
	          {"id": "via_p2",  "name": "Nisan Modulu",       "desc": "+%8 kritik",         "cost": 400, "mods": {"crit": 0.08}}],
	"h9":   [{"id": "h9_p1",   "name": "Derin Manyetik",     "desc": "+70 toplama yaricapi","cost": 300, "mods": {"mag": 70.0}},
	          {"id": "h9_p2",   "name": "Hurda Verimi",       "desc": "+%10 parcacik",      "cost": 400, "mods": {"frag": 0.10}}],
	"k7":   [{"id": "k7_p1",   "name": "Duvar Refleksi",     "desc": "+40 can",            "cost": 350, "mods": {"hp": 40}},
	          {"id": "k7_p2",   "name": "Siginak Akusu",      "desc": "Q bekleme -%10",     "cost": 400, "mods": {"skill": -0.10}}],
	"dg":   [{"id": "dg_p1",   "name": "Damar Takviyesi",    "desc": "+50 can · +0.5 zirh","cost": 450, "mods": {"hp": 50, "armor": 0.5}},
	          {"id": "dg_p2",   "name": "Kristal Asiriyukleme","desc": "+%7 hasar",         "cost": 450, "mods": {"dmg": 0.07}}],
}

# aktif sasinin alinmis perklerinin mod toplami
static func perk_stats(hid: String) -> Dictionary:
	var out := {}
	var owned: Array = (G.meta.data.get("perks", {}) as Dictionary).get(hid, [])
	for p in PERKS.get(hid, []):
		if owned.has(p.id):
			for k in p.mods:
				out[k] = float(out.get(k, 0.0)) + float(p.mods[k])
	return out

static func slot_of(id: String) -> String:
	return str(DEFS.get(id, {}).get("slot", ""))

# işleme: Saphire eşyayı choralim karşılığında +3'e kadar işler —
# modlar işleme seviyesi başına %30 ölçeklenir (grind / para gideri)
static func item_lvl(id: String) -> int:
	return int(G.meta.data.get("item_lvl", {}).get(id, 0))

static func _lscale(id: String) -> float:
	return 1.0 + 0.30 * item_lvl(id)

static func disp_name(id: String) -> String:
	var n := str(DEFS.get(id, {}).get("name", id))
	var l := item_lvl(id)
	return "%s +%d" % [n, l] if l > 0 else n

static func forge_price(id: String) -> int:
	var d: Dictionary = DEFS.get(id, {})
	if d.is_empty() or item_lvl(id) >= 3:
		return 0
	return Quests.rep_price(int([70, 130, 240, 420, 700][mini(int(d.r), 4)] * (item_lvl(id) + 1) * (0.75 if G.meta.has_build("atolye") else 1.0)))

static func forge(id: String) -> int:
	var p := forge_price(id)
	if p <= 0 or int(G.meta.data.get("choralim", 0)) < p:
		return 0
	G.meta.data["choralim"] -= p
	var lv: Dictionary = G.meta.data.get("item_lvl", {})
	lv[id] = item_lvl(id) + 1
	G.meta.data["item_lvl"] = lv
	G.meta.save()
	return p

# grind→para: zuladaki eşyayı choralim'e çevir (rarity başına fiyat)
static func sell_price(id: String) -> int:
	var d: Dictionary = DEFS.get(id, {})
	if d.is_empty():
		return 0
	return [20, 50, 110, 190, 320][mini(int(d.r), 4)]

static func sell(id: String) -> int:
	var st: Array = G.meta.data.get("stash", [])
	if not st.has(id):
		return 0
	st.erase(id)
	G.meta.data["stash"] = st
	var lv: Dictionary = G.meta.data.get("item_lvl", {})
	lv.erase(id)
	G.meta.data["item_lvl"] = lv
	var p := sell_price(id)
	G.meta.data["choralim"] = int(G.meta.data.get("choralim", 0)) + p
	G.meta.save()
	return p

# kamp tezgâhı: koşu sayısına bağlı yenilenen 3'lü stok — choralim'in harcama yeri
const SHOP_N := 3

static func shop_stock() -> Array:
	var gen := int(G.meta.data.get("runs", 0))
	var stock: Array = G.meta.data.get("shop_stock", [])
	if int(G.meta.data.get("shop_gen", -1)) != gen:
		var pool: Array = []
		for id in DEFS:
			if not _in_stash(id) and int(DEFS[id].r) < 3:  # r3 = görev/boss ganimeti, tezgâha çıkmaz
				pool.append(id)
		pool.shuffle()
		stock = pool.slice(0, mini(SHOP_N, pool.size()))
		G.meta.data["shop_stock"] = stock
		G.meta.data["shop_gen"] = gen
		G.meta.save()
	return stock

static func buy_price(id: String) -> int:
	return Quests.rep_price(sell_price(id) * 3)

# 0 = stokta yok · -1 = choralim yetmez · >0 = alındı (ödenen fiyat)
static func buy(id: String) -> int:
	var st: Array = shop_stock()
	if not st.has(id):
		return 0
	var p := buy_price(id)
	if int(G.meta.data.get("choralim", 0)) < p:
		return -1
	G.meta.data["choralim"] -= p
	st.erase(id)
	G.meta.data["shop_stock"] = st
	var bag: Array = G.meta.data.get("stash", [])
	bag.append(id)
	G.meta.data["stash"] = bag
	G.meta.save()
	return p

# hurda takası: 2 zula eşyası → 1 yeni eşya; nadirlik ≥ ikisinin düşük olanı.
# koleksiyon doluysa "full" döner ve eşyalar yanmaz.
static func barter(a: String, b: String) -> String:
	if a == b:
		return ""
	var st: Array = G.meta.data.get("stash", [])
	if not st.has(a) or not st.has(b):
		return ""
	var rmin := mini(int(DEFS.get(a, {}).get("r", 0)), int(DEFS.get(b, {}).get("r", 0)))
	var pool: Array = []
	for id in DEFS:
		if int(DEFS[id].r) >= rmin and not _in_stash(id):
			pool.append(id)
	if pool.is_empty():
		for id in DEFS:
			if not _in_stash(id):
				pool.append(id)
	if pool.is_empty():
		return "full"
	st.erase(a)
	st.erase(b)
	var nid: String = pool[randi() % pool.size()]
	st.append(nid)
	G.meta.data["stash"] = st
	G.meta.save()
	return nid

# tek satırlık mod özeti — envanter kartlarında gösterilir
static func stat_text(id: String) -> String:
	var d: Dictionary = DEFS.get(id, {})
	if d.is_empty():
		return ""
	var names := {"hp": "can", "armor": "zırh", "dmg": "hasar", "spd": "hız",
		"crit": "kritik", "critmult": "kritik×", "ls": "can emme", "mag": "mıknatıs",
		"xp": "XP", "frag": "parçacık", "dash_regen": "dash yenileme", "revive": "dirilme",
		"skill": "Q bekleme", "thorns": "yansıtma"}
	var parts: Array = []
	for k in d.mods:
		var f := float(d.mods[k]) * (1.0 if k == "revive" else _lscale(id))
		var fmt := "%+d" % int(f) if absf(f) >= 1.5 else "%+d%%" % int(f * 100)
		parts.append("%s %s" % [fmt, names.get(k, k)])
	return "  ".join(parts)
