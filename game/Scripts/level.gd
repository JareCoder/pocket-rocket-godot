extends Node2D

@export var starAmount: int = 17
## Base meteor spawn interval (wait_time of MeteorTimer) at 1920px width.
@export var base_spawn_time: float = 0.15
## Reference width at which the base spawn interval is applied.
@export var base_spawn_width: float = 1920.0

var meteor_scene: PackedScene = load("res://Scenes/meteor.tscn")
var laser_scene: PackedScene = load("res://Scenes/laser.tscn")
var star_scene: PackedScene = load("res://Scenes/star.tscn")
var shield_item_scene: PackedScene = load("res://Scenes/shield_item.tscn")
var hp_item_scene: PackedScene = load("res://Scenes/hp_item.tscn")
var points_item_scene: PackedScene = load("res://Scenes/points_item.tscn")

var size := Vector2.ZERO
var rng := RandomNumberGenerator.new()

var shield: int = 0
var health: int = 3

func _ready():
	LobbyMusic.stop()
	GameMusic.play_random()
	size = get_viewport().get_visible_rect().size
	print("Level ready size: ", size)
	
	# Connect viewport resize signal for dynamic scaling
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# Center player ship initially at the bottom-center of the screen
	$Player.position = Vector2(size.x / 2.0, size.y - 120.0)
	
	# Instantiate mobile touch controls if touchscreen is available and enabled in settings
	if Global.is_touch_device() and Settings.touch_controls_enabled:
		var touch_controls = load("res://Scenes/touch_controls.tscn").instantiate()
		add_child(touch_controls)
	
	# Apply starting stat upgrades
	health = 3 + Upgrades.get_level("starting_health")
	shield = Upgrades.get_level("starting_shield")
	
	$Player/Shield.modulate = Color.YELLOW
	if shield <= 0:
		$Player/Shield.visible = false
	
	# Spawn stars covering a large region so they remain visible when resized
	for i in starAmount:
		var star = star_scene.instantiate()
		
		var random_x = rng.randi_range(0, max(3840, int(size.x)))
		var random_y = rng.randi_range(0, max(2160, int(size.y)))
		star.position = Vector2(random_x, random_y)
		
		var random_scale = rng.randf_range(0.5, 2)
		star.scale = Vector2(random_scale, random_scale)
		
		var star_sprite = star.get_node("AnimatedSprite2D")
		star_sprite.speed_scale = rng.randf_range(0.3, 0.6)
		star_sprite.frame = rng.randi_range(0, 10)
		
		$Stars.add_child(star)
		
	# Apply dynamic sizing to walls, background and meteor spawns immediately
	_on_viewport_size_changed()
		
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
	# Shield: base chance 20% (≤1 out of 0–10), each level +2 to threshold
	# HP:     base chance 5%  (≤0 out of 0–20), each level +1 to threshold
	var drop_level := Upgrades.get_level("item_drop_rate")
	var shield_threshold := 1 + drop_level * 2
	var hp_threshold     := 0 + drop_level
	
	var a: int = rng.randi_range(0, 9)
	var b := rng.randi_range(0, 19)
	
	if (a <= shield_threshold):
		var new_shield_item = _spawn_item(shield_item_scene)
		new_shield_item.connect('collision', _on_shield_item_collision)
		$BonusItems.add_child(new_shield_item)
		
	if (b <= hp_threshold):
		var new_hp_item = _spawn_item(hp_item_scene)
		new_hp_item.connect('collision', _on_hp_item_collision)
		$BonusItems.add_child(new_hp_item)
		
	# Points item: 5% chance of spawning, moves
	var c := rng.randi_range(0, 19)
	if (c == 0):
		var new_points_item = _spawn_item(points_item_scene)
		# Spawn between halfway (size.y / 2) and the top of the screen (0)
		new_points_item.position.y = rng.randf_range(18.0, size.y / 2.0)
		new_points_item.popped.connect(_on_points_item_popped)
		$BonusItems.add_child(new_points_item)

func _on_points_item_popped(points: int) -> void:
	get_tree().call_group('ui', 'add_score', points)
		

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

func _on_viewport_size_changed() -> void:
	size = get_viewport().get_visible_rect().size
	print("Viewport size changed: ", size)
	
	# Reposition and resize borders (duplicate shapes to prevent shared resource issues)
	if has_node("Borders/LeftWall"):
		$Borders/LeftWall.position = Vector2(-22, size.y / 2.0)
		$Borders/LeftWall/CollisionShape2D.position = Vector2.ZERO
		var shape = $Borders/LeftWall/CollisionShape2D.shape.duplicate()
		shape.size = Vector2(44, size.y + 100)
		$Borders/LeftWall/CollisionShape2D.shape = shape
		
	if has_node("Borders/RightWall"):
		$Borders/RightWall.position = Vector2(size.x + 22, size.y / 2.0)
		$Borders/RightWall/CollisionShape2D.position = Vector2.ZERO
		var shape = $Borders/RightWall/CollisionShape2D.shape.duplicate()
		shape.size = Vector2(44, size.y + 100)
		$Borders/RightWall/CollisionShape2D.shape = shape
		
	if has_node("Borders/TopWall2"):
		$Borders/TopWall2.position = Vector2(size.x / 2.0, -24)
		$Borders/TopWall2/CollisionShape2D.position = Vector2.ZERO
		var shape = $Borders/TopWall2/CollisionShape2D.shape.duplicate()
		shape.size = Vector2(size.x + 100, 48)
		$Borders/TopWall2/CollisionShape2D.shape = shape
		
	if has_node("Borders/BotWall"):
		$Borders/BotWall.position = Vector2(size.x / 2.0, size.y + 24)
		$Borders/BotWall/CollisionShape2D.position = Vector2.ZERO
		var shape = $Borders/BotWall/CollisionShape2D.shape.duplicate()
		shape.size = Vector2(size.x + 100, 48)
		$Borders/BotWall/CollisionShape2D.shape = shape
		
	# Update Background to cover the new size and repeat tiling
	if has_node("Background"):
		$Background.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		$Background.region_enabled = true
		$Background.region_rect = Rect2(Vector2.ZERO, size)
		$Background.position = size / 2.0
		$Background.scale = Vector2.ONE
		
	# Balance meteor spawn rate dynamically based on screen width
	if has_node("MeteorTimer"):
		$MeteorTimer.wait_time = base_spawn_time * (base_spawn_width / max(1.0, size.x))
		
	# Clamp player ship position so they aren't pushed off-screen if the window was shrunk
	if has_node("Player"):
		$Player.position.x = clamp($Player.position.x, 32.0, size.x - 32.0)
		$Player.position.y = clamp($Player.position.y, 32.0, size.y - 32.0)
