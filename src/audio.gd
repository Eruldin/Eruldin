class_name Audio2
extends Node

# Procedurally synthesized SFX + ambient drones. No audio assets needed.

const SR := 22050
var clips := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var sfx_vol := 0.7
var mus_vol := 0.35
var srng := RandomNumberGenerator.new()

func _ready() -> void:
	_ensure_bus("Music")
	_ensure_bus("SFX")
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		players.append(p)

# Müzik ve efektler ayrı bus'larda — ileride miks/ducking/ayar kolaylaşır
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

func play(n: String, pitch := 1.0, vol := 1.0) -> void:
	var c := _clip(n)
	if c == null:
		return
	var free: AudioStreamPlayer = null
	for p in players:
		if not p.playing:
			free = p
			break
	if free == null:
		free = players[0]
	free.stream = c
	free.pitch_scale = pitch
	var sfx_mult := 1.0
	if G.meta != null:
		sfx_mult = float(G.meta.data.get("settings", {}).get("sfx", 1.0))
	free.volume_db = linear_to_db(clampf(vol * sfx_vol * sfx_mult, 0.001, 1.0))
	free.play()

func play_music(n: String) -> void:
	var c := _clip(n)
	if c == null or music.stream == c:
		return
	music.stream = c
	var mus_mult := 1.0
	if G.meta != null:
		mus_mult = float(G.meta.data.get("settings", {}).get("mus", 1.0))
	music.volume_db = linear_to_db(clampf(mus_vol * mus_mult, 0.001, 1.0))
	music.play()

func dbg_clip_info(n: String) -> Dictionary:
	var c := _clip(n)
	if c == null:
		return {"ok": false}
	var rate := 0
	var dur := 0.0
	if c is AudioStreamWAV:
		rate = c.mix_rate
		dur = c.get_length()
	return {"ok": true, "mix_rate": rate, "len": dur, "file": c.resource_path}

func stop_music() -> void:
	music.stop()
	music.stream = null

func jingle(kind: String) -> void:
	match kind:
		"clear": play("door", 1.0, 0.8); play("boon", 1.2, 0.5)
		"boon": play("boon", 1.0, 0.8)
		"boss": play("roar", 0.7, 0.6); play("door", 0.7, 0.7)
		"victory": play("victory", 1.0, 0.9)
		"legendary": play("legendary", 1.0, 0.9)
		_: play("ui", 1.0, 0.5)

func boss_sting() -> void:
	play("roar", 0.65, 0.8)
	play("alarm", 0.8, 0.5)

func _clip(n: String) -> AudioStream:
	if clips.has(n):
		return clips[n]
	var c: AudioStream = null
	for ext in ["ogg", "mp3", "wav"]:
		var p := "res://audio/%s.%s" % [n, ext]
		if ResourceLoader.exists(p):
			c = load(p)
			break
	if c == null:
		var data := _synth(n)
		if data.is_empty():
			return null
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = SR
		w.data = data
		c = w
	if n.begins_with("mus_"):
		if c is AudioStreamWAV:
			c.loop_mode = AudioStreamWAV.LOOP_FORWARD
			c.loop_begin = 0
			c.loop_end = int(c.get_length() * c.mix_rate)
		elif c is AudioStreamOggVorbis:
			c.loop = true
	clips[n] = c
	return c

func _pack(samples: PackedFloat32Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32000.0)
		b.encode_s16(i * 2, v)
	return b

func _noise() -> float:
	return srng.randf_range(-1.0, 1.0)

func _synth(n: String) -> PackedByteArray:
	match n:
		"hit": return _thud(0.10, 380.0, 0.85)
		"hitHeavy": return _thud(0.18, 170.0, 1.0)
		"crit": return _crack(0.12, 2600.0, 0.9)
		"slash": return _whoosh(0.16, 2600.0, 700.0, 0.9)
		"slash2": return _whoosh(0.14, 3400.0, 900.0, 0.7)
		"comboFin": return _whoosh(0.24, 3800.0, 300.0, 1.0)
		"dash": return _whoosh(0.18, 1800.0, 400.0, 0.6)
		"parry": return _metallic([1900.0, 2900.0, 4300.0], 0.10, 0.5)
		"parryOk": return _metallic([1320.0, 2210.0, 3400.0, 5200.0], 0.30, 0.8)
		"chargeFull": return _chime([880.0, 1320.0, 1760.0], 0.3)
		"stance": return _chime([392.0, 587.0, 784.0], 0.4)
		"gateOpen": return _chime([220.0, 330.0, 440.0, 660.0], 0.6)
		"plasma": return _sweep(0.22, 220.0, 90.0, false)
		"plasmaCharge": return _sweep(0.5, 120.0, 700.0, false)
		"shoot": return _zapgun(0.12, 1100.0, 240.0, 0.7)
		"zap": return _crack(0.10, 2200.0, 0.8)
		"beam": return _laser(0.3, 0.8)
		"laser": return _laser(0.22, 0.9)
		"die": return _thud(0.3, 140.0, 0.9)
		"hurt": return _thud(0.13, 300.0, 0.75)
		"door": return _chime([330.0, 495.0], 0.35)
		"boon": return _metallic([780.0, 1180.0, 1770.0, 2600.0], 0.45, 0.6)
		"ui": return _click()
		"heal": return _chime([660.0, 880.0], 0.4)
		"roar": return _roar()
		"alarm": return _chime([220.0, 180.0], 0.5)
		"explode": return _boom(0.55, 1.0)
		"pickup": return _metallic([1560.0, 2350.0, 3500.0], 0.16, 0.5)
		"legendary": return _metallic([620.0, 930.0, 1240.0, 1860.0, 2790.0], 0.9, 0.9)
		"manapick": return _metallic([1980.0, 2970.0], 0.10, 0.35)
		"rankup": return _metallic([880.0, 1320.0, 1980.0, 2970.0], 0.35, 0.7)
		"supernova": return _boom(1.2, 1.0)
		"victory": return _chime([523.0, 659.0, 784.0, 1046.0], 1.0)
		# layered ambient: drone base + sparse motif notes + (combat) pulse
		"mus_hub": return _drone2([55.0, 82.5, 110.0], 14.0, 0.16, [220.0, 277.0, 330.0, 440.0], false)
		"mus_0": return _drone2([49.0, 73.5, 98.0], 12.0, 0.2, [196.0, 233.0, 294.0, 392.0], true)
		"mus_1": return _drone2([41.0, 61.7, 82.4], 12.0, 0.23, [164.0, 196.0, 247.0, 330.0], true)
		"mus_2": return _drone2([46.0, 69.3, 92.5], 12.0, 0.21, [185.0, 220.0, 277.0, 370.0], true)
		"mus_3": return _drone2([36.7, 55.0, 73.4], 14.0, 0.24, [147.0, 175.0, 220.0, 294.0], true)
		"mus_4": return _drone2([44.0, 65.4, 87.3], 13.0, 0.22, [174.0, 196.0, 262.0, 349.0], true)
		"mus_5": return _drone2([38.9, 58.3, 77.8], 12.0, 0.25, [155.0, 185.0, 233.0, 311.0], true)
		"mus_6": return _drone2([43.7, 65.4, 87.3], 13.5, 0.2, [174.0, 208.0, 262.0, 349.0], true)
		"mus_7": return _drone2([32.7, 49.0, 65.4], 15.0, 0.26, [131.0, 165.0, 196.0, 262.0], true)
		"mus_8": return _drone2([43.7, 65.4, 87.3], 16.0, 0.19, [262.0, 330.0, 415.0, 523.0], true)
		# boss dövüşü: alçak kök + hızlı nabız + keskin motif
		"mus_boss": return _drone2([36.7, 55.0, 73.4], 7.0, 0.3, [147.0, 156.0, 220.0, 311.0], true)
	return PackedByteArray()

# richer ambient: chord drone + slow wandering motif + soft pulse for combat
func _drone2(fs: Array, dur: float, vol: float, motif: Array, pulse: bool) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var step := dur / 7.0
	for i in n:
		var t := i / float(SR)
		var v := 0.0
		for k in fs.size():
			v += sin(t * fs[k] * TAU + sin(t * 0.7 + k) * 0.6) / (k + 1)
		v += sin(t * fs[0] * 2.02 * TAU) * 0.15 * (0.5 + 0.5 * sin(t * 0.5))
		# sparse motif: one soft note per step, slow attack/release
		var step_i := int(t / step)
		var mt := t - step_i * step
		var nf: float = motif[(step_i * 2 + 1) % motif.size()]
		var menv := minf(1.0, mt * 2.5) * exp(-mt * 0.9)
		v += sin(t * nf * TAU) * menv * 0.22
		# combat pulse: soft low thump every half second
		if pulse:
			var pt := fmod(t, 0.5)
			v += sin(t * 55.0 * TAU) * exp(-pt * 14.0) * 0.5
		var loop := minf(1.0, minf(i, n - i) / (SR * 0.6))
		d[i] = v * vol * loop * (0.75 + 0.25 * sin(t * 0.9))
	return _pack(d)

# --- realistic one-shots: noise/filter driven instead of sine beeps ---

# kılıç savurması / dash: bant-geçiren gürültü, keskin hücum, aşağı süpürme
func _whoosh(dur: float, f0: float, f1: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := i / float(SR)
		var k := t / dur
		var cf := lerpf(f0, f1, k) / (SR * 0.5)
		lp += clampf(cf, 0.0, 0.9) * (_noise() - lp)
		var env := pow(sin(minf(1.0, k * 1.15) * PI), 1.5)
		d[i] = env * lp * vol * 2.2
	return _pack(d)

# beden darbesi: düşen sub sine + gürültü darbesi — tok, beep'siz
func _thud(dur: float, freq: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := i / float(SR)
		var k := t / dur
		var f := freq * (1.0 - k * 0.72)
		var body := sin(t * f * TAU) * exp(-t * 22.0)
		lp += 0.18 * (_noise() - lp)
		var env := exp(-t * 16.0)
		d[i] = (body * 0.7 + lp * 0.8) * env * vol * 1.6
	return _pack(d)

# keskin çatlak: yüksek gürültü patlaması + kısa zil kalıntısı
func _crack(dur: float, freq: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := i / float(SR)
		lp += 0.55 * (_noise() - lp)
		var ring := sin(t * freq * TAU) * exp(-t * 40.0)
		d[i] = (lp * exp(-t * 26.0) + ring * 0.5) * vol * 1.5
	return _pack(d)

# metalik tonlar: uyumsuz kısmi tonlar — gerçek "tık/çıng" hissi
func _metallic(fs: Array, dur: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := i / float(SR)
		var v := 0.0
		for k in fs.size():
			var f: float = fs[k]
			v += sin(t * f * TAU + sin(t * f * 0.011) * 0.7) * exp(-t * (9.0 + k * 3.5)) / (1.0 + k * 0.5)
		d[i] = v * vol * 1.1
	return _pack(d)

# lazer: hızlı düşen cıvıltı + harmonik + ince hava kuyruğu
func _laser(dur: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var ph := 0.0
	for i in n:
		var t := i / float(SR)
		var k := t / dur
		var f := lerpf(2600.0, 320.0, pow(k, 0.6))
		ph += f * TAU / SR
		var env := exp(-t * 9.0)
		var wob := 1.0 + sin(t * 240.0 * TAU) * 0.12
		d[i] = env * (sin(ph) * 0.6 + sin(ph * 2.01) * 0.25 + _noise() * 0.18) * wob * vol * 0.9
	return _pack(d)

# mermi: çok kısa lazer benzeri tik — hafif ve tekrar dostu
func _zapgun(dur: float, f0: float, f1: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var ph := 0.0
	for i in n:
		var t := i / float(SR)
		var k := t / dur
		ph += lerpf(f0, f1, k) * TAU / SR
		var env := exp(-t * 30.0)
		d[i] = env * (sin(ph) * 0.55 + _noise() * 0.3) * vol
	return _pack(d)

# patlama: sub düşüş + yoğun düşük-geçiren gürültü, uzun kuyruk
func _boom(dur: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var lp := 0.0
	for i in n:
		var t := i / float(SR)
		var k := t / dur
		lp += lerpf(0.5, 0.04, k) * (_noise() - lp)
		var sub := sin(t * lerpf(90.0, 34.0, k) * TAU) * exp(-t * 6.0)
		d[i] = (sub * 0.8 + lp * 1.4) * exp(-t * 4.5) * vol * 1.5
	return _pack(d)

# UI tık: çok kısa gürültü + alçak tik — kağıt/mekanik his
func _click() -> PackedByteArray:
	var n := int(SR * 0.035)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := i / float(SR)
		d[i] = (_noise() * 0.5 + sin(t * 900.0 * TAU) * 0.5) * exp(-t * 160.0) * 0.6
	return _pack(d)

func _hit(dur: float, freq: float, mix: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := i / float(SR)
		var env := exp(-t * 30.0)
		d[i] = env * (sin(t * freq * TAU) * (1 - mix) + _noise() * mix) * 0.8
	return _pack(d)

func _sweep(dur: float, f0: float, f1: float, noisy: bool) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	var ph := 0.0
	for i in n:
		var t := i / float(SR)
		var k := t / dur
		ph += lerpf(f0, f1, k) * TAU / SR
		var env := sin(k * PI)
		d[i] = env * ((_noise() * 0.7) if noisy else sin(ph) + sin(ph * 0.5) * 0.3) * 0.6
	return _pack(d)

func _chime(fs: Array, dur: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := i / float(SR)
		var v := 0.0
		for k in fs.size():
			v += sin(t * fs[k] * TAU) * exp(-t * (5.0 + k * 4.0))
		d[i] = exp(-t * 8.0) * v * 0.35
	return _pack(d)

func _roar() -> PackedByteArray:
	var n := int(SR * 0.9)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := i / float(SR)
		var k := t / 0.9
		var env := sin(minf(1.0, k * 1.4) * PI)
		var f := 60.0 + sin(t * 30.0) * 20.0 + k * 40.0
		d[i] = env * (sin(t * f * TAU) * 0.6 + _noise() * 0.4) * 0.8
	return _pack(d)

func _drone(fs: Array, dur: float, vol: float) -> PackedByteArray:
	var n := int(SR * dur)
	var d := PackedFloat32Array()
	d.resize(n)
	for i in n:
		var t := i / float(SR)
		var v := 0.0
		for k in fs.size():
			v += sin(t * fs[k] * TAU + sin(t * 0.7 + k) * 0.6) / (k + 1)
		v += sin(t * fs[0] * 2.02 * TAU) * 0.15 * (0.5 + 0.5 * sin(t * 0.5))
		var loop := minf(1.0, minf(i, n - i) / (SR * 0.5))
		d[i] = v * vol * loop * (0.75 + 0.25 * sin(t * 0.9))
	return _pack(d)
