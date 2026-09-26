class_name Items
extends RefCounted

# HoT-style equipment: items drop during runs into the run bag, then move to
# the permanent stash (meta) on run end — win or lose. Equip at camp via
# Saphire's EŞYA panel; equipped stat mods apply at run start.
#
# slots: bas govde eldiven cizme kolye yuzuk1 yuzuk2  (7 slots, HoT parity)
const SLOTS := ["bas", "govde", "eldiven", "cizme", "kolye", "yuzuk1", "yuzuk2"]
const SLOT_NAME := {
	"bas": "BAŞLIK", "govde": "GÖVDE", "eldiven": "ELDİVEN", "cizme": "ÇİZME",
	"kolye": "KOLYE", "yuzuk1": "YÜZÜK I", "yuzuk2": "YÜZÜK II",
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
}

const RARITY_COL := ["9aa0b0", "42d4f4", "ffd700"]
const RARITY_NAME := ["ORTAK", "NADİR", "EFSANE"]

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
		# already own everything at that rarity — fall back to any unowned
		for id in DEFS:
			if not _in_stash(id):
				pool.append(id)
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]

static func _in_stash(id: String) -> bool:
	var st: Array = G.meta.data.get("stash", [])
	var eq: Dictionary = G.meta.data.get("equip", {})
	return st.has(id) or eq.values().has(id)

# drop during a run → into the run's loot bag
static func drop_to_run(id: String) -> void:
	if id == "" or not DEFS.has(id):
		return
	var bag: Array = G.run.stats.get("loot", [])
	bag.append(id)
	G.run.stats["loot"] = bag
	var d: Dictionary = DEFS[id]
	G.ui.toast("%s bulundu: %s" % [RARITY_NAME[int(d.r)], str(d.name)])
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
static func equip_stats() -> Dictionary:
	var out := {"hp": 0.0, "armor": 0.0, "dmg": 0.0, "spd": 0.0, "crit": 0.0,
		"critmult": 0.0, "ls": 0.0, "mag": 0.0, "xp": 0.0, "frag": 0.0,
		"dash_regen": 0.0, "revive": 0}
	var eq: Dictionary = G.meta.data.get("equip", {})
	for slot in eq:
		var id := str(eq[slot])
		if not DEFS.has(id):
			continue
		for k in DEFS[id].mods:
			out[k] = float(out.get(k, 0.0)) + float(DEFS[id].mods[k])
	return out

static func slot_of(id: String) -> String:
	return str(DEFS.get(id, {}).get("slot", ""))

# tek satırlık mod özeti — envanter kartlarında gösterilir
static func stat_text(id: String) -> String:
	var d: Dictionary = DEFS.get(id, {})
	if d.is_empty():
		return ""
	var names := {"hp": "can", "armor": "zırh", "dmg": "hasar", "spd": "hız",
		"crit": "kritik", "critmult": "kritik×", "ls": "can emme", "mag": "mıknatıs",
		"xp": "XP", "frag": "parçacık", "dash_regen": "dash yenileme", "revive": "dirilme"}
	var parts: Array = []
	for k in d.mods:
		var f := float(d.mods[k])
		var fmt := "+%d" % int(f) if absf(f) >= 1.5 else "+%d%%" % int(f * 100)
		parts.append("%s %s" % [fmt, names.get(k, k)])
	return "  ".join(parts)
