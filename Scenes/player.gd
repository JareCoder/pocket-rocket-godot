extends Node2D

@export var speed: int = 500

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(100, 100)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var dir = Input.get_vector("left", "right", "up", "down")
	position += dir * speed * delta
