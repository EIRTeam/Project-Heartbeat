tool
extends Panel

export(String) var action_name setget set_action_name
export(String) var text setget set_text

func set_action_name(val):
	action_name = val
	$HBoxContainer/PromptInputAction.input_action = val

func set_text(val):
	text = val
	$HBoxContainer/Label.text = val
	call_deferred("_on_resize")

func _ready():
	connect("resized", self, "_on_resize")
	set_action_name(action_name)
	set_text(text)
	$HBoxContainer/Label.connect("minimum_size_changed", self, "_on_resize")
	_on_resize()
	
func _on_resize():
	rect_min_size = $HBoxContainer.get_minimum_size() + Vector2(10, 0)
	rect_size.x = 0
