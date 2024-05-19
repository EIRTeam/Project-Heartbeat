extends ColorPickerButton

class_name HBEditorColorPickerButton

signal input_accepted
signal input_rejected

func _ready():
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	get_popup().popup_hide.connect(self._on_modal_closed)

func _on_modal_closed():
	if not Input.is_action_just_pressed("ui_accept"):
		input_rejected.emit()
	if Input.is_action_just_pressed("ui_accept"):
		emit_signal("input_accepted")
