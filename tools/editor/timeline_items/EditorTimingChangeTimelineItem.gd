extends EditorTimelineItem

class_name EditorTimingChangeTimelineItem

onready var label = get_node("Label")

func _init():
	_class_name = "EditorTimingChangeTimelineItem" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItem")
	
	data = HBTimingChange.new()

func _ready():
	._ready()
	
	label.connect("resized", self, "_on_label_resized")
	label.text = "%.2f BPM; %d/%d" % [data.bpm, data.time_signature.numerator, data.time_signature.denominator]


func get_editor_size():
	return rect_size

func get_editor_description():
	return """Sets the tempo of the song."""


func sync_value(property_name: String):
	.sync_value(property_name)
	
	if property_name in ["bpm", "time_signature"]:
		label.text = "%.2f BPM; %d/%d" % [data.bpm, data.time_signature.numerator, data.time_signature.denominator]


func _on_label_resized():
	rect_size.x = label.rect_size.x
