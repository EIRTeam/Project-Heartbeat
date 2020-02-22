extends Panel

const ICON_TYPE_SELECT_BUTTON = preload("res://menus/options_menu/IconTypeSelectButton.tscn")

signal selected_pack_changed(pack)
onready var pack_container = get_node("Control/VBoxContainer")
onready var scroll_container = get_node("Control")
func _ready():
	for pack in IconPackLoader.packs:
		var icon_select_button = ICON_TYPE_SELECT_BUTTON.instance()
		pack_container.add_child(icon_select_button)
		icon_select_button.icon_pack = pack
		icon_select_button.connect("pressed", self, "_on_pack_selected", [pack])

	connect("focus_entered", self, "_on_focus_grabbed")
func _on_focus_grabbed():
	scroll_container.grab_focus()
	for button in pack_container.get_children():
		if button.icon_pack == UserSettings.user_settings.icon_pack:
			scroll_container.select_child(button, true)
func _on_pack_selected(pack_name):
	emit_signal("selected_pack_changed", pack_name)


func _on_Control_back():
	_on_pack_selected(UserSettings.user_settings.icon_pack)
