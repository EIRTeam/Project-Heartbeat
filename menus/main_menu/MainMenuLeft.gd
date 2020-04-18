extends HBMenu

onready var start_menu = get_node("VBoxContainer/StartMenu")

func _ready():
	start_menu.connect("navigate_to_menu", self, "change_to_menu")
	if not PlatformService.service_provider.implements_lobby_list:
		get_tree().call_group("mponly", "queue_free")
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	start_menu.grab_focus()
