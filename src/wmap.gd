class_name Wmap
extends RefCounted

# BG2-style world map: node graph of areas. Each node is a destination —
# either the camp hub or an arena run with its own biome art, modifiers and
# unlock rule. Travel happens through the map screen (David / world key).

# node def:
#   id, name, icon, pos (map px on 1180x660 space), col
#   biome  — arena art/hazard set to reuse
#   mods   — run modifiers: frag, elite_t (elite interval mult), miniboss, final
#   unlock — "open" | "quest" (meta.unlocked contains id) | "bosses n"
#   desc   — flavor + rule text
const NODES := [
	{"id": "kamp",   "name": "VIATOR KAMPI",      "icon": "ico_camp",    "pos": Vector2(300, 360), "col": "c9a227", "kind": "hub",  "unlock": "open",   "desc": "Son güvenli toprak. NPC'ler, yükseltmeler, görevler."},
	{"id": "b0",     "name": "ENDUSTERRA BARRENS", "icon": "ico_run",     "pos": Vector2(520, 240), "col": "00E5FF", "kind": "arena", "biome": 0, "unlock": "open",   "desc": "Proterian çoraklığı. Efendi: Alfa-05.", "mods": {}},
	{"id": "b1",     "name": "SIMITHAR MINE",      "icon": "icn_mine",    "pos": Vector2(760, 200), "col": "00E676", "kind": "arena", "biome": 1, "unlock": "boss rex","desc": "Simithar damarları. Efendi: Proterian Host.", "mods": {}},
	{"id": "b2",     "name": "SOL PRIMUS ENKAZI",  "icon": "ico_run",     "pos": Vector2(940, 340), "col": "ffb74d", "kind": "arena", "biome": 2, "unlock": "boss host","desc": "İmparatorluk enkazı. Efendiler: Nahum & Tuman.", "mods": {}},
	{"id": "b3",     "name": "AETERNA SPIRE",      "icon": "icn_crown",   "pos": Vector2(760, 520), "col": "c26bff", "kind": "arena", "biome": 3, "unlock": "boss twins","desc": "Protokolün kalbi. Efendiler: Kirin & Constantin.", "mods": {}},
	{"id": "yol",    "name": "PUSLU GEÇİT",        "icon": "icn_dash",    "pos": Vector2(430, 130), "col": "8fd4ff", "kind": "arena", "biome": 1, "unlock": "node", "desc": "Elitler sık doğar, ganimet bol — keşif koşusu.", "lore": "Kervanların kaybolduğu geçit. Sis perdesi arkasında elit sürüler dönüyor — cesareti olan ganimeti kapar.", "mods": {"elite_t": 0.55, "frag": 1.2, "dusk": true}},
	{"id": "tarla",  "name": "YANIK TARLALAR",     "icon": "ico_frag",    "pos": Vector2(600, 430), "col": "ff9e4d", "kind": "arena", "biome": 0, "unlock": "node", "desc": "Kül tarlaları — parçacık bereketi, kovan seyrek.", "lore": "Eski imparatorluğun tahıl ambarı. Küllerin altında hâlâ choralim kristalleri çiçek açıyor.", "mods": {"spawn": 1.25, "frag": 1.5, "hp": 0.85}},
	{"id": "pazar",  "name": "HURDA PAZARI",       "icon": "ico_boon",    "pos": Vector2(180, 180), "col": "c9a227", "kind": "arena", "biome": 2, "unlock": "node", "desc": "Yıkık çarşı — eşya düşüşü yoğun, sürü zayıf.", "lore": "Tüccarların son durağı. Raflar devrildi ama eşya hâlâ orada — kovanın artıkları arasında.", "mods": {"loot": 2.5, "hp": 0.75, "frag": 0.8}},
	{"id": "kuyu",   "name": "DERİN KUYU",         "icon": "icn_skull",   "pos": Vector2(980, 560), "col": "ff5533", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Aeterna'nın dibi — en sert kovan, en iyi ganimet.", "lore": "Kulenin temel kuyusu. Aşağıda ışık yok; kovanın kalbi burada atıyor. Geri dönüş garanti değil.", "mods": {"hp": 1.5, "dmg": 1.3, "loot": 2.0, "frag": 1.6}},
	{"id": "yuvalar","name": "KOVAN YUVALARI",     "icon": "icn_kovan",   "pos": Vector2(760, 60),  "col": "ff5c5c", "kind": "arena", "biome": 2, "unlock": "node", "desc": "Kovanın üreme ocağı — sürü kesintisiz, frag bereketli.", "lore": "Enkazın altında kovan kuluçkası. Duvarlar nabız atıyor; her çatlaktan yeni bir sürü doğuyor.", "mods": {"spawn": 1.45, "elite_t": 0.8, "frag": 1.4, "hp": 1.1}},
	{"id": "vatika", "name": "SESSİZ VATİKA",      "icon": "icn_crown",   "pos": Vector2(600, 620), "col": "9be8ff", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Protokolün sessiz sığınağı — alacakaranlık, bol choralim.", "lore": "Neva'nın bahsettiği sığınak. Işık burada ölür ama choralim şarkısı çift yankılanır.", "mods": {"hp": 1.3, "frag": 2.0, "dusk": true, "loot": 1.4}},
]

# harita üstünde çizilen seyahat hatları (BG2 bağlantıları)
const EDGES := [
	["kamp", "b0"], ["kamp", "pazar"], ["kamp", "tarla"], ["kamp", "yol"],
	["b0", "yol"], ["b0", "tarla"], ["yol", "b1"], ["b1", "b2"],
	["tarla", "b3"], ["b2", "b3"], ["b3", "kuyu"], ["b2", "kuyu"],
	["pazar", "yuvalar"], ["b1", "yuvalar"], ["b3", "vatika"], ["kuyu", "vatika"],
]

static func node(id: String) -> Dictionary:
	for n in NODES:
		if n.id == id:
			return n
	return {}

static func _unlocked() -> Array:
	return G.meta.data.get("unlocked", [])

# is this node reachable? "open" / "node" (quest-unlocked) / "boss <id>"
static func can_enter(id: String) -> bool:
	var n := node(id)
	if n.is_empty():
		return false
	match str(n.get("unlock", "open")):
		"open":
			return true
		"node":
			return _unlocked().has(id)
		_:
			var u := str(n.unlock)  # "boss rex"
			if u.begins_with("boss "):
				return (G.meta.data.get("bosses", []) as Array).has(u.substr(5))
			return false

# görev ödülüyle node açılınca oynatılan tek kartlık sinematik
static func unlock_cine(id: String) -> void:
	var n := node(id)
	if n.is_empty():
		return
	var bi := int(n.get("biome", 0))
	var lore := str(n.get("lore", n.get("desc", "")))
	G.ui.cinematic("cine_%d_0" % bi, str(n.name) + " — AÇILDI", lore, 3.4)

static func unlock_text(id: String) -> String:
	var n := node(id)
	match str(n.get("unlock", "open")):
		"open": return ""
		"node": return "görevle açılır"
		_:
			var u := str(n.unlock)
			if u.begins_with("boss "):
				var bid := u.substr(5)
				var names := {"rex": "ALFA-05", "host": "KONAKÇI", "twins": "NAHUM & TUMAN", "final": "KİRİN & CONSTANTİN"}
				return "önce %s düşmeli" % str(names.get(bid, bid))
			return "?"
