extends VBoxContainer

var tool_name setget set_tool_name

const DOWN_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_down.svg")
const RIGHT_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_right.svg")
onready var toggle_tool_button = get_node("HBoxContainer/ToggleToolButton")
var tool_control 

func set_tool_name(val):
	tool_name = val

func set_tool(child):
	tool_control = child
	add_child(child)



func _on_ToggleToolButton_pressed():
	if tool_control:
		if tool_control in get_children():
			remove_child(tool_control)
			toggle_tool_button.icon = RIGHT_ICON
		else:
			toggle_tool_button.icon = DOWN_ICON
			add_child(tool_control)
