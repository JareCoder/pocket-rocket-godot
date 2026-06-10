extends Area2D

var rotationSpeed: int
var speed: int
var dir_x: float

func _ready():
	var rng := RandomNumberGenerator.new()
	
	
	var path: String = "res://Assets/PNG/Meteors/big" + str(rng.randi_range(1, 8)) + ".png"
	$Sprite2D.texture = load(path)
	
	var width = get_viewport().get_visible_rect().size[0]
	
	var random_x = rng.randi_range(0, width)
	var random_y = rng.randi_range(-150, -50)
	position = Vector2(random_x, random_y)
	
	speed = rng.randi_range(200, 500)
	dir_x = rng.randf_range(-1, 1)
	rotationSpeed = rng.randi_range(40, 100)
	
	
func _process(delta: float) -> void:
	position += Vector2(dir_x, 1) * speed * delta
	rotation_degrees += rotationSpeed * delta

func _on_body_entered(_body: Node2D) -> void:
	print("Ouch!")
