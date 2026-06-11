extends Node2D

@export var starAmount: int = 17

var meteor_scene: PackedScene = load("res://Scenes/meteor.tscn")
var laser_scene: PackedScene = load("res://Scenes/laser.tscn")
var star_scene: PackedScene = load("res://Scenes/star.tscn")

var health: int = 3

func _ready():
	var size := get_viewport().get_visible_rect().size
	var rng := RandomNumberGenerator.new()
	
	for i in starAmount:
		var star = star_scene.instantiate()
		
		var random_x = rng.randi_range(0, int(size.x))
		var random_y = rng.randi_range(0, int(size.y))
		star.position = Vector2(random_x, random_y)
		
		var random_scale = rng.randf_range(0.5, 2)
		star.scale = Vector2(random_scale, random_scale)
		
		var star_sprite = star.get_node("AnimatedSprite2D")
		star_sprite.speed_scale = rng.randf_range(0.3, 0.6)
		star_sprite.frame = rng.randi_range(0, 10)
		
		$Stars.add_child(star)
		
	get_tree().call_group('ui', 'set_health', health)

func _on_meteor_timer_timeout() -> void:
	var new_meteor = meteor_scene.instantiate()
	
	$Meteors.add_child(new_meteor)
	
	new_meteor.connect('collision', _on_meteor_collision)
	
func _on_meteor_collision():
	health -= 1
	get_tree().call_group('ui', 'set_health', health)
	if health <= 0:
		get_tree().change_scene_to_file("res://Scenes/game_over.tscn")

func _on_player_laser(pos) -> void:
	var laser = laser_scene.instantiate()
	$Lasers.add_child(laser)
	laser.position = pos
