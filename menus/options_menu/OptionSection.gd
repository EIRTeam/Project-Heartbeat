extends Control

@onready var section_data = {}: set = _set_section_data

const OptionBool = preload("res://menus/options_menu/OptionBool.tscn")
const OptionRange = preload("res://menus/options_menu/OptionRange.tscn")
const OptionSelect = preload("res://menus/options_menu/OptionSelect.tscn")
const OptionSoundSelect = preload("res://menus/options_menu/OptionCustomSoundSelect.tscn")
const OptionControllerSelect = preload("res://menus/options_menu/OptionControllerSelect.tscn")
signal back
signal changed(property_name, new_value)
signal value_changed

@onready var options_container = get_node("VBoxContainer/Panel2/MarginContainer/container/ScrollContainer/VBoxContainer")
@onready var scroll_container = get_node("VBoxContainer/Panel2/MarginContainer/container/ScrollContainer")
@onready var section_label = get_node("VBoxContainer/Panel2/MarginContainer/container/SectionInfoLabel")
var settings_source
var postfix = ""

var section_text := "": set = set_section_text

func set_section_text(val):
	if val:
		section_text = val
		section_label.show()
		section_label.text = section_text
	else:
		section_label.hide()

func _ready():
	connect("focus_entered", Callable(self, "_on_focus_entered"))
	connect("focus_exited", Callable(self, "_on_focus_exited"))
	focus_mode = Control.FOCUS_ALL
	set_process_input(false)
	section_label.hide()

func _set_section_data(val):
	section_data = val
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()
	for option_name in section_data:
		var option = section_data[option_name]
		if option_name == "__section_label":
			continue
				
		var option_scene
		if option.has('type'):
			match option.type:
				"sound_type_selector":
					option_scene = OptionSoundSelect.instantiate()
					option_scene.sound_name = option.sound_name
				"controller_selector":
					option_scene = OptionControllerSelect.instantiate()
				"options":
					option_scene = OptionSelect.instantiate()
					option_scene.options = option.options
					option_scene.options_pretty = option.options_pretty
					option_scene.value = option.default_value
		else:
			match typeof(option.default_value):
				TYPE_BOOL:
					option_scene = OptionBool.instantiate()
				TYPE_FLOAT, TYPE_INT:
					option_scene = OptionRange.instantiate()
					if option.has("maximum"):
						option_scene.maximum = option.maximum
					if option.has("minimum"):
						option_scene.minimum = option.minimum
					if option.has("step"):
						option_scene.step = option.step
					if option.has("debounce_step"):
						option_scene.debounce_step = option.debounce_step
					if option.has("postfix"):
						option_scene.postfix = option.postfix
					if option.has("postfix_callback"):
						option_scene.postfix_callback = option.postfix_callback
					if option.has("text_overrides"):
						option_scene.text_overrides = option.text_overrides
					if option.has("percentage"):
						option_scene.percentage = option.percentage
					if option.has("disabled_callback"):
						option_scene.disabled_callback = option.disabled_callback
		if option_scene:
			var sett_src = settings_source
			if "value_source" in option:
				sett_src = option.value_source
			options_container.add_child(option_scene)
			option_scene.value = sett_src.get(option_name)
			option_scene.text = section_data[option_name].name
			if not "signal_method" in section_data[option_name]:
				option_scene.connect("changed", Callable(self, "_on_value_changed").bind(option_name))
			else:
				var binds = []
				if "signal_binds" in section_data[option_name]:
					binds = section_data[option_name].signal_binds
				option_scene.connect("changed", Callable(section_data[option_name].signal_object, section_data[option_name].signal_method).bind(binds))
			option_scene.connect("hovered", Callable(self, "_on_option_hovered").bind(option_name))
			if option_scene.has_signal("back"):
				option_scene.connect("back", Callable(self, "_on_option_back"))
			connect("value_changed", Callable(option_scene, "update_disabled"))
			option_scene.update_disabled()
		if section_data.size() > 0:
			# We force a hover on the first section data to make sure the description
			# text is completely filled
			var first_key_i := 0
			for key_i in range(section_data.keys().size()):
				if not section_data.keys()[key_i].begins_with("__"):
					first_key_i = key_i
					break
			_on_option_hovered(section_data.keys()[first_key_i])
			scroll_container.select_item(0)

var input_disabled = false
var last_selected_item
func toggle_input():
	input_disabled = not input_disabled
	if input_disabled:
		if scroll_container.get_selected_item():
			last_selected_item = scroll_container.get_selected_item()
	else:
		if last_selected_item:
			last_selected_item.hover()
			grab_focus()

func _unhandled_input(event):
	if visible and not input_disabled:
		if event.is_action_pressed("gui_cancel"):
			if get_viewport().gui_get_focus_owner() == scroll_container:
				HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
				get_viewport().set_input_as_handled()
				emit_signal("back")
				if scroll_container.get_selected_item():
					scroll_container.get_selected_item().stop_hover()
		else:
			if scroll_container.get_selected_item() and scroll_container.has_focus():
				if scroll_container.get_selected_item().has_method("_gui_input"):
					scroll_container.get_selected_item()._gui_input(event)


func _on_value_changed(value, property_name):
	emit_signal("changed", property_name, value)
	emit_signal("value_changed")
	
func _on_option_hovered(option_name):
	if section_data[option_name].has("description"):
		$VBoxContainer/Panel/MarginContainer/HBoxContainer/DescriptionLabel.text = section_data[option_name].description

func _on_focus_entered():
	scroll_container.grab_focus()
	set_process_input(true)
func _on_focus_exited():
	set_process_input(false)

func _on_option_back():
	scroll_container.grab_focus()
