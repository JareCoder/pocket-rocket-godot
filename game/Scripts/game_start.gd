extends Control

## game_start.gd
##
## Handles the "start a new game session" flow for both paths:
##   - First play (from start_menu): no username saved → shows the username panel.
##   - Restart   (from game_over):   username already saved → skips the panel and
##     calls Api.start_game() immediately with the saved name.
##
## In both cases the result is: Global.session_token is set (or empty on offline)
## and the scene transitions to level.tscn.

static var level_scene: PackedScene = load("res://Scenes/level.tscn")

# Mirrors the backend regex: ^[\w\- ]+$
var _username_regex := RegEx.new()

func _ready() -> void:
	_username_regex.compile("^[\\w\\- ]+$")

	var saved: String = Global.load_username()
	var has_name: bool = saved is String and saved.length() > 0

	if has_name:
		# Restart path: reuse saved username, no UI interaction needed.
		%UsernamePanel.visible = false
		await _start_session(saved)
	else:
		# First-play path: show the panel so the player can enter a name.
		%UsernameInput.text = ""
		%UsernameError.visible = false
		%UsernamePanel.visible = true
		%UsernameInput.grab_focus()

# --- Username panel ---

func _on_back_button_pressed() -> void:
	# Return to the main menu.
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")

# Connected to both the "Let's go!" button press and LineEdit text_submitted.
func _on_confirm_username_pressed(_text: String = "") -> void:
	var raw: String = %UsernameInput.text.strip_edges()

	if raw.length() == 0 or raw.length() > 32 or _username_regex.search(raw) == null:
		%UsernameError.text = "Name must be 1–32 characters: letters, numbers, spaces, _ or -."
		%UsernameError.visible = true
		return

	%UsernameError.visible = false
	%ConfirmButton.disabled = true
	%ConfirmButton.text = "Connecting..."

	Global.save_username(raw)
	await _start_session(raw)

# --- Session start (shared by both paths) ---

func _start_session(username: String) -> void:
	var result: Dictionary = await Api.start_game(username)

	if result.ok:
		Global.session_token = result.token
	else:
		Global.session_token = ""
		# Show inline warning then proceed — graceful degradation.
		%UsernamePanel.visible = true
		%UsernameError.text = "⚠ Leaderboard offline — score won't be saved."
		%UsernameError.visible = true
		await get_tree().create_timer(1.5).timeout

	get_tree().change_scene_to_packed(level_scene)
