extends "Option.gd"
signal changed(value)

var text = "" setget set_text
signal pressed

onready var selected_text = get_node("HBoxContainer/Control/Label2")
onready var controller_select_dropdown = get_node("CanvasLayer/DropDown")
onready var controller_select_list = get_node("CanvasLayer/DropDown/MarginContainer/Control")
onready var controller_item_container = get_node("CanvasLayer/DropDown/MarginContainer/Control/VBoxContainer")
func set_text(val):
	text = val
	$HBoxContainer/Label.text = val

func _ready():
	controller_select_dropdown.hide()
	connect("pressed", self, "_on_pressed")
	show_current()
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	
func _gui_input(event: InputEvent):
	pass
	
func show_current():
	selected_text.text = "None Connected"
	if UserSettings.user_settings.controller_guid:
		for controller_idx in Input.get_connected_joypads():
			if Input.get_joy_guid(controller_idx) == UserSettings.user_settings.controller_guid:
				selected_text.text = Input.get_joy_name(controller_idx)
				break
var _old_focus
	
func show_list():
	if Input.get_connected_joypads().size() == 0:
		return
	for child in controller_item_container.get_children():
		controller_item_container.remove_child(child)
		child.queue_free()
	var button_to_select = 0
	for controller in Input.get_connected_joypads():
		var button = HBHovereableButton.new()
		button.text = Input.get_joy_name(controller)
		button.connect("pressed", self, "_on_controller_button_pressed", [controller])
		controller_item_container.add_child(button)
		if Input.get_joy_guid(controller) == UserSettings.user_settings.controller_guid:
			button_to_select = button.get_position_in_parent()
	controller_select_dropdown.show()
	controller_select_list.grab_focus()
	controller_select_list.select_item(button_to_select)
func _on_pressed():
	_old_focus = get_focus_owner()
	show_list()
	
func _on_controller_button_pressed(device: int):
	UserSettings.user_settings.controller_guid = Input.get_joy_guid(device)
	show_current()
	close_dropdown()
	UserSettings.map_actions_to_controller()
	UserSettings.save_user_settings()
func close_dropdown():
	_old_focus.grab_focus()
	controller_select_dropdown.hide()
func _on_joy_connection_changed(device, connected):
	show_current()
	if controller_select_dropdown.visible:
		show_list()
