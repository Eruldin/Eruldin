class_name Fx
extends Node2D

# Code-driven FX: pooled particles, floating combat text, telegraph decals,
# blood decals, dash ghosts, screen shake, hitstop.

var pool: Array[Sprite2D] = []
var pdata := {}          # Sprite2D -> dict
var teles: Array[Dictionary] = []
var floats: Array = []       # {l: Label, t: float}
var shake_amp := 0.0
var shake_t := 0.0
var hitstop_t := 0.0
var prev_scale := 1.0
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect

func _ready() -> void:
	z_index = 60
	y_sort_enabled = false

func _mk(tex_name: String, order: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Px.S(tex_name)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.z_index = order
	add_child(s)
	return s

# ---------- particles ----------
const T_SMOKE := ["fx_smoke_0", "fx_smoke_1", "fx_smoke_2"]
const T_FLAME := ["fx_flame_0", "fx_flame_1"]
const T_SPARK := ["fx_spark_0", "fx_spark_1", "fx_spark_2"]
const T_TRACE := ["fx_trace_0", "fx_trace_1"]

func _ptex(p: Sprite2D, tl: Array) -> float:
	var tt: Texture2D = Px.S(str(tl[G.ri(0, tl.size() - 1)]))
	if tt == null:
		p.texture = Px.S("dot")
		return 1.0
	p.texture = tt
	p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return 16.0 / float(tt.get_height())

func burst(pos: Vector2, col: Color, n: int, spd: float, size: float, life: float, grav := 0.0, order := 60, tex := "") -> void:
	var tl: Array = T_SMOKE if tex == "" else [tex]
	var grow := size * 0.5 if tex == "" or tex.begins_with("fx_flame") or tex.begins_with("fx_smoke") else 0.0
	for i in n:
		var p := _pget()
		var a := G.rf(0, TAU)
		var v := spd * G.rf(0.3, 1.0)
		pdata[p] = {"vel": Vector2(cos(a), sin(a)) * v, "life": life * G.rf(0.6, 1.1), "max": life * G.rf(0.6, 1.1), "grav": grav, "col": col}
		pdata[p]["max"] = pdata[p]["life"]
		pdata[p]["grow"] = grow * G.rf(0.7, 1.3)
		pdata[p]["spin"] = G.rf(-1.4, 1.4) if grow > 0.0 else 0.0
		var ts := _ptex(p, tl)
		p.global_position = pos + Vector2(G.rf(-4, 4), G.rf(-4, 4))
		p.scale = Vector2.ONE * size * G.rf(0.6, 1.4) * ts
		p.rotation = G.rf(0, TAU)
		p.z_index = order
		p.modulate = col
		p.visible = true

func directional(pos: Vector2, dir: Vector2, col: Color, n: int, spd: float, size: float, life: float, spread := 0.7, tex := "") -> void:
	var tl: Array = T_SPARK if tex == "" else [tex]
	for i in n:
		var p := _pget()
		var a := dir.angle() + G.rf(-spread, spread)
		var v := spd * G.rf(0.5, 1.0)
		var lf := life * G.rf(0.6, 1.1)
		pdata[p] = {"vel": Vector2(cos(a), sin(a)) * v, "life": lf, "max": lf, "grav": 0.0, "col": col, "grow": 0.0, "spin": 0.0}
		var ts := _ptex(p, tl)
		p.global_position = pos
		p.scale = Vector2.ONE * size * G.rf(0.6, 1.3) * ts
		p.rotation = a if tl == T_TRACE else G.rf(0, TAU)
		p.z_index = 60
		p.modulate = col
		p.visible = true

func _pget() -> Sprite2D:
	for p in pool:
		if not p.visible:
			return p
	var p := _mk("dot", 60)
	pool.append(p)
	return p

func _pgrow(p: Sprite2D, dt: float) -> void:
	var d: Dictionary = pdata[p]
	var gr: float = d.get("grow", 0.0)
	if gr != 0.0:
		p.scale += Vector2.ONE * gr * dt
	var sp: float = d.get("spin", 0.0)
	if sp != 0.0:
		p.rotation += sp * dt

# ---------- floating text ----------
const FLOAT_CAP := 42   # geç oyunda hasar spam'i kare düşürür — havuz sınırlı

func float_text(pos: Vector2, txt: String, col: Color, size := 1.0) -> void:
	if floats.size() >= FLOAT_CAP:
		var old: Dictionary = floats.pop_front()
		if is_instance_valid(old.get("h")):
			old["h"].queue_free()
		elif is_instance_valid(old["l"]):
			old["l"].queue_free()
	# eğik dünyada rakamlar dik okunur: taşıyıcı sheared konuma oturur, harfler düz
	var h := Node2D.new()
	h.transform = Transform2D(0.0, pos + Vector2(G.rf(-8, 8), -14)) * G.SHEAR_INV
	add_child(h)
	var l := Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_font_size_override("font_size", int(14 * size))
	l.add_theme_font_override("font", Ui.ui_font())
	l.z_index = 90
	l.position = Vector2.ZERO
	h.add_child(l)
	floats.append({"l": l, "t": 0.0, "h": h})

# ---------- telegraphs ----------
func tele_circle(pos: Vector2, radius: float, dur: float, col := Color(1, 0.15, 0.1, 0.28)) -> Dictionary:
	var s := _mk("circle", -40)
	s.global_position = pos
	s.scale = Vector2.ONE * (radius * 2.0) / 72.0
	s.modulate = col
	var r := _mk("ring", -39)
	r.global_position = pos
	r.scale = s.scale
	r.modulate = Color(col.r, col.g, col.b, 0.7)
	var t := {"sr": s, "sr2": r, "t": dur, "dur": dur, "done": false, "follow": null}
	teles.append(t)
	return t

func tele_wedge(pos: Vector2, angle_deg: float, length: float, dur: float, col := Color(1, 0.15, 0.1, 0.30)) -> Dictionary:
	var s := _mk("wedge", -40)
	s.global_position = pos
	s.rotation_degrees = angle_deg + 90  # wedge texture points up (-y); rotate to face angle
	s.scale = Vector2.ONE * (length / 90.0)
	s.modulate = col
	var t := {"sr": s, "t": dur, "dur": dur, "done": false, "follow": null}
	teles.append(t)
	return t

func tele_ring(pos: Vector2, radius: float, dur: float, col := Color(1, 0.2, 0.1, 0.5)) -> Dictionary:
	var s := _mk("ring", -40)
	s.global_position = pos
	s.scale = Vector2.ONE * (radius * 2.0) / 72.0
	s.modulate = col
	var t := {"sr": s, "t": dur, "dur": dur, "done": false, "follow": null}
	teles.append(t)
	return t

func kill_tele(t: Dictionary) -> void:
	if t.is_empty(): return
	t["done"] = true
	if is_instance_valid(t.get("sr")):
		t["sr"].queue_free()
	if is_instance_valid(t.get("sr2")):
		t["sr2"].queue_free()
	teles.erase(t)

# ---------- decals / ghosts ----------
const SPLAT_LIFE := 55.0   # kan/iz lekeleri solup temizlenir — haritada kalıcı iz kalmaz

func splat(pos: Vector2, col: Color, sc := 1.0) -> void:
	var s := _mk("splat", -50)
	s.global_position = pos + Vector2(G.rf(-6, 6), G.rf(-6, 6))
	s.rotation = G.rf(0, TAU)
	s.scale = Vector2.ONE * sc * G.rf(0.7, 1.3)
	s.modulate = Color(col.r, col.g, col.b, 0.55)
	var life := SPLAT_LIFE * G.rf(0.7, 1.2)
	if is_instance_valid(G.room):
		s.reparent(G.room.decals)
		# room.decals'te biriken eski izleri de sınırla (performans + görsel kalıntı)
		var kids := G.room.decals.get_children()
		if kids.size() > 30:
			kids[0].queue_free()
	else:
		life = 8.0
	var tw := create_tween()
	tw.tween_interval(life)
	tw.tween_property(s, "modulate:a", 0.0, 3.0)
	var wr: WeakRef = weakref(s)
	tw.tween_callback(func():
		var _s: Sprite2D = wr.get_ref()
		if _s:
			_s.queue_free()
	)

func ghost(src: Sprite2D, col: Color) -> void:
	var s := _mk("px1", 45)
	s.texture = src.texture
	s.global_position = src.global_position
	s.scale = src.global_scale
	s.flip_h = src.flip_h
	s.modulate = Color(col.r, col.g, col.b, 0.45)
	var tw := create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): if is_instance_valid(s): s.queue_free())

func clear_decals() -> void:
	for t in teles.duplicate():
		kill_tele(t)
	for p in pool:
		p.visible = false
		pdata.erase(p)
	for f in floats:
		if is_instance_valid(f.get("h")):
			f["h"].queue_free()
		elif is_instance_valid(f["l"]):
			f["l"].queue_free()
	floats.clear()
	# kan/iz lekeleri de odayla birlikte temizlenir
	if is_instance_valid(G.room) and is_instance_valid(G.room.decals):
		for d in G.room.decals.get_children():
			d.queue_free()

# ---------- screen fx ----------
func shake(amp: float, dur: float) -> void:
	if G.meta != null and not bool(G.meta.data.get("settings", {}).get("shake", true)):
		return
	shake_amp = maxf(shake_amp, amp)
	shake_t = maxf(shake_t, dur)

func hitstop(sec: float) -> void:
	if hitstop_t <= 0.0:
		prev_scale = Engine.time_scale
	Engine.time_scale = 0.06
	hitstop_t = maxf(hitstop_t, sec)

func flash(col: Color, a := 0.35) -> void:
	G.ui.screen_flash(col, a)

# ---------- v2: lights, slash trails, room transitions ----------
func mk_light(parent: Node, pos: Vector2, col: Color, energy: float, tex_scale: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = Px.S2("light")
	l.color = col
	l.energy = energy
	l.texture_scale = tex_scale
	l.position = pos
	l.shadow_enabled = false
	parent.add_child(l)
	return l

# generated pixel-art explosion sprite — a real boom frame on top of the
# particle burst (colors are baked into the art, so modulate stays white)
func boom(pos: Vector2, col: Color, radius := 70.0) -> void:
	var s := _mk("fx_boom", 64)
	if s.texture == null:
		burst(pos, col, 14, 300.0, 4.5, 0.4)
		return
	s.global_position = pos
	s.rotation = G.rf(0, TAU)
	burst(pos, col.lightened(0.2), 7, 240.0, 4.5, 0.35, 0.0, 63, "fx_flame_0")
	burst(pos + Vector2(0, 6), Color(0.2, 0.16, 0.2, 0.8), 5, 90.0, 6.0, 0.9, -0.4, 61)
	var sc := radius * 2.0 / float(maxi(s.texture.get_height(), 1))
	s.scale = Vector2.ONE * sc * 0.7
	s.modulate = Color(1, 1, 1, 0.95)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tw := create_tween()
	tw.tween_property(s, "scale", Vector2.ONE * sc * 1.25, 0.3)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): if is_instance_valid(s): s.queue_free())

func light_flash(pos: Vector2, col: Color, energy := 1.6, tex_scale := 2.5, dur := 0.22) -> void:
	var l := mk_light(self, pos, col, energy, tex_scale)
	l.z_index = 70
	var tw := create_tween()
	tw.tween_property(l, "energy", 0.0, dur)
	tw.tween_callback(func(): if is_instance_valid(l): l.queue_free())

func slash_fx(pos: Vector2, ang: float, reach: float, col: Color, heavy := false) -> void:
	var s := _mk("slash_arc", 55)
	s.global_position = pos + Vector2(0, -14) + Vector2(cos(ang), sin(ang)) * reach * 0.5
	s.rotation = ang
	s.scale = Vector2.ONE * (reach * 2.2 / 96.0) * (1.25 if heavy else 1.0)
	s.modulate = col
	var tw := create_tween()
	tw.tween_property(s, "modulate:a", 0.0, 0.18)
	tw.parallel().tween_property(s, "scale", s.scale * 1.15, 0.18)
	tw.tween_callback(func(): if is_instance_valid(s): s.queue_free())
	# lingering secondary trail — sells the weight of the swing
	var s2 := _mk("slash_arc", 54)
	s2.global_position = s.global_position
	s2.rotation = ang + (0.35 if heavy else 0.2)
	s2.scale = s.scale * 0.85
	s2.modulate = Color(col.r, col.g, col.b, 0.4)
	var tw2 := create_tween()
	tw2.tween_property(s2, "modulate:a", 0.0, 0.3)
	tw2.parallel().tween_property(s2, "rotation", s2.rotation + 0.3, 0.3)
	tw2.tween_callback(func(): if is_instance_valid(s2): s2.queue_free())
	light_flash(pos + Vector2(0, -14), col, 1.2 if heavy else 0.7, 2.0, 0.15)

# Starburst + sparks + light pop at a struck point — the "punch" of every hit.
func impact(pos: Vector2, dir: Vector2, col: Color, heavy := false) -> void:
	var s := _mk("spark", 62)
	s.global_position = pos
	s.rotation = G.rf(0, TAU)
	s.scale = Vector2.ONE * (2.4 if heavy else 1.5)
	s.modulate = Color(1, 1, 1, 0.95)
	var tw := create_tween()
	tw.tween_property(s, "scale", s.scale * 2.4, 0.11)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.11)
	tw.tween_callback(func(): if is_instance_valid(s): s.queue_free())
	if dir.length_squared() > 0.01:
		directional(pos, dir, col, 7 if heavy else 4, 230.0, 3.0, 0.22, 0.45)
		directional(pos, dir.rotated(2.6), col.darkened(0.35), 3, 150.0, 2.5, 0.28, 0.7)
		if heavy:
			directional(pos, dir, Color(1, 0.9, 0.7, 0.8), 3, 330.0, 2.0, 0.16, 0.25, "fx_trace_0")
	light_flash(pos, col, 1.1 if heavy else 0.7, 1.9, 0.13)

func transition(mid := Callable(), in_dur := 0.16, hold := 0.06, out_dur := 0.32) -> void:
	if _fade_layer == null:
		_fade_layer = CanvasLayer.new()
		_fade_layer.layer = 200
		add_child(_fade_layer)
		_fade_rect = ColorRect.new()
		_fade_rect.color = Color(0, 0, 0, 0)
		_fade_rect.size = get_viewport().get_visible_rect().size
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade_layer.add_child(_fade_rect)
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, in_dur)
	if mid.is_valid():
		tw.tween_callback(mid)
	tw.tween_interval(hold)
	tw.tween_property(_fade_rect, "color:a", 0.0, out_dur)

func _process(dt: float) -> void:
	# hitstop restore on real time
	if hitstop_t > 0:
		hitstop_t -= get_process_delta_time() / maxf(Engine.time_scale, 0.001)
		if hitstop_t <= 0:
			Engine.time_scale = prev_scale

	# particles
	for p in pool:
		if not p.visible or not pdata.has(p):
			continue
		var d: Dictionary = pdata[p]
		d["life"] -= dt
		if d["life"] <= 0:
			p.visible = false
			continue
		var vel: Vector2 = d["vel"]
		vel.y += d["grav"] * 100.0 * dt
		d["vel"] = vel
		p.global_position += vel * dt
		_pgrow(p, dt)
		var k: float = d["life"] / d["max"]
		var c: Color = d["col"]
		c.a = clampf(k * 1.4, 0.0, 1.0)
		p.modulate = c

	# floating combat text
	for i in range(floats.size() - 1, -1, -1):
		var f: Dictionary = floats[i]
		if not is_instance_valid(f["l"]):
			floats.remove_at(i)
			continue
		f["t"] += dt
		var fl: Label = f["l"]
		fl.position.y -= 42 * dt
		fl.modulate.a = 1.0 - f["t"] / 0.9
		if f["t"] >= 0.9:
			if is_instance_valid(f.get("h")):
				f["h"].queue_free()
			else:
				fl.queue_free()
			floats.remove_at(i)

	# telegraph pulse
	for i in range(teles.size() - 1, -1, -1):
		var t: Dictionary = teles[i]
		if t["done"]:
			continue
		t["t"] -= dt
		if is_instance_valid(t.get("follow")):
			t["sr"].global_position = t["follow"].global_position
			if is_instance_valid(t.get("sr2")):
				t["sr2"].global_position = t["follow"].global_position
		var k := 1.0 - clampf(t["t"] / t["dur"], 0.0, 1.0)
		var c: Color = t["sr"].modulate
		if t["dur"] > 100.0:
			# kalıcı tehlike işareti: leke değil işaretli bölge gibi okunur —
			# neredeyse şeffaf dolgu + yavaş dönen halka
			c.a = 0.05 + sin(Time.get_ticks_msec() * 0.003) * 0.025
			t["sr"].modulate = c
			if is_instance_valid(t.get("sr2")):
				var c2: Color = t["sr2"].modulate
				c2.a = 0.5 + sin(Time.get_ticks_msec() * 0.004) * 0.15
				t["sr2"].modulate = c2
				t["sr2"].rotation += dt * 0.5
		else:
			c.a = lerpf(0.16, 0.5, k) + sin(Time.get_ticks_msec() * 0.018) * 0.06
			t["sr"].modulate = c
			if is_instance_valid(t.get("sr2")):
				var c2: Color = t["sr2"].modulate
				c2.a = lerpf(0.3, 0.85, k)
				t["sr2"].modulate = c2
				t["sr2"].scale = t["sr"].scale * lerpf(1.08, 1.0, k)
		if t["t"] <= 0:
			kill_tele(t)

	# camera shake
	if shake_t > 0 and is_instance_valid(G.cam):
		shake_t -= dt
		if shake_t <= 0:
			shake_amp = 0
			G.cam.offset = Vector2.ZERO
		else:
			G.cam.offset = Vector2(G.rf(-1, 1), G.rf(-1, 1)) * shake_amp * 100.0
