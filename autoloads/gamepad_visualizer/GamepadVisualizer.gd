extends Control

@onready var item_controls = get_node("VBoxContainer/HBoxContainer")

const ANALOG_GAMEPAD_VISUALIZER = preload("res://autoloads/gamepad_visualizer/AnalogGamepadVisualizer.tscn")
const ANALOG_SLIDER_VISUALIZER = preload("res://autoloads/gamepad_visualizer/AnalogSliderVisualizer.tscn")
const BUTTON_VISUALIZER = preload("res://autoloads/gamepad_visualizer/GamepadButtonVisualizer.tscn")
func _ready():
	UserSettings.connect("controller_swapped", Callable(self, "create_controller_map"))
	for device in Input.get_connected_joypads():
		if Input.get_joy_guid(device) == UserSettings.controller_guid:
			create_controller_map(device)
func get_slider_axis(axis, device):
	var visualizer = ANALOG_SLIDER_VISUALIZER.instantiate()
	visualizer.axis = axis
	return visualizer
func create_controller_map(joypad):
	#for i in range(JOY_BUTTON_MAX):
	for i in item_controls.get_children():
		i.queue_free()
	for i in range(0, 4, 2):
		var visualizer = ANALOG_GAMEPAD_VISUALIZER.instantiate()
		visualizer.axis_x = i
		visualizer.axis_y = i + 1
		visualizer.device = joypad
		item_controls.add_child(visualizer)
	
	var vbox_container = VBoxContainer.new()
	
	vbox_container.alignment = VBoxContainer.ALIGNMENT_CENTER
	
	var slider1 = get_slider_axis(JOY_AXIS_TRIGGER_LEFT, joypad)
	vbox_container.add_child(slider1)
	
	var slider2 = get_slider_axis(JOY_AXIS_TRIGGER_RIGHT, joypad)
	vbox_container.add_child(slider2)
	
	item_controls.add_child(vbox_container)
	
	var button_control = VBoxContainer.new()
	
	button_control.custom_minimum_size = Vector2(200, 0)
	
	var button_row_up = HBoxContainer.new()
	var button_row_down = HBoxContainer.new()
	
	button_control.add_child(button_row_up)
	button_control.add_child(button_row_down)
	
	button_row_down.size_flags_vertical = SIZE_EXPAND_FILL
	button_row_up.size_flags_vertical = SIZE_EXPAND_FILL
	
	item_controls.add_child(button_control)
	
	for i in range(min(JOY_BUTTON_MAX, 30)):
		var bv = BUTTON_VISUALIZER.instantiate()
		bv.device = joypad
		bv.button = i
		
		if i % 2 == 0:
			button_row_up.add_child(bv)
		else:
			button_row_down.add_child(bv)
