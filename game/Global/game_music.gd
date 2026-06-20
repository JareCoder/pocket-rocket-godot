extends AudioStreamPlayer

var _playlist: Array[String] = []
var _current_index: int = 0

func _ready() -> void:
	bus = "GameMusic"
	volume_db = -25.0
	finished.connect(_on_finished)

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
	stream = load(_playlist[_current_index])
	play()

func _on_finished() -> void:
	_current_index += 1
	if _current_index >= _playlist.size():
		# Reshuffle at end of playlist, then loop
		_current_index = 0
		_playlist.shuffle()
	_play_current()
