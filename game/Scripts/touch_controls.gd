extends Control

# Custom mobile overlay with dynamic virtual joystick & fire button
# Built for Godot 4.6 - draws programmatically to match the game's premium neon aesthetic.

# Joystick properties
var joystick_base_radius := 80.0
var joystick_handle_radius := 35.0
var joystick_center := Vector2.ZERO
var joystick_handle_pos := Vector2.ZERO
var joystick_visible := false
var joystick_touch_id := -1

# Joystick styling
var joystick_base_color := Color(0.05, 0.1, 0.2, 0.3)
var joystick_border_color := Color(0.0, 0.75, 1.0, 0.8) # neon cyan
var joystick_handle_color := Color(0.0, 0.75, 1.0, 0.5)

# Fire button properties
var fire_button_center := Vector2(1012, 508) # bottom right relative to 1152x648
var fire_button_radius := 65.0
var fire_pressed := false
var fire_touch_id := -1

# Fire button styling
var fire_base_color := Color(0.2, 0.05, 0.05, 0.3)
var fire_border_color := Color(1.0, 0.2, 0.2, 0.8) # neon red
var fire_pressed_color := Color(1.0, 0.2, 0.2, 0.6)

func _ready() -> void:
	# Compute position relative to default viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	fire_button_center = Vector2(viewport_size.x - 140, viewport_size.y - 140)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var viewport_size = get_viewport().get_visible_rect().size
		if event.pressed:
			# Left side of screen triggers dynamic joystick
			if joystick_touch_id == -1 and event.position.x < (viewport_size.x / 2.0):
				joystick_touch_id = event.index
				joystick_center = event.position
				joystick_handle_pos = event.position
				joystick_visible = true
				queue_redraw()
			# Right side checks if hitting the fire button area
			elif fire_touch_id == -1 and event.position.distance_to(fire_button_center) < (fire_button_radius + 30.0):
				fire_touch_id = event.index
				fire_pressed = true
				Input.action_press("shoot")
				queue_redraw()
		else:
			# Touch released
			if event.index == joystick_touch_id:
				joystick_touch_id = -1
				joystick_visible = false
				_reset_joystick_inputs()
				queue_redraw()
			elif event.index == fire_touch_id:
				fire_touch_id = -1
				fire_pressed = false
				Input.action_release("shoot")
				queue_redraw()

	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_id:
			var drag_vector = event.position - joystick_center
			if drag_vector.length() > joystick_base_radius:
				drag_vector = drag_vector.normalized() * joystick_base_radius
			joystick_handle_pos = joystick_center + drag_vector
			
			# Map to input actions
			_update_joystick_inputs(drag_vector / joystick_base_radius)
			queue_redraw()

func _update_joystick_inputs(dir: Vector2) -> void:
	var threshold = 0.15
	
	# Horizontal actions
	if dir.x < -threshold:
		_simulate_action("left", true, -dir.x)
		_simulate_action("right", false, 0.0)
	elif dir.x > threshold:
		_simulate_action("right", true, dir.x)
		_simulate_action("left", false, 0.0)
	else:
		_simulate_action("left", false, 0.0)
		_simulate_action("right", false, 0.0)

	# Vertical actions
	if dir.y < -threshold:
		_simulate_action("up", true, -dir.y)
		_simulate_action("down", false, 0.0)
	elif dir.y > threshold:
		_simulate_action("down", true, dir.y)
		_simulate_action("up", false, 0.0)
	else:
		_simulate_action("up", false, 0.0)
		_simulate_action("down", false, 0.0)

func _simulate_action(action: String, pressed: bool, strength: float) -> void:
	if pressed:
		var ev = InputEventAction.new()
		ev.action = action
		ev.pressed = true
		ev.strength = strength
		Input.parse_input_event(ev)
	else:
		if Input.is_action_pressed(action):
			var ev = InputEventAction.new()
			ev.action = action
			ev.pressed = false
			Input.parse_input_event(ev)

func _reset_joystick_inputs() -> void:
	for action in ["left", "right", "up", "down"]:
		_simulate_action(action, false, 0.0)

func _draw() -> void:
	if joystick_visible:
		# Draw base ring
		draw_circle(joystick_center, joystick_base_radius, joystick_base_color)
		draw_arc(joystick_center, joystick_base_radius, 0, TAU, 32, joystick_border_color, 2.0, true)
		
		# Draw handle
		draw_circle(joystick_handle_pos, joystick_handle_radius, joystick_handle_color)
		draw_arc(joystick_handle_pos, joystick_handle_radius, 0, TAU, 24, joystick_border_color, 1.5, true)
		
	# Draw Fire Button
	var fire_color = fire_pressed_color if fire_pressed else fire_base_color
	draw_circle(fire_button_center, fire_button_radius, fire_color)
	draw_arc(fire_button_center, fire_button_radius, 0, TAU, 32, fire_border_color, 3.0, true)
	
	# Draw crosshair ornament in fire button for high-tech look
	draw_arc(fire_button_center, fire_button_radius * 0.4, 0, TAU, 24, fire_border_color, 1.5, true)
	draw_line(fire_button_center - Vector2(20, 0), fire_button_center + Vector2(20, 0), fire_border_color, 2.0)
	draw_line(fire_button_center - Vector2(0, 20), fire_button_center + Vector2(0, 20), fire_border_color, 2.0)
