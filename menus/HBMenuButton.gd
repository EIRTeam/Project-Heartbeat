tool
extends Button

class_name HBMenuButton

export (NodePath) var next_menu

func _ready():
	focus_mode = Control.FOCUS_NONE
	flat = false
	align = ALIGN_LEFT
