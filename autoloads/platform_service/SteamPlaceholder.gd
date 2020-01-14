extends Node

func _init():
	if Engine.has_singleton("Steam"):
		free()
