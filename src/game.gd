class_name Game
extends Node2D

# Bootstrap: builds the global context, world node, camera, and starts at
# the title screen. Everything else is spawned in code.

var world: Node2D
var cam: Camera2D

func _ready() -> void:
	G.game = self
	G.rng.randomize()
	G.meta = Meta.new()
	G.meta.load()

	world = Node2D.new()
	world.name = "world"
	# dimetrik eğim: y ekseni %14 sıkışır + hafif sola kayma — BG2'nin izometrik
	# okunuşunu taklit eder; kamera aynı dönüşümle mantık konumunu takip eder
	world.transform = G.SHEAR
	add_child(world)

	G.fx = Fx.new()
	world.add_child(G.fx)

	G.audio = Audio2.new()
	add_child(G.audio)

	cam = Camera2D.new()
	cam.zoom = Vector2.ONE * 0.72
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	add_child(cam)
	G.cam = cam

	# 2D lighting atmosphere: global darkening + HDR glow so emissive
	# colors (Choralim purple, plasma cyan, hive green) bloom.
	_dark = CanvasModulate.new()
	_dark.color = Color(0.45, 0.40, 0.36)
	add_child(_dark)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.glow_enabled = true
	env.glow_normalized = false
	env.glow_intensity = 0.55
	env.glow_strength = 1.1
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.85
	env.glow_mix = 0.75
	env.set_glow_level(0, 0.0)
	env.set_glow_level(1, 0.9)
	env.set_glow_level(2, 0.4)
	env.set_glow_level(3, 0.15)
	we.environment = env
	add_child(we)

	G.ui = Ui.new()
	add_child(G.ui)

	G.run = Run.new(self)
	add_child(G.run)

	G.ui.title_screen()

	if OS.get_cmdline_user_args().has("--probe"):
		add_child(preload("res://tests/probe.gd").new())

var _dark: CanvasModulate

func set_dark(c: Color) -> void:
	if is_instance_valid(_dark):
		_dark.color = c

func _process(_d: float) -> void:
	if G.player != null and is_instance_valid(G.player) and not G.player.dead:
		cam.global_position = world.global_transform * G.player.pos
	elif is_instance_valid(G.room):
		cam.global_position = Vector2.ZERO
