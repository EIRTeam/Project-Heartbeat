extends EditorTimelineItem

class_name EditorSectionTimelineItem

@onready var label = get_node("Label")

func _init():
	_class_name = "EditorSectionTimelineItem" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItem")
	
	data = HBChartSection.new()

func _ready():
	super._ready()
	
	label.connect("resized", Callable(self, "_on_label_resized"))
	label.text = data.name


func get_editor_size():
	return size

func get_ph_editor_description():
	return """Marks a section of the chart with a specific name and color."""


func sync_value(property_name: String):
	super.sync_value(property_name)
	if property_name == "color" or property_name == "time":
		editor.timeline.update()
		editor.timeline.minimap.update()
	if property_name == "name":
		label.text = data.name


func _on_label_resized():
	size.x = label.size.x
