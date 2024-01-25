@uid("uid://btjtkniphugcg") # Generated automatically, do not modify.
extends Panel

var normal_style
var hover_style
var action
var event : set = set_event
signal hovered
signal pressed
@onready var icon_panel = get_node("HBoxContainer/HBoxContainer/Panel")
@onready var glyph_rect: InputGlyphRect = get_node("%InputGlyphRect")
@onready var info_label: Label = get_node("%InfoLabel")
func set_event(val):
	event = val
	if is_inside_tree():
		glyph_rect.hide()
		if event is InputEventJoypadMotion or event is InputEventJoypadButton:
			var origin := InputGlyphsSingleton.get_origin_from_joy_event(event)
			glyph_rect.forced_joy_origin = origin
			info_label.text = ""
			glyph_rect.show()
			if event is InputEventJoypadMotion:
				if UserSettings.user_settings.use_direct_joystick_access:
					if event.axis <= JOY_AXIS_RIGHT_Y and action in ["heart_note", "slide_left", "slide_right"]:
						info_label.text += tr(" (Disabled due to Input -> Use direct joystick access)")
		elif event is InputEventKey:
			info_label.text = InputGlyphsSingleton.get_event_display_string(event)
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
