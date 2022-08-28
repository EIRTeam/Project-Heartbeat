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

var inspecting_items: Array
var inspecting_properties = {}


signal properties_changed(property, values)
signal property_change_committed(property)
signal notes_pasted(notes)
signal reset_pos()

var copied_notes: Array

func get_inspector_type(type: String):
	return INSPECTOR_TYPES[type]

func _ready():
	copy_icon.connect("pressed", self, "_on_copy_pressed")
	paste_icon.connect("pressed", self, "_on_paste_pressed")
	copy_icon.disabled = true
	paste_icon.disabled = true

func get_common_inspecting_class():
	if not inspecting_items:
		return EditorTimelineItem.new()
	
	var common_class = inspecting_items[0]._class_name
	
	var i = 1
	var inheritance_size = inspecting_items[0]._inheritance.size()
	for item in inspecting_items:
		var _data_class = item._class_name
		
		while (not common_class in item._inheritance) and _data_class != common_class:
			common_class = inspecting_items[0]._inheritance[inheritance_size - i]
			i += 1
	
	var instance = load("res://tools/editor/timeline_items/%s.gd" % common_class).new()
	return instance

func get_common_data_class():
	if not inspecting_items:
		return HBTimingPoint.new()
	
	var common_data_class = inspecting_items[0].data._class_name
	
	var i = 1
	var inheritance_size = inspecting_items[0].data._inheritance.size()
	for item in inspecting_items:
		var _data_class = item.data._class_name
		
		while (not common_data_class in item.data._inheritance) and _data_class != common_data_class:
			common_data_class = inspecting_items[0].data._inheritance[inheritance_size - i]
			i += 1
	
	var path = "res://rythm_game/lyrics/%s.gd" if "Lyrics" in common_data_class else "res://scripts/timing_points/%s.gd"
	var instance = load(path % common_data_class).new()
	return instance

func get_property_range(property_name: String):
	if not inspecting_items:
		return []
	
	var _max = inspecting_items[0].data.get(property_name)
	var _min = inspecting_items[0].data.get(property_name)
	
	for item in inspecting_items:
		_max = max(_max, item.data.get(property_name))
		_min = min(_min, item.data.get(property_name))
	
	return [_min, _max]

func _on_copy_pressed():
	copied_notes.clear()
	for item in inspecting_items:
		copied_notes.append(item.data.clone())
	
	paste_icon.disabled = false

func _on_paste_pressed():
	emit_signal("notes_pasted", copied_notes)

func update_label():
	var item_description = get_common_inspecting_class().get_editor_description()
	description_label.text = ""
	if item_description != "":
		description_label.text += "%s" % [item_description]
		description_label.visible = true
	else:
		description_label.visible = false
	
	if inspecting_items.size() == 0:
		title_label.text = ""
	elif inspecting_items.size() == 1:
		var time = HBUtils.format_time(inspecting_items[0].data.time, HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS | HBUtils.TimeFormat.FORMAT_MILISECONDS)
		title_label.text = "Item at %s" % time
	else:
		var times = get_property_range("time")
		times[0] = HBUtils.format_time(times[0], HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS | HBUtils.TimeFormat.FORMAT_MILISECONDS)
		times[1] = HBUtils.format_time(times[1], HBUtils.TimeFormat.FORMAT_MINUTES | HBUtils.TimeFormat.FORMAT_SECONDS | HBUtils.TimeFormat.FORMAT_MILISECONDS)
		title_label.text = "Items from %s to %s" % times

func stop_inspecting():
	for item in inspecting_items:
		if item and is_instance_valid(item):
			item.disconnect("property_changed", self, "update_value")
	inspecting_items = []
	
	for child in property_container.get_children():
		property_container.remove_child(child)
		child.queue_free()
	
	inspecting_properties = {}
	copy_icon.disabled = true
	paste_icon.disabled = true
	
	update_label()

func sync_visible_values_with_data():
	for property_name in inspecting_properties:
		sync_value(property_name)

# Syncs a single property
func sync_value(property_name: String):
	var inputs = []
	for item in inspecting_items:
		inputs.append(item.data.clone())
	
	inspecting_properties[property_name].sync_value(inputs)
	
	update_label()

func inspect(items: Array):
	if inspecting_items == items:
		return
	else:
		inspecting_items = items.duplicate()
	
	var common_data_class = get_common_data_class()
	
	if common_data_class is HBBaseNote:
		copy_icon.disabled = false
		paste_icon.disabled = false
	else:
		copy_icon.disabled = true
		paste_icon.disabled = true
	
	if not copied_notes:
		paste_icon.disabled = true
	
	inspecting_properties = {}
	
	update_label()
	
	for child in property_container.get_children():
		child.free()
	
	for item in inspecting_items:
		item.connect("property_changed", self, "update_value")
	
	var properties = common_data_class.get_inspector_properties()
	for property in properties:
		var inspector_editor = get_inspector_type(properties[property].type).instance()
		if properties[property].has("params"):
			inspector_editor.call_deferred("set_params", properties[property].params)
		inspector_editor.property_name = property
		
		var label = Label.new()
		label.text = property.capitalize()
		property_container.add_child(label)
		inspector_editor.connect("values_changed", self, "_on_property_value_changed_by_user", [property])
		inspector_editor.connect("value_change_committed", self, "_on_property_value_commited_by_user", [property])
		property_container.add_child(inspector_editor)
		inspecting_properties[property] = inspector_editor
		
		if property == "position":
			var reset_position_button = Button.new()
			reset_position_button.text = "Reset to default"
			reset_position_button.connect("pressed", self, "_on_reset_pos_pressed")
			reset_position_button.size_flags_horizontal = reset_position_button.SIZE_EXPAND_FILL
			property_container.add_child(reset_position_button)
	
	sync_visible_values_with_data()

func _on_property_value_changed_by_user(values, property_name):
	emit_signal("properties_changed", property_name, values)

func _on_property_value_commited_by_user(property_name):
	emit_signal("property_change_committed", property_name)

func _on_reset_pos_pressed():
	emit_signal("reset_pos")
