extends Control

static var game_start_scene: PackedScene = load("res://Scenes/game_start.tscn")
static var leaderboard_scene: PackedScene = load("res://Scenes/leaderboard.tscn")
static var credits_scene: PackedScene = load("res://Scenes/credits.tscn")
static var options_scene: PackedScene = load("res://Scenes/options.tscn")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(game_start_scene)

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_packed(options_scene)

func _on_leaderboard_button_pressed() -> void:
	get_tree().change_scene_to_packed(leaderboard_scene)

func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_packed(credits_scene)
