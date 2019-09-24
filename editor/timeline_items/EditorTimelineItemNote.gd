extends "res://editor/timeline_items/EditorTimelineItem.gd"
var position = Vector2()
func _ready():
	pass

func get_inspector_properties():
	return {
		"start": "float",
		"position": "Vector2"
	}
