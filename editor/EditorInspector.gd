extends Control

var editor

const INSPECTOR_TYPES = {
	"float": preload("res://editor/inspector_types/float.tscn"),
	"Vector2": preload("res://editor/inspector_types/Vector2.tscn"),
	"NoteTypeSelector": preload("res://editor/inspector_types/NoteTypeSelector.tscn")
}

var inspecting_item: EditorTimelineItem
var inspecting_properties = {}
func _ready():
	pass

func get_inspector_type(type: String):
	return INSPECTOR_TYPES[type]

func _on_property_value_changed(value, editor):
	inspecting_item.set(editor.property_name, value)

func update_label():
		$MarginContainer/VBoxContainer/TitleLabel.text = "Note at %s" % HBUtils.format_time(inspecting_item.start, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS | HBUtils.TimeFormat.FORMAT_MILISECONDS)

func update_values():
	update_label()	
	for property in inspecting_item.get_inspector_properties():
		inspecting_properties[property].set_value(inspecting_item.get(property))

func inspect(item: EditorTimelineItem):
	print(item)
	if item == inspecting_item:
		return
	if inspecting_item:
		inspecting_item.disconnect("item_bounds_changed", self, "_on_item_bounds_changed")
	inspecting_properties = {}
	inspecting_item = item
	
	update_label()
	
	for child in $MarginContainer/VBoxContainer/PropertyContainer.get_children():
		child.free()
	var properties = item.get_inspector_properties()
	
	item.connect("item_bounds_changed", self, "update_values")
	
	for property in properties:
		var inspector_editor = get_inspector_type(properties[property]).instance()
		inspector_editor.property_name = property
		
		var label = Label.new()
		label.text = property.capitalize()
		$MarginContainer/VBoxContainer/PropertyContainer.add_child(label)
		inspector_editor.connect("value_changed", self, "_on_property_value_changed", [inspector_editor])
		$MarginContainer/VBoxContainer/PropertyContainer.add_child(inspector_editor)
		inspecting_properties[property] = inspector_editor
	update_values()
