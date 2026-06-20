extends AudioStreamPlayer

func _ready() -> void:
	bus = "LobbyMusic"
	stream = load("res://Audio/Music/Calima - Usual Rigmarole.mp3")
	volume_db = -25.0
	finished.connect(_on_finished)
	play()

func _on_finished() -> void:
	play()
