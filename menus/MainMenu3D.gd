extends "res://menus/MainMenu.gd"

func _ready():
	fullscreen_menu_container = get_node("FullscreenMenuContainer")
	left_menu_container = get_node("ViewportLeft/MenuLeftContainer")
	right_menu_container = get_node("ViewportRight/MenuRightContainer")
	change_to_menu("start_menu")
func _on_change_to_menu(menu_name: String):
	._on_change_to_menu(menu_name)
	
