extends Area2D

@export var speed: int = 500

func _ready() -> void:
	var tween = create_tween()
	tween.tween_property($Sprite2D, 'scale', Vector2.ONE, 0.2).from(Vector2.ZERO)

func _process(delta: float) -> void:
	# Direction is derived from the laser's rotation so spread lasers
	# travel at whatever angle they were fired at (0 = straight up).
	position += Vector2(sin(rotation), -cos(rotation)) * speed * delta
