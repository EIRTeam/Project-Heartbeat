extends Button

@export var action := ""

@export var check_visibility := true

var og_hint: String = ""

var by_shortcut := false

func _ready():
	og_hint = tooltip_text
	update_shortcuts()

func _toggled(_pressed: bool):
	release_focus()

func _pressed():
	by_shortcut = false
	
	release_focus()

func _unhandled_input(event):
	var invisible = not is_visible_in_tree() and check_visibility
	if action == "" or invisible or disabled:
		return
	
	if event.is_action_pressed(action, false, true):
		by_shortcut = true
		
		if toggle_mode:
			set_pressed_no_signal(!pressed)
		else:
			emit_signal("pressed")
		
		get_viewport().set_input_as_handled()

func update_shortcuts():
	var action_list = InputMap.action_get_events(action)
	var event = action_list[0] if action_list else InputEventKey.new()
	
	var text = HBUtils.get_event_text(event)
	
	tooltip_text = og_hint + "\nShortcut: " + text
