extends Node3D

signal changed_to_menu(menu_name)

var MENUS = {} # should be HBMenu

var LOG_NAME = "MenuTransitionProvider"

func change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	if not menu_name in MENUS:
		Log.log(self, "Error loading menu %s, menu not found" % menu_name, Log.LogLevel.ERROR)
		return
	emit_signal("changed_to_menu", menu_name, force_hard_transition, args)
