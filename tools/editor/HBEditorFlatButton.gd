extends Button

# Small script to lose focus on toggle, since it looks ugly
# Also registers actions in exact mode

export(String) var action := ""

func _ready():
	connect("toggled", self, "_on_toggled")

func _on_toggled(_pressed: bool):
	release_focus()

func _unhandled_input(event):
	if action == "":
		return
	
	if event.is_action_pressed(action, false, true):
		pressed = !pressed
		get_tree().set_input_as_handled()
