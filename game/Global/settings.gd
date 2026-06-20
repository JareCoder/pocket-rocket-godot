extends Node

const SAVE_PATH := "user://settings.cfg"

## Volume values: 0.0 (silent) to 1.0 (full). Bus volumes are set from these.
var sfx_volume: float = 1.0
var lobby_music_volume: float = 1.0
var game_music_volume: float = 1.0

## Resource paths for the 4 in-game tracks. All enabled by default.
var enabled_tracks: Array[String] = [
	"res://Audio/Music/Aylex - This Is Phonk.mp3",
	"res://Audio/Music/Walen - HEADPHONK.mp3",
	"res://Audio/Music/Aylex - Off Road.mp3",
	"res://Audio/Music/Aylex - LOUD.mp3",
]

## Whether on-screen touch controls are enabled on touchscreen devices
var touch_controls_enabled: bool = true


func _ready() -> void:
	_ensure_buses()
	_load()
	apply()

## Creates the SFX, LobbyMusic, and GameMusic buses if they don't exist.
func _ensure_buses() -> void:
	for bus_name: String in ["SFX", "LobbyMusic", "GameMusic"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

## Applies current volume settings to the audio buses.
func apply() -> void:
	_set_bus_volume("SFX", sfx_volume)
	_set_bus_volume("LobbyMusic", lobby_music_volume)
	_set_bus_volume("GameMusic", game_music_volume)

## Saves settings to disk.
func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "lobby_music_volume", lobby_music_volume)
	cfg.set_value("audio", "game_music_volume", game_music_volume)
	cfg.set_value("audio", "enabled_tracks", enabled_tracks)
	cfg.set_value("controls", "touch_controls_enabled", touch_controls_enabled)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return  # No file yet — use defaults
	sfx_volume = cfg.get_value("audio", "sfx_volume", sfx_volume)
	lobby_music_volume = cfg.get_value("audio", "lobby_music_volume", lobby_music_volume)
	game_music_volume = cfg.get_value("audio", "game_music_volume", game_music_volume)
	var saved_tracks = cfg.get_value("audio", "enabled_tracks", enabled_tracks)
	if saved_tracks is Array and not saved_tracks.is_empty():
		enabled_tracks = saved_tracks
	touch_controls_enabled = cfg.get_value("controls", "touch_controls_enabled", touch_controls_enabled)
	# Guard: ensure at least one track is always enabled
	if enabled_tracks.is_empty():
		enabled_tracks = ["res://Audio/Music/Aylex - This Is Phonk.mp3"]

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(max(linear, 0.001)))
