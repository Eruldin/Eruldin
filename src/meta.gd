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

const SAVE_PATH := "user://dusus_save.json"

var data := {
	"version": 1,
	"choralim": 0,
	"deaths": 0,
	"runs": 0,
	"kills": 0,
	"victories": 0,
	"best_depth": 0,
	"bosses": [],          # defeated boss ids: "rex","host","twins","final"
	"upg": {"hp":0,"dmg":0,"dash":0,"revive":0,"frag":0,"shield":0,"spd":0,"mag":0,"luck":0},
	"seen_lines": [],
	"stance": "",          # chosen doctrine from Rhasa
	"hero": "ely",         # chosen chassis — "ely" or heavy "elyb"
	"unlocked_w": [],      # gated silahların duyurulduğu id'ler (toast bir kez)
	"arena_biome": 0,      # arena sector picked via David (İz Sürücü)
	"hyper": false,        # AŞILAMA: sürü hızlı/kalabalık akar, ödeme ×1.5
	"dark": false,         # KARANLIK: şifa küresi düşmez, ödeme ×1.25
	"blessing": false,     # Ahusk'un desteği — koşu rasgele lütufla açılır
	"contract": {},        # Ehnar's aktif görevi: {key,need,reward}
	"feats_seen": [],      # duyurulmuş başarımlar (toast bir kez)
	"reapers": 0,          # kesilen HASATÇI sayısı
	"best_evos": 0,        # tek koşuda en çok evrim
	"curse_wins": 0,       # 2+ sözleşmeyle kazanılan zafer
	"eggs": 0,             # toplanan altın nüve (kalıcı +%0.5 hasar/adet)
	"last_run": {},        # son koşu özeti: {kills,time,level,win}
	"last_death": {"killer":"", "biome":0, "depth":0, "boss":false},
	"settings": {"shake": true, "crt": true, "mus": 1.0, "sfx": 1.0},
}

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
		{"name": "İLK ZAFER", "desc": "bir koşuyu zaferle bitir", "done": int(data["victories"]) > 0},
		{"name": "KESİM MAKİNESİ", "desc": "toplam 1.000 kesim", "done": int(data["kills"]) >= 1000},
		{"name": "KOVAN KIRICI", "desc": "toplam 10.000 kesim", "done": int(data["kills"]) >= 10000},
		{"name": "EFENDİ AVCISI", "desc": "dört efendiyi de düşür", "done": (data["bosses"] as Array).size() >= 4},
		{"name": "DERİN GEZGİN", "desc": "tek koşuda 10+ dakika dayan", "done": int(data["best_depth"]) >= 600 or int(data["victories"]) > 0},
		{"name": "İNATÇI", "desc": "10 koşuya çık", "done": int(data["runs"]) >= 10},
		{"name": "TAM ARSENAL", "desc": "tüm silahların kilidini aç", "done": arsenal},
		{"name": "HASAT AVCISI", "desc": "bir HASATÇI'yı kes", "done": int(data.get("reapers", 0)) > 0},
		{"name": "EVRİM MİMARI", "desc": "tek koşuda 3 evrim tamamla", "done": int(data.get("best_evos", 0)) >= 3},
		{"name": "NÜVE AVCISI", "desc": "10 altın nüve topla", "done": int(data.get("eggs", 0)) >= 10},
		{"name": "AZAPLI ŞAMPİYON", "desc": "2+ karanlık sözleşmeyle zafer kazan", "done": int(data.get("curse_wins", 0)) > 0},
		{"name": "SKOR AVCISI", "desc": "tek koşuda 4000+ skor", "done": int(data.get("best_score", 0)) >= 4000},
		{"name": "MARATONCU", "desc": "tek koşuda 14+ dakika dayan", "done": int(data.get("best_depth", 0)) >= 840},
		{"name": "KOZ KOLEKSİYONCUSU", "desc": "7 koz kartının hepsini kullan", "done": (data.get("arcanas_seen", []) as Array).size() >= Boons.ARCANAS.size()},
	]

# feats completed since last check — announced once via toast
func new_feats() -> Array:
	var seen: Array = data.get("feats_seen", [])
	var out: Array = []
	for a in achievements():
		if bool(a.done) and not seen.has(str(a.name)):
			seen.append(str(a.name))
			out.append(str(a.name))
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
