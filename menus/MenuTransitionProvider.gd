extends Spatial

signal change_to_menu(menu_name)

var MENUS = {} # should be HBMenu

func change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	if not menu_name in MENUS:
		printerr("Error loading menu %s, menu not found" % menu_name)
		return
	emit_signal("change_to_menu", menu_name, force_hard_transition, args)
