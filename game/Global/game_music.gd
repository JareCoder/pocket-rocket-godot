extends Node

var _playlist: Array[String] = []
var _current_index: int = 0
var _player_nodes: Dictionary = {}

signal song_started(title: String)

const SONG_TITLES := {
	"res://Audio/Music/Aylex - This Is Phonk.mp3": "This Is Phonk — Aylex",
	"res://Audio/Music/Walen - HEADPHONK.mp3": "HEADPHONK — Walen",
	"res://Audio/Music/Aylex - Off Road.mp3": "Off Road — Aylex",
	"res://Audio/Music/Aylex - LOUD.mp3": "LOUD — Aylex"
}

func _ready() -> void:
	# Instantiate dedicated child AudioStreamPlayers to avoid stream-swapping lag
	for path in SONG_TITLES.keys():
		var p := AudioStreamPlayer.new()
		p.bus = "GameMusic"
		p.volume_db = -25.0
		p.stream = load(path)
		add_child(p)
		p.finished.connect(_on_finished)
		_player_nodes[path] = p

## Builds a shuffled playlist from Settings.enabled_tracks and starts playback.
func play_random() -> void:
	_build_playlist()
	if _playlist.is_empty():
		return
	_current_index = 0
	_play_current()

## Builds a shuffled copy of the enabled tracks list.
func _build_playlist() -> void:
	_playlist = Settings.enabled_tracks.duplicate()
	_playlist.shuffle()

func _play_current() -> void:
	if _playlist.is_empty():
		return
		
	# Stop all players first
	for p in _player_nodes.values():
		p.stop()
		
	var path = _playlist[_current_index]
	if _player_nodes.has(path):
		_player_nodes[path].play()
		
	var title = SONG_TITLES.get(path, path.get_file().get_basename())
	song_started.emit(title)

func _on_finished() -> void:
	_current_index += 1
	if _current_index >= _playlist.size():
		# Reshuffle at end of playlist, then loop
		_current_index = 0
		_playlist.shuffle()
	_play_current()

func stop() -> void:
	for p in _player_nodes.values():
		p.stop()
