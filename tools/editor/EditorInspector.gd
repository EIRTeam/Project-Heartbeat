extends Control

const INSPECTOR_TYPES = {
	"int": preload("res://tools/editor/inspector_types/int.tscn"),
	"Vector2": preload("res://tools/editor/inspector_types/Vector2.tscn"),
	"float": preload("res://tools/editor/inspector_types/float.tscn"),
	"Angle": preload("res://tools/editor/inspector_types/angle.tscn"),
	"bool": preload("res://tools/editor/inspector_types/bool.tscn"),
	"String": preload("res://tools/editor/inspector_types/String.tscn"),
	"Color": preload("res://tools/editor/inspector_types/Color.tscn"),
}

onready var title_label = get_node("MarginContainer/ScrollContainer/VBoxContainer/TitleLabel")
onready var property_container = get_node("MarginContainer/ScrollContainer/VBoxContainer/PropertyContainer")
onready var copy_icon = get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/CopyIcon")
onready var paste_icon = get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/PasteIcon")
onready var description_label = get_node("MarginContainer/ScrollContainer/VBoxContainer/DescriptionLabel")

var inspecting_item: EditorTimelineItem
var inspecting_properties = {}


signal property_changed(property, value)
signal property_change_committed(property)
signal note_pasted(note_data)

var copied_note: HBBaseNote

func get_inspector_type(type: String):
	return INSPECTOR_TYPES[type]

func _ready():
	copy_icon.connect("pressed", self, "_on_copy_pressed")
	paste_icon.connect("pressed", self, "_on_paste_pressed")
	copy_icon.disabled = true
	paste_icon.disabled = true
func _on_copy_pressed():
	copied_note = inspecting_item.data.clone()
	paste_icon.disabled = false

func _on_paste_pressed():
	emit_signal("note_pasted", copied_note)

func update_label():
	title_label.text = "Note at %s" % HBUtils.format_time(inspecting_item.data.time, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS | HBUtils.TimeFormat.FORMAT_MILISECONDS)
	var item_description = inspecting_item.get_editor_description()
	description_label.text = ""
	if item_description != "":
		description_label.text += "%s" % [item_description]
func stop_inspecting():
	if inspecting_item and is_instance_valid(inspecting_item):
		inspecting_item.disconnect("property_changed", self, "update_value")
	inspecting_item = null
	for child in property_container.get_children():
		property_container.remove_child(child)
		child.queue_free()
	inspecting_properties = {}
	copy_icon.disabled = true
	paste_icon.disabled = true
	

func sync_visible_values_with_data():
	for property_name in inspecting_properties:
		sync_value(property_name)
# Syncs a single value
func sync_value(property_name: String):
	if property_name in inspecting_item.data:
		inspecting_properties[property_name].sync_value(inspecting_item.data.get(property_name))
	update_label()
func inspect(item: EditorTimelineItem):
	if item.data is HBBaseNote:
		paste_icon.disabled = false
		
	if not copied_note:
		paste_icon.disabled = true
		 
	if item.data is HBBaseNote:
		copy_icon.disabled = false
	else:
		copy_icon.disabled = true
		paste_icon.disabled = true
	if item == inspecting_item:
		return
	inspecting_properties = {}
	inspecting_item = item
	
	update_label()
	
	for child in property_container.get_children():
		child.free()
	var properties = item.data.get_inspector_properties()
	item.connect("property_changed", self, "update_value")
	
	for property in properties:
		var inspector_editor = get_inspector_type(properties[property].type).instance()
		if properties[property].has("params"):
			inspector_editor.call_deferred("set_params", properties[property].params)
		inspector_editor.property_name = property
		
		var label = Label.new()
		label.text = property.capitalize()
		property_container.add_child(label)
		inspector_editor.connect("value_changed", self, "_on_property_value_changed_by_user", [property])
		inspector_editor.connect("value_change_committed", self, "_on_property_value_commited_by_user", [property])
		property_container.add_child(inspector_editor)
		inspecting_properties[property] = inspector_editor
	sync_visible_values_with_data()

func _on_property_value_changed_by_user(value, property_name):
	emit_signal("property_changed", property_name, value)
func _on_property_value_commited_by_user(property_name):
	emit_signal("property_change_committed", property_name)
