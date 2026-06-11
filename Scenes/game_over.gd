extends Control

var level_scene: PackedScene = load("res://Scenes/level.tscn")
var scoreText: String = $CenterContainer/VBoxContainer/Score.text

func _ready():
	scoreText = scoreText + str(Global.score)

func _process(delta: float) -> void:
	if Input.is_action_pressed("ui_select"):
		get_tree().change_scene_to_packed(level_scene)
