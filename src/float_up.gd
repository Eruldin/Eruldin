class_name FloatUp
extends Label

# Floating combat text — drifts up and fades.

var t := 0.0
var life := 0.9

func _process(dt: float) -> void:
	t += dt
	position.y -= 42 * dt
	modulate.a = 1.0 - t / life
	if t >= life:
		queue_free()
