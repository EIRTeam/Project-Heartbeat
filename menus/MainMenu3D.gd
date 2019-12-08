extends "res://menus/MainMenu.gd"
func _ready():
	fullscreen_menu_container = get_node("FullscreenMenuContainer")
	left_menu_container = get_node("ViewportLeft/MenuLeftContainer")
	right_menu_container = get_node("ViewportRight/MenuRightContainer")
	change_to_menu(starting_menu, false, starting_menu_args)
