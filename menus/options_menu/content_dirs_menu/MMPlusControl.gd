extends "res://menus/options_menu/Option.gd"

var options = ["No", "Yes"]
var options_pretty = []
var selected_option = 0
var text : set = set_text

@onready var checkbox: CheckBox = get_node("VBoxContainer/HBoxContainer/Control/CheckBox")
@onready var label: Label = get_node("VBoxContainer/HBoxContainer/Label")
@onready var mm_error_label: RichTextLabel = get_node("VBoxContainer/VBoxContainer/RichTextLabel")

func set_value(val):
	super.set_value(val)
	select(val)
	
func select(val: bool):
	checkbox.set_block_signals(true)
	checkbox.button_pressed = val
	checkbox.set_block_signals(false)
	
func set_text(val):
	text = val
	if is_inside_tree() and text:
		label.text = val
func _ready():
	focus_mode = Control.FOCUS_ALL
	set_text(text)
	
func update_error():
	mm_error_label.clear()
	mm_error_label.push_underline()
	if HBGame.mmplus_error == HBGame.MMPLUS_ERROR.NEEDS_RESTART:
		mm_error_label.push_color(Color.LIGHT_CORAL)
		mm_error_label.append_text(tr("A restart is needed for changes to apply"))
		mm_error_label.pop()
		mm_error_label.newline()
		return
	elif not UserSettings.user_settings.enable_system_mmplus_loading:
		return
	elif HBGame.mmplus_error == HBGame.MMPLUS_ERROR.OK and not (HBGame.mmplus_loader and HBGame.mmplus_loader.has_fatal_error()):
		mm_error_label.push_color(Color.LIGHT_GREEN)
		mm_error_label.append_text(tr("MM+ loaded succesfully from:"))
		mm_error_label.newline()
		mm_error_label.append_text(HBGame.mmplus_loader.GAME_LOCATION)
		mm_error_label.pop()
	elif HBGame.mmplus_error != HBGame.MMPLUS_ERROR.OK:
		var mmplus_load_error := HBGame.get_system_mmplus_error() as String
		mm_error_label.push_color(Color.LIGHT_CORAL)
		mm_error_label.append_text(tr("There was an issue loading MM+: %s" % mmplus_load_error))
		mm_error_label.pop()
	mm_error_label.pop()
	mm_error_label.newline()
	if HBGame.mmplus_loader:
		if HBGame.mmplus_loader.has_fatal_error():
			mm_error_label.newline()
			mm_error_label.push_underline()
			mm_error_label.push_color(Color.LIGHT_CORAL)
			mm_error_label.append_text(tr("%d fatal errors were found:" % HBGame.mmplus_loader.fatal_error_messages.size()))
			mm_error_label.pop()
			mm_error_label.pop()
			mm_error_label.newline()
			for error in HBGame.mmplus_loader.fatal_error_messages:
				mm_error_label.append_text(error)
				mm_error_label.newline()
		if HBGame.mmplus_loader.has_error():
			mm_error_label.newline()
			mm_error_label.push_underline()
			mm_error_label.push_color(Color.LIGHT_GOLDENROD)
			mm_error_label.append_text(tr("%d non-fatal errors were found:" % HBGame.mmplus_loader.error_messages.size()))
			mm_error_label.pop()
			mm_error_label.pop()
			mm_error_label.newline()
			for error in HBGame.mmplus_loader.error_messages:
				mm_error_label.append_text(error)
				mm_error_label.newline()
	
func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		get_viewport().set_input_as_handled()
		set_value(!value)
		select(value)
		change_value(value)

func _on_CheckBox_toggled(button_pressed):
	set_value(button_pressed)
	change_value(button_pressed)
