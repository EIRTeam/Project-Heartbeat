extends Control

const INSPECTOR_TYPES = {
	"int": preload("res://tools/editor/inspector_types/int.tscn"),
	"Vector2": preload("res://tools/editor/inspector_types/Vector2.tscn"),
	"float": preload("res://tools/editor/inspector_types/float.tscn"),
	"NoteTypeSelector": preload("res://tools/editor/inspector_types/NoteTypeSelector.tscn"),
	"Angle": preload("res://tools/editor/inspector_types/angle.tscn"),
	"bool": preload("res://tools/editor/inspector_types/bool.tscn")
}

onready var title_label = get_node("MarginContainer/ScrollContainer/VBoxContainer/TitleLabel")
onready var property_container = get_node("MarginContainer/ScrollContainer/VBoxContainer/PropertyContainer")
var inspecting_item: EditorTimelineItem
var inspecting_properties = {}

signal user_changed_property(property_name)
signal user_commited_property(property_name)

func get_inspector_type(type: String):
	return INSPECTOR_TYPES[type]

var ignore_next_value_update = false

func _on_property_value_changed_by_user(value, property_editor):
	emit_signal("user_changed_property", property_editor.property_name, value)

func _on_property_value_commited_by_user(property_editor):
	emit_signal("user_commited_property", property_editor.property_name)

func update_label():
		title_label.text = "Note at %s" % HBUtils.format_time(inspecting_item.data.time, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS | HBUtils.TimeFormat.FORMAT_MILISECONDS)

func stop_inspecting():
	inspecting_item = null
	for child in property_container.get_children():
		child.free()

func update_value(name, old_value, new_value):
	if ignore_next_value_update:
		ignore_next_value_update = false
		return
	update_label()
	for property_name in inspecting_item.get_inspector_properties():
		if property_name == name:
			var editor = inspecting_properties[property_name]
			ignore_next_value_update = true
			inspecting_properties[property_name].set_value(inspecting_item.data.get(property_name))
		
func update_values():
	for property_name in inspecting_item.get_inspector_properties():
		var editor = inspecting_properties[property_name]

		inspecting_properties[property_name].set_value(inspecting_item.data.get(property_name))

func inspect(item: EditorTimelineItem):
	print(item)
	if item == inspecting_item:
		return
	if inspecting_item:
		inspecting_item.disconnect("property_changed", self, "update_value")
	inspecting_properties = {}
	inspecting_item = item
	
	update_label()
	
	for child in property_container.get_children():
		child.free()
	var properties = item.get_inspector_properties()
	
	item.connect("property_changed", self, "update_value")
	
	for property in properties:
		var inspector_editor = get_inspector_type(properties[property]).instance()
		inspector_editor.property_name = property
		
		var label = Label.new()
		label.text = property.capitalize()
		property_container.add_child(label)
		inspector_editor.connect("value_changed", self, "_on_property_value_changed_by_user", [inspector_editor])
		inspector_editor.connect("value_committed", self, "_on_property_value_commited_by_user", [inspector_editor])
		property_container.add_child(inspector_editor)
		inspecting_properties[property] = inspector_editor
	update_values()
