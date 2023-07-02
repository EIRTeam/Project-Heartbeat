extends Panel

var normal_style
var hover_style
var action
var event : set = set_event
signal hovered
signal pressed
@onready var icon_panel = get_node("HBoxContainer/HBoxContainer/Panel")
@onready var button_icon := get_node("HBoxContainer/TextureRect")
func set_event(val):
	event = val
	if is_inside_tree():
		button_icon.hide()
		if event is InputEventJoypadMotion:
			$HBoxContainer/Label.text = UserSettings.get_axis_name(event)
			var button_tex = JoypadSupport.get_joy_axis_prompt_for(str(event.axis))
			if button_tex:
				button_icon.texture = button_tex
				button_icon.show()
			if UserSettings.should_use_direct_joystick_access():
				if event.axis <= JOY_AXIS_RIGHT_Y and action in ["heart_note", "slide_left", "slide_right"]:
					$HBoxContainer/Label.text += tr(" (Disabled due to Input -> Use direct joystick access)")
		elif event is InputEventJoypadButton:
			var button_tex = JoypadSupport.get_joypad_button_prompt_for(str(event.button_index))
			if button_tex:
				button_icon.texture = button_tex
				button_icon.show()
				$HBoxContainer/Label.hide()
			$HBoxContainer/Label.text = UserSettings.get_button_name(event)
		elif event is InputEventKey:
			var button_tex = JoypadSupport.get_keyboard_prompt_for(str(event.keycode))
			if button_tex:
				button_icon.texture = button_tex
				button_icon.show()
				$HBoxContainer/Label.hide()
			$HBoxContainer/Label.text = OS.get_keycode_string(event.keycode)
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
func _ready():
	stop_hover()
	set_event(event)
func hover():
	icon_panel.add_theme_stylebox_override("panel", hover_style)
	emit_signal("hovered")

func stop_hover():
	add_theme_stylebox_override("panel", normal_style)
	icon_panel.add_theme_stylebox_override("panel", normal_style)

func _gui_input(_i_event):
	if _i_event.is_action_pressed("gui_accept"):
		get_viewport().set_input_as_handled()
		emit_signal("pressed")
