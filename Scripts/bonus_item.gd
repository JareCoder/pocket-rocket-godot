extends Area2D

signal collision

func _on_body_entered(body: Node2D) -> void:
	collision.emit()
	queue_free()
