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
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	_username_regex.compile("^[\\w\\- ]+$")

	var saved: String = Global.load_username()
	var has_name: bool = saved is String and saved.length() > 0

	if has_name:
		# Restart path: reuse saved username, keep panel visible but disabled and show connecting state
		%UsernameInput.text = saved
		%UsernameInput.editable = false
		%ConfirmButton.disabled = true
		%ConfirmButton.text = "Connecting..."
		%BackButton.disabled = true
		%UsernameError.visible = false
		%UsernamePanel.visible = true
		await _start_session(saved)
	else:
		# First-play path: show the panel so the player can enter a name.
		%UsernameInput.text = ""
		%UsernameInput.editable = true
		%ConfirmButton.disabled = false
		%ConfirmButton.text = "Let's go!"
		%BackButton.disabled = false
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
	%UsernameInput.editable = false
	%ConfirmButton.disabled = true
	%ConfirmButton.text = "Connecting..."
	%BackButton.disabled = true

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
		%UsernameError.text = "⚠ Leaderboard offline — score won't be saved."
		%UsernameError.visible = true
		await get_tree().create_timer(1.5).timeout

	get_tree().change_scene_to_packed(level_scene)

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	if has_node("UsernamePanel"):
		var target_scale = 1.2 if size.x >= 550 else 1.0
		$UsernamePanel.scale = Vector2(target_scale, target_scale)
		$UsernamePanel.custom_minimum_size.x = min(440.0, (size.x - 20.0) / target_scale)
		# Force centering manually on resize
		$UsernamePanel.position = (size - $UsernamePanel.size * target_scale) / 2.0
