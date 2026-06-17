extends Control

static var level_scene: PackedScene = load("res://Scenes/level.tscn")
static var options_scene: PackedScene = load("res://Scenes/level.tscn")
static var leaderboard_scene: PackedScene = load("res://Scenes/level.tscn")
static var credits_scene: PackedScene = load("res://Scenes/level.tscn")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(level_scene)


func _on_options_button_pressed() -> void:
	print("Options pressed!")


func _on_leaderboard_button_pressed() -> void:
	print("Leaderboard pressed!")


func _on_credits_button_pressed() -> void:
	print("Credits pressed!")
