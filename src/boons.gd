class_name Boons
extends RefCounted

# Boon (Lütuf) system — Resonance Protocols. Each patron grants a themed set.
# rarity: 0 common, 1 rare, 2 epic. Applied instantly on pick, run-scoped.

static func all() -> Array:
	return [
		# --- Rhasa Doktrini (physical) ---
		{"id":"crushing","patron":"Rhasa","name":"Ezici Vuruşlar","desc":"+%20 kılıç hasarı","rarity":0,"color":Px.C("a8842f")},
		{"id":"shredder","patron":"Rhasa","name":"Zırh Kemiren","desc":"Vuruşlar zırhı yok sayar, +4 düz hasar","rarity":1,"color":Px.C("a8842f")},
		{"id":"veteran","patron":"Rhasa","name":"Kıdemli Kavrama","desc":"+%12 saldırı hızı","rarity":0,"color":Px.C("a8842f")},
		{"id":"bulwark","patron":"Rhasa","name":"Siper Doktrini","desc":"+2 zırh, -%8 alınan hasar","rarity":1,"color":Px.C("a8842f")},
		{"id":"shockslam","patron":"Rhasa","name":"Şok Darbesi","desc":"Ağır vuruşlar alan şoku salar","rarity":2,"color":Px.C("a8842f")},
		# --- Neva Rezonansı (telekinesis) ---
		{"id":"well","patron":"Neva","name":"Yerçekimi Anomalisi","desc":"Vuruşlar %25 ihtimalle düşmanları çeker","rarity":1,"color":Px.C("7B1FA2")},
		{"id":"homing","patron":"Neva","name":"Kıvrılan Mermiler","desc":"Plazma mermileri hedefe döner","rarity":1,"color":Px.C("7B1FA2")},
		{"id":"mind","patron":"Neva","name":"Zihin Kırılması","desc":"+%15 kritik ihtimali","rarity":0,"color":Px.C("7B1FA2")},
		{"id":"aegis","patron":"Neva","name":"Telekinetik Zırh","desc":"Dash sonrası +0.15sn dokunulmazlık","rarity":2,"color":Px.C("7B1FA2")},
		{"id":"revive","patron":"Neva","name":"İkinci Nefes","desc":"Ölümden bir kez %40 canla dönersin","rarity":2,"color":Px.C("7B1FA2")},
		# --- Saphire Kabile Taktikleri ---
		{"id":"venom","patron":"Saphire","name":"Zehir Sürme","desc":"Vuruşlar zehir bırakır (hasarın %25'i/sn)","rarity":0,"color":Px.C("00E676")},
		{"id":"predator","patron":"Saphire","name":"Avcı Odağı","desc":"+%10 kritik, kritik ×2.4","rarity":1,"color":Px.C("00E676")},
		{"id":"swift","patron":"Saphire","name":"Yıldırım Ayaklar","desc":"Dash yenilenmesi %35 hızlı","rarity":0,"color":Px.C("00E676")},
		{"id":"camo","patron":"Saphire","name":"Kamuflaj Sıçrayışı","desc":"Dash sonrası 1.2sn düşmanlar seni görmez","rarity":2,"color":Px.C("00E676")},
		{"id":"ritm","patron":"Saphire","name":"Seri Ritim","desc":"Katliam serisi x30 üstündeyken +%30 hareket hızı","rarity":1,"color":Px.C("00E676")},
		{"id":"regen","patron":"Saphire","name":"Köksülük","desc":"Saniyede +0.8 can yenilenmesi","rarity":1,"color":Px.C("00E676")},
		# --- Rex Sibernetik Glitch ---
		{"id":"emp","patron":"Rex","name":"EMP Patlaması","desc":"Vuruşlar %20 ihtimalle zincir şok salar","rarity":1,"color":Px.C("ff4444")},
		{"id":"overcharge","patron":"Rex","name":"Aşırı Isınma","desc":"+%35 plazma hasarı, daha hızlı dolum","rarity":1,"color":Px.C("ff4444")},
		{"id":"static","patron":"Rex","name":"Statik Alan","desc":"Yakındaki düşmanlar saniyede 6 şok hasarı alır","rarity":0,"color":Px.C("ff4444")},
		{"id":"parryemp","patron":"Rex","name":"Kafa Karıştıran","desc":"Her 6sn etrafında şok dalgası patlatır","rarity":2,"color":Px.C("ff4444")},
		{"id":"xpgain","patron":"Rex","name":"İşlemci Aşısı","desc":"+%15 deneyim kazanımı","rarity":0,"color":Px.C("ff4444")},
		{"id":"heartcall","patron":"Neva","name":"Kan Çağrısı","desc":"Şifa küresi düşme şansı iki katına çıkar","rarity":1,"color":Px.C("7B1FA2")},
		# --- Kovan Mutasyonu (chaos — bedelli) ---
		{"id":"bloodlust","patron":"Kovan","name":"Kan Hırsı","desc":"+%40 hasar — ama +%15 hasar alırsın","rarity":1,"color":Px.C("39ff14")},
		{"id":"frenzy","patron":"Kovan","name":"Kuduz","desc":"+%18 saldırı hızı — ama -15 azami can","rarity":0,"color":Px.C("39ff14")},
		{"id":"carapace","patron":"Kovan","name":"Et Zırhı","desc":"+%8 can çalma — ama -%10 azami can","rarity":2,"color":Px.C("39ff14")},
		{"id":"scav","patron":"Kovan","name":"Çöpçü İçgüdüsü","desc":"Elit kesimi +8 can yeniler","rarity":2,"color":Px.C("39ff14")},
	]

static func roll(owned: Array, luck := 0.0) -> Array:
	# pick 3 distinct boons not already owned; weight by rarity (epic rare)
	var pool: Array = []
	for b in all():
		if owned.has(b.id):
			continue
		var w: float = [10.0, 4.0, 1.4][int(b.rarity)]
		if int(b.rarity) == 2:
			w += luck * 3.0
		pool.append({"b": b, "w": w})
	var out: Array = []
	for i in 3:
		if pool.is_empty():
			break
		var total := 0.0
		for e in pool: total += e.w
		var r := G.rf(0, total)
		var acc := 0.0
		var idx := 0
		for j in pool.size():
			acc += pool[j].w
			if r <= acc:
				idx = j
				break
		out.append(pool[idx].b)
		pool.remove_at(idx)
	return out

# KOZ kartları (VS arcana): koşu başında bir tane seçilir, tüm koşuyu boylar
const ARCANAS := {
	"kan":     {"name": "KAN AYI",       "desc": "+%12 can çalma — ama -%15 azami can", "col": "ff4444"},
	"firtina": {"name": "FIRTINA GÖZÜ",  "desc": "Kristaller çok uzaktan sana doğru akar", "col": "00E5FF"},
	"sari":    {"name": "SARI HAT",      "desc": "Elitler %20 daha sık doğar — ödeme ×1.25", "col": "ffb74d"},
	"golge":   {"name": "GÖLGE ADIM",    "desc": "Sürü %10 yavaşlar — sen %5 yavaşsın", "col": "7B1FA2"},
	"hasat":   {"name": "HASAT ŞENLİĞİ", "desc": "Her kesimde %2 ihtimalle +1 parçacık", "col": "39ff14"},
	"temkin":  {"name": "TEMKİN ZIRHI",  "desc": "+3 zırh — ama -%8 hasar", "col": "8ea0b5"},
	"kum":     {"name": "KUM SAATİ",     "desc": "+%18 deneyim kazancı", "col": "f0e68c"},
	"aci":     {"name": "ACI ODAKI",     "desc": "+%20 kritik şansı — ama -%10 deneyim", "col": "ff8a65"},
	"hurda":   {"name": "HURDA KALBİ",   "desc": "+%35 şans — sahada eşya bereketi", "col": "8d6e63"},
	"yanki":   {"name": "ÇİFT YANKI",    "desc": "+1 ek atılım şarjı — ama -%8 hız", "col": "4dd0e1"},
	"kasa":    {"name": "KASA MÜHRÜ",    "desc": "Her sandık +25 parçacık döker — ödeme ×1.05", "col": "c9a227"},
	"kervan":  {"name": "KERVAN GÖZÜ",   "desc": "Sahada +3 kalıntı belirir — +40 toplama yarıçapı", "col": "80cbc4"},
	"toren":   {"name": "SESSİZ TÖREN",  "desc": "+%25 hasar — ama silahlar %12 yavaş atar", "col": "b26bff"},
	"nabiz":   {"name": "KORO NABZI",    "desc": "Q yeteneği %30 erken döner — ama -10 can", "col": "e8d060"},
	"alacak":  {"name": "ALACAKARANLIK", "desc": "Sürü baskınları %25 sıklaşır — ödeme ×1.10", "col": "5c6bc0"},
	"ocak":    {"name": "OCAK EKMEĞİ",    "desc": "Şifa küreleri yarı yarıya güçlü sarar", "col": "8bc34a"},
	"sarj":    {"name": "ŞARJ ISITICISI", "desc": "F aşırı yükü +4sn sürer — ama bedeli %50 artar", "col": "ffd75f"},
	"sofra":   {"name": "SOFRA DÜZENİ",   "desc": "İksir ve şarap %50 daha uzun/güçlü etki eder", "col": "ef5350"},
	"pence":   {"name": "PENÇE ROTASI",   "desc": "+%15 saldırı hızı — ama -%10 hasar", "col": "ff7043"},
	"yemin":   {"name": "DİRENÇ YEMİNİ",  "desc": "+1 dirilme hakkı — ama -%15 parçacık verimi", "col": "90a4ae"},
	"kirici":  {"name": "KIRICI ÖFKESİ",   "desc": "+%30 kritik hasarı — ama -%5 kritik şansı", "col": "ff5252"},
	"borclu":  {"name": "BORÇLU KADER",    "desc": "+300 koşu parçacığı — ama ödeme ×0.85", "col": "c9a227"},
	"sur":     {"name": "SUR ÇİZGİSİ",     "desc": "150 adım içindeki sürü %28 yavaşlar — ama -8 can", "col": "80d8ff"},
	"mercek":  {"name": "MERCEK DÜZENİ",   "desc": "+%22 etki alanı — ama -%8 hareket hızı", "col": "b26bff"},
	"ikiz":    {"name": "İKİZ SANDIK",     "desc": "Her sandık yanına bir eşiyle doğar — ama -%8 deneyim", "col": "ffb74d"},
	"efsaat":  {"name": "EFENDİ SAATİ",    "desc": "Efendiler %20 erken doğar — ama -8 azami can", "col": "ff5533"},
	"olayy":   {"name": "OLAY YERİ",        "desc": "Her seyahatte bir yol olayı — ama -%6 hareket hızı", "col": "e8a04c"},
	"kursun":  {"name": "NABIZ KURŞUNU",    "desc": "Baskın işaretli düğümde ganimet daha bereketli — ama sürü de sıklaşır", "col": "3ec8b8"},
	"kalip":   {"name": "AĞIR KALIP",       "desc": "+%35 hasar — ama -%12 saldırı hızı", "col": "90a4ae"},
	"celikk":  {"name": "ÇELİK KARIN",      "desc": "+30 azami can — ama -%10 hareket hızı", "col": "80d8ff"},
	"guzergah":{"name": "KAÇAK GÜZERGÂHI",  "desc": "Kaçak elitler çok daha sık çıkar — ama sürü %8 sıklaşır", "col": "ffd54f"},
	"yagma":   {"name": "KESKİN YAĞMA",     "desc": "Kritik vuruşlar %8 ihtimalle parçacık döker — ama -%10 deneyim", "col": "ffd75f"},
	"narakad": {"name": "NARA KADERİ",      "desc": "Fanatik elitler çok daha sık çıkar — ama -6 azami can", "col": "ff5252"},
	"itibar":  {"name": "KAMP ELBİSESİ",    "desc": "Kamp itibar kademesi başına +%6 hasar", "col": "c9a227"},
	"geri":    {"name": "GERİ KAZANIM",      "desc": "Her taslak seçimi +8 parçacık döker — ama -%8 deneyim", "col": "39ff14"},
}

static func apply_arcana(id: String, p: Player) -> void:
	match id:
		"kan":
			p.lifesteal += 0.12
			p.max_hp *= 0.85
			p.hp = minf(p.hp, p.max_hp)
		"firtina":
			p.magnet_r += 420.0
		"sari":
			G.run.elite_fever = true
			G.run.reward_mult *= 1.25
		"golge":
			G.run.slow_all = true
			p.speed *= 0.95
		"hasat":
			p.set_meta("harvest", true)
		"temkin":
			p.armor += 3.0
			p.dmg_mult *= 0.92
		"kum":
			p.xp_mult *= 1.18
		"aci":
			p.crit_ch += 0.20
			p.xp_mult *= 0.90
		"hurda":
			G.run.luck += 0.35
		"yanki":
			p.dash_max += 1
			p.dash_charges += 1
			p.speed *= 0.92
		"kasa":
			G.run.reward_mult *= 1.05
		"kervan":
			p.magnet_r += 40.0
		"toren":
			p.dmg_mult *= 1.25
			p.cd_mult *= 1.12
		"nabiz":
			p.skill_max *= 0.70
			p.max_hp -= 10.0
			p.hp = minf(p.hp, p.max_hp)
		"alacak":
			p.set_meta("surge_up", true)
			G.run.reward_mult *= 1.10
		"ocak":
			p.set_meta("heal_plus", true)
		"sarj":
			p.set_meta("over_dur", 4.0)
			p.set_meta("over_cost", 0.5)
		"sofra":
			p.set_meta("table", true)
		"pence":
			p.cd_mult *= 0.85
			p.dmg_mult *= 0.90
		"yemin":
			p.revives_extra += 1
			p.frag_mult *= 0.85
		"kirici":
			p.crit_mult += 0.30
			p.crit_ch -= 0.05
		"borclu":
			G.run.fragments += 300
			G.run.reward_mult *= 0.85
		"sur":
			p.set_meta("wall", true)
			p.max_hp -= 8.0
			p.hp = minf(p.hp, p.max_hp)
		"mercek":
			p.area_mult *= 1.22
			p.speed *= 0.92
		"ikiz":
			G.run.twin_chest = true
			p.xp_mult *= 0.92
		"efsaat":
			if G.director != null:
				G.director.mini_t *= 0.8
				G.director.final_t *= 0.8
			p.max_hp -= 8.0
			p.hp = minf(p.hp, p.max_hp)
		"olayy":
			G.run.waylay_chance = 1.0
			p.speed *= 0.94
		"kursun":
			G.run.baskin_plus = true
		"kalip":
			p.dmg_mult *= 1.35
			p.cd_mult *= 1.12
		"celikk":
			p.max_hp += 30.0
			p.speed *= 0.90
		"guzergah":
			G.run.kacak_plus = true
			G.run.node_mods["spawn"] = float(G.run.node_mods.get("spawn", 1.0)) * 1.08
		"narakad":
			G.run.fanatik_plus = true
			p.max_hp -= 6.0
			p.hp = minf(p.hp, p.max_hp)
		"yagma":
			p.set_meta("crit_frag", true)
			p.xp_mult *= 0.90
		"itibar":
			p.dmg_mult *= 1.0 + Quests.rep_tier() * 0.06
		"geri":
			p.xp_mult *= 0.92

static func parry_bonus() -> float:
	return 0.05 if G.run != null and G.run.boon_ids.has("bulwark") else 0.0

static func apply(id: String, p: Player) -> void:
	match id:
		"crushing": p.melee_dmg *= 1.20
		"shredder": p.melee_dmg += 4.0; p.set_meta("shred", true)
		"veteran": p.atk_speed *= 1.12
		"bulwark":
			p.armor += 2.0
			p.dmg_taken_mult *= 0.92
		"shockslam": p.set_meta("shockslam", true)
		"well": p.b_gravity_well = true
		"homing": p.b_homing = true
		"mind": p.crit_ch += 0.15
		"aegis": p.set_meta("aegis", true)
		"venom": p.b_poison = true
		"predator": p.crit_ch += 0.10; p.crit_mult = 2.4
		"swift": p.dash_regen_mult *= 1.35
		"camo": p.b_stealth_dash = true
		"regen": p.set_meta("regen", 0.8)
		"ritm": p.set_meta("streak_spd", true)
		"emp": p.b_emp = true
		"overcharge": p.plasma_mult *= 1.35; p.charge_rate *= 1.45
		"static": p.set_meta("static", 6.0)
		"parryemp": p.set_meta("pulse", 6.0)
		"bloodlust": p.dmg_mult *= 1.40; p.dmg_taken_mult *= 1.15
		"frenzy": p.atk_speed *= 1.18; p.max_hp = maxf(20.0, p.max_hp - 15); p.hp = minf(p.hp, p.max_hp)
		"carapace": p.lifesteal += 0.08; p.max_hp = maxf(20.0, p.max_hp * 0.9); p.hp = minf(p.hp, p.max_hp)
		"revive": p.revives_extra += 1
		"scav": p.set_meta("elite_heal", true)
		"xpgain": p.xp_mult *= 1.15
		"heartcall": p.set_meta("heal_luck", true)
