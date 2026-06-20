extends Control

var _current_page: int = 1
var _total_pages: int = 1

# Loaded once; used for row font styling
var _font_thin: Font = load("res://Assets/Fonts/kenvector_future_thin.ttf")
var _font_bold: Font = load("res://Assets/Fonts/kenvector_future.ttf")

func _ready() -> void:
	_load_page(1)

func _load_page(page: int) -> void:
	_clear_entries()
	%StatusLabel.text = "Loading..."
	%StatusLabel.visible = true
	%PrevButton.disabled = true
	%NextButton.disabled = true

	var result: Dictionary = await Api.get_leaderboard(page)

	%StatusLabel.visible = false

	if not result.ok:
		var err_msg: String = result.get("error", "unknown error")
		if err_msg.begins_with("Network error") or err_msg.begins_with("Failed to send"):
			%StatusLabel.text = "⚠ Leaderboard offline — please try again later."
		else:
			%StatusLabel.text = "⚠ Could not load leaderboard: " + err_msg
		%StatusLabel.visible = true
		return

	var scores: Array = result.get("scores", [])
	var pagination: Dictionary = result.get("pagination", {})

	_current_page = pagination.get("page", page)
	_total_pages = pagination.get("totalPages", 1)

	if scores.is_empty():
		%StatusLabel.text = "No scores yet — be the first!"
		%StatusLabel.visible = true
	else:
		for entry in scores:
			_add_row(
					entry.get("rank", 0),
					entry.get("username", "?"),
					entry.get("score", 0),
					entry.get("time_played", 0)
			)

	%PageLabel.text = "Page %d / %d" % [_current_page, _total_pages]
	%PrevButton.disabled = _current_page <= 1
	%NextButton.disabled = _current_page >= _total_pages


func _clear_entries() -> void:
	for child in %EntriesContainer.get_children():
		child.queue_free()


func _add_row(rank: int, username: String, score: int, time_played: int) -> void:
	var hbox := HBoxContainer.new()

	# Highlight top 3
	var row_color := Color.WHITE
	if rank == 1:
		row_color = Color(1.0, 0.84, 0.0, 1.0)   # gold
	elif rank == 2:
		row_color = Color(0.75, 0.75, 0.75, 1.0)  # silver
	elif rank == 3:
		row_color = Color(0.8, 0.5, 0.2, 1.0)     # bronze

	var rank_lbl  := _make_label("#%d" % rank, 70.0, row_color, HORIZONTAL_ALIGNMENT_LEFT)
	var name_lbl  := _make_label(username, 0.0, row_color, HORIZONTAL_ALIGNMENT_LEFT, true)
	var score_lbl := _make_label(str(score), 80.0, row_color, HORIZONTAL_ALIGNMENT_RIGHT)
	var time_lbl  := _make_label(_format_time(time_played), 90.0, row_color, HORIZONTAL_ALIGNMENT_RIGHT)

	hbox.add_child(rank_lbl)
	hbox.add_child(name_lbl)
	hbox.add_child(score_lbl)
	hbox.add_child(time_lbl)

	%EntriesContainer.add_child(hbox)


func _make_label(text: String, min_width: float, color: Color,
		alignment: HorizontalAlignment, expand: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = alignment
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_override("font", _font_thin)
	lbl.add_theme_font_size_override("font_size", 18)
	if min_width > 0:
		lbl.custom_minimum_size = Vector2(min_width, 0.0)
	if expand:
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


## Format seconds as m:ss (e.g. 312 → "5:12")
func _format_time(seconds: int) -> String:
	var m := seconds / 60
	var s := seconds % 60
	return "%d:%02d" % [m, s]


# --- Pagination buttons ---

func _on_prev_pressed() -> void:
	if _current_page > 1:
		_load_page(_current_page - 1)

func _on_next_pressed() -> void:
	if _current_page < _total_pages:
		_load_page(_current_page + 1)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/start_menu.tscn")
