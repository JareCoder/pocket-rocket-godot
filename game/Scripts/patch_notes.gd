extends Control

var start_menu_scene: PackedScene = load("res://Scenes/start_menu.tscn")

@onready var content_vbox: VBoxContainer = $CenterContainer/VBox/ScrollContainer/ContentVBox

# Keep references to the generated panels and buttons to toggle them
var _panels: Array[PanelContainer] = []
var _buttons: Array[Button] = []
var _patch_data: Array = []

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	
	_load_patch_notes()

func _load_patch_notes() -> void:
	if not FileAccess.file_exists("res://patch_notes.json"):
		printerr("Patch notes file not found!")
		return
		
	var file = FileAccess.open("res://patch_notes.json", FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(json_string)
	if not parsed is Array:
		printerr("Invalid patch notes format!")
		return
		
	_patch_data = parsed
	_build_ui()

func _build_ui() -> void:
	# Clean up any existing children first (just in case)
	for child in content_vbox.get_children():
		child.queue_free()
		
	_panels.clear()
	_buttons.clear()
	
	var main_theme = load("res://Assets/Themes/MainTheme.tres")
	var thin_font = load("res://Assets/Fonts/kenvector_future_thin.ttf")
	
	# Create StyleBox for panels
	var style_box = StyleBoxFlat.new()
	style_box.content_margin_left = 12.0
	style_box.content_margin_top = 10.0
	style_box.content_margin_right = 12.0
	style_box.content_margin_bottom = 10.0
	style_box.bg_color = Color(0.07, 0.06, 0.1, 0.5)
	style_box.border_width_left = 1
	style_box.border_width_top = 1
	style_box.border_width_right = 1
	style_box.border_width_bottom = 1
	style_box.border_color = Color(0.3, 0.5, 0.8, 0.3)
	style_box.corner_radius_top_left = 6
	style_box.corner_radius_top_right = 6
	style_box.corner_radius_bottom_right = 6
	style_box.corner_radius_bottom_left = 6
	
	for i in range(_patch_data.size()):
		var patch = _patch_data[i]
		var version: String = patch.get("version", "v0.0.0")
		var title: String = patch.get("title", "")
		var date: String = patch.get("date", "")
		var notes: Array = patch.get("notes", [])
		
		# Create toggle button
		var btn = Button.new()
		btn.theme = main_theme
		btn.add_theme_font_override("font", thin_font)
		btn.add_theme_font_size_override("font_size", 18)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		content_vbox.add_child(btn)
		_buttons.append(btn)
		
		# Create panel container for notes list
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", style_box)
		content_vbox.add_child(panel)
		_panels.append(panel)
		
		# Create inner vbox container
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 6)
		panel.add_child(vbox)
		
		# Create RichTextLabels for notes
		for note in notes:
			var lbl = RichTextLabel.new()
			lbl.add_theme_font_override("normal_font", thin_font)
			lbl.add_theme_font_size_override("normal_font_size", 15)
			lbl.bbcode_enabled = true
			lbl.fit_content = true
			lbl.scroll_active = false
			lbl.text = str(note)
			vbox.add_child(lbl)
			lbl.meta_clicked.connect(_on_link_clicked)
			
		# Connect button pressed signal
		btn.pressed.connect(_on_button_pressed.bind(i))
		
		# Add a separator between versions
		if i < _patch_data.size() - 1:
			var sep = HSeparator.new()
			content_vbox.add_child(sep)
			
		# Default state: first patch is open, others closed
		var is_open = (i == 0)
		panel.visible = is_open
		_update_button_text(btn, title, version, date, is_open)

func _update_button_text(button: Button, title: String, version: String, date: String, is_open: bool) -> void:
	var arrow := "v" if is_open else ">"
	button.text = arrow + "  " + version + " — " + title + " (" + date + ")"

func _on_button_pressed(index: int) -> void:
	var panel = _panels[index]
	var btn = _buttons[index]
	var patch = _patch_data[index]
	
	var now_open = not panel.visible
	panel.visible = now_open
	
	_update_button_text(btn, patch.get("title", ""), patch.get("version", ""), patch.get("date", ""), now_open)

func _on_link_clicked(meta: Variant) -> void:
	OS.shell_open(str(meta))

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_packed(start_menu_scene)

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	if has_node("CenterContainer/VBox"):
		$CenterContainer/VBox.custom_minimum_size.x = min(680.0, size.x - 30.0)
