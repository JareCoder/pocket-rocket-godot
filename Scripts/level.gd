extends Node2D

@export var starAmount: int = 17

var meteor_scene: PackedScene = load("res://Scenes/meteor.tscn")
var laser_scene: PackedScene = load("res://Scenes/laser.tscn")
var star_scene: PackedScene = load("res://Scenes/star.tscn")
var shield_item_scene: PackedScene = load("res://Scenes/shield_item.tscn")

var size := Vector2.ZERO
var rng := RandomNumberGenerator.new()

var shield: int = 0
var health: int = 3

func _ready():
	
	size = get_viewport().get_visible_rect().size
	print(size)
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
		
	get_tree().call_group('ui', 'set_shield', shield)
	get_tree().call_group('ui', 'set_health', health)
	
func _reduce_player_health() -> void:
	if shield <= 0:
		health -= 1
		get_tree().call_group('ui', 'set_health', health)
	else:
		shield -= 1
		get_tree().call_group('ui', 'set_shield', shield)
		
	if shield == 0:
		$Player/Shield.visible = false
	
	if health <= 0:
		get_tree().call_deferred("change_scene_to_file", "res://Scenes/game_over.tscn")
	$Player.play_collision_sound()

func _on_meteor_timer_timeout() -> void:
	var new_meteor = meteor_scene.instantiate()
	
	$Meteors.add_child(new_meteor)
	
	new_meteor.connect('collision', _on_meteor_collision)
	
func _on_meteor_collision():
	_reduce_player_health()

func _on_player_laser(pos) -> void:
	var laser = laser_scene.instantiate()
	$Lasers.add_child(laser)
	laser.position = pos


func _on_shield_spawn_timer_timeout() -> void:
	print("Shield spawning...")
	print("Size: ", size)
	# Shield spawn chance 20%
	var a: int = rng.randi_range(0, 10)
	if (a <= 1):
		var new_shield_item = shield_item_scene.instantiate()
		new_shield_item.connect('shield_collision', _on_shield_item_collision)
		var random_x = rng.randi_range(0, int(size.x))
		var random_y = rng.randi_range(0, int(size.y))
		new_shield_item.position = Vector2(random_x, random_y)
		
		$ShieldItems.add_child(new_shield_item)
		print("Shield spawned to: ", new_shield_item.position)
		
		
func _on_shield_item_collision() -> void:
	shield += 1
	get_tree().call_group('ui', 'set_shield', shield)
	$Player/Shield.visible = true
