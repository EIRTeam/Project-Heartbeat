extends Control

const INSPECTOR_TYPES = {
	"int": preload("res://tools/editor/inspector_types/int.tscn"),
	"Vector2": preload("res://tools/editor/inspector_types/Vector2.tscn"),
	"float": preload("res://tools/editor/inspector_types/float.tscn"),
	"Angle": preload("res://tools/editor/inspector_types/angle.tscn"),
	"bool": preload("res://tools/editor/inspector_types/bool.tscn"),
	"String": preload("res://tools/editor/inspector_types/String.tscn"),
	"Color": preload("res://tools/editor/inspector_types/Color.tscn"),
	"list": preload("res://tools/editor/inspector_types/list.tscn"),
	"time_signature": preload("res://tools/editor/inspector_types/time_signature.tscn"),
}

@onready var title_label = get_node("MarginContainer/ScrollContainer/VBoxContainer/TitleLabel")
@onready var property_container = get_node("MarginContainer/ScrollContainer/VBoxContainer/PropertyContainer")
@onready var copy_icon = get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/CopyIcon")
@onready var paste_icon = get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/PasteIcon")
@onready var description_label = get_node("MarginContainer/ScrollContainer/VBoxContainer/DescriptionLabel")

var inspecting_items: Array
var inspecting_properties = {}
var labels = {}
var condition_properties = {}
var conditional_properties = {}


signal properties_changed(property, values)
signal property_change_committed(property)
signal notes_pasted(notes)
signal reset_pos()

var copied_notes: Array

func get_inspector_type(type: String):
	return INSPECTOR_TYPES[type]

func _ready():
	copy_icon.connect("pressed", Callable(self, "_on_copy_pressed"))
	paste_icon.connect("pressed", Callable(self, "_on_paste_pressed"))
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
	var item_description = get_common_inspecting_class().get_ph_editor_description()
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
			item.disconnect("property_changed", Callable(self, "update_value"))
	inspecting_items = []
	
	for child in property_container.get_children():
		property_container.remove_child(child)
		child.queue_free()
	
	inspecting_properties.clear()
	labels.clear()
	condition_properties.clear()
	conditional_properties.clear()
	
	copy_icon.disabled = true
	paste_icon.disabled = true
	
	update_label()

func sync_visible_values_with_data():
	var inputs = []
	for item in inspecting_items:
		inputs.append(item.data.clone())
	
	for property_name in inspecting_properties:
		sync_value(property_name, inputs)

# Syncs a single property
func sync_value(property_name: String, inputs: Array):
	inspecting_properties[property_name].sync_value(inputs)
	
	if property_name in condition_properties:
		pass
	
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
	
	inspecting_properties.clear()
	labels.clear()
	condition_properties.clear()
	conditional_properties.clear()
	
	update_label()
	
	for child in property_container.get_children():
		child.free()
	
	for item in inspecting_items:
		if not item.is_connected("property_changed", Callable(self, "update_value")):
			item.connect("property_changed", Callable(self, "update_value"))
	
	var properties = common_data_class.get_inspector_properties()
	for property_name in properties.keys():
		var property = properties[property_name]
		var inspector_editor = get_inspector_type(property.type).instantiate()
		inspector_editor.property_name = property_name
		
		var name = property_name.capitalize()
		if property.has("params"):
			inspector_editor.call_deferred("set_params", property.params)
			
			if property.params.has("name"):
				name = property.params.name
			
			if property.params.has("affects_properties"):
				condition_properties[property_name] = property.params.affects_properties
				for conditional_property in property.params.affects_properties:
					conditional_properties[conditional_property] = properties[conditional_property].params.condition
		
		var label = Label.new()
		label.text = name
		property_container.add_child(label)
		labels[property_name] = label
		
		inspector_editor.connect("values_changed", Callable(self, "_on_property_value_changed_by_user").bind(property_name))
		inspector_editor.connect("value_change_committed", Callable(self, "_on_property_value_commited_by_user").bind(property_name))
		property_container.add_child(inspector_editor)
		inspecting_properties[property_name] = inspector_editor
		
		if property_name == "position":
			var reset_position_button = Button.new()
			reset_position_button.text = "Reset to default"
			reset_position_button.connect("pressed", Callable(self, "_on_reset_pos_pressed"))
			reset_position_button.size_flags_horizontal = reset_position_button.SIZE_EXPAND_FILL
			property_container.add_child(reset_position_button)
	
	check_conditional_properties()
	
	sync_visible_values_with_data()

func _on_property_value_changed_by_user(values, property_name):
	emit_signal("properties_changed", property_name, values)
	
	if property_name in condition_properties:
		check_conditional_properties()

func _on_property_value_commited_by_user(property_name):
	emit_signal("property_change_committed", property_name)

func _on_reset_pos_pressed():
	emit_signal("reset_pos")

func check_conditional_properties():
	var condition_differences := []
	var condition_equalities := []
	var property_values := []
	for property_name in condition_properties.keys():
		var first_value = inspecting_items[0].data.get(property_name)
		
		var found_diff := false
		for item in inspecting_items:
			if item.data.get(property_name) != first_value:
				condition_differences.append_array(condition_properties[property_name])
				found_diff = true
				break
		
		if not found_diff:
			condition_equalities.append(property_name)
			property_values.append(first_value)
	
	for property_name in conditional_properties.keys():
		var property = inspecting_properties[property_name]
		var label = labels[property_name]
		
		if property_name in condition_differences:
			property.visible = false
			label.visible = false
			continue
		
		var condition = conditional_properties[property_name]
		var expression := Expression.new()
		expression.parse(condition, condition_equalities)
		var result = expression.execute(property_values)
		
		property.visible = bool(result)
		label.visible = bool(result)
