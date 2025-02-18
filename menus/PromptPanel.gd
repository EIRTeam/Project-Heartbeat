@tool
extends PanelContainer

@export var action_name: String: set = set_action_name
@export var text: String: set = set_text

func set_action_name(val):
	action_name = val
	if not is_inside_tree():
		return
	$HBoxContainer/InputGlyphRect.action_name = val

func set_text(val):
	text = val
	if not is_inside_tree():
		return
	$HBoxContainer/InputGlyphRect.action_text = atr(val)

func _ready():
	set_action_name(action_name)
	set_text(text)
	
