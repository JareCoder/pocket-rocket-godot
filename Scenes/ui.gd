extends CanvasLayer

static var image = load("res://Assets/PNG/UI/playerLife1_blue.png")
var seconds_elapsed := 0

func set_health(amount):
	for child in $HpMargin/HpBoxContainer.get_children():
		child.queue_free()
		
	for i in amount:
		var text_rect = TextureRect.new()
		text_rect.texture = image
		$HpMargin/HpBoxContainer.add_child(text_rect)
		text_rect.stretch_mode = TextureRect.STRETCH_KEEP


func _on_score_timer_timeout() -> void:
	seconds_elapsed += 1
	$ScoreMargin/Label.text = str(seconds_elapsed)
	Global.score = seconds_elapsed
