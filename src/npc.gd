class_name NPC
extends Node2D

# Hub NPC — shows a prompt when Ely is near; E opens their dialogue.

static var NAMES := {
	"rhasa": "GENEL RHASA", "neva": "NEVA", "saphire": "SAPHIRE", "vane": "DR. VANE",
	"david": "İZ SÜRÜCÜ DAVID", "zirkon": "VEZİR ZİRKON"
}

var nid := ""
var body: Sprite2D
var prompt: Label
var _e_held := false
var _bob := 0.0

static func make(id: String, p: Vector2, parent: Node) -> NPC:
	var n := NPC.new()
	n.nid = id
	parent.add_child(n)
	n.position = p
	return n

var _fr: Array = []
var _fr_i := 0
var _fr_t := 0.0

func _ready() -> void:
	var sh := Sprite2D.new()
	sh.texture = Px.S("shadow")
	sh.scale = Vector2.ONE * 0.9
	sh.z_index = -45
	add_child(sh)
	body = Sprite2D.new()
	body.texture = Px.S2("npc2_" + nid)
	body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.offset = Vector2(0, -body.texture.get_height() * 0.5)
	Px.fit(body, 80.0)
	add_child(body)
	_fr = [Px.S2("npc2_" + nid), Px.S2("npcb_" + nid)]
	if nid == "neva":
		G.fx.mk_light(self, Vector2(0, -24), Px.C("c26bff"), 0.6, 1.8)
	prompt = Label.new()
	prompt.text = "E · " + NAMES.get(nid, nid)
	prompt.add_theme_font_size_override("font_size", 12)
	prompt.add_theme_font_override("font", Ui.ui_font())
	prompt.add_theme_color_override("font_color", Px.C("00E5FF"))
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 3)
	prompt.position = Vector2(-46, -body.texture.get_height() - 20)
	prompt.visible = false
	prompt.z_index = 500
	add_child(prompt)
	_bob = G.rf(0, TAU)

func _process(d: float) -> void:
	z_index = int(position.y)
	_bob += d
	_fr_t += d
	if _fr_t > 0.5:
		_fr_t = 0.0
		_fr_i = (_fr_i + 1) % _fr.size()
		if is_instance_valid(body):
			body.texture = _fr[_fr_i]
	if G.player == null or G.player.dead or G.state != G.State.HUB or G.ui.overlay_open():
		if is_instance_valid(prompt):
			prompt.visible = false
		return
	var near := position.distance_to(G.player.pos) < 58.0
	prompt.visible = near
	if near and is_instance_valid(body):
		body.flip_h = G.player.pos.x < position.x
	var e := Input.is_key_pressed(KEY_E)
	if near and e and not _e_held:
		G.ui.dialogue(nid)
	_e_held = e
