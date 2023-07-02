extends VBoxContainer

@onready var toggle_tool_button = get_node("HBoxContainer/ToggleToolButton")
@onready var tool_name_label = get_node("HBoxContainer/ToolName")

const DOWN_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_down.svg")
const RIGHT_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_right.svg")
var tool_control 

func set_tool(child, tool_name: String):
	tool_control = child
	$HBoxContainer/ToolName.text = tool_name
	add_child(child)
	child.hide()

func _on_ToggleToolButton_pressed():
	if tool_control:
		if tool_control.visible:
			tool_control.hide()
			toggle_tool_button.icon = RIGHT_ICON
		else:
			tool_control.show()
			toggle_tool_button.icon = DOWN_ICON
