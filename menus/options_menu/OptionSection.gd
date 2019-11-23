extends Control

var section_data = {}

const OptionBool = preload("res://menus/options_menu/OptionBool.tscn")
const OptionRange = preload("res://menus/options_menu/OptionRange.tscn")
signal back
signal changed(property_name, new_value)

onready var options_container = get_node("VBoxContainer/Panel2/MarginContainer/ScrollContainer/MarginContainer/VBoxContainer")
onready var scroll_container = get_node("VBoxContainer/Panel2/MarginContainer/ScrollContainer")
func _ready():
	focus_mode = Control.FOCUS_ALL
	for option_name in section_data:
		var option = section_data[option_name]
		print(option_name)
		var option_scene
		match typeof(option.default_value):
			TYPE_BOOL:
				option_scene = OptionBool.instance()
			TYPE_REAL, TYPE_INT:
				option_scene = OptionRange.instance()
				if option.has("maximum"):
					option_scene.maximum = option.maximum
				if option.has("minimum"):
					option_scene.minimum = option.minimum
				if option.has("step"):
					option_scene.step = option.step
		if option_scene:
			options_container.add_child(option_scene)
			option_scene.text = section_data[option_name].name
			option_scene.connect("changed", self, "_on_value_changed", [option_name])
			option_scene.connect("hover", self, "_on_option_hovered", [option_name])
			option_scene.value = section_data[option_name].default_value
		if section_data.size() > 0:
			# We force a hover on the first section data to make sure the description
			# text is completely filled
			_on_option_hovered(section_data.keys()[0])
func _unhandled_input(event):
	if visible:
		if event.is_action_pressed("ui_cancel"):
			emit_signal("back")
			get_tree().set_input_as_handled()
			if scroll_container.selected_child:
				scroll_container.selected_child.stop_hover()
		else:
			if scroll_container.selected_child:
				scroll_container.selected_child._gui_input(event)
				
func _on_value_changed(value, property_name):
	emit_signal("changed", property_name, value)
	
func _on_option_hovered(option_name):
	if section_data[option_name].has("description"):
		$VBoxContainer/Panel/MarginContainer/HBoxContainer/DescriptionLabel.text = section_data[option_name].description
