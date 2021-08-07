tool
extends Button

export var button_text: String setget set_button_text
func set_button_text(val):
	button_text = val
	if is_inside_tree() or Engine.editor_hint:
		$HBoxContainer/Label.text = button_text
		call_deferred("_on_resize")
	
export var action: String setget set_action
func set_action(val):
	action = val
	if is_inside_tree() or Engine.editor_hint:
		$HBoxContainer/PromptInputAction.input_action = action
		call_deferred("_on_resize")

func _ready():
	set_button_text(button_text)
	set_action(action)
	connect("resized", self, "_on_resize")


func _on_resize():
	rect_min_size = $HBoxContainer.get_minimum_size() + Vector2(10, 0)
	rect_size = rect_min_size
