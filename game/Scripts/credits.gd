extends Control

var start_menu_scene: PackedScene = load("res://Scenes/start_menu.tscn")

@onready var music_button: Button = %MusicButton
@onready var music_panel: VBoxContainer = %MusicPanel
@onready var graphics_button: Button = %GraphicsButton
@onready var graphics_panel: VBoxContainer = %GraphicsPanel

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	# Both panels start collapsed
	music_panel.visible = false
	graphics_panel.visible = false
	_update_button_text(music_button, false)
	_update_button_text(graphics_button, false)



func _update_button_text(button: Button, is_open: bool) -> void:
	var arrow := "v" if is_open else ">"
	var base := "Music" if button == music_button else "Graphics & Sound"
	button.text = arrow + "  " + base

func _on_music_button_pressed() -> void:
	var now_open := not music_panel.visible
	music_panel.visible = now_open
	_update_button_text(music_button, now_open)

func _on_graphics_button_pressed() -> void:
	var now_open := not graphics_panel.visible
	graphics_panel.visible = now_open
	_update_button_text(graphics_button, now_open)

func _on_link_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_packed(start_menu_scene)

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	if has_node("CenterContainer/VBox"):
		$CenterContainer/VBox.custom_minimum_size.x = min(680.0, size.x - 30.0)
