class_name Run
extends Node

# One arena run: hub → open field → time-scripted swarm → miniboss → final boss.
# Victory by killing the final boss (or outlasting the collapse timer).
# Holds run-scoped state (fragments, boons). On death all of it resets;
# meta progression (Pure Choralim + upgrades) persists via G.meta.

const ROOMS_PER_BIOME := 3  # combat rooms before the boss room
const FINAL_BOSS := 3
const BOSS_IDS := ["rex", "host", "twins", "final", "final"]
const BOSS_NAMES := ["REX / ALPHA-05", "PROTERIAN HOST", "NAHUM & TUMAN", "KIRIN & CONSTANTIN", "KIRIN & CONSTANTIN"]

var game: Node2D
var biome := 0
var depth := 0
var hyper := false          # AŞILAMA modu — David'in saha panelinden açılır
var curse := 0             # KARANLIK SÖZLEŞME yığını — düşmanları sertleştirir
var dark := false          # KARANLIK mutator — şifa düşmez, ödeme ×1.25
var reward_mult := 1.0     # choralim payout multiplier (hyper ×1.5, dark ×1.25)
var fragments := 0        # impure choralim gathered this run → purified on death
var boon_ids: Array = []
var luck := 0.0           # raised by elites; sways epic boon rolls
var alive := true
var endless := false      # victory'den sonra SONSUZ mod — kovan geri döner, ödül bankada
var time := 0.0           # seconds survived this run (Director drives it)
var pending_drafts := 0     # queued level-up drafts
var draft_reroll := false   # one card reroll available per level-up draft
var draft_banish := false   # one card banish available per level-up draft
var banished: Array = []    # ids kovulanlar — bu koşuda draft'a girmez
var arcana := ""           # koşu başında seçilen KOZ kartı (VS arcana)
var elite_fever := false   # SARI HAT: elitler %20 sık doğar
var slow_all := false      # GÖLGE ADIM: sürü %10 yavaşlar
var pending_ambush := false  # YOL OLAYI pusu: arenaya kuşatılmış girilir
var _skip_waylay := false    # TEKRAR DENE: aynı node'a dönerken yol olayı atlanır
var pending_dmg := 0.0     # YOL OLAYI harabe: girişte alınan enkaz hasarı
var force_waylay := ""     # probe/debug: yol olayını zorla
var _first_visit := false   # bu koşu düğüme ilk iniş mi (lore kartı için)
var daily := {}             # günlük protokol mutasyonu (Wmap.daily)
var stats := {"kills": 0, "rooms": 0}
var node_id := "b0"       # wmap node this run entered through
var node_name := ""       # banner'da node adı (fallback: biome adı)
var node_mods := {}       # spawn/hp/dmg/frag/loot/elite_t çarpanları
var frag_node := 1.0      # node "frag" modu — parçacık düşüşlerini büyütür

func _init(g: Node2D) -> void:
	game = g

# hp_scale/dmg_scale: biome + derinlik + KARANLIK SÖZLEŞME yığını (curse)
func hp_scale() -> float: return (1.0 + biome * 0.35 + depth * 0.12) * (1.0 + curse * 0.12)
func dmg_scale() -> float: return (1.0 + biome * 0.18 + depth * 0.06) * (1.0 + curse * 0.12)

func hub() -> void:
	biome = 0
	depth = 0
	G.state = G.State.HUB
	G.fx.transition()
	_room_to(G.room)
	var r := Room.new()
	game.world.add_child(r)
	r.build_hub()
	_spawn_player(r.spawn_point())
	_contract_tick()
	G.ui.hub_ui(true)
	_intro_story()

# ilk kampa inişte tek seferlik açılış sinematiği (seen_story ile korunur)
func _intro_story() -> void:
	var seen: Array = G.meta.data.get("seen_story", [])
	if not seen.has("intro"):
		seen.append("intro")
		G.meta.data["seen_story"] = seen
		G.meta.save()
		G.ui.cine_seq([
			{"tex": "bg3", "title": "DÜŞÜŞ: CHORALIM PROTOKOLÜ", "sub": "Viator son kampa çekildi. Protokol, hayatta kalan tek praetorianı seçti: sen."},
			{"tex": "por_neva", "title": "NEVA", "sub": "Rezonans seni geri getirir, Alfa-04. Her düşüşte bir parçan eksik döner — ama dönersin."},
			{"tex": "por_david", "title": "DAVID", "sub": "Harita açık. Görevler yazılı, yollar kilitli. Efendileri düşür, dünya açılsın."},
		])
		return
	# ilk zaferden sonraki kampa dönüş — epilog kartları
	if int(G.meta.data.get("victories", 0)) > 0 and not seen.has("epilog"):
		seen.append("epilog")
		G.meta.data["seen_story"] = seen
		G.meta.save()
		G.ui.cine_seq([
			{"tex": "cine_3_0", "title": "AETERNA DÜŞTÜ", "sub": "Son masa boşaldı. Protokolün şarkısı sustu — yerine seninki başladı."},
			{"tex": "por_neva", "title": "NEVA", "sub": "Döndün. Bu sefer her şeyi geri getirdin. Kamp ateşi bu gece daha parlak yanıyor."},
			{"tex": "por_david", "title": "DAVID", "sub": "Harita artık tamamen senin. Ama kovan sessizliği uzun sürmez — sözleşmeler bekliyor."},
		])

func start_run() -> void:
	# açık-dünya düğümü: David'in haritasında seçilen node biome + mods verir
	var nid := str(G.meta.data.get("arena_node", ""))
	var nd := Wmap.node(nid)
	if nd.is_empty() or not Wmap.can_enter(nid):
		# eski saha seçimiyle geriye uyum
		nid = "b%d" % clampi(int(G.meta.data.get("arena_biome", 0)), 0, 3)
		nd = Wmap.node(nid)
		if nd.is_empty() or not Wmap.can_enter(nid):
			nid = "b0"
			nd = Wmap.node("b0")
	node_id = nid
	node_name = str(nd.get("name", ""))
	node_mods = (nd.get("mods", {}) as Dictionary).duplicate()
	frag_node = float(node_mods.get("frag", 1.0))
	biome = clampi(int(nd.get("biome", 0)), 0, Room.BIOME_NAME.size() - 1)
	hyper = bool(G.meta.data.get("hyper", false))
	dark = bool(G.meta.data.get("dark", false))
	reward_mult = (1.5 if hyper else 1.0) * (1.25 if dark else 1.0) * (1.0 + 0.08 * float(G.meta.data.get("ng", 0)))
	depth = -1
	fragments = 0
	boon_ids.clear()
	luck = G.meta.upg(Meta.U.LUCK) * 0.15
	# günlük protokol: tarihe göre seçilen mutasyon tüm koşuya uygulanır
	daily = Wmap.daily()
	if not daily.is_empty():
		for mk in (daily.get("mods", {}) as Dictionary):
			node_mods[mk] = float(node_mods.get(mk, 1.0)) * float(daily.mods[mk])
		luck += float(daily.get("luck", 0.0))
		reward_mult *= float(daily.get("rew", 1.0))
		frag_node = float(node_mods.get("frag", 1.0))
		stats["daily"] = str(daily.name)
	alive = true
	endless = false
	time = 0.0
	pending_drafts = 0
	banished.clear()
	arcana = ""
	elite_fever = false
	slow_all = false
	curse = 0
	pending_ambush = false
	pending_dmg = 0.0
	stats = {"kills": 0, "rooms": 0}
	G.meta.data["runs"] += 1
	# saha keşfi: görevler için distinct biome sayısı birikir
	var vis: Array = G.meta.data.get("visited", [])
	if not vis.has(biome):
		vis.append(biome)
		G.meta.data["visited"] = vis
	# node-bazlı ziyaret: haritada ✓ işaretlerini besler
	var vn: Array = G.meta.data.get("visited_nodes", [])
	_first_visit = not vn.has(node_id)
	if _first_visit:
		vn.append(node_id)
		G.meta.data["visited_nodes"] = vn
	G.meta.save()
	Quests.tick("biomes")
	# seyahat olayı (BG2 "waylaid"): arenaya girmeden önce rastgele karşılaşma
	var wk := force_waylay
	force_waylay = ""
	if _skip_waylay:
		_skip_waylay = false
		wk = ""
	elif wk == "" and randf() < 0.35:
		wk = G.pick(["pusu", "kervan", "harabe", "gezgin"])
	if wk != "":
		G.ui.travel_event(wk, node_name)
	else:
		_enter_arena()

# yol olayı seçimi yapıldıktan (ya da olaysız) arenayı kurar
func _enter_arena() -> void:
	G.fx.transition()
	_room_to(G.room)
	var a := Arena.new()
	game.world.add_child(a)
	G.state = G.State.TRANSITION
	a.build_arena(biome)
	_place_player(a)
	G.player.reset_for_run()
	G.ui.hub_ui(false)
	if hyper:
		G.ui.toast("AŞILAMA AKTİF — kovan hızlı akıyor, ödeme ×1.5")
	if not daily.is_empty():
		G.ui.toast("BUGÜNÜN PROTOKOLÜ: %s — %s" % [str(daily.name), str(daily.desc)])
	if bool(G.meta.data.get("blessing", false)):
		G.meta.data["blessing"] = false
		G.meta.save()
		take_boon(G.pick(Boons.all()))
	if bool(G.meta.data.get("neva_song", false)):
		G.meta.data["neva_song"] = false
		G.meta.save()
		G.player.xp_mult *= 1.15
		G.ui.toast("NEVA'NIN ŞARKISI — bu koşuda +%15 XP")
	if bool(G.meta.data.get("hired", false)):
		G.meta.data["hired"] = false
		G.meta.save()
		var comp := Drone.spawn(0)
		comp.dmg = 16.0
		comp.cd = 0.85
		comp.tint(Px.C("ffd75f"))
		G.ui.toast("YOLDAŞ yanında — muhafız dronu koşu boyunca seninle")
	if pending_dmg > 0.0:
		G.player.hp = maxf(1.0, G.player.hp - pending_dmg)
		pending_dmg = 0.0
		G.ui.toast("enkaz altında kaldın")
	# ilk ziyaret: bölge kartı (BG2 "yeni alan" hissi) — lore varsa oynat
	if _first_visit:
		_first_visit = false
		var nd2 := Wmap.node(node_id)
		var lore := str(nd2.get("lore", nd2.get("desc", "")))
		if lore != "":
			G.ui.cinematic("cine_%d_0" % biome, node_name, lore, 3.2)
	# kilitli silahlar koşulu ilk kez tutunca duyurulur
	var seen: Array = G.meta.data.get("unlocked_w", [])
	var changed := false
	for wid in Weapons.DEFS:
		var dd: Dictionary = Weapons.DEFS[wid]
		if dd.get("hidden", false) or dd.get("req", {}).is_empty():
			continue
		if Weapons.unlocked(wid) and not seen.has(wid):
			seen.append(wid)
			changed = true
			G.ui.toast("yeni silah açıldı: %s" % dd.name)
	if changed:
		G.meta.data["unlocked_w"] = seen
		G.meta.save()
	var dr := Director.new()
	dr.biome = biome
	add_child(dr)
	G.director = dr
	G.state = G.State.ROOM
	G.ui.arcana_choice()

# level-up drafts queue up while an overlay is open; open the next when clear
func _process(_d: float) -> void:
	if pending_drafts > 0 and G.state == G.State.ROOM and is_instance_valid(G.ui) and not G.ui.overlay_open():
		pending_drafts -= 1
		# her 5. seviye bir lütuf taslağı açar — kilometre taşı ödülü
		if int(G.player.level) % 5 == 0:
			G.ui.boon_choice()
		else:
			G.ui.levelup_draft()
	if streak_t > 0.0:
		streak_t -= get_process_delta_time()
		if streak_t <= 0.0:
			streak = 0

# kill streak: chained kills within 2.5s pay milestone fragment bonuses
var streak := 0
var streak_t := 0.0

func on_kill(_elite: bool) -> void:
	streak += 1
	streak_t = 2.5
	if streak > int(stats.get("best_streak", 0)):
		stats["best_streak"] = streak
	var bonus := 0
	match streak:
		15: bonus = 10
		30: bonus = 25
		60: bonus = 60
		120: bonus = 150
	if bonus > 0:
		fragments += bonus
		G.ui.toast("KATLİAM x%d  —  +%d parçacık" % [streak, bonus])
		G.audio.jingle("boon")
	Quests.tick("kills")

func open_chest() -> void:
	if arcana == "kasa":
		fragments += 25
		G.fx.float_text(G.player.pos + Vector2(0, -30), "+25", Px.C("c9a227"), 0.8)
	var evos := Weapons.evo_ready(G.player)
	if evos.is_empty():
		fragments += 120
		G.player.heal(G.player.max_hp * 0.25)
		G.ui.toast("sandık: +120 parçacık · can yenilendi")
		G.audio.jingle("boon")
		return
	G.ui.chest_choice(evos)

func apply_evo(spec: Dictionary) -> void:
	Weapons.apply_evo(spec, G.player)
	Quests.tick("evos")
	# evrim şöleni — dönüşüm koşuda görünür bir an olsun
	if is_instance_valid(G.player):
		G.fx.flash(Px.C("ffd75f"), 0.22)
		G.fx.burst(G.player.pos + Vector2(0, -20), Px.C("ffd75f"), 34, 260.0, 5.0, 0.8)
		G.fx.boom(G.player.pos, Px.C("fff2b0"), 90.0)
		G.fx.light_flash(G.player.pos + Vector2(0, -24), Px.C("fff2b0"), 2.2, 3.4, 0.4)
		G.fx.shake(0.14, 0.3)
		G.fx.hitstop(0.06)
		G.audio.jingle("victory")

func next_room(reward: int) -> void:
	depth += 1
	stats.rooms += 1
	var is_boss := depth >= ROOMS_PER_BIOME
	var rt := Room.Type.BOSS if is_boss else (Room.Type.ELITE if _elite_room() else Room.Type.COMBAT)
	G.fx.transition()
	_room_to(G.room)
	var r := Room.new()
	game.world.add_child(r)
	G.state = G.State.TRANSITION
	r.build(biome, rt, reward, depth, randi())
	G.state = G.State.ROOM
	_place_player(r)
	G.ui.hub_ui(false)
	# cinematic cards: dossier still on biome entry, portrait card on boss
	if is_boss:
		var por: String = {"rex": "rex", "host": "host", "twins": "nahum", "final": "kirin"}[BOSS_IDS[biome]]
		G.ui.cinematic("por_" + por, BOSS_NAMES[biome], _boss_intro_sub(biome), 2.4)
	elif depth == 0:
		# görev node'ları kendi lore kartıyla açılır; boss sahaları biome kartını korur
		var nd := Wmap.node(node_id)
		var lore := str(nd.get("lore", ""))
		if lore != "":
			G.ui.cinematic("cine_%d_0" % biome, node_name, lore, 3.0)
		else:
			G.ui.cinematic("cine_%d_0" % biome, Room.BIOME_NAME[clampi(biome, 0, Room.BIOME_NAME.size() - 1)], _biome_sub(biome), 2.8)

func _biome_sub(b: int) -> String:
	return ["Proterian çoraklığı — Alfa-05'in izi burada.",
			"Simithar damarları — kovanın derinliklere uzandığı yer.",
			"Sol Primus enkazı — imparatorluğun çürüyen tahtı.",
			"Aeterna Kulesi — protokolün kalbi.",
			"Çürük Bataklık — imparatorluğun unuttuğu çamur, burada hiçbir şey temiz çürümez."][mini(b, 4)]

func _boss_intro_sub(b: int) -> String:
	return ["Alfa-05 · Düşmüş Kardeş — transistörü hâlâ şarkı söylüyor.",
			"Proterian Yeni Nesil Konakçı — kovan eti hatırlıyor.",
			"Nahum & Tuman — ikiz protokol, çift ölüm.",
			"Kirin & Constantin — masanın son iki sandalyesi.",
			"Kirin & Constantin — masanın son iki sandalyesi."][mini(b, 4)]

func _elite_room() -> bool:
	return depth == 1 and G.chance(0.35)

func descend() -> void:
	# boss beaten — go deeper (or win)
	if biome >= FINAL_BOSS:
		victory()
		return
	biome += 1
	depth = -1
	next_room(Room.Reward.BOON)

# Ehnar's rotating contracts — one field task per camp visit, pays choralim
const CONTRACTS := [
	{"key": "kills", "need": 150, "reward": 45},
	{"key": "kills", "need": 400, "reward": 90},
	{"key": "time",  "need": 480, "reward": 60},
	{"key": "time",  "need": 660, "reward": 85},
	{"key": "level", "need": 10,  "reward": 40},
	{"key": "level", "need": 16,  "reward": 70},
	{"key": "win",   "need": 1,   "reward": 120},
]

func contract_text(c: Dictionary) -> String:
	if c.is_empty():
		return "—"
	match str(c.get("key", "")):
		"kills": return "Tek koşuda %d kesim" % int(c.need)
		"time":  return "Tek koşuda %d saniye dayan" % int(c.need)
		"level": return "Tek koşuda seviye %d'e ulaş" % int(c.need)
		"win":   return "Son efendiyi düşür ve dön"
	return "—"

func _write_last_run(win: bool) -> void:
	# eşya ganimeti kalıcı zulaya taşınır + kalan görev tipleri son kez tıklanır
	var banked := Items.bank_bag()
	if banked > 0:
		stats["loot_banked"] = banked
		if is_instance_valid(G.ui):
			G.ui.toast("ganimet zulada: %d eşya" % banked)
	stats["won"] = win
	# skor önce yazılır — tick_all 'score' görevlerini bu değerle değerlendirir
	var score := int(stats.get("kills", 0)) * 10 + int(stats.get("level", 1)) * 120 + int(time) * 3 + int(stats.get("evos", 0)) * 500 + curse * 250
	stats["score"] = score
	if score > int(G.meta.data.get("best_score", 0)):
		G.meta.data["best_score"] = score
		stats["new_record"] = true
		G.meta.save()
	Quests.tick_all()
	G.meta.data["last_run"] = {
		"kills": int(stats.get("kills", 0)),
		"time": int(time),
		"level": G.player.level if is_instance_valid(G.player) else 1,
		"win": win,
	}
	# koşu geçmişi — Zirkon'un arşivi, son 5 koşu
	var hist: Array = G.meta.data.get("history", [])
	hist.append({"n": node_name, "k": int(stats.get("kills", 0)), "t": int(time), "w": win, "s": score})
	while hist.size() > 5:
		hist.pop_front()
	G.meta.data["history"] = hist
	# tür-bazlı kesimler meta'ya birikir — Zirkon'un kayıtlarında listelenir
	var kk: Dictionary = stats.get("kind_kills", {})
	if not kk.is_empty():
		var mk: Dictionary = G.meta.data.get("kind_kills", {})
		for kn in kk:
			mk[kn] = int(mk.get(kn, 0)) + int(kk[kn])
		G.meta.data["kind_kills"] = mk
		G.meta.save()
	G.meta.data["best_evos"] = maxi(int(G.meta.data.get("best_evos", 0)), int(stats.get("evos", 0)))
	G.meta.data["best_streak_all"] = maxi(int(G.meta.data.get("best_streak_all", 0)), int(stats.get("best_streak", 0)))
	if win and curse >= 2:
		G.meta.data["curse_wins"] = int(G.meta.data.get("curse_wins", 0)) + 1
		G.meta.save()

func _contract_met(c: Dictionary, lr: Dictionary) -> bool:
	if c.is_empty() or lr.is_empty():
		return false
	match str(c.get("key", "")):
		"kills": return int(lr.get("kills", 0)) >= int(c.need)
		"time":  return int(lr.get("time", 0)) >= int(c.need)
		"level": return int(lr.get("level", 0)) >= int(c.need)
		"win":   return bool(lr.get("win", false))
	return false

# evaluate the last run against Ehnar's contract, then hand out the next one
func _contract_tick() -> void:
	var c: Dictionary = G.meta.data.get("contract", {})
	if _contract_met(c, G.meta.data.get("last_run", {})):
		var r := int(c.get("reward", 0))
		G.meta.add_choralim(r)
		G.ui.toast("EHNAR: sözleşme tuttu — +%d◆" % r)
		G.audio.jingle("boon")
		c = {}
	if c.is_empty():
		var nxt: Dictionary = CONTRACTS[randi() % CONTRACTS.size()]
		# don't repeat the identical task back-to-back
		var last_k: String = G.meta.data.get("_last_contract_key", "")
		if str(nxt.key) == last_k:
			nxt = CONTRACTS[(CONTRACTS.find(nxt) + 1) % CONTRACTS.size()]
		G.meta.data["contract"] = {"key": nxt.key, "need": nxt.need, "reward": nxt.reward}
		G.meta.data["_last_contract_key"] = nxt.key
		G.meta.save()

func victory() -> void:
	if not alive:
		return
	G.state = G.State.VICTORY
	alive = false
	if is_instance_valid(G.director):
		G.director.running = false
	if is_instance_valid(G.room):
		G.room.boss = null
	G.ui.boss_bar(false, null)
	stats.time = time
	stats.level = G.player.level if is_instance_valid(G.player) else 1
	stats["node_id"] = node_id
	stats["node_name"] = node_name
	_write_last_run(true)
	var wn: Array = G.meta.data.get("won_nodes", [])
	if not wn.has(node_id):
		wn.append(node_id)
		G.meta.data["won_nodes"] = wn
	var tribute := wn.size() * 12
	var gained := int(fragments * G.meta.frag_mult() * reward_mult) + tribute
	G.meta.add_choralim(gained)
	stats.gained = gained
	fragments = 0
	if tribute > 0:
		G.ui.toast("FETİH HARACI  +%d◆" % tribute)
	G.meta.data["victories"] += 1
	G.meta.data["ng"] = int(G.meta.data.get("ng", 0)) + 1
	stats["ng"] = int(G.meta.data.get("ng", 0))
	var first_end := node_id == "b3" and not bool(G.meta.data.get("ended", false))
	if node_id == "b3":
		G.meta.data["ended"] = true
	G.meta.save()
	for f in G.meta.new_feats():
		G.ui.toast("BAŞARIM: %s" % f)
	G.audio.jingle("boss")
	# zafer sinematiği: biome kartı + Neva repliği, sonra sonuç paneli.
	# b3 ilk zaferinde GERÇEK SON — 3 kartlık ending zinciri.
	var ci := clampi(biome, 0, 5)
	if first_end:
		G.ui.cine_seq([
			{"tex": "cine_3_0", "title": "AETERNA SUSTU", "sub": "Kirin ve Constantin düştü. Spire'ın tepesinde ışık ilk kez kapandı."},
			{"tex": "cine_3_2", "title": "PROTOKOL KIRILDI", "sub": "Kovanın şarkısı senin adınla bitiyor, Alfa-04."},
			{"tex": "por_neva", "title": "NEVA", "sub": "Döndün. Bu sefer geride şarkı bırakmadın — yerine sessizlik, ve bir kamp ateşi."},
		], func(): G.ui.victory_screen(stats))
	else:
		var tex := "cine_%d_%d" % [ci, randi() % 4] if ci <= 3 else "cine_%d_0" % ci
		var epi := G.ui.epilog(node_id)
		G.ui.cine_seq([
			{"tex": tex, "title": "PROTOKOL KIRILDI", "sub": (node_name + "\n" + epi) if epi != "" else node_name},
			{"tex": "por_neva", "title": "NEVA", "sub": "Şarkı sustu, Alfa-04. Bu sefer geriye tam döndün."},
		], func(): G.ui.victory_screen(stats))
	if not G.ui.overlay_open():
		G.ui.victory_screen(stats)

# zaferden sonra devam — kovan sonsuz ölçeklenmeye döner, sonraki ölüm normal öder
func continue_endless() -> void:
	if endless:
		return
	endless = true
	alive = true
	G.state = G.State.ROOM
	if is_instance_valid(G.director):
		G.director.running = true
	G.ui.toast("SONSUZ — kovan geri akıyor; ölüm hâlâ öder")

func on_player_death(h: Dictionary) -> void:
	if not alive:
		return
	alive = false
	G.state = G.State.DEAD
	var killer := "kovan"
	var src = h.get("source")
	if src is Actor:
		killer = src.actor_name
	var was_boss := is_instance_valid(G.room) and G.room.boss != null
	if is_instance_valid(G.director):
		G.director.running = false
	G.ui.boss_bar(false, null)
	# endless'te zafer çoktan bankada — sözleşmeler/özet zaferi korur
	_write_last_run(endless)
	G.meta.record_death(killer, biome, int(time), was_boss)
	var gained := int(fragments * G.meta.frag_mult() * reward_mult)
	G.meta.add_choralim(gained)
	fragments = 0
	for f in G.meta.new_feats():
		G.ui.toast("BAŞARIM: %s" % f)
	# ölüm sinematiği: solgun biome kartı + Neva repliği, sonra ölüm paneli
	var ci2 := clampi(biome, 0, 5)
	var dtex := "cine_%d_0" % ci2
	G.ui.cine_seq([
		{"tex": dtex, "title": "DÜŞTÜN", "sub": "%s seni kovana kattı." % killer},
		{"tex": "por_neva", "title": "NEVA", "sub": "Rezonans tuttu seni. Bir parçan eksik — ama döndün."},
	], func(): G.ui.death_screen(killer, gained))
	if not G.ui.overlay_open():
		G.ui.death_screen(killer, gained)

func abandon_to_hub() -> void:
	if not alive:
		return
	alive = false
	var gained := int(fragments * G.meta.frag_mult() * reward_mult)
	if gained > 0:
		G.meta.add_choralim(gained)
	fragments = 0
	respawn_to_hub()

func retry_node() -> void:
	# ölüm ekranından hızlı dönüş — kamp atlanır, aynı node'a direkt koşu
	_skip_waylay = true
	respawn_to_hub()
	start_run()

func respawn_to_hub() -> void:
	# purge the dead player shell, rebuild at camp
	if is_instance_valid(G.player):
		G.player.queue_free()
	G.player = null
	hub()
	G.ui.death_reaction()

func on_room_cleared() -> void:
	# grant the reward promised by the door we entered through
	match G.room.pending_reward:
		Room.Reward.BOON:
			G.ui.boon_choice()
		Room.Reward.HEAL:
			G.player.heal(G.player.max_hp * 0.4)
			G.room.spawn_fragments(Vector2(0, -60), 14 + biome * 4)
			G.ui.toast("yenilendin")
		_:
			G.room.spawn_fragments(Vector2(0, -60), 18 + biome * 6)
			G.ui.toast("+%d choralim parçacığı" % (18 + biome * 6))
	if G.room.rtype == Room.Type.ELITE:
		luck += 0.15
		G.ui.toast("elit ganimeti — şans arttı")

func on_boss_dead() -> void:
	G.meta.boss_down(BOSS_IDS[biome])
	G.room.spawn_fragments(Vector2(0, -40), 60 + biome * 50)
	G.ui.toast("%s düştü — kapı açıldı" % BOSS_NAMES[biome])

func take_boon(b: Dictionary) -> void:
	boon_ids.append(b.id)
	Boons.apply(b.id, G.player)
	G.fx.burst(G.player.pos + Vector2(0, -24), b.color, 20, 150.0, 4.0, 0.7)
	G.audio.jingle("boon")
	G.ui.toast("%s — %s" % [b.name, b.desc])
	if b.patron == "Kovan":
		G.fx.flash(Color(0.1, 0.9, 0.2, 0.1), 0.6)

func drop_fragments(p: Vector2, total: int) -> void:
	if is_instance_valid(G.room):
		G.room.spawn_fragments(p, int(total * frag_node))

func _room_to(old: Room) -> void:
	if old != null and is_instance_valid(old):
		old.queue_free()
	for e in G.enemies.duplicate():
		if is_instance_valid(e):
			e.queue_free()
		G.enemies.erase(e)
	for p in G.projectiles.duplicate():
		if is_instance_valid(p):
			p.queue_free()
		G.projectiles.erase(p)
	for c in game.world.get_children():
		if c is Enemy and is_instance_valid(c):
			c.queue_free()
			G.enemies.erase(c)
	G.melee_tokens = 2
	G.MELEE_TOKENS_MAX = 2
	if is_instance_valid(G.ui):
		G.ui.boss_bar(false, null)
	if is_instance_valid(G.director):
		G.director.queue_free()
		G.director = null
	if is_instance_valid(G.fx):
		G.fx.clear_decals()
		G.fx.hitstop_t = 0.0
		G.fx.prev_scale = 1.0
	Engine.time_scale = 1.0

func _spawn_player(p: Vector2) -> void:
	if G.player == null or not is_instance_valid(G.player) or G.player.dead:
		if is_instance_valid(G.player):
			G.player.queue_free()
		var pl := Player.new()
		game.world.add_child(pl)
		pl.pos = p
		pl.init()
		G.player = pl
	else:
		G.player.pos = p
		if G.player.get_parent() == null:
			game.world.add_child(G.player)

func _place_player(r: Room) -> void:
	_spawn_player(r.spawn_point())
	G.player.pos = r.spawn_point()
	G.player.ext_vel = Vector2.ZERO

# ---------------------------------------------------------------- debug (MCP playtest)

func dbg() -> Dictionary:
	var es := []
	if is_instance_valid(G.room):
		for e in G.enemies:
			if is_instance_valid(e):
				es.append({"p": [roundi(e.pos.x), roundi(e.pos.y)], "hp": roundi(e.hp), "dead": e.dead, "path": str(e.get_path())})
	var ds := []
	if is_instance_valid(G.room):
		for d in G.room.doors:
			ds.append({"p": [roundi(d.pos.x), roundi(d.pos.y)], "locked": d.locked, "gate": d.get("gate", false), "descend": d.get("descend", false), "reward": d.reward})
	return {
		"state": G.state, "biome": biome, "depth": depth, "alive": alive,
		"fragments": fragments, "boons": boon_ids.size(), "luck": luck,
		"p_pos": [roundi(G.player.pos.x), roundi(G.player.pos.y)] if is_instance_valid(G.player) else [],
		"p_hp": roundi(G.player.hp) if is_instance_valid(G.player) else -1,
		"p_dead": G.player.dead if is_instance_valid(G.player) else false,
		"p_path": str(G.player.get_path()) if is_instance_valid(G.player) else "",
		"r_cleared": G.room.cleared if is_instance_valid(G.room) else false,
		"r_hub": G.room.is_hub if is_instance_valid(G.room) else false,
		"r_wave": [G.room.wave_idx, G.room.waves.size(), G.room.alive] if is_instance_valid(G.room) else [],
		"enemies": es, "doors": ds,
		"overlay": G.ui.overlay_open() if is_instance_valid(G.ui) else false,
		"o_kind": G.ui._overlay.get_meta("kind", "") if is_instance_valid(G.ui) and G.ui.overlay_open() else "",
		"paused": get_tree().paused,
		"t_scale": Engine.time_scale,
		"choralim": G.meta.data.choralim if G.meta != null else -1,
	}

func dbg_to_door(i: int = 0) -> void:
	# teleport the player onto door i (or the first unlocked one) — skips walking
	if not is_instance_valid(G.player) or not is_instance_valid(G.room):
		return
	var idx := i
	if i < 0:
		for j in G.room.doors.size():
			if not G.room.doors[j].locked:
				idx = j
				break
	if idx < G.room.doors.size():
		G.player.pos = G.room.doors[idx].pos + Vector2(0, 6)

func dbg_hit_enemy(i: int, dmg: float) -> void:
	# scalar-only args so MCP runtime_call can marshal them safely
	var live: Array = []
	for e in G.enemies:
		if is_instance_valid(e) and not e.dead:
			live.append(e)
	if i >= 0 and i < live.size():
		var e: Actor = live[i]
		e.take_hit({"dmg": dmg, "type": G.DamageType.MELEE, "from": e.pos + Vector2(0, 20), "knock": 4.0, "stagger": 0.3, "source": G.player})

func dbg_clear_room() -> void:
	for e in G.enemies.duplicate():
		if is_instance_valid(e) and not e.dead:
			e.invuln = 0.0
			if "shielded" in e:
				e.set("shielded", false)
			e.die({"dmg": 99999.0, "type": G.DamageType.PURE, "from": e.pos, "source": G.player})

func dbg_god() -> void:
	# test-only godmode: survive long enough to stage visuals
	if is_instance_valid(G.player):
		G.player.max_hp = 99999.0
		G.player.hp = 99999.0
		G.player.armor = 99.0

func dbg_hurt_player(dmg: float) -> void:
	if is_instance_valid(G.player):
		G.player.invuln = 0.0
		G.player.take_hit({"dmg": dmg, "type": G.DamageType.MELEE, "from": G.player.pos + Vector2(10, 0), "source": null})

func dbg_swing() -> void:
	# fire the sword swing directly — input polling can't be driven while suspended
	if is_instance_valid(G.player) and not G.player.dead:
		G.player._start_swing()

func dbg_aim(x: float, y: float) -> void:
	if is_instance_valid(G.player):
		G.player.aim_dir = (Vector2(x, y) - G.player.pos).normalized()

func dbg_pick_boon(i: int) -> void:
	if is_instance_valid(G.ui._overlay) and str(G.ui._overlay.get_meta("kind", "")) in ["boon", "draft", "chest"]:
		var opts: Array = G.ui._overlay.get_meta("opts", [])
		if i >= 0 and i < opts.size():
			G.ui._pick_card(opts[i])

func dbg_step_to_clear(max_steps: int = 20) -> int:
	# returns how many door-steps remain; used to sanity-check progression
	return max_steps

func dbg_give_choralim(n: int) -> void:
	G.meta.add_choralim(n)

func dbg_shoot(speed: float = 170.0, dist: float = 150.0) -> void:
	# enemy bolt fired straight at the player from the east — parry test staging
	if not is_instance_valid(G.player):
		return
	var p := Projectile.new()
	G.game.world.add_child(p)
	p.setup(G.Team.ENEMY, G.player.pos + Vector2(dist, 0), Vector2(-speed, 0),
		6.0, 8.0, Px.C("FF5252"), "dot")

func dbg_buy(u: int) -> bool:
	return G.meta.buy(u)
