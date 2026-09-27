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
	music = AudioStreamPlayer.new()
	music.bus = "Master"
	add_child(music)
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)

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
		_: play("ui", 1.0, 0.5)

func boss_sting() -> void:
	play("roar", 0.65, 0.8)
	play("alarm", 0.8, 0.5)

func _clip(n: String) -> AudioStream:
	if clips.has(n):
		return clips[n]
	var c: AudioStream = null
	var p := "res://audio/%s.wav" % n
	if ResourceLoader.exists(p):
		c = load(p)
	if c == null:
		var data := _synth(n)
		if data.is_empty():
			return null
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = SR
		w.data = data
		c = w
	if n.begins_with("mus_") and c is AudioStreamWAV:
		c.loop_mode = AudioStreamWAV.LOOP_FORWARD
		c.loop_begin = 0
		c.loop_end = int(c.get_length() * c.mix_rate)
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
		"hit": return _hit(0.09, 900.0, 0.5)
		"hitHeavy": return _hit(0.16, 300.0, 0.9)
		"crit": return _hit(0.12, 1400.0, 0.35)
		"dash": return _sweep(0.14, 1400.0, 300.0, true)
		"parry": return _hit(0.05, 1600.0, 0.35)
		"parryOk": return _chime([1320.0, 1980.0], 0.22)
		"chargeFull": return _chime([880.0, 1320.0, 1760.0], 0.3)
		"stance": return _chime([392.0, 587.0, 784.0], 0.4)
		"gateOpen": return _chime([220.0, 330.0, 440.0, 660.0], 0.6)
		"plasma": return _sweep(0.22, 220.0, 90.0, false)
		"plasmaCharge": return _sweep(0.5, 120.0, 700.0, false)
		"shoot": return _sweep(0.12, 900.0, 200.0, false)
		"zap": return _hit(0.08, 2400.0, 0.65)
		"beam": return _sweep(0.3, 1800.0, 500.0, false)
		"die": return _hit(0.3, 180.0, 0.9)
		"hurt": return _hit(0.14, 500.0, 0.6)
		"door": return _chime([330.0, 495.0], 0.35)
		"boon": return _chime([523.0, 784.0, 1046.0], 0.5)
		"ui": return _hit(0.04, 1200.0, 0.2)
		"heal": return _chime([660.0, 880.0], 0.4)
		"roar": return _roar()
		"alarm": return _chime([220.0, 180.0], 0.5)
		"explode": return _hit(0.5, 90.0, 1.0)
		"pickup": return _chime([880.0, 1174.0], 0.18)
		# layered ambient: drone base + sparse motif notes + (combat) pulse
		"mus_hub": return _drone2([55.0, 82.5, 110.0], 14.0, 0.16, [220.0, 277.0, 330.0, 440.0], false)
		"mus_0": return _drone2([49.0, 73.5, 98.0], 12.0, 0.2, [196.0, 233.0, 294.0, 392.0], true)
		"mus_1": return _drone2([41.0, 61.7, 82.4], 12.0, 0.23, [164.0, 196.0, 247.0, 330.0], true)
		"mus_2": return _drone2([46.0, 69.3, 92.5], 12.0, 0.21, [185.0, 220.0, 277.0, 370.0], true)
		"mus_3": return _drone2([36.7, 55.0, 73.4], 14.0, 0.24, [147.0, 175.0, 220.0, 294.0], true)
		"mus_4": return _drone2([44.0, 65.4, 87.3], 13.0, 0.22, [174.0, 196.0, 262.0, 349.0], true)
		"mus_5": return _drone2([38.9, 58.3, 77.8], 12.0, 0.25, [155.0, 185.0, 233.0, 311.0], true)
		"mus_6": return _drone2([43.7, 65.4, 87.3], 13.5, 0.2, [174.0, 208.0, 262.0, 349.0], true)
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
