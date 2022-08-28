extends EditorTimelineItem

class_name EditorTimelineItemNote

func _init():
	_class_name = "EditorTimelineItemNote" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItem")
	
	data = HBNoteData.new()

func get_inspector_properties():
	return
