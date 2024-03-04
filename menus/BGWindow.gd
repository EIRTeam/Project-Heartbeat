@tool
extends Window

class_name BGWindow

@onready var panel := Panel.new()

func _ready() -> void:
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel, false, Node.INTERNAL_MODE_FRONT)
	panel.theme_type_variation = "WindowBGPanel"
