extends EditorTimelineItem

class_name EditorSectionTimelineItem

onready var label = get_node("Label")

func _init():
	_class_name = "EditorSectionTimelineItem" # Workaround for godot#4708
	_inheritance.append("EditorTimelineItem")
	
	data = HBChartSection.new()

func _ready():
	._ready()
	
	label.connect("resized", self, "_on_label_resized")
	label.text = data.name


func get_editor_size():
	return Vector2(rect_size.x, rect_size.y)

func get_editor_description():
	return """Marks a section of the chart with a specific name and color."""


func sync_value(property_name: String):
	.sync_value(property_name)
	if property_name == "color" or property_name == "time":
		editor.timeline.update()
		editor.timeline.minimap.update()
	if property_name == "name":
		label.text = data.name


func _on_label_resized():
	rect_size.x = label.rect_size.x
