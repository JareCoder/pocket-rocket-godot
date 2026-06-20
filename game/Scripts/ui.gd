extends CanvasLayer

static var hpTexture = load("res://Assets/PNG/UI/playerLife1_blue.png")
static var shieldTexture = load("res://Assets/PNG/Power-ups/shield_gold.png")
var seconds_elapsed := 0
var _popup_tween: Tween = null

func _ready() -> void:
	GameMusic.song_started.connect(_on_song_started)

func _on_song_started(title: String) -> void:
	if _popup_tween:
		_popup_tween.kill()
		
	%SongTitleLabel.text = title
	$MusicPopup.visible = true
	$MusicPopup.modulate.a = 0.0
	
	_popup_tween = create_tween()
	_popup_tween.tween_property($MusicPopup, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_interval(3.0)
	_popup_tween.tween_property($MusicPopup, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_popup_tween.tween_callback(func(): $MusicPopup.visible = false)

func set_health(amount):
	for child in %HpContainer.get_children():
		child.queue_free()
		
	for i in amount:
		var text_rect = TextureRect.new()
		text_rect.texture = hpTexture
		%HpContainer.add_child(text_rect)
		text_rect.stretch_mode = TextureRect.STRETCH_KEEP

func set_shield(amount):
	%ShieldPanel.visible = amount > 0
	
	for child in %ShieldContainer.get_children():
		child.queue_free()
		
	for i in amount:
		var text_rect = TextureRect.new()
		text_rect.texture = shieldTexture
		%ShieldContainer.add_child(text_rect)
		text_rect.stretch_mode = TextureRect.STRETCH_KEEP

func _on_score_timer_timeout() -> void:
	seconds_elapsed += 1
	$ScoreMargin/Label.text = str(seconds_elapsed)
	Global.score = seconds_elapsed
