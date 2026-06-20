extends AudioStreamPlayer

func _ready() -> void:
	stream = load("res://Audio/Music/Calima - Usual Rigmarole.mp3")
	volume_db = -25.0
	play()

func _on_finished() -> void:
	play()
