extends Button

export(String) var action := ""
var og_hint: String = ""

func _ready():
	og_hint = hint_tooltip
	update_shortcuts()

func _toggled(_pressed: bool):
	release_focus()

func _pressed():
	release_focus()

func _unhandled_input(event):
	if action == "" or not visible or disabled:
		return
	
	if event.is_action_pressed(action, false, true):
		if toggle_mode:
			pressed = !pressed
		else:
			emit_signal("pressed")
		
		get_tree().set_input_as_handled()

func update_shortcuts():
	var text = "None"
	
	var action_list = InputMap.get_action_list(action)
	var event = action_list[0] if action_list else InputEventKey.new()
	
	if event is InputEventKey:
		text = event.as_text() if not "Physical" in event.as_text() else "None"
		if "Kp " in text:
			text = text.replace("Kp ", "Keypad ")
	elif event is InputEventMouseButton:
		text = "Mouse %d" % event.button_index
	
	hint_tooltip = og_hint + "\nShortcut: " + text
