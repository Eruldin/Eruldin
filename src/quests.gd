class_name Quests
extends RefCounted

# BG2-style quest journal: NPCs offer quests; progress is tracked live during
# runs (kills / kind_kills / time / boss downs / loot); turn-in at the giver
# pays choralim, items, or unlocks world-map nodes.

# objective types:
#   kills n               — total kills this run
#   kind <name> n         — kills of one enemy kind (KIND_NAME)
#   time n                — survive n seconds in one run
#   boss <id>             — defeat boss id ("rex","host","twins","final")
#   win                   — any victory
#   elites n              — elite kills this run
#   evos n                — evolutions this run
#   loot n                — items found this run
#   biomes n              — visit n distinct areas (meta.visited)
# reward: {"cho": int, "item": id, "node": node_id, "wep": weapon_id}
const DEFS := [
	{"id": "q_kan",    "giver": "rhasa",   "name": "KAN VERGİSİ",      "desc": "Kovan kanla beslenir. Tek koşuda 200 kesim yap.",         "obj": {"type": "kills", "n": 200},  "rew": {"cho": 60}},
	{"id": "q_varl",   "giver": "ehnar",   "name": "ÇÖLAYAN AVI",      "desc": "Çölayan Varl'lar kamp sınırını kokluyor. 25 tanesini kes.", "obj": {"type": "kind", "k": "Çölayan Varl", "n": 25}, "rew": {"cho": 50, "item": "i_cizme"}},
	{"id": "q_surv",   "giver": "neva",    "name": "REZONANS TÜRKÜSÜ", "desc": "Şarkıya altı dakika dayan — bir koşuda 360 sn hayatta kal.", "obj": {"type": "time", "n": 360}, "rew": {"cho": 80}},
	{"id": "q_rex",    "giver": "rhasa",   "name": "DÜŞMÜŞ KARDEŞ",    "desc": "Alfa-05'i serbest bırak — Endusterra'nın efendisini düşür.", "obj": {"type": "boss", "k": "rex"}, "rew": {"cho": 120, "node": "yol"}},
	{"id": "q_elit",   "giver": "ehnar",   "name": "ELİT DEFTERİ",     "desc": "Elitler sandık taşır. Tek koşuda 6 elit kes.",             "obj": {"type": "elites", "n": 6},   "rew": {"cho": 70, "item": "i_hirsiz"}},
	{"id": "q_evo",    "giver": "vane",    "name": "SAHA DENEYİ",      "desc": "Evrim zincirini test et — bir koşuda 2 evrim tamamla.",    "obj": {"type": "evos", "n": 2},     "rew": {"cho": 90, "item": "i_maske"}},
	{"id": "q_host",   "giver": "david",   "name": "DAMARLARIN KALBİ", "desc": "Simithar'ın Konakçı'sını düşür — madenin kapağını açar.",  "obj": {"type": "boss", "k": "host"}, "rew": {"cho": 140, "node": "tarla"}},
	{"id": "q_loot",   "giver": "saphire", "name": "HURDA MERAKI",     "desc": "Pazar için malzeme lazım. Bir koşuda 3 eşya bul.",         "obj": {"type": "loot", "n": 3},    "rew": {"cho": 60, "node": "pazar"}},
	{"id": "q_gez",    "giver": "david",   "name": "İZ SÜRÜCÜNÜN İZİ", "desc": "Dört sahayı da gör. Her bioma bir koşu yap.",              "obj": {"type": "biomes", "n": 4},   "rew": {"cho": 110, "item": "i_ikiz"}},
	{"id": "q_final",  "giver": "zirkon",  "name": "SON KAYIT",        "desc": "Masadaki son iki isim: Kirin ve Constantin'i düşür.",      "obj": {"type": "boss", "k": "final"}, "rew": {"cho": 250, "item": "i_final"}},
	{"id": "q_zafer",  "giver": "ahusk",   "name": "GÖÇEBENİN İNADI",  "desc": "Kovandan kaçan yaşar, kovana dönen kazanır. Bir zafer getir.", "obj": {"type": "win"}, "rew": {"cho": 100, "item": "i_kantas"}},
	{"id": "q_deep",   "giver": "vane",    "name": "DERİN PROTOKOL",   "desc": "Aeterna'nın altında bir şey sinyal veriyor — Kirin sonrası açılır.", "obj": {"type": "boss", "k": "final"}, "rew": {"node": "kuyu"}, "prereq": "q_final"},
	# — zincir görevler: ilk halka teslim edilince ikincisi açılır —
	{"id": "q_varl2",  "giver": "ehnar",   "name": "SINIR TEMİZLİĞİ",  "desc": "Sınır hâlâ sıcak. 40 Çölayan Varl daha kes — bu sefer kökünden.", "obj": {"type": "kind", "k": "Çölayan Varl", "n": 40}, "rew": {"cho": 80, "item": "i_ruzgar"}, "prereq": "q_varl"},
	{"id": "q_kan2",   "giver": "rhasa",   "name": "KAN ORANI",        "desc": "Vergi büyüdü. Tek koşuda 300 kesim — kovan bunu hissedecek.",  "obj": {"type": "kills", "n": 300},  "rew": {"cho": 120, "item": "i_halka2"}, "prereq": "q_kan"},
	{"id": "q_surv2",  "giver": "neva",    "name": "UZUN TÜRKÜ",       "desc": "Şarkı sekiz dakikaya uzuyor — bir koşuda 480 sn hayatta kal.",  "obj": {"type": "time", "n": 480},   "rew": {"cho": 130, "item": "i_aegis"}, "prereq": "q_surv"},
	{"id": "q_loot2",  "giver": "saphire", "name": "KOLEKSİYONCUNUN GÖZÜ", "desc": "Tezgâh doluyor ama hâlâ eksik. Bir koşuda 6 eşya bul — karşılığında bilinen bir rota var.", "obj": {"type": "loot", "n": 6}, "rew": {"cho": 120, "node": "yuvalar"}, "prereq": "q_loot"},
	{"id": "q_vatika", "giver": "neva",    "name": "SESSİZ VATİKA",    "desc": "Aeterna dibinde bir sığınak var. Uzun Türkü'nü bitirene yolu açarım.", "obj": {"type": "boss", "k": "twins"}, "rew": {"node": "vatika"}, "prereq": "q_surv2"},
	{"id": "q_dua",    "giver": "ahusk",   "name": "SESSİZ DUA",       "desc": "Mabed hâlâ dinliyor. Bir koşuda 300 sn boyunca tek parça kal — tapınağın yolu açılır.", "obj": {"type": "time", "n": 300}, "rew": {"cho": 90, "node": "mabed"}},
	{"id": "q_nobet",  "giver": "ehnar",   "name": "SON NÖBET",        "desc": "Mezardaki nöbetçiler sayıyor. Tek koşuda 10 elit kes — mezarın kapağı kalkar.", "obj": {"type": "elites", "n": 10}, "rew": {"cho": 110, "node": "mezarlik"}, "prereq": "q_elit"},
	{"id": "q_batak",  "giver": "david",   "name": "BATAKLIK ROTASI",   "desc": "Konakçı Yaratıkların izi doğuda bir bataklığa çıkıyor. 8 tanesini kes — rotayı çizerim.", "obj": {"type": "kind", "k": "Konakçı Yaratık", "n": 8}, "rew": {"cho": 90, "node": "batak"}, "prereq": "q_gez"},
	{"id": "q_sis",    "giver": "ahusk",   "name": "SİS PERDESİ",        "desc": "Kistlerin şarkısı batıda bir geçidi işaretliyor. 12 Cerebellum Kisti kes — geçidi bulayım.", "obj": {"type": "kind", "k": "Cerebellum Kisti", "n": 12}, "rew": {"cho": 100, "node": "sisgecidi"}, "prereq": "q_dua"},
	{"id": "q_sinir",  "giver": "david",   "name": "HARİTA SINIRI",      "desc": "Haritanın tamamı yankılanmalı. Altı farklı sahada koşu yap.", "obj": {"type": "biomes", "n": 6}, "rew": {"cho": 150}, "prereq": "q_batak"},
	{"id": "q_nobet2", "giver": "ehnar",   "name": "NÖBETÇİNİN KİLİDİ",  "desc": "Elitler defterde iz bırakır. Tek koşuda 15 elit kes — rekoru kır.", "obj": {"type": "elites", "n": 15}, "rew": {"cho": 140, "item": "i_gocek"}, "prereq": "q_nobet"},
	{"id": "q_lanet", "giver": "saphire", "name": "LANETLİ MALLAR",    "desc": "Kızıl sandıklar pusu taşıyor ama içi dolu. 3 lanetli sandık aç — pusuya değer.", "obj": {"type": "cursed", "n": 3}, "rew": {"cho": 130, "item": "i_bosluk"}, "prereq": "q_loot"},
	{"id": "q_kul",   "giver": "david",   "name": "KÜL ROTASI",         "desc": "Kuyu'nun doğusunda kül hâlâ yanıyor — Alfa Şövalyeleri orada toplanıyor. 10 tanesini kes, rotayı çıkarayım.", "obj": {"type": "kind", "k": "Alfa Şövalye", "n": 10}, "rew": {"cho": 150, "node": "kulovasi"}, "prereq": "q_sinir"},
	{"id": "q_yemin", "giver": "ehnar",   "name": "DARE YEMİNİ",        "desc": "Güneyde eski bir dare yeri var — şifa küresi düşmeyen meydan. Bir zafer getir, yemin kapısını açayım.", "obj": {"type": "win"}, "rew": {"cho": 180, "node": "yemin"}, "prereq": "q_nobet"},
	{"id": "q_iz",    "giver": "neva",    "name": "YANKININ İZİ",       "desc": "Düştüğün yerde parçacıkların kalır. Öldüğün sahaya geri dön, eski cesedinden yükünü geri al — iki kez.", "obj": {"type": "ceset", "n": 2}, "rew": {"cho": 140, "item": "i_koro"}, "prereq": "q_surv"},
	{"id": "q_aura",  "giver": "vane",    "name": "AURA FİŞEĞİ",         "desc": "Rezonans protokolü denemeye hazır. Tek koşuda 12 elit kes — fişeği sana bağlarım.", "obj": {"type": "elites", "n": 12}, "rew": {"cho": 160, "wep": "aura"}, "prereq": "q_nobet"},
	{"id": "q_skor",  "giver": "rhasa",   "name": "SKOR VERGİSİ",        "desc": "Kovan rekor sever. Tek koşuda 4000 skor yap — oranını yükseltirim.", "obj": {"type": "score", "n": 4000}, "rew": {"cho": 260}, "prereq": "q_kan2"},
	{"id": "q_vergi", "giver": "rhasa",   "name": "ALTIN VERGİ",         "desc": "Kovan altınla sınanır — sahada gezen şampiyonların madalyonları hazinenin. Üç şampiyon kes, kovan seni tanısın.", "obj": {"type": "champ", "n": 3}, "rew": {"cho": 300, "item": "i_cengel"}, "prereq": "q_skor"},
	{"id": "q_frag",  "giver": "saphire", "name": "PARÇACIK HASADI",     "desc": "Tezgâh parçacıksız dönmez. Tek koşuda 600 parçacık topla — kesende dursun, teslime gerek yok.", "obj": {"type": "frag", "n": 600}, "rew": {"cho": 140}, "prereq": "q_loot"},
	{"id": "q_glaive","giver": "ehnar",   "name": "AĞIR TAHMİS",         "desc": "Sırp diskleri depoda paslanıyor. Tek koşuda 400 kesim yaparsan birini sana kalibrarım.", "obj": {"type": "kills", "n": 400}, "rew": {"cho": 150, "wep": "glaive"}, "prereq": "q_nobet2"},
	{"id": "q_deneme","giver": "ehnar",   "name": "DENEME KANITI",       "desc": "Sahalardaki eski deneme totemleri hâlâ sayıyor. İkisini tamamla — ikisinin de elitleri düşsün.", "obj": {"type": "totem", "n": 2}, "rew": {"cho": 170, "item": "i_koro"}, "prereq": "q_elit"},
	{"id": "q_damar", "giver": "saphire", "name": "DAMAR AVCISI",          "desc": "Sahalarda altın choralim damarları beliriyor — yanında durup kır, parçacıklar senin. Üçünü kır.", "obj": {"type": "vein", "n": 3}, "rew": {"cho": 220}, "prereq": "q_frag"},
	{"id": "q_son",   "giver": "zirkon",  "name": "ARŞİVİN SONU",        "desc": "Defterin son sayfası boş kalmasın. On görev teslim et — arşivin mührü senin olsun.", "obj": {"type": "quests", "n": 10}, "rew": {"cho": 400, "wep": "meteor"}, "prereq": "q_final"},
	{"id": "q_siparis","giver": "saphire","name": "MÜŞTERİ SİPARİŞİ",    "desc": "Bir müşteri Boşluk Halkası istiyor — bulursan stoğa değil, doğrudan bana getir. Teslimde parça senden çıkar.", "obj": {"type": "item", "id": "i_bosluk", "n": 1}, "rew": {"cho": 320, "item": "i_ruzgar"}, "prereq": "q_lanet"},
	{"id": "q_kayit", "giver": "zirkon",  "name": "VERİ AVCISI",          "desc": "Sahalarda hâlâ kütük parçaları saçılı. Beş veri kütüğü topla — arşiv senden borçlu kalacak.", "obj": {"type": "kayit", "n": 5}, "rew": {"cho": 180, "item": "i_merdiven"}, "prereq": "q_final"},
	{"id": "q_sampiyon","giver": "ehnar", "name": "ALTIN TEHDİT",        "desc": "Geç saatlerde altınla parlayan şampiyonlar geziyor — birini kes, madalyonun benim olsun.", "obj": {"type": "champ", "n": 1}, "rew": {"cho": 220}, "prereq": "q_nobet2"},
	{"id": "q_anil",  "giver": "david",   "name": "SON İZLER",            "desc": "Müfretemin son izi Kızıl Çöl'de bitti. Yedi sahayı da gör — haritanın tamamı yankılansın, eski defter kapansın.", "obj": {"type": "biomes", "n": 7}, "rew": {"cho": 300, "cine": [{"tex": "por_david", "title": "DAVID", "sub": "Hepsini gördün. Müfretemin izi artık haritada değil — hatırada."}, {"tex": "cine_6_0", "title": "SON İZ", "sub": "Kızıl Çöl'ün kumunda yarım bir izcilik nişanı: S-7. Geri getiren tek parçacık oydu."}]}, "prereq": "q_kul"},
	{"id": "q_tekel", "giver": "saphire", "name": "TEKEL BARIŞI",        "desc": "Açgöz bobinleri hâlâ işliyor — tek koşuda 1800 parçacık biriktir, bobinin kalibrasyon hakkı senin.", "obj": {"type": "frag", "n": 1800}, "rew": {"cho": 260}, "prereq": "q_damar"},
	{"id": "q_vaha",  "giver": "saphire", "name": "ÇÖLÜN ALACASI",       "desc": "Kervanlar bir vaha rotasını benden gizledi — tek koşuda 900 parçacık getir, haritadaki yeşil lekeyi sana satarım.", "obj": {"type": "frag", "n": 900}, "rew": {"cho": 220, "node": "vaha"}, "prereq": "q_tekel"},
	{"id": "q_fener", "giver": "ehnar",  "name": "YANKI AVCISI",         "desc": "Sahalardaki sinyal fenerleri yankı şampiyonları uyandırıyor. Üç feneri kır — deneme alanı temizlensin.", "obj": {"type": "fener", "n": 3}, "rew": {"cho": 280, "item": "i_cengel"}, "prereq": "q_deneme"},
	{"id": "q_ocak",  "giver": "ehnar",   "name": "OCAĞIN KAPISI",       "desc": "Kuzeyde çatlak bir ocak var — elitler nabzını koruyor. Tek koşuda 12 elit kes — kapıyı göstereyim.", "obj": {"type": "elites", "n": 12}, "rew": {"cho": 160, "node": "tasocagi"}, "prereq": "q_nobet"},
	{"id": "q_lena",  "giver": "lena",    "name": "LENA'NIN HARİTASI",    "desc": "Kafes beni haritadan attı; haritayı geri çizelim. Üç farklı düğümde zafer getir — pusulamı sana bırakırım.", "obj": {"type": "nodes", "n": 3}, "rew": {"cho": 200, "item": "i_pusula"}},
	{"id": "q_koro",  "giver": "lena",    "name": "ÇAN KESİCİ",           "desc": "Haritada bir yeri işaretledim: orada sürüyü çanla yöneten sözcüler dolaşıyor. Altısını kes, güzergâhlar açılsın — vizörüm senin.", "obj": {"type": "kind", "k": "Koro Sözcüsü", "n": 6}, "rew": {"cho": 220, "item": "i_gocek"}, "prereq": "q_lena"},
	{"id": "q_kum",   "giver": "lena",    "name": "KUM SESLERİ",          "desc": "Çölayan varllerin izleri batıdaki kızıl kuma uzanıyor — on tanesinin izini sür, çölün kapısını haritaya işlerim.", "obj": {"type": "kind", "k": "Çölayan Varl", "n": 10}, "rew": {"cho": 200, "node": "kum"}, "prereq": "q_koro"},
	{"id": "q_sofra", "giver": "mina",    "name": "SOFRANIN BEREKETİ",    "desc": "Sahada düşen her şifa küresi ocak için malzeme — on beşini topla, senin için saklarım.", "obj": {"type": "sifa", "n": 15}, "rew": {"cho": 160, "item": "i_cevher"}},
	{"id": "q_ziyafet","giver": "mina",   "name": "KURTULUŞ ZİYAFETİ",    "desc": "Büyük sofra büyük malzeme ister. Otuz küre daha — karşılığında damlayı veririm, seni geri getirir.", "obj": {"type": "sifa", "n": 30}, "rew": {"cho": 320, "item": "i_neva"}, "prereq": "q_sofra"},
]

# states in meta.data["quests"]: qid -> {"st": "act"|"done"|"claimed", "prog": int}
static func _q() -> Dictionary:
	if not G.meta.data.has("quests"):
		G.meta.data["quests"] = {}
	return G.meta.data["quests"]

static func state(id: String) -> String:
	var st := str(_q().get(id, {}).get("st", ""))
	# meta-seviye objektifler (eşya teslimi, kütük toplama) tembel kontrol edilir —
	# koşu dışında da ilerleyebildikleri için state() okurken tamamlanmayı denetler
	if st == "act":
		var q := def(id)
		var t := str(q.obj.get("type", ""))
		var cur := -1
		if t == "item":
			cur = _item_count(str(q.obj.get("id", "")))
		elif t == "kayit":
			cur = (G.meta.data.get("lore", []) as Array).size()
		elif t == "nodes":
			cur = (G.meta.data.get("won_nodes", []) as Array).size()
		if cur >= 0:
			_q()[id]["prog"] = maxi(prog(id), cur)
		if cur >= int(q.obj.get("n", 1)):
			_q()[id]["st"] = "done"
			st = "done"
			G.meta.save()
	return st

static func _item_count(iid: String) -> int:
	var n := 0
	for v in (G.meta.data.get("stash", []) as Array):
		if str(v) == iid:
			n += 1
	for s in (G.meta.data.get("equip", {}) as Dictionary).values():
		if str(s) == iid:
			n += 1
	return n

static func prog(id: String) -> int:
	return int(_q().get(id, {}).get("prog", 0))

static func def(id: String) -> Dictionary:
	for q in DEFS:
		if q.id == id:
			return q
	return {}

static func available_for(nid: String) -> Array:
	var out: Array = []
	for q in DEFS:
		if q.giver != nid:
			continue
		if state(q.id) != "":
			continue
		var pre := str(q.get("prereq", ""))
		if pre != "" and state(pre) != "claimed":
			continue
		out.append(q)
	return out

# quests this NPC can take back: done but unclaimed
static func claimable_for(nid: String) -> Array:
	var out: Array = []
	for q in DEFS:
		if q.giver == nid and state(q.id) == "done":
			out.append(q)
	return out

static func active() -> Array:
	var out: Array = []
	for q in DEFS:
		if state(q.id) == "act":
			out.append(q)
	return out

# quests this NPC gave that are still being worked
static func active_for(nid: String) -> Array:
	var out: Array = []
	for q in DEFS:
		if q.giver == nid and state(q.id) == "act":
			out.append(q)
	return out

# anything to talk about: new offer, live progress, or a claimable reward
static func has_business(nid: String) -> bool:
	return not (available_for(nid).is_empty() and claimable_for(nid).is_empty() and active_for(nid).is_empty())

# koşu sonunda kalan tüm objektif tiplerini son durumla değerlendir
static func tick_all() -> void:
	var done: Array = []
	for type in ["kills", "time", "elites", "evos", "loot", "biomes", "win", "score", "frag", "quests", "item", "kayit", "champ", "vein", "nodes"]:
		done.append_array(tick(type))
	for q in DEFS:
		if state(q.id) != "act" or str(q.obj.get("type", "")) != "boss":
			continue
		var need := str(q.obj.get("k", ""))
		if (G.meta.data.get("bosses", []) as Array).has(need):
			_q()[q.id]["st"] = "done"
			_q()[q.id]["prog"] = 1
			done.append(q)
	for q in DEFS:
		if state(q.id) != "act" or str(q.obj.get("type", "")) != "kind":
			continue
		var kk: Dictionary = G.run.stats.get("kind_kills", {})
		var cur := int(kk.get(str(q.obj.k), 0))
		_q()[q.id]["prog"] = cur
		if cur >= int(q.obj.get("n", 1)):
			_q()[q.id]["st"] = "done"
			done.append(q)
	if not done.is_empty():
		G.meta.save()
		_announce(done)

static func _announce(done_now: Array) -> void:
	for q in done_now:
		if is_instance_valid(G.ui):
			G.ui.toast("GÖREV TAMAM: %s — %s yanına dön" % [str(q.name), str(NPC.NAMES.get(str(q.giver), str(q.giver)))])
			G.audio.jingle("boon")

static func accept(id: String) -> void:
	_q()[id] = {"st": "act", "prog": 0}
	G.meta.save()

static func abandon(id: String) -> void:
	_q().erase(id)
	G.meta.save()

# live progress — called from run hooks; returns quests that just finished
static func tick(type: String, arg := "", n := 1) -> Array:
	var done_now: Array = []
	for q in DEFS:
		if state(q.id) != "act":
			continue
		var o: Dictionary = q.obj
		if str(o.type) != type:
			continue
		if str(o.get("k", "")) != "" and arg != str(o.k):
			continue
		# boss/biomes check absolute values, not increments
		var need := int(o.get("n", 1))
		var cur: int
		match type:
			"kills":   cur = int(G.run.stats.get("kills", 0))
			"kind":    cur = int(G.run.stats.get("kind_kills", {}).get(arg, 0))
			"time":    cur = int(G.run.time)
			"elites":  cur = int(G.run.stats.get("elite_kills", 0))
			"evos":    cur = int(G.run.stats.get("evos", 0))
			"loot":    cur = (G.run.stats.get("loot", []) as Array).size()
			"win":     cur = 1 if bool(G.run.stats.get("won", false)) else 0
			"biomes":  cur = (G.meta.data.get("visited", []) as Array).size()
			"nodes":   cur = (G.meta.data.get("won_nodes", []) as Array).size()
			"score":   cur = int(G.run.stats.get("score", 0))
			"frag":    cur = int(G.run.fragments)
			"quests":  cur = _claimed_count()
			"item":    cur = _item_count(str(o.get("id", "")))
			"champ":   cur = int(G.run.stats.get("champ_kills", 0))
			"kayit":   cur = (G.meta.data.get("lore", []) as Array).size()
			_:         cur = prog(q.id) + n
		_q()[q.id]["prog"] = maxi(prog(q.id), cur)
		if cur >= need:
			_q()[q.id]["st"] = "done"
			done_now.append(q)
	if not done_now.is_empty():
		G.meta.save()
		_announce(done_now)
	return done_now

static func claim(id: String) -> Dictionary:
	if state(id) != "done":
		return {}
	var q := def(id)
	_q()[id]["st"] = "claimed"
	var rew: Dictionary = q.get("rew", {})
	if int(rew.get("cho", 0)) > 0:
		G.meta.data["choralim"] = int(G.meta.data.get("choralim", 0)) + int(rew.cho)
	if str(rew.get("item", "")) != "":
		var st: Array = G.meta.data.get("stash", [])
		if not st.has(str(rew.item)):
			st.append(str(rew.item))
		G.meta.data["stash"] = st
	if str(rew.get("node", "")) != "":
		var un: Array = G.meta.data.get("unlocked", [])
		if not un.has(str(rew.node)):
			un.append(str(rew.node))
		G.meta.data["unlocked"] = un
	# eşya teslimi görevi: müşteriye giden parça stoğu/equipten düşer
	if str(q.obj.get("type", "")) == "item":
		var iid := str(q.obj.get("id", ""))
		var st2: Array = G.meta.data.get("stash", [])
		if st2.has(iid):
			st2.erase(iid)
		else:
			var eq: Dictionary = G.meta.data.get("equip", {})
			for sl in eq:
				if str(eq[sl]) == iid:
					eq.erase(sl)
					break
			G.meta.data["equip"] = eq
		G.meta.data["stash"] = st2
	if str(rew.get("wep", "")) != "":
		var wu: Array = G.meta.data.get("wep_unlocked", [])
		if not wu.has(str(rew.wep)):
			wu.append(str(rew.wep))
		G.meta.data["wep_unlocked"] = wu
	G.meta.save()
	return rew

static func rew_text(rew: Dictionary) -> String:
	var parts: Array = []
	if int(rew.get("cho", 0)) > 0:
		parts.append("◆ %d choralim" % int(rew.cho))
	if str(rew.get("item", "")) != "":
		parts.append("eşya: %s" % str(Items.DEFS.get(str(rew.item), {}).get("name", rew.item)))
	if str(rew.get("node", "")) != "":
		parts.append("yeni bölge açıldı")
	if str(rew.get("wep", "")) != "":
		parts.append("silah: %s" % str(Weapons.DEFS.get(str(rew.wep), {}).get("name", rew.wep)))
	if rew.get("cine") is Array and not (rew["cine"] as Array).is_empty():
		parts.append("anı kaydı")
	return " + ".join(parts)

static func obj_text(q: Dictionary) -> String:
	var o: Dictionary = q.obj
	var need := int(o.get("n", 1))
	match str(o.type):
		"kills":  return "%d kesim" % need
		"kind":   return "%s x%d" % [str(o.k), need]
		"time":   return "%d sn hayatta kal" % need
		"boss":   return "efendi: %s" % str(o.k).to_upper()
		"win":    return "bir zafer"
		"elites": return "%d elit" % need
		"evos":   return "%d evrim" % need
		"loot":   return "%d eşya" % need
		"biomes": return "%d farklı saha" % need
		"score":  return "%d skor" % need
		"frag":   return "%d parçacık topla" % need
		"totem":  return "%d deneme totemi tamamla" % need
		"fener":  return "%d sinyal feneri kır" % need
		"vein":   return "%d choralim damarı kır" % need
		"quests": return "%d görev teslim et" % need
		"item":   return "%s getir" % str(Items.DEFS.get(str(o.get("id", "")), {}).get("name", str(o.get("id", ""))))
		"kayit":  return "%d veri kütüğü bul" % need
		"champ":  return "%d şampiyon elit kes" % need
	return "?"

static func _claimed_count() -> int:
	var n := 0
	for qid in _q():
		if str(_q()[qid].get("st", "")) == "claimed":
			n += 1
	return n

static func prog_text(q: Dictionary) -> String:
	var o: Dictionary = q.obj
	var need := int(o.get("n", 1))
	return "%d / %d" % [mini(prog(q.id), need), need]

# ---------------------------------------------------------------- veri kütükleri
# Sahada nadiren düşen kalıcı lore parçaları — meta.data["lore"] listesine yazar,
# Zirkon'un kayıtlarındaki ÖYKÜ codex'inde okunur (BG2 kitap/not sistemi).
const LORE := [
	{"id": "l_protokol", "name": "KÜTÜK: PROTOKOLÜN DOĞUŞU", "txt": "Choralim protokolü bir silah değildi — bir vaatti. Viator ilk praetorianı gömdüğünde rezonans bir daha susmadı."},
	{"id": "l_kovan",    "name": "KÜTÜK: KOVANIN İLKİ",     "txt": "Kovan önce böcek değildi. İmparatorluk savas uşaklarını korozyona saldı; korozyon onları geri gönderdi — değişmiş olarak."},
	{"id": "l_alfa05",   "name": "KÜTÜK: ALFA-05'İN SONU",  "txt": "Beşinci praetorian Endusterra'da düştü. Kraterdeki zırh hâlâ sıcak — kovan cesedine dokunmaya korkuyor."},
	{"id": "l_viator",   "name": "KÜTÜK: VIATOR ANDI",      "txt": "'Kırılan geri döner, dönen tekrar kırılır.' Viator kampı bu andın üstüne kuruldu — ateş hiç sönmez."},
	{"id": "l_simithar", "name": "KÜTÜK: SİMİTHAR",         "txt": "Maden cevheri sadece metal değil — damarların içinde eski imparatorluğun belleği saklı. Kes ve anılar sana akar."},
	{"id": "l_masa",     "name": "KÜTÜK: SON MASA",         "txt": "Efendiler bir masanın etrafında oturur: Rex, Host, Nahum & Tuman, Kirin & Constantin. Boş sandalye sizin için ayrılmış."},
	{"id": "l_neva",     "name": "KÜTÜK: NEVA'NIN ŞARKISI", "txt": "Neva'nın türküsü dua değil, talimattır. Rezonans onu dinler — seni geri getiren o frekans."},
	{"id": "l_sis",      "name": "KÜTÜK: SİS PERDESİ",      "txt": "Batıdaki sis hava değil — bataklığın nefesi. Göçebeler oraya 'duvar' der; kistler içinde şarkı söyler."},
]
