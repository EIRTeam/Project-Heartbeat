extends Panel

class_name HBOptionControlsSectionAction

var normal_style
var hover_style
var action : set = set_action
var action_name : set = set_action_name
signal hovered
signal pressed
@onready var icon_panel = get_node("HBoxContainer/HBoxContainer/Panel")
@onready var note_icon := get_node("HBoxContainer/TextureRect")

func set_action_name(val):
	action_name = val
	if is_inside_tree():
		if action_name.begins_with("note_") or action_name == "heart_note":
			note_icon.show()
			var note_text := ""
			if action_name == "heart_note":
				note_text = "heart"
			else:
				note_text = action_name.split("_")[1] as String
			note_icon.texture = ResourcePackLoader.get_graphic("%s_%s.png" % [note_text, "note"])
		elif action_name in ["slide_left", "slide_right"]:
			note_icon.show()
			note_icon.texture = ResourcePackLoader.get_graphic("%s_%s.png" % [action_name, "note"])
			
		else:
			note_icon.hide()
func set_action(val):
	$HBoxContainer/Label.text = val
	action = val

	
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")

func _ready():
	stop_hover()
	set_action(action)
	set_action_name(action_name)

func hover():
	icon_panel.add_theme_stylebox_override("panel", hover_style)
	emit_signal("hovered")

func stop_hover():
	icon_panel.add_theme_stylebox_override("panel", normal_style)

func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		get_viewport().set_input_as_handled()
		emit_signal("pressed")
