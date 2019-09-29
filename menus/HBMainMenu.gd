extends Control

export (NodePath) var initial_menu_path

var current_menu

class_name HBMainMenu

func _ready():
	current_menu = get_node(initial_menu_path) as HBMenu
	current_menu.grab_focus()
	for child in get_children():
		var menu_item = child
		if not menu_item == current_menu:
			menu_item.hide()
			menu_item.mouse_filter = MOUSE_FILTER_IGNORE
