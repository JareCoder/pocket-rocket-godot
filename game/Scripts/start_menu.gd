extends Control

static var level_scene: PackedScene = load("res://Scenes/level.tscn")
static var leaderboard_scene: PackedScene = load("res://Scenes/leaderboard.tscn")

# Username validation — mirrors the backend regex: ^[\w\- ]+$
var _username_regex := RegEx.new()

func _ready() -> void:
	_username_regex.compile("^[\\w\\- ]+$")

	var saved = Global.load_username()
	if saved is String and saved.length() > 0:
		%UsernameInput.text = saved

	%UsernameError.visible = false
	%UsernamePanel.visible = false

func _on_play_button_pressed() -> void:
	%UsernamePanel.visible = true
	%UsernameInput.grab_focus()
	%UsernameInput.select_all()

func _on_options_button_pressed() -> void:
	print("Options pressed!")

func _on_leaderboard_button_pressed() -> void:
	get_tree().change_scene_to_packed(leaderboard_scene)

func _on_credits_button_pressed() -> void:
	print("Credits pressed!")

# --- Username panel ---

func _on_back_button_pressed() -> void:
	%UsernamePanel.visible = false
	%UsernameError.visible = false

# Called by both the "Let's go!" button and pressing Enter in the LineEdit.
func _on_confirm_username_pressed(_text: String = "") -> void:
	var raw: String = %UsernameInput.text.strip_edges()

	# Client-side validation (mirrors backend rules)
	if raw.length() == 0 or raw.length() > 32 or _username_regex.search(raw) == null:
		%UsernameError.text = "Name must be 1–32 characters: letters, numbers, spaces, _ or -."
		%UsernameError.visible = true
		return

	%UsernameError.visible = false
	%ConfirmButton.disabled = true
	%ConfirmButton.text = "Connecting..."

	Global.save_username(raw)

	var result: Dictionary = await Api.start_game(raw)

	if result.ok:
		Global.session_token = result.token
	else:
		Global.session_token = ""
		# Inform the player but don't block them — score just won't be submitted
		%UsernameError.text = "⚠ Leaderboard offline — score won't be saved."
		%UsernameError.visible = true
		await get_tree().create_timer(1.5).timeout

	get_tree().change_scene_to_packed(level_scene)
