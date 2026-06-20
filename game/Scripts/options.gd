extends Control

var start_menu_scene: String = "res://Scenes/start_menu.tscn"

@onready var sfx_slider: HSlider = %SfxSlider
@onready var game_music_slider: HSlider = %GameMusicSlider
@onready var lobby_music_slider: HSlider = %LobbyMusicSlider

@onready var tracks_button: Button = %TracksButton
@onready var tracks_panel: VBoxContainer = %TracksPanel
@onready var fullscreen_button: CheckButton = %FullscreenButton
@onready var touch_controls_button: CheckButton = %TouchControlsButton

@onready var track_buttons: Array[CheckButton] = [
	%TrackButton1,
	%TrackButton2,
	%TrackButton3,
	%TrackButton4
]

const TRACK_PATHS := [
	"res://Audio/Music/Aylex - This Is Phonk.mp3",
	"res://Audio/Music/Walen - HEADPHONK.mp3",
	"res://Audio/Music/Aylex - Off Road.mp3",
	"res://Audio/Music/Aylex - LOUD.mp3"
]

func _ready() -> void:
	# Load volume values into sliders
	sfx_slider.value = Settings.sfx_volume
	game_music_slider.value = Settings.game_music_volume
	lobby_music_slider.value = Settings.lobby_music_volume

	# Connect sliders
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	game_music_slider.value_changed.connect(_on_game_music_volume_changed)
	lobby_music_slider.value_changed.connect(_on_lobby_music_volume_changed)

	# Connect viewport resize signal
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

	# Set up track toggle buttons
	for i in range(TRACK_PATHS.size()):
		var path = TRACK_PATHS[i]
		var btn = track_buttons[i]
		btn.button_pressed = Settings.enabled_tracks.has(path)
		# Use bind to pass the index/path
		btn.toggled.connect(_on_track_toggled.bind(i))

	# Tracks dropdown section toggle
	tracks_panel.visible = false
	tracks_button.text = "▶  Game Tracks"
	tracks_button.pressed.connect(_on_tracks_button_pressed)

	# Set up Fullscreen button
	fullscreen_button.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_button.toggled.connect(_on_fullscreen_toggled)

	# Set up Touch Controls button
	if Global.is_touch_device():
		touch_controls_button.disabled = false
		touch_controls_button.button_pressed = Settings.touch_controls_enabled
		touch_controls_button.toggled.connect(_on_touch_controls_toggled)
	else:
		touch_controls_button.disabled = true
		touch_controls_button.button_pressed = false
		touch_controls_button.text = "Touch Controls (N/A)"

func _on_sfx_volume_changed(value: float) -> void:
	Settings.sfx_volume = value
	Settings.apply()
	Settings.save()

func _on_game_music_volume_changed(value: float) -> void:
	Settings.game_music_volume = value
	Settings.apply()
	Settings.save()

func _on_lobby_music_volume_changed(value: float) -> void:
	Settings.lobby_music_volume = value
	Settings.apply()
	Settings.save()

func _on_tracks_button_pressed() -> void:
	tracks_panel.visible = not tracks_panel.visible
	if tracks_panel.visible:
		tracks_button.text = "▼  Game Tracks"
	else:
		tracks_button.text = "▶  Game Tracks"

func _on_track_toggled(pressed: bool, index: int) -> void:
	var path = TRACK_PATHS[index]
	
	if not pressed:
		# Check if this is the last remaining enabled track
		var enabled_count = 0
		for btn in track_buttons:
			if btn.button_pressed:
				enabled_count += 1
				
		if enabled_count == 0:
			# Re-enable the button since we need at least 1 track
			track_buttons[index].set_pressed_no_signal(true)
			return
			
		# Remove from enabled tracks
		if Settings.enabled_tracks.has(path):
			Settings.enabled_tracks.erase(path)
	else:
		# Add to enabled tracks
		if not Settings.enabled_tracks.has(path):
			Settings.enabled_tracks.append(path)
			
	Settings.save()

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_touch_controls_toggled(pressed: bool) -> void:
	Settings.touch_controls_enabled = pressed
	Settings.save()

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	if has_node("CenterContainer/VBox"):
		$CenterContainer/VBox.custom_minimum_size.x = min(680.0, size.x - 30.0)

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(start_menu_scene)
