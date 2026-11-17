extends Control
## Simple pulsing ring for guided onboarding highlights

var min_alpha: float = 0.3
var max_alpha: float = 0.8
var speed: float = 1.0
var direction: int = 1

func _init_pulse(p_min: float, p_max: float, p_speed: float) -> void:
	min_alpha = p_min
	max_alpha = p_max
	speed = p_speed

func _process(delta: float) -> void:
	var alpha: float = modulate.a + direction * speed * delta
	if alpha >= max_alpha:
		alpha = max_alpha
		direction = -1
	elif alpha <= min_alpha:
		alpha = min_alpha
		direction = 1
	modulate = Color(modulate.r, modulate.g, modulate.b, alpha)
	queue_redraw()

func _draw() -> void:
	var radius: float = get_meta("_draw_radius", 50.0)
	var color: Color = get_meta("_draw_color", Color("#3f6652"))
	var center: Vector2 = size / 2
	draw_circle(center, radius, Color(color.r, color.g, color.b, modulate.a), 3)