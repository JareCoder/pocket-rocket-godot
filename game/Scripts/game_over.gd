extends Control

var game_start_scene: PackedScene = load("res://Scenes/game_start.tscn")

func _ready() -> void:
	LobbyMusic.play()
	%Score.text = "Score: " + str(Global.score)
	_submit_score()

func _submit_score() -> void:
	if Global.session_token == "":
		# No token means the backend was offline at game start — inform player
		%StatusLabel.text = "⚠ Leaderboard offline — score not saved."
		%StatusLabel.visible = true
		return

	%StatusLabel.text = "Submitting score..."
	%StatusLabel.visible = true

	var result: Dictionary = await Api.end_game(Global.session_token, Global.score)

	# Clear token immediately so a restart doesn't re-submit
	Global.session_token = ""

	if result.ok:
		%StatusLabel.visible = false
		%RankLabel.text = "🏆 Leaderboard rank: #" + str(result.rank)
		%RankLabel.visible = true
	else:
		%StatusLabel.text = "⚠ Could not save score: " + result.get("error", "unknown error")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		get_tree().change_scene_to_packed(game_start_scene)
