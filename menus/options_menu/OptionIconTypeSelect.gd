extends "Option.gd"
signal changed(value)

var text = "" setget set_text
signal pressed

onready var pack_select_dropdown = get_node("CanvasLayer/DropDown")

func set_text(val):
	text = val
	$HBoxContainer/Label.text = val

func _ready():
	pack_select_dropdown.hide()
	connect("pressed", self, "_on_pressed")
	$HBoxContainer/Control/IconPackPreview.icon_pack = UserSettings.user_settings.icon_pack
	pack_select_dropdown.connect("selected_pack_changed", self, "_on_selected_pack_changed")
func _gui_input(event: InputEvent):
	pass
	
var _old_focus
	
func _on_pressed():
	_old_focus = get_focus_owner()
	pack_select_dropdown.show()
	pack_select_dropdown.grab_focus()
func _on_selected_pack_changed(new_pack):
	IconPackLoader.set_current_pack(new_pack)
	emit_signal("changed", new_pack)
	$HBoxContainer/Control/IconPackPreview.icon_pack = new_pack
	_old_focus.grab_focus()
	pack_select_dropdown.hide()
