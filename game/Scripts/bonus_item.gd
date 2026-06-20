extends Area2D

signal collision

func _ready() -> void:
	$Sprite2D.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property($Sprite2D, "scale", Vector2(2.0, 2.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property($Sprite2D, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_body_entered(body: Node2D) -> void:
	collision.emit()
	queue_free()
