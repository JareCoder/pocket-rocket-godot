extends Control

## how_to_play.gd

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
