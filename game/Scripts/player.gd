extends CharacterBody2D

# ── Balance constants — edit these to tune gameplay ───────────────────────────
## Base movement speed (also editable per-instance via the Inspector).
@export var speed: int = 500
## How much speed is added per ship_speed upgrade level.
const SPEED_PER_LEVEL: int = 50
## Cooldown multiplier applied per fire_rate upgrade level (stacks multiplicatively).
## 0.9 = 10% faster per level. Lower = bigger improvement per level.
const FIRE_RATE_MULTIPLIER: float = 0.90
# ─────────────────────────────────────────────────────────────────────────────

var onCooldown: bool

signal laser(pos)

func _ready() -> void:
	onCooldown = false
	speed = speed + Upgrades.get_level("ship_speed") * SPEED_PER_LEVEL
	var fire_level := Upgrades.get_level("fire_rate")
	if fire_level > 0:
		$ShootCooldownTimer.wait_time *= pow(FIRE_RATE_MULTIPLIER, fire_level)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var dir = Input.get_vector("left", "right", "up", "down")
	velocity = dir * speed
	move_and_slide()
	
	if Input.is_action_pressed("shoot") && onCooldown == false:
		laser.emit($LaserStartPos.global_position)
		$LaserSound.play()
		onCooldown = true
		$ShootCooldownTimer.start()

func play_collision_sound():
	$DamageSound.play()

func _on_shoot_cooldown_timer_timeout() -> void:
	onCooldown = false
