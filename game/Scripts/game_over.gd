extends Control

var game_start_scene: PackedScene = load("res://Scenes/game_start.tscn")
var start_menu_scene: PackedScene = load("res://Scenes/start_menu.tscn")
var upgrade_shop_scene: PackedScene = load("res://Scenes/upgrade_shop.tscn")

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	await get_tree().process_frame
	_on_viewport_size_changed()
	GameMusic.stop()
	LobbyMusic.play()
	%Score.text = "Score: " + str(Global.score)
	_award_flyons()
	_submit_score()

func _award_flyons() -> void:
	# Flyons earned = floor(score / divisor)
	# flyons_rate upgrade lowers the divisor by 2 per level (min 1), default 10
	var divisor: float = max(1, 10 - Upgrades.get_level("flyons_rate") * 2)
	var earned:  float = int(Global.score) / divisor
	Upgrades.add_flyons(earned)
	Upgrades.save()
	%FloyonsEarnedLabel.text = "+" + str(earned) + " Flyons earned"
	%FloyonsTotalLabel.text  = "Total: " + str(Upgrades.get_flyons()) + " Flyons"

func _submit_score() -> void:
	if Global.session_token == "":
		# No token means the backend was offline at game start — inform player
		%StatusLabel.text = "Leaderboard offline — score not saved."
		%StatusLabel.visible = true
		return

	%StatusLabel.text = "Submitting score..."
	%StatusLabel.visible = true

	var result: Dictionary = await Api.end_game(Global.session_token, Global.score)

	# Clear token immediately so a restart doesn't re-submit
	Global.session_token = ""

	if result.ok:
		%StatusLabel.visible = false
		%RankLabel.text = "Leaderboard rank: #" + str(result.rank)
		%RankLabel.visible = true
	else:
		%StatusLabel.text = "Could not save score: " + result.get("error", "unknown error")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		get_tree().change_scene_to_packed(game_start_scene)

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_packed(start_menu_scene)

func _on_shop_button_pressed() -> void:
	get_tree().change_scene_to_packed(upgrade_shop_scene)

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	if has_node("CenterContainer/VBoxContainer"):
		var vbox = $CenterContainer/VBoxContainer
		var scale_factor = 1.3 if (size.x < 1200 or size.y < 700) else 1.0
		vbox.scale = Vector2(scale_factor, scale_factor)
		vbox.custom_minimum_size.x = min(500.0, (size.x - 30.0) / scale_factor)
		vbox.pivot_offset = vbox.size / 2.0
