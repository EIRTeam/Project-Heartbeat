extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorBool

@onready var checkbox := CheckBox.new()

func _init_inspector():
	super._init_inspector()
	await self.ready
	vbox_container.add_child(checkbox)
	checkbox.size_flags_horizontal = SIZE_EXPAND_FILL
	checkbox.text = "Enabled"
	checkbox.connect("toggled", Callable(self, "_on_checkbox_toggled"))

func _on_checkbox_toggled(enabled: bool):
	value = enabled
	emit_signal("value_changed", value)

func set_value(val):
	super.set_value(val)
	if is_inside_tree():
		checkbox.set_block_signals(true)
		checkbox.button_pressed = val
		checkbox.set_block_signals(false)
