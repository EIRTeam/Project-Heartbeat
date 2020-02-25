extends HBMenu

onready var start_menu = get_node("VBoxContainer/StartMenu")

func _ready():
	start_menu.connect("navigate_to_menu", self, "change_to_menu")
	
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	start_menu.grab_focus()
