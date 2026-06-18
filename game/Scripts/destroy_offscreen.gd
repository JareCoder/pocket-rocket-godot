extends Node

@export var lifetime: float = 5.0 

func _ready():
	get_tree().create_timer(lifetime).timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	var parent = get_parent()
	if parent:
		parent.queue_free()
