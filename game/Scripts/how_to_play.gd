extends Control

## how_to_play.gd

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	if has_node("CenterContainer/VBox"):
		$CenterContainer/VBox.custom_minimum_size.x = min(680.0, size.x - 30.0)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
