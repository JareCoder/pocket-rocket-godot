extends Control

var level_scene: PackedScene = load("res://Scenes/level.tscn")

func _ready():
	$CenterContainer/VBoxContainer/Score.text = $CenterContainer/VBoxContainer/Score.text + str(Global.score)

func _input(event):
	if event.is_action_pressed("ui_select"):
		get_tree().change_scene_to_packed(level_scene)
