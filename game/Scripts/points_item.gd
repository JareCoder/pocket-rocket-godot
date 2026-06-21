extends Area2D

## points_item.gd
##
## A "quick time event" collectible that drifts across the screen.
## Shoot it MAX_HP times before it exits the screen to earn bonus points.
## Laser is consumed on each hit (one laser = one hit).

signal popped(points: int)

# ── Balance constants — edit these to tune gameplay ───────────────────────────
## Pixels per second. Lower = more time for the player to react.
const MOVE_SPEED: float  = 80.0
## Visual and collision radius in pixels.
const RADIUS: float      = 18.0
## Number of laser hits required to pop the ball.
const MAX_HP: int        = 4
## Point value range. A random multiple-of-10 in this range is chosen on spawn.
const MIN_POINTS: int    = 50
const MAX_POINTS: int    = 200
# ─────────────────────────────────────────────────────────────────────────────

## Neon color palette — one entry is picked randomly on spawn.
const COLORS: Array[Color] = [
	Color(0.0,  1.0,  0.9),   # cyan
	Color(1.0,  0.3,  0.9),   # magenta
	Color(1.0,  0.85, 0.0),   # gold
	Color(0.4,  1.0,  0.3),   # lime
	Color(1.0,  0.5,  0.1),   # orange
]

var _color:     Color
var _direction: Vector2
var _hp:        int = MAX_HP
var _points:    int
var _rng := RandomNumberGenerator.new()
var _is_flashing: bool = false

func _ready() -> void:
	_rng.randomize()
	_color  = COLORS[_rng.randi_range(0, COLORS.size() - 1)]
	# Multiples of 10, in the MIN–MAX range
	_points = _rng.randi_range(MIN_POINTS / 10, MAX_POINTS / 10) * 10
	# Travel direction: always more sideways than vertical (abs(x) > abs(y))
	# Always take the longest route sideways off screen (opposite of spawn side)
	var center_x := get_viewport_rect().size.x / 2.0
	var angle: float
	if position.x > center_x:
		# Spawned on the right half -> move left
		angle = _rng.randf_range(3.0 * PI / 4.0, 5.0 * PI / 4.0)
	else:
		# Spawned on the left half -> move right
		angle = _rng.randf_range(-PI / 4.0, PI / 4.0)
	_direction = Vector2(cos(angle), sin(angle))

	%PointsLabel.text = str(_points)
	queue_redraw()

	# Pop-in tween
	scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	position += _direction * MOVE_SPEED * delta
	# QTE: self-destruct when fully offscreen — no bouncing
	var vp := get_viewport_rect()
	var margin := RADIUS * 3.0
	if (position.x < -margin or position.x > vp.size.x + margin
			or position.y < -margin or position.y > vp.size.y + margin):
		queue_free()

func _draw() -> void:
	var draw_color := Color.WHITE if _is_flashing else _color
	# Outer glow layers
	draw_circle(Vector2.ZERO, RADIUS + 7.0, Color(draw_color.r, draw_color.g, draw_color.b, 0.18))
	draw_circle(Vector2.ZERO, RADIUS + 3.5, Color(draw_color.r, draw_color.g, draw_color.b, 0.35))
	# Main ball
	draw_circle(Vector2.ZERO, RADIUS, draw_color)
	# Specular highlight
	draw_circle(
		Vector2(-RADIUS * 0.28, -RADIUS * 0.28),
		RADIUS * 0.28,
		Color(1.0, 1.0, 1.0, 0.45)
	)

func _on_area_entered(area: Area2D) -> void:
	# Only respond to lasers (collision layer 4 = bitmask 8)
	if not (area.collision_layer & 8):
		return
	area.queue_free()   # consume the laser
	_take_hit()

func _take_hit() -> void:
	_hp -= 1
	if _hp <= 0:
		_pop()
		return
	# Trigger a white flash
	_is_flashing = true
	queue_redraw()
	
	# Settle back to normal color after a short delay
	var flash_timer := get_tree().create_timer(0.08)
	flash_timer.timeout.connect(func():
		_is_flashing = false
		queue_redraw()
	)
	
	# Settle to the transparency level for remaining HP (fading down to 0.25 alpha)
	var target_alpha := 1.0 - (float(MAX_HP - _hp) / float(MAX_HP)) * 0.75
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", target_alpha, 0.18)

func _pop() -> void:
	popped.emit(_points)
	set_process(false)   # stop moving
	set_monitoring(false)
	# Burst-and-fade tween
	var tween := create_tween()
	tween.tween_property(self, "scale",      Vector2(1.6, 1.6), 0.1).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0,               0.18)
	tween.tween_callback(queue_free)
