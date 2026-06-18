extends CanvasLayer

static var hpTexture = load("res://Assets/PNG/UI/playerLife1_blue.png")
static var shieldTexture = load("res://Assets/PNG/Power-ups/shield_gold.png")
var seconds_elapsed := 0

func set_health(amount):
	for child in $BuffersMargin/VBuffersContainer/HpContainer.get_children():
		child.queue_free()
		
	for i in amount:
		var text_rect = TextureRect.new()
		text_rect.texture = hpTexture
		$BuffersMargin/VBuffersContainer/HpContainer.add_child(text_rect)
		text_rect.stretch_mode = TextureRect.STRETCH_KEEP

func set_shield(amount):
	for child in $BuffersMargin/VBuffersContainer/ShieldContainer.get_children():
		child.queue_free()
		
	for i in amount:
		var text_rect = TextureRect.new()
		text_rect.texture = shieldTexture
		$BuffersMargin/VBuffersContainer/ShieldContainer.add_child(text_rect)
		text_rect.stretch_mode = TextureRect.STRETCH_KEEP

func _on_score_timer_timeout() -> void:
	seconds_elapsed += 1
	$ScoreMargin/Label.text = str(seconds_elapsed)
	Global.score = seconds_elapsed
