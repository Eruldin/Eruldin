extends Node

# --probe autopilot (vanilla Godot): title -> hub -> portal -> arena, godmode,
# auto-picks level-up drafts/chests, saves viewport screenshots to
# user://probe/, logs status lines, then quits.

var _step := 0
var _sub := 0
var _shot_at := -1.0
var _msg_at := 0.0
var _shot_n := 0
var _roster_done := false
var _edge_done := false
var _mono_done := false
var _mono_check := false
var _tome_done := false
var _tome_ck := false
var _tome_boons := 0
var _loot_done := false
var _loot_ck := false
var _merch_done := false
var _merch_ck := false
var _merch_close := false

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://probe"))
	Engine.time_scale = 5.0
	print("[probe] armed, shots -> %s" % ProjectSettings.globalize_path("user://probe"))

func _process(_d: float) -> void:
	match _step:
		0:
			if is_instance_valid(G.ui) and G.ui.overlay_open():
				G.ui._advance_overlay()
				_step = 1
				print("[probe] title -> hub")
		1:
			if G.state == G.State.HUB and is_instance_valid(G.player) and is_instance_valid(G.room) and not G.room.doors.is_empty():
				# açılış/epilog sinematiği oynuyorsa önce boşalt — paneller onu yemesin
				if is_instance_valid(G.ui) and G.ui.overlay_open() and str(G.ui._overlay.get_meta("kind", "")) == "cine":
					G.ui._advance_overlay()
					return
				# one action per frame so each shot captures a distinct state
				match _sub:
					0:
						_shoot()                    # camp + new NPCs
					1:
						G.ui.dialogue("ehnar")      # görevli NPC -> diyalog
					2:
						G.ui._advance_overlay()     # diyalog -> görev panosu
					3:
						_shoot()                    # quest panel açıkken çek
					4:
						var qa := Quests.available_for("ehnar")
						if not qa.is_empty():
							Quests.accept(str(qa[0].id))
							print("[probe] quest accepted: %s" % str(qa[0].id))
						G.ui._advance_overlay()     # quest panel -> close
					5:
						G.ui.inventory_panel()      # saphire envanteri (doğrudan)
					6:
						_shoot()                    # inventory visible
					7:
						var st: Array = G.meta.data.get("stash", [])
						if st.is_empty():
							st.append("i_migfer")
							G.meta.data["stash"] = st
						if not st.is_empty():
							var iid0 := str(st[0])
							var c0 := int(G.meta.data.get("choralim", 0))
							var got := Items.sell(iid0)
							print("[probe] sell %s -> +%d (choralim %d->%d)" % [iid0, got, c0, int(G.meta.data.get("choralim", 0))])
						G.ui._advance_overlay()     # close -> camp
					8:
						var st2: Array = G.meta.data.get("stash", [])
						for sid in ["i_palto", "i_halka1"]:
							if not st2.has(sid):
								st2.append(sid)
						G.meta.data["stash"] = st2
						G.ui.barter_panel()         # saphire takas paneli
					9:
						_shoot()                    # barter panel açıkken çek
					10:
						var st3: Array = G.meta.data.get("stash", [])
						if st3.size() >= 2:
							var n0 := st3.size()
							var a0 := str(st3[0])
							var b0 := str(st3[1])
							var got2 := Items.barter(a0, b0)
							print("[probe] barter %s+%s -> %s (stash %d->%d)" % [a0, b0, got2, n0, (G.meta.data.get("stash", []) as Array).size()])
						G.ui._advance_overlay()
					11:
						G.ui.worldmap_panel()       # david dünya haritası
					12:
						_shoot()                    # node-graph map visible
					13:
						G.ui._wmap_pick("b0", Label.new(), {"id": "b0"})
					14:
						_shoot()                    # map with selection refreshed
						G.ui._advance_overlay()
					15:
						G.ui.records_panel()        # zirkon kayıtları + ÖYKÜ sütunu
					16:
						_shoot()                    # records visible (kapanış sonraki adımda)
					17:
						G.ui._advance_overlay()
					18:
						G.ui.boss_taunt("rex", "REX — AVCI FORMU", "Şarkı sustuğunda... beni hatırla, Alfa-04.")
					19:
						_shoot()                    # faz-2 hikaye kartı görünürken
					20:
						G.ui.shop_panel()           # saphire pazar tezgâhı
					21:
						_shoot()                    # tezgâh açıkken çek
					22:
						var stk := Items.shop_stock()
						if not stk.is_empty():
							var sid := str(stk[0])
							var paid := Items.buy(sid)
							print("[probe] shop buy %s -> %d (choralim %d)" % [sid, paid, int(G.meta.data.get("choralim", 0))])
						G.ui._advance_overlay()
					_:
						G.player.pos = G.room.doors[0].pos + Vector2(0, 6)
						_step = 2
						_sub = -1
				_sub += 1
		2:
			if G.state == G.State.ROOM:
				G.run.dbg_god()
				_step = 3
				print("[probe] arena live")
		3:
			if G.ui.overlay_open():
				var k := str(G.ui._overlay.get_meta("kind", ""))
				if k in ["draft", "chest", "boon"]:
					G.run.dbg_pick_boon(0)
			if not G.run.alive:
				_shoot()
				print("[probe] run ended (alive=%s)" % G.run.alive)
				get_tree().quit()
				return
			var t := G.run.time
			if t >= _msg_at:
				_msg_at = t + 15.0
				print("[probe] t=%.0f hp=%.0f lvl=%d enemies=%d kills=%d pending=%d" % [t, G.player.hp, G.player.level, G.enemies.size(), int(G.run.stats.get("kills", 0)), G.run.pending_drafts])
			# visual coverage: roster of the new enemy kinds, then a vista shot at the arena edge
			if not _roster_done and t >= 30.0:
				_roster_done = true
				for i in [Enemy.EKind.VARL, Enemy.EKind.CEREB, Enemy.EKind.KONAKCI, Enemy.EKind.ALFA].size():
					var kd: int = [Enemy.EKind.VARL, Enemy.EKind.CEREB, Enemy.EKind.KONAKCI, Enemy.EKind.ALFA][i]
					Enemy.spawn(kd, G.player.pos + Vector2.from_angle(TAU * i / 4.0) * 240.0, false, 1.0, 0.0, G.room)
				_shot_at = t + 2.0
			if not _edge_done and t >= 45.0:
				_edge_done = true
				G.player.pos = Vector2(1350, -880)
				_shot_at = t + 1.0
			# rezonans kümesi kapsaması: oyuncunun dibinde doğur, kısa şarjla çözülmesini bekle
			if not _mono_done and t >= 95.0:
				_mono_done = true
				G.room.spawn_monolith(G.player.pos + Vector2(30, 0))
				G.room.mono["need"] = 3.0
				print("[probe] monolith spawned")
			if _mono_done and not _mono_check and not G.room.mono_active:
				_mono_check = true
				print("[probe] monolith resolved ok")
			if not _tome_done and t >= 112.0 and G.player != null:
				_tome_done = true
				_tome_boons = G.run.boon_ids.size()
				G.room.spawn_tome(G.player.pos + Vector2(10, 0))
				_tome_ck = true
				print("[probe] tome spawned")
			if _tome_ck and t >= 118.0:
				_tome_ck = false
				print("[probe] tome consumed ok" if G.run.boon_ids.size() > _tome_boons else "[probe] WARN tome not consumed")
			# eşya düşüşü kapsaması: elit loot spawn + toplama -> run loot bag
			if not _loot_done and t >= 130.0:
				_loot_done = true
				var iid := Items.roll(0.0)
				print("[probe] loot roll -> %s" % iid)
				if iid != "":
					G.room.spawn_loot(iid, G.player.pos + Vector2(12, 0))
			if _loot_done and not _loot_ck and t >= 140.0:
				_loot_ck = true
				var bag := (G.run.stats.get("loot", []) as Array).size()
				print("[probe] loot bag=%d elite_kills=%d" % [bag, int(G.run.stats.get("elite_kills", 0))])
			# gezgin tüccar kapsaması: frag ver, dibinde doğur -> panel açılmalı
			if not _merch_done and t >= 142.0:
				_merch_done = true
				G.run.fragments = 800
				G.room.spawn_merchant(G.player.pos + Vector2(8, 0))
				_merch_ck = true
				print("[probe] merchant spawned")
			# panel açılınca koşu durur — t bazlı beklemek kilitlenirdi; her frame bak
			if _merch_ck and is_instance_valid(G.ui) and is_instance_valid(G.ui._overlay) and str(G.ui._overlay.get_meta("kind", "")) == "merchant":
				_merch_ck = false
				_merch_close = true      # shot deferred — kapanış bir frame sonra
				print("[probe] merchant panel=merchant")
				_shoot()
			elif _merch_close:
				_merch_close = false
				G.ui._advance_overlay()
			if _merch_ck and t >= 146.0:
				_merch_ck = false
				print("[probe] WARN merchant panel didn't open")
			if t >= _shot_at:
				_shot_at = t + 15.0
				_shoot()
			if t > 150.0:
				_shoot()
				print("[probe] done t=%.0f" % t)
				get_tree().quit()

func _shoot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://probe/shot_%02d.png" % _shot_n)
	_shot_n += 1
