extends Button

signal action_down(act_name)
signal action_up(act_name)

@export (String) var action

func _ready():
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))

func _on_button_down():
	emit_signal("action_down", action)
func _on_button_up():
	emit_signal("action_up", action)
