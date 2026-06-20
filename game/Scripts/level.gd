extends Node2D

@export var starAmount: int = 17

var meteor_scene: PackedScene = load("res://Scenes/meteor.tscn")
var laser_scene: PackedScene = load("res://Scenes/laser.tscn")
var star_scene: PackedScene = load("res://Scenes/star.tscn")
var shield_item_scene: PackedScene = load("res://Scenes/shield_item.tscn")
var hp_item_scene: PackedScene = load("res://Scenes/hp_item.tscn")

var size := Vector2.ZERO
var rng := RandomNumberGenerator.new()

var shield: int = 0
var health: int = 3

func _ready():
	LobbyMusic.stop()
	GameMusic.play_random()
	size = get_viewport().get_visible_rect().size
	print(size)
	
	# Apply starting stat upgrades
	health = 3 + Upgrades.get_level("starting_health")
	shield = Upgrades.get_level("starting_shield")
	
	$Player/Shield.modulate = Color.YELLOW
	if shield <= 0:
		$Player/Shield.visible = false
	
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
		_damage_animation($Player/PlayerImage, Color.RED, Color.WHITE)
	else:
		shield -= 1
		get_tree().call_group('ui', 'set_shield', shield)
		_damage_animation($Player/Shield, Color.RED, Color.YELLOW)
		
	if shield == 0:
		_damage_animation($Player/Shield, Color.RED, Color.YELLOW)
		await get_tree().create_timer(0.05).timeout #Play anim before hiding
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

func _on_player_laser(pos: Vector2) -> void:
	var bullet_level := Upgrades.get_level("bullet_amount")
	# Each entry is [angle_deg, perp_offset].
	# perp_offset shifts the spawn position perpendicular to travel direction,
	# so "doubled" lasers appear as a split pair rather than overlapping.
	# Level 0 → 1 centred laser
	# Level 1 → 2 side-by-side lasers (single direction, offset ±10 px)
	# Level 2 → 3-way spread (forward + 45° L/R), all centred
	# Level 3 → L2 pattern doubled — every direction gets a ±10 px split pair
	const OFFSET := 10.0
	var shots: Array = []
	match bullet_level:
		0: shots = [[0.0,    0.0]]
		1: shots = [[0.0,  -OFFSET],
					[0.0,   OFFSET]]
		2: shots = [[0.0,    0.0],
					[-45.0,  0.0],
					[45.0,   0.0]]
		3: shots = [[0.0,   -OFFSET], [0.0,    OFFSET],
					[-45.0, -OFFSET], [-45.0,  OFFSET],
					[45.0,  -OFFSET], [45.0,   OFFSET]]

	for shot in shots:
		_fire_laser(pos, shot[0], shot[1])

## Spawns a single laser.
## angle_deg  — rotation (0 = straight up).
## perp_offset — pixels to shift perpendicular to the travel direction;
##               positive = right of travel, negative = left.
func _fire_laser(pos: Vector2, angle_deg: float, perp_offset: float = 0.0) -> void:
	var laser = laser_scene.instantiate()
	$Lasers.add_child(laser)
	var angle_rad := deg_to_rad(angle_deg)
	# Perpendicular to travel direction Vector2(sin(θ), -cos(θ)) is Vector2(cos(θ), sin(θ))
	var perp := Vector2(cos(angle_rad), sin(angle_rad))
	laser.position = pos + perp * perp_offset
	laser.rotation_degrees = angle_deg

func _on_item_spawn_timer_timeout() -> void:
	# Item drop thresholds increase with the item_drop_rate upgrade level.
	# Shield: base chance ~18% (≤1 out of 0–10), each level +2 to threshold
	# HP:     base chance ~5%  (≤0 out of 0–20), each level +1 to threshold
	var drop_level := Upgrades.get_level("item_drop_rate")
	var shield_threshold := 1 + drop_level * 2
	var hp_threshold     := 0 + drop_level
	
	var a: int = rng.randi_range(0, 10)
	var b := rng.randi_range(0, 20)
	
	if (a <= shield_threshold):
		var new_shield_item = _spawn_item(shield_item_scene)
		new_shield_item.connect('collision', _on_shield_item_collision)
		$BonusItems.add_child(new_shield_item)
		
	if (b <= hp_threshold):
		var new_hp_item = _spawn_item(hp_item_scene)
		new_hp_item.connect('collision', _on_hp_item_collision)
		$BonusItems.add_child(new_hp_item)
		

func _on_shield_item_collision() -> void:
	shield += 1
	get_tree().call_group('ui', 'set_shield', shield)
	$Player/Shield.visible = true

func _on_hp_item_collision() -> void:
	health += 1
	get_tree().call_group('ui', 'set_health', health)
	
func _damage_animation(texture, dmgColor, originalColor):
	var tween = create_tween()
	texture.modulate = dmgColor
	tween.tween_property(texture, "modulate", originalColor, 0.2)
	
func _spawn_item(sceneToSpawn):
	var new_item = sceneToSpawn.instantiate()	
	var random_x = rng.randi_range(0, int(size.x))
	var random_y = rng.randi_range(0, int(size.y))
	new_item.position = Vector2(random_x, random_y)
	
	return new_item
