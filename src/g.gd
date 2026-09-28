class_name G
extends RefCounted

# Global game context — static references + shared enums.

enum State { TITLE, HUB, ROOM, DEAD, VICTORY, TRANSITION }
enum Team { PLAYER, ENEMY }
enum DamageType { MELEE, PLASMA, PROJECTILE, HAZARD, SHOCK, EXPLOSION, POISON, PURE }
enum Reward { BOON, HEAL, FRAGMENTS, ELITE, BOSS, EXIT }

static var game: Node2D          # Game root (game.gd)
static var player: Player
static var run: Run
static var meta: Meta
static var ui: Ui
static var fx: Fx
static var audio: Audio2
static var room: Room            # current room node
static var cam: Camera2D
static var state: int = State.TITLE

static var enemies: Array = []        # Array[Enemy]
static var projectiles: Array = []    # Array[Projectile]
static var director: Director          # arena swarm director (null outside runs)
static var melee_tokens := 2          # attack director: simultaneous melee attackers
static var MELEE_TOKENS_MAX := 2       # Director raises the cap as minutes pass

static var rng := RandomNumberGenerator.new()

# dimetrik eğim (BG2/iso okunuşu): world Node2D'ye uygulanır; karakterler
# upright() ile karşı-eğimli tutulur ki zeminde dik dursunlar
const SHEAR := Transform2D(Vector2(1.0, 0.0), Vector2(-0.10, 0.86), Vector2.ZERO)
static var SHEAR_INV := SHEAR.affine_inverse()

# sprite'ı eğik dünyada dik gösteren taşıyıcı — konum sheared kalır, çizim düz
static func upright(n: Node2D) -> Node2D:
	var h := Node2D.new()
	h.transform = SHEAR_INV
	n.add_child(h)
	return h

static func rf(a: float, b: float) -> float: return rng.randf_range(a, b)
static func ri(a: int, b: int) -> int: return rng.randi_range(a, b)
static func chance(p: float) -> bool: return rng.randf() < p
static func pick(arr: Array): return arr[rng.randi() % arr.size()]

static func in_combat() -> bool: return state == State.ROOM
