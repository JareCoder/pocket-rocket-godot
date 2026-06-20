extends CanvasLayer

# ── Balance constants — edit these to tune gameplay ───────────────────────────
## Points awarded every TICK_INTERVAL seconds (must match ScoreTimer.wait_time in ui.tscn).
const POINTS_PER_TICK: int = 50
# ─────────────────────────────────────────────────────────────────────────────

static var hpTexture = load("res://Assets/PNG/UI/playerLife1_blue.png")
static var shieldTexture = load("res://Assets/PNG/Power-ups/shield_gold.png")

var _total_score: int = 0
var _popup_tween: Tween = null

func _ready() -> void:
	GameMusic.song_started.connect(_on_song_started)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	await get_tree().process_frame
	_on_viewport_size_changed()

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

## Called by the ScoreTimer every POINTS_PER_TICK seconds.
func _on_score_timer_timeout() -> void:
	_total_score += POINTS_PER_TICK
	$ScoreMargin/Label.text = str(_total_score)
	Global.score = _total_score

## Called via get_tree().call_group('ui', 'add_score', amount)
## when a points item is popped. Updates the HUD and Global.score immediately.
func add_score(amount: int) -> void:
	_total_score += amount
	$ScoreMargin/Label.text = str(_total_score)
	Global.score = _total_score

func _on_viewport_size_changed() -> void:
	var size = get_viewport().get_visible_rect().size
	var scale_factor = 1.3 if (size.x < 1200 or size.y < 700) else 1.0
	
	if has_node("ScoreMargin"):
		$ScoreMargin.scale = Vector2(scale_factor, scale_factor)
		$ScoreMargin.pivot_offset = Vector2($ScoreMargin.size.x / 2.0, 0.0)
		
	if has_node("BuffersMargin"):
		$BuffersMargin.scale = Vector2(scale_factor, scale_factor)
		$BuffersMargin.pivot_offset = Vector2(0.0, $BuffersMargin.size.y)
		
	if has_node("MusicPopup"):
		$MusicPopup.scale = Vector2(scale_factor, scale_factor)
		$MusicPopup.pivot_offset = $MusicPopup.size
