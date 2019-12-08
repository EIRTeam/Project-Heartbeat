extends HBMenu

func _ready():
	$StartMenu.connect("navigate_to_menu", self, "change_to_menu")
	
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	$StartMenu.grab_focus()
