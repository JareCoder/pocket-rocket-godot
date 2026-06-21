extends Control

static var game_start_scene: PackedScene = load("res://Scenes/game_start.tscn")
static var how_to_play_scene: PackedScene = load("res://Scenes/how_to_play.tscn")
static var leaderboard_scene: PackedScene = load("res://Scenes/leaderboard.tscn")
static var credits_scene: PackedScene = load("res://Scenes/credits.tscn")
static var options_scene: PackedScene = load("res://Scenes/options.tscn")
static var upgrade_shop_scene: PackedScene = load("res://Scenes/upgrade_shop.tscn")
static var patch_notes_scene: PackedScene = load("res://Scenes/patch_notes.tscn")

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	var is_narrow = size.x < 1.3 * size.y
	
	if has_node("Label"):
		$Label.size.x = size.x
		$Label.position.x = 0
		$Label.position.y = size.y * 0.08
		$Label.add_theme_font_size_override("font_size", int(min(63.0, size.x / 15.0)))
		
	if has_node("VBoxContainer") and has_node("ShipImage"):
		if is_narrow:
			# Vertical layout
			$VBoxContainer.size.x = min(448.0, size.x - 60.0)
			$VBoxContainer.position = Vector2((size.x - $VBoxContainer.size.x) / 2.0, size.y * 0.48)
			
			$ShipImage.size = Vector2(237, 180)
			$ShipImage.position = Vector2((size.x - $ShipImage.size.x) / 2.0, size.y * 0.22)
		else:
			# Horizontal layout (side-by-side)
			$VBoxContainer.size.x = 448
			$VBoxContainer.position = Vector2(size.x * 0.5 - 532.0, size.y * 0.5 - 170.0)
			
			$ShipImage.size = Vector2(319.4, 242)
			$ShipImage.position = Vector2(size.x * 0.5 + 153.0, size.y * 0.5 - 120.0)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(game_start_scene)

func _on_how_to_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(how_to_play_scene)

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_packed(options_scene)

func _on_leaderboard_button_pressed() -> void:
	get_tree().change_scene_to_packed(leaderboard_scene)

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_packed(credits_scene)

func _on_upgrades_button_pressed() -> void:
	get_tree().change_scene_to_packed(upgrade_shop_scene)

func _on_patch_notes_button_pressed() -> void:
	get_tree().change_scene_to_packed(patch_notes_scene)
