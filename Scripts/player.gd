extends CharacterBody2D

@export var speed: int = 500
var onCooldown: bool

signal laser(pos)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(100, 100)
	onCooldown = false


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
