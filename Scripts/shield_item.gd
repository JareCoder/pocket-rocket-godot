extends Area2D

signal shield_collision

func _on_body_entered(body: Node2D) -> void:
	print("Shield hit by ", body.name)
	shield_collision.emit()
	queue_free()
