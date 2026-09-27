class_name Meta
extends RefCounted

# Persistent meta-progression: Pure Choralim currency, permanent upgrades,
# death/run stats, boss flags, seen dialogue lines. JSON save at user://.

enum U { HP, DMG, DASH, REVIVE, FRAG, SHIELD, SPD, MAG, LUCK }

const UPG := {
	U.HP:     {"name": "Sinirsel Dayanıklılık", "desc": "+20 azami can", "max": 5, "base": 40},
	U.DMG:    {"name": "Kas Yoğunluğu", "desc": "+%8 hasar", "max": 5, "base": 45},
	U.DASH:   {"name": "Ek Transistör", "desc": "+1 dash yükü", "max": 1, "base": 120},
	U.REVIVE: {"name": "Neva'nın Bağı", "desc": "Koşuda bir kez %40 canla diril", "max": 1, "base": 200},
	U.FRAG:   {"name": "Choralim Sifonu", "desc": "+%15 parçacık kazancı", "max": 3, "base": 50},
	U.SHIELD: {"name": "Zırh Kaplama", "desc": "+1 zırh (düz hasar azaltma)", "max": 3, "base": 60},
	U.SPD:    {"name": "Servo Ayaklar", "desc": "+%6 hareket hızı", "max": 4, "base": 55, "icon": "icn_upg_dash"},
	U.MAG:    {"name": "Toplayıcı Bobin", "desc": "+45 toplama yarıçapı", "max": 3, "base": 60, "icon": "icn_upg_frag"},
	U.LUCK:   {"name": "Talih Devresi", "desc": "+0.15 şans — daha iyi taslaklar", "max": 3, "base": 75, "icon": "icn_upg_revive"},
}

# kamp inşaatı — Vane'nin panelinde tek seferlik satın alınan kalıcı binalar
const BUILDS := {
	"yuva":   {"name": "Ehil Yuva",      "cost": 300, "icon": "icn_upg_hp",     "desc": "Mina'nın ocağı büyür — iksir stoğu 3→4, kor şarabı 2→3"},
	"atolye": {"name": "Atölye",         "cost": 400, "icon": "icn_upg_shield", "desc": "Saphire'in tezgâhı kurulur — işleme bedeli %25 iner"},
	"kule":   {"name": "Nöbet Kulesi",   "cost": 450, "icon": "icn_upg_dash",   "desc": "Kamp gözcüsü — her koşuya koruyucu zarf + iksirle çıkarsın"},
	"kuyu":   {"name": "Kuyu",           "cost": 500, "icon": "icn_upg_hp",     "req": "yuva", "desc": "Temiz su — her koşunun başında iki şifa küresi sahaya düşer"},
	"sur":    {"name": "Sur Duvarı",     "cost": 600, "icon": "icn_upg_shield", "req": "kule", "desc": "Kamp surları — her sahada ekstra bir sandık bekler"},
	"ahir":   {"name": "Ağıl",           "cost": 550, "icon": "icn_kovan",      "req": "kuyu", "desc": "Yakaladığın sürüngenler kampına döner — her biri koşu başına +3 parçacık (en çok 12)"},
}

const SAVE_PATH := "user://dusus_save.json"

var data := {
	"version": 1,
	"choralim": 0,
	"deaths": 0,
	"runs": 0,
	"kills": 0,
	"victories": 0,
	"ng": 0,
	"best_depth": 0,
	"bosses": [],          # defeated boss ids: "rex","host","twins","final"
	"upg": {"hp":0,"dmg":0,"dash":0,"revive":0,"frag":0,"shield":0,"spd":0,"mag":0,"luck":0},
	"seen_lines": [],
	"stance": "",          # chosen doctrine from Rhasa
	"hero": "ely",         # chosen chassis — "ely" or heavy "elyb"
	"unlocked_w": [],      # gated silahların duyurulduğu id'ler (toast bir kez)
	"arena_biome": 0,      # arena sector picked via David (İz Sürücü)
	"arena_node": "b0",    # world-map node the next run targets (wmap.gd)
	"unlocked": [],        # quest/node unlocks — wmap "node" gating
	"visited": [],         # distinct biomes seen this save
	"visited_nodes": [],   # distinct wmap nodes run at — haritada ✓ işareti
	"quests": {},          # qid -> {st:"act"|"done"|"claimed", prog:int}
	"stash": [],           # collected items awaiting equipment
	"equip": {},           # slot -> item id (7 slots, items.gd)
	"item_lvl": {},        # item id -> işleme seviyesi (Saphire forge, max 3)
	"camp_builds": {},     # satın alınan kamp binaları: id -> true
	"pets": 0,             # ağıla dönen sürüngen sayısı (Ağıl binası)
	"loot_found": 0,       # lifetime item drops
	"seen_story": [],      # cinematic cards already shown (one-shot story beats)
	"story_done": [],      # tamamlanan hikaye düğümleri — haritada tek seferlik duraklar,
	"lore": [],            # bulunan veri kütükleri (ÖYKÜ codex'i besler)
	"hyper": false,        # AŞILAMA: sürü hızlı/kalabalık akar, ödeme ×1.5
	"dark": false,         # KARANLIK: şifa küresi düşmez, ödeme ×1.25
	"blessing": false,     # Ahusk'un desteği — koşu rasgele lütufla açılır
	"hired": false,        # Ahusk yoldaşı — koşu boyunca muhafız dronu
	"seen_kinds": [],      # ilk kez görülen düşman türleri (EKind id'leri)
	"boss_seen": [],       # ilk karşılaşması sinematikle oynatılan efendi kind'leri
	"intro_seen": false,   # açılış sinematik kartları bir kez oynatılır
	"tut": false,          # ilk koşu ipucu dizisi oynatıldı mı
	"ended": false,        # b3 zaferi — gerçek son gösterildi
	"contract": {},        # Ehnar's aktif görevi: {key,need,reward}
	"feats_seen": [],      # duyurulmuş başarımlar (toast bir kez)
	"reapers": 0,          # kesilen HASATÇI sayısı
	"champs": 0,           # kesilen ŞAMPİYON elit sayısı
	"best_evos": 0,        # tek koşuda en çok evrim
	"curse_wins": 0,       # 2+ sözleşmeyle kazanılan zafer
	"eggs": 0,             # toplanan altın nüve (kalıcı +%0.5 hasar/adet)
	"last_run": {},        # son koşu özeti: {kills,time,level,win}
	"history": [],         # son 5 koşu: {n,k,t,w,s}
	"won_nodes": [],       # zaferle fethedilmiş wmap node'ları — haraç öder
	"wep_mastery": {},     # silah başına kümülatif hasar — 25K/50K/75K'de kalıcı +%4
	"node_rec": {},        # node başına rekor: {s: skor, w: zafer, d: yenilgi}
	"camp_tier": 0,        # kamp büyüme aşaması — talep edilen görev sayısına göre
	"over_uses": 0,        # toplam AŞIRI YÜK (F) kullanımı
	"keg_kills": 0,        # dinamitçi fıçısıyla ölen sürü kesimleri
	"baskin_wins": 0,      # koro baskını altında kazanılan zaferler
	"contracts_done": 0,  # Ehnar'da tutan sözleşme sayısı
	"title": "",           # takılı unvan (TITLES id) — koşu sonu ekranlarında görünür
	"kind_kills": {},      # tür-bazlı toplam kesimler (Zirkon kayıtları)
	"best_streak_all": 0,  # tüm zamanların en uzun serisi
	"best_score": 0,       # en yüksek koşu skoru
	"bet": {},             # Tegan'ın aktif bahsi: {type,stake,pay,need}
	"bets_won": 0,         # Tegan'da tutan bahis sayısı
	"hero_wins": {},       # şasi başına zafer sayısı: {ely: n, ...}
	"arcanas_seen": [],    # kullanılan koz kartları (KOLEKSİYONCUSU besler)
	"wep_unlocked": [],    # görev ödülüyle açılan silahlar (feat koşulunu atlar)
	"_last_contract_key": "",  # Ehnar sözleşme tekrar engeli
	"last_death": {"killer":"", "biome":0, "depth":0, "boss":false},
	"shop_stock": [],      # Saphire'in tezgâh stoku — koşu başına yenilenir
	"shop_gen": -1,        # stok üretimindeki koşu sayacı
	"neva_song": false,    # Neva'nın şarkısı — sonraki koşuda +%15 XP
	"rescued_mina": false, # sahada kafesten kurtarılan Aşçı Mina — kampa katılır
	"mina_meal": false,    # Mina'nın yemeği — sonraki koşuda şifa küresi şansı ×2
	"rescued_lena": false, # sahada kafesten kurtarılan Kartograf Lena — kampa katılır
	"lena_route": false,   # Lena'nın keşif güzergâhı — sonraki koşuda saha zengin
	"settings": {"shake": true, "crt": true, "mus": 1.0, "sfx": 1.0, "full": false},
}

var _defaults: Dictionary

func _init() -> void:
	_defaults = data.duplicate(true)

# VERİYİ SIFIRLA — pause ayarlarından çift-onaylı tam reset
func reset_all() -> void:
	data = _defaults.duplicate(true)
	save()

static func _key(u: int) -> String:
	return ["hp","dmg","dash","revive","frag","shield","spd","mag","luck"][u]

func upg(u: int) -> int:
	return int(data["upg"].get(_key(u), 0))

func upg_cost(u: int) -> int:
	var lvl := upg(u)
	if lvl >= int(UPG[u]["max"]):
		return -1
	return int(UPG[u]["base"]) * (lvl + 1)

func buy(u: int) -> bool:
	var cost := upg_cost(u)
	if cost < 0 or data["choralim"] < cost:
		return false
	data["choralim"] -= cost
	data["upg"][_key(u)] = upg(u) + 1
	save()
	return true

func has_build(b: String) -> bool:
	return bool((data.get("camp_builds", {}) as Dictionary).get(b, false))

func buy_build(b: String) -> bool:
	var spec: Dictionary = BUILDS.get(b, {})
	if spec.is_empty() or has_build(b) or data["choralim"] < int(spec.cost):
		return false
	data["choralim"] -= int(spec.cost)
	var cb: Dictionary = data.get("camp_builds", {})
	cb[b] = true
	data["camp_builds"] = cb
	save()
	return true

func add_choralim(n: int) -> void:
	data["choralim"] += n
	save()

func record_death(killer: String, biome: int, depth: int, was_boss: bool) -> void:
	data["deaths"] += 1
	data["best_depth"] = maxi(data["best_depth"], depth)
	data["last_death"] = {"killer": killer, "biome": biome, "depth": depth, "boss": was_boss}
	save()

func boss_down(id: String) -> void:
	if not data["bosses"].has(id):
		data["bosses"].append(id)
	save()

# milestone list — Zirkon's BAŞARIMLAR section + end-of-run toasts
func achievements() -> Array:
	var arsenal := true
	for wid in Weapons.DEFS:
		if not Weapons.DEFS[wid].get("hidden", false) and not Weapons.unlocked(wid):
			arsenal = false
	return [
		{"name": "İLK ZAFER", "desc": "bir koşuyu zaferle bitir", "done": int(data["victories"]) > 0, "rew": 150},
		{"name": "KESİM MAKİNESİ", "desc": "toplam 1.000 kesim", "done": int(data["kills"]) >= 1000, "rew": 100},
		{"name": "KOVAN KIRICI", "desc": "toplam 10.000 kesim", "done": int(data["kills"]) >= 10000, "rew": 300},
		{"name": "EFENDİ AVCISI", "desc": "dört efendiyi de düşür", "done": (data["bosses"] as Array).size() >= 4, "rew": 200},
		{"name": "ÇÖLÜN HÜKÜMRARI", "desc": "Kum Anası'nı düşür", "done": (data["bosses"] as Array).has("anasi"), "rew": 180},
		{"name": "BATAKLIĞIN EFENDİSİ", "desc": "Bataklık Devi'ni düşür", "done": (data["bosses"] as Array).has("dev"), "rew": 180},
		{"name": "KÜLLERİN EFENDİSİ", "desc": "Kor Yücelten'i düşür", "done": (data["bosses"] as Array).has("kor"), "rew": 180},
		{"name": "DERİN GEZGİN", "desc": "tek koşuda 10+ dakika dayan", "done": int(data["best_depth"]) >= 600 or int(data["victories"]) > 0, "rew": 100},
		{"name": "İNATÇI", "desc": "10 koşuya çık", "done": int(data["runs"]) >= 10, "rew": 80},
		{"name": "TAM ARSENAL", "desc": "tüm silahların kilidini aç", "done": arsenal, "rew": 250},
		{"name": "HASAT AVCISI", "desc": "bir HASATÇI'yı kes", "done": int(data.get("reapers", 0)) > 0, "rew": 150},
		{"name": "ŞAMPİYON AVCISI", "desc": "bir altın ŞAMPİYON elit kes", "done": int(data.get("champs", 0)) > 0, "rew": 180},
		{"name": "KATALOGLUCU", "desc": "tüm düşman türlerini kayıt defterine işlet", "done": (data.get("seen_kinds", []) as Array).size() >= Enemy.EKind.size(), "rew": 120},
		{"name": "ON HİKÂYE", "desc": "on efendinin hepsiyle yüz yüze gel", "done": (data.get("boss_seen", []) as Array).size() >= 10, "rew": 160},
		{"name": "EVRİM MİMARI", "desc": "tek koşuda 3 evrim tamamla", "done": int(data.get("best_evos", 0)) >= 3, "rew": 120},
		{"name": "NÜVE AVCISI", "desc": "10 altın nüve topla", "done": int(data.get("eggs", 0)) >= 10, "rew": 120},
		{"name": "AZAPLI ŞAMPİYON", "desc": "2+ karanlık sözleşmeyle zafer kazan", "done": int(data.get("curse_wins", 0)) > 0, "rew": 150},
		{"name": "SKOR AVCISI", "desc": "tek koşuda 4000+ skor", "done": int(data.get("best_score", 0)) >= 4000, "rew": 150},
		{"name": "S SINIFI", "desc": "tek koşuda S notası al (5000+ skor)", "done": int(data.get("best_score", 0)) >= 5000, "rew": 250},
		{"name": "MARATONCU", "desc": "tek koşuda 14+ dakika dayan", "done": int(data.get("best_depth", 0)) >= 840, "rew": 200},
		{"name": "KOZ KOLEKSİYONCUSU", "desc": "tüm koz kartlarını kullan", "done": (data.get("arcanas_seen", []) as Array).size() >= Boons.ARCANAS.size(), "rew": 150},
		{"name": "HARİTA USTASI", "desc": "kamp hariç tüm node'lara koşu yap", "done": (data.get("visited_nodes", []) as Array).size() >= int(Wmap.NODES.size()) - 1, "rew": 200},
		{"name": "KOLEKSİYONER", "desc": "zula + ekipmanda 10+ eşya", "done": (data.get("stash", []) as Array).size() + (data.get("equip", {}) as Dictionary).size() >= 10, "rew": 100},
		{"name": "GÖREV ERİ", "desc": "8 görevi teslim et", "done": _claimed_count() >= 8, "rew": 150},
		{"name": "ARŞİVCİ", "desc": "8 veri kütüğünü topla", "done": (data.get("lore", []) as Array).size() >= Quests.LORE.size(), "rew": 200},
		{"name": "DERİN SEÇİLMİŞ", "desc": "3. derinliğe ulaş (3 zafer)", "done": int(data.get("ng", 0)) >= 3, "rew": 300},
		{"name": "ALTIN KIRICI", "desc": "toplam 10 şampiyon elit kes", "done": int(data.get("champs", 0)) >= 10, "rew": 400},
		{"name": "DARE KIRAN", "desc": "Yemin Daresini fethet (şifa küresiz zafer)", "done": (data.get("won_nodes", []) as Array).has("yemin"), "rew": 250},
		{"name": "ÇUKURUN DİBİ", "desc": "Kristal Çukur'u fethet — ikiz nöbeti kır", "done": (data.get("won_nodes", []) as Array).has("cukur"), "rew": 300},
		{"name": "PROTOKOLÜ KIRAN", "desc": "Aeterna Spire'ı düşür — gerçek sonu gör", "done": bool(data.get("ended", false)), "rew": 500},
		{"name": "KOVAN ATEŞİ", "desc": "dinamitçi fıçısıyla 30 sürü kesimi yaptır", "done": int(data.get("keg_kills", 0)) >= 30, "rew": 200},
		{"name": "BASKIN AVCISI", "desc": "koro baskını altında 3 zafer kazan", "done": int(data.get("baskin_wins", 0)) >= 3, "rew": 220},
		{"name": "SÖZLEŞME USTASI", "desc": "Ehnar'da 8 sözleşme tuttur", "done": int(data.get("contracts_done", 0)) >= 8, "rew": 200},
		{"name": "MASA KIRANI", "desc": "Tegan'da 6 bahis tuttur", "done": int(data.get("bets_won", 0)) >= 6, "rew": 180},
		{"name": "BEŞ GÖVDE", "desc": "beş farklı şasiyle zafer kazan", "done": (data.get("hero_wins", {}) as Dictionary).size() >= 5, "rew": 400},
		{"name": "MİMAR", "desc": "kampın altı binasını da kur", "done": (data.get("camp_builds", {}) as Dictionary).size() >= 6, "rew": 350},
	]

# unvanlar — başarımların açtığı lakaplar; src = kilidi açan başarımın adı
const TITLES := [
	{"id": "surus",   "name": "SÜRÜ AVCISI",    "src": "KOVAN KIRICI"},
	{"id": "efendi",  "name": "EFENDİ AVCISI",  "src": "EFENDİ AVCISI"},
	{"id": "arsiv",   "name": "ARŞİV BEKÇİSİ",  "src": "ARŞİVCİ"},
	{"id": "harita",  "name": "HARİTA USTASI",  "src": "HARİTA USTASI"},
	{"id": "altin",   "name": "ALTIN KIRICI",   "src": "ALTIN KIRICI"},
	{"id": "s",       "name": "S SINIFI",       "src": "S SINIFI"},
	{"id": "kolek",   "name": "KOLEKSİYONER",   "src": "KOLEKSİYONER"},
	{"id": "baskin",  "name": "BASKIN KIRICI",  "src": "BASKIN AVCISI"},
	{"id": "sozlesme","name": "SÖZLEŞME KILICI", "src": "SÖZLEŞME USTASI"},
	{"id": "kiran",   "name": "PROTOKOLÜ KIRAN", "src": "PROTOKOLÜ KIRAN"},
	{"id": "dare",    "name": "DARE KIRAN",      "src": "DARE KIRAN"},
	{"id": "cukur",   "name": "DAMAR YÜRÜYEN",    "src": "ÇUKURUN DİBİ"},
	{"id": "kralice", "name": "ÇÖL TİRANI",      "src": "ÇÖLÜN HÜKÜMRARI"},
	{"id": "dev",     "name": "BATAKLIK NÖBETÇİSİ","src": "BATAKLIĞIN EFENDİSİ"},
	{"id": "kor",     "name": "KOR KIRAN",        "src": "KÜLLERİN EFENDİSİ"},
	{"id": "kumar",   "name": "KUMARBAZ",         "src": "MASA KIRANI"},
	{"id": "govde",   "name": "ÇOK GÖVDELİ",      "src": "BEŞ GÖVDE"},
	{"id": "mimar",   "name": "KAMP MİMARI",      "src": "MİMAR"},
]

func title_open(tid: String) -> bool:
	var src := ""
	for t in TITLES:
		if str(t.id) == tid:
			src = str(t.src)
	if src == "":
		return false
	for a in achievements():
		if str(a.name) == src:
			return bool(a.done)
	return false

# takılı unvanın görünen adı (kilitliyse boş döner — eski save'lerde güvenli)
func title_name() -> String:
	var tid := str(data.get("title", ""))
	if tid == "" or not title_open(tid):
		return ""
	for t in TITLES:
		if str(t.id) == tid:
			return str(t.name)
	return ""

func _claimed_count() -> int:
	var n := 0
	for qid in (data.get("quests", {}) as Dictionary):
		if str(data["quests"][qid].get("st", "")) == "claimed":
			n += 1
	return n

# feats completed since last check — announced once via toast
func new_feats() -> Array:
	var seen: Array = data.get("feats_seen", [])
	var out: Array = []
	for a in achievements():
		if bool(a.done) and not seen.has(str(a.name)):
			seen.append(str(a.name))
			var r := int(a.get("rew", 0))
			if r > 0:
				data["choralim"] = int(data.get("choralim", 0)) + r
			out.append(str(a.name) + ("  +◆%d" % r if r > 0 else ""))
	data["feats_seen"] = seen
	if not out.is_empty():
		save()
	return out

func seen_line(id: String) -> bool:
	return data["seen_lines"].has(id)

func mark_line(id: String) -> void:
	data["seen_lines"].append(id)

func save() -> void:
	var f := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	# atomic-ish swap
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	DirAccess.rename_absolute(SAVE_PATH + ".tmp", SAVE_PATH)

func load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	# merge onto defaults so old saves gain new fields
	for k in parsed:
		if k == "upg" and typeof(parsed[k]) == TYPE_DICTIONARY:
			for uk in parsed[k]:
				data["upg"][uk] = parsed[k][uk]
		elif k == "last_death" and typeof(parsed[k]) == TYPE_DICTIONARY:
			for dk in parsed[k]:
				data["last_death"][dk] = parsed[k][dk]
		elif data.has(k):
			data[k] = parsed[k]

func frag_mult() -> float:
	return 1.0 + upg(U.FRAG) * 0.15
