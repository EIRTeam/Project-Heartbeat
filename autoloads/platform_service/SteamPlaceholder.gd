extends Node

func _init():
	if Engine.has_singleton("Steam"):
		queue_free()
	name = "SteamPlaceholder"
