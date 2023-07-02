@tool
extends Panel

@export var action_name: String: set = set_action_name
@export var text: String: set = set_text

func set_action_name(val):
	action_name = val
	$HBoxContainer/PromptInputAction.input_action = val

func set_text(val):
	text = val
	$HBoxContainer/Label.text = val
	call_deferred("_on_resize")

func _ready():
	connect("resized", Callable(self, "_on_resize"))
	set_action_name(action_name)
	set_text(text)
	$HBoxContainer/Label.connect("minimum_size_changed", Callable(self, "_on_resize"))
	_on_resize()
	
func _on_resize():
	custom_minimum_size = $HBoxContainer.get_minimum_size() + Vector2(10, 0)
	size.x = 0
