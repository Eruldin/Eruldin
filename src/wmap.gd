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
	{"id": "mabed",  "name": "KIRILMIŞ MABED",     "icon": "icn_crown",   "pos": Vector2(420, 560), "col": "ffd75f", "kind": "arena", "biome": 0, "unlock": "node", "desc": "Yıkık tapınak — ganimet çift kat, elitler nöbette.", "lore": "Viator'ın eski dua yeri. Sunak kırık ama kutsamalar hâlâ taşın içinde — kovan da bunu biliyor.", "mods": {"loot": 2.2, "elite_t": 0.6, "spawn": 0.8, "frag": 1.2}},
	{"id": "mezarlik","name": "DÜŞMÜŞLER MEZARI",  "icon": "icn_skull",   "pos": Vector2(950, 150), "col": "90a4ae", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Efendilerin eski çöplüğü — elit kaynağı, sert kovan.", "lore": "Protokolün reddettiği gövdeler buraya atıldı. Şimdi hepsi kalkmış, mezarlarında nöbet tutuyor.", "mods": {"hp": 1.25, "elite_t": 0.5, "dmg": 1.15, "frag": 1.35}},
	{"id": "batak",  "name": "ÇÜRÜK BATAKLIK",    "icon": "ico_boon",    "pos": Vector2(1120, 430), "col": "66bb6a", "kind": "arena", "biome": 4, "unlock": "node", "desc": "İmparatorluğun unuttuğu bataklık — çeken balçık, mantarlı karanlık, bol ganimet.", "lore": "Protokol buraya hiç bakmadı; bataklık da kimseyi geri vermedi. Suların altında efendilerin artıkları, üstünde küsen sürüler.", "mods": {"hp": 1.05, "spawn": 1.15, "frag": 1.3, "loot": 1.6, "dusk": true}},
	# kind "story": savaşsız tek seferlik hikaye durağı — sinematik + ödül, sonra tükenir
	{"id": "kayalik","name": "YANKI KAYASI",        "icon": "icn_skull",   "pos": Vector2(300, 520), "col": "8fd4ff", "kind": "story", "unlock": "open",    "desc": "Kampın güneyinde koro taşı — bir kez dinlenir.", "rew": {"cho": 60},
	 "cards": [
	 	{"tex": "cine_0_1", "title": "YANKI KAYASI", "sub": "Taş, düşen her praetorianın son sinyalini saklar. Parmağını değdir — binlerce yankı aynı anda senin adını söyler."},
	 	{"tex": "por_neva", "title": "NEVA", "sub": "Bunu hissettin değil mi? Kaya korosuna katıldın — artık düşersen bir kaydın var. Parçacıklarını al, git."},
	 ]},
	{"id": "sisgecidi", "name": "SİS GEÇİDİ",      "icon": "icn_dash",    "pos": Vector2(160, 480), "col": "a5d6a7", "kind": "arena", "biome": 4, "unlock": "node", "desc": "Batıdaki sis perdesi — kasılmak isteyenlerin geçidi: sürü bol, frag ve ganimet bereketli.", "lore": "Bataklığın sisi burada duvar gibi. İçinde kistler şarkı söylüyor; göçebe Ahusk bu yolu gençliğinde kaçarak geçti.", "mods": {"spawn": 1.25, "frag": 1.45, "loot": 1.4, "dusk": true}},
	{"id": "avlis",  "name": "EFENDİ AVLISI",   "icon": "icn_crown",   "pos": Vector2(1230, 90),  "col": "ffd75f", "kind": "arena", "biome": 5, "unlock": "boss twins", "desc": "Boss-rush: altı efendi arka arkaya — zincirin sonu zafer.", "lore": "Kirin ve Constantin düştükten sonra açılan arena: protokolün bütün efendileri burada nöbet sırası bekliyor. Altısını da tek koşuda düşür.", "mods": {"rush": 1, "frag": 2.0, "loot": 2.0}},
	{"id": "kulovasi", "name": "KÜL OVASI",        "icon": "icn_mine",    "pos": Vector2(1160, 260), "col": "ff7722", "kind": "arena", "biome": 5, "unlock": "node", "desc": "Praetorian yangınının külü — lav püskürtücüler, kor hücreleri, çok sert kovan.", "lore": "İmparatorluk burasını yakarak temizledi; kül hâlâ sıcak. Yerdeki her çatlak kor saklıyor — kovan ateşi sevdiği için burada en kalını.", "mods": {"hp": 1.55, "dmg": 1.35, "spawn": 1.2, "frag": 1.7, "loot": 1.8}},
	{"id": "yemin",   "name": "YEMİN DARESİ",      "icon": "icn_skull",   "pos": Vector2(330, 660),  "col": "ff3355", "kind": "arena", "biome": 3, "unlock": "node", "desc": "Eski praetorian yemini — şifa küresi düşmez, tek yaşamla sınanırsın; bedeli çift öder.", "lore": "Viator'ın en eski meydan okuması: hiçbir yankı sana küre taşımayacak. Geçersen darénin haracı krallık ölçeğindedir.", "mods": {"noheal": true, "hp": 1.25, "dmg": 1.2, "frag": 2.2, "loot": 1.5}},
	{"id": "krater", "name": "DÜŞÜK KRATER",       "icon": "icn_mine",    "pos": Vector2(860, 650), "col": "ffb74d", "kind": "story", "unlock": "boss rex","desc": "İlk efendinin düştüğü yerde bir krater — içinde hâlâ ışık yanıyor.", "rew": {"cho": 120, "item": "i_palto"},
	 "cards": [
	 	{"tex": "cine_0_2", "title": "DÜŞÜK KRATER", "sub": "Alfa-05 burada düştü. Kraterin dibinde henüz çürümemiş bir zırh parçası duruyor — kovan bile ona dokunmamış."},
	 	{"tex": "por_rhasa", "title": "RHASA", "sub": "Onun parçasını taşıyorsun artık. Kraterin kenarında bir şey parlıyor — al ve git, koku burada da sürer."},
	 ]},
	{"id": "tasocagi","name": "ÇATLAK OCAK",       "icon": "icn_mine",    "pos": Vector2(560, 70),  "col": "ffab91", "kind": "arena", "biome": 1, "unlock": "node", "desc": "Çatlakların altında ocak — elit kaynağı, kovan kesintisiz.", "lore": "Simithar'ın ilk ocağı; damarın çatlağı hâlâ yanıyor. Elitler çatlağın nabzını nöbet tutar gibi koruyor.", "mods": {"elite_t": 0.5, "spawn": 1.1, "dmg": 1.1, "loot": 1.3, "frag": 1.1}},
	{"id": "sondurme","name": "SÖNDÜRÜLMÜŞ FIRIN",  "icon": "ico_frag",    "pos": Vector2(1120, 640), "col": "b0bec5", "kind": "story", "unlock": "boss twins","desc": "İmparatorluğun son fırını — gövdesi soğuk, içi hâlâ dolu.", "lore": "Efendiler burada dövüldü. Fırın söndü ama korları — içlerinde kilitli bir Hisar Kalkanı, kovanın eli değmemiş halde.", "rew": {"cho": 140, "item": "i_hisar"}},
]

# günlük protokol: tarihe göre deterministik saha mutasyonu (roguelite daily run)
const DAILY := [
	{"name": "KALABALIK GÜN", "desc": "sürü %25 daha kalabalık akar", "mods": {"spawn": 1.25}, "rew": 1.1},
	{"name": "ZIRHLI SÜRÜ",   "desc": "kovan %20 daha dayanıklı",      "mods": {"hp": 1.2}, "rew": 1.15},
	{"name": "ACIMASIZ GÜN",  "desc": "kovan %20 daha sert vurur",     "mods": {"dmg": 1.2}, "rew": 1.15},
	{"name": "BEREKET",       "desc": "parçacık düşüşü +%40",          "mods": {"frag": 1.4}, "rew": 1.0},
	{"name": "ŞANSLI GÜN",    "desc": "eşya/kalite şansı +0.2",        "luck": 0.2, "rew": 1.0},
	{"name": "ELİT NÖBETİ",   "desc": "elitler sık doğar",             "mods": {"elite_t": 0.7}, "rew": 1.1},
]

static func daily() -> Dictionary:
	var dk := Time.get_date_string_from_system()
	return DAILY[abs(dk.hash()) % DAILY.size()]

# harita üstünde çizilen seyahat hatları (BG2 bağlantıları)
const EDGES := [
	["kamp", "b0"], ["kamp", "pazar"], ["kamp", "tarla"], ["kamp", "yol"],
	["b0", "yol"], ["b0", "tarla"], ["yol", "b1"], ["b1", "b2"],
	["tarla", "b3"], ["b2", "b3"], ["b3", "kuyu"], ["b2", "kuyu"],
	["pazar", "yuvalar"], ["b1", "yuvalar"], ["b3", "vatika"], ["kuyu", "vatika"],
	["tarla", "mabed"], ["mabed", "vatika"], ["yuvalar", "mezarlik"], ["b1", "mezarlik"],
	["b2", "batak"], ["batak", "kuyu"],
	["tarla", "kayalik"], ["kamp", "kayalik"],
	["mabed", "krater"], ["vatika", "krater"],
	["kayalik", "sisgecidi"], ["kamp", "sisgecidi"],
	["kuyu", "kulovasi"], ["mezarlik", "kulovasi"],
	["kulovasi", "avlis"],
	["vatika", "yemin"], ["kayalik", "yemin"],
	["yol", "tasocagi"], ["tasocagi", "yuvalar"],
	["avlis", "sondurme"], ["kulovasi", "sondurme"],
]

static func node(id: String) -> Dictionary:
	for n in NODES:
		if n.id == id:
			return n
	return {}

static func _unlocked() -> Array:
	return G.meta.data.get("unlocked", [])

# canlı harita: kampa dönüşte işaretlenen baskın düğümü ("" = yok)
static func hot_node() -> String:
	return str(G.meta.data.get("hot_node", ""))

# is this node reachable? "open" / "node" (quest-unlocked) / "boss <id>"
static func can_enter(id: String) -> bool:
	var n := node(id)
	if n.is_empty():
		return false
	if str(n.get("kind", "")) == "story" and (G.meta.data.get("story_done", []) as Array).has(id):
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
	if str(n.get("kind", "")) == "story" and (G.meta.data.get("story_done", []) as Array).has(id):
		return "tamamlandı"
	match str(n.get("unlock", "open")):
		"open": return ""
		"node": return "görevle açılır"
		_:
			var u := str(n.unlock)
			if u.begins_with("boss "):
				var bid := u.substr(5)
				var names := {"rex": "ALFA-05", "host": "PROTERYAN KONAKÇI", "twins": "NAHUM & TUMAN", "final": "KİRİN & CONSTANTİN"}
				return "önce %s düşmeli" % str(names.get(bid, bid))
			return "?"
