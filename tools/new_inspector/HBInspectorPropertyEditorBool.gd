extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorBool

onready var checkbox := CheckBox.new()

func _init_inspector():
	._init_inspector()
	yield(self, "ready")
	vbox_container.add_child(checkbox)
	checkbox.size_flags_horizontal = SIZE_EXPAND_FILL
	checkbox.text = "Enabled"
	checkbox.connect("toggled", self, "_on_checkbox_toggled")

func _on_checkbox_toggled(enabled: bool):
	value = enabled
	emit_signal("value_changed", value)

func set_value(val):
	.set_value(val)
	if is_inside_tree():
		checkbox.set_block_signals(true)
		checkbox.pressed = val
		checkbox.set_block_signals(false)
