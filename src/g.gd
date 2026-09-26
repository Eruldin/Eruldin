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
static var melee_tokens := 2          # attack director: simultaneous melee attackers
const MELEE_TOKENS_MAX := 2

static var rng := RandomNumberGenerator.new()

static func rf(a: float, b: float) -> float: return rng.randf_range(a, b)
static func ri(a: int, b: int) -> int: return rng.randi_range(a, b)
static func chance(p: float) -> bool: return rng.randf() < p
static func pick(arr: Array): return arr[rng.randi() % arr.size()]

static func in_combat() -> bool: return state == State.ROOM
