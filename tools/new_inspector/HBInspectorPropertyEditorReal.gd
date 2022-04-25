extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorReal

onready var spinbox := SpinBox.new()

func _init_inspector():
	._init_inspector()
	yield(self, "ready")
	spinbox.size_flags_horizontal = SIZE_EXPAND_FILL
	spinbox.min_value = -100000000
	spinbox.max_value = 100000000
	vbox_container.add_child(spinbox)
	spinbox.connect("value_changed", self, "_on_value_changed")

func set_property_data(data: Dictionary):
	.set_property_data(data)
	if data.type == TYPE_REAL:
		spinbox.step = 0.001
	else:
		spinbox.step = 1

func _on_value_changed(value: float):
	emit_signal("value_changed", value)

func set_value(val):
	.set_value(val)
	if is_inside_tree():
		spinbox.set_block_signals(true)
		spinbox.value = val
		spinbox.set_block_signals(false)
