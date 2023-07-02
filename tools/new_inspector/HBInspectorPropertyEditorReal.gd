extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorReal

@onready var spinbox := SpinBox.new()

func _init_inspector():
	super._init_inspector()
	await self.ready
	spinbox.size_flags_horizontal = SIZE_EXPAND_FILL
	spinbox.min_value = -100000000
	spinbox.max_value = 100000000
	vbox_container.add_child(spinbox)
	spinbox.connect("value_changed", Callable(self, "_on_value_changed"))

func set_property_data(data: Dictionary):
	super.set_property_data(data)
	if data.type == TYPE_FLOAT:
		spinbox.step = 0.001
	else:
		spinbox.step = 1
	if data.get("hint", 0) == PROPERTY_HINT_RANGE:
		var hint_s := data.get("hint_string", "") as String
		var hint_vals := hint_s.split(",")
		spinbox.set_block_signals(true)
		match hint_vals.size():
			2:
				spinbox.min_value = hint_vals[0].to_float()
				spinbox.max_value = hint_vals[1].to_float()
			3:
				spinbox.min_value = hint_vals[0].to_float()
				spinbox.max_value = hint_vals[1].to_float()
				spinbox.step = hint_vals[2].to_float()
			4, 5:
				if "or_lesser" in hint_vals:
					spinbox.allow_lesser = true
				if "or_greater" in hint_vals:
					spinbox.allow_greater = true

		spinbox.set_block_signals(false)
func _on_value_changed(value: float):
	emit_signal("value_changed", value)

func set_value(val):
	super.set_value(val)
	if is_inside_tree():
		spinbox.set_block_signals(true)
		spinbox.value = val
		spinbox.set_block_signals(false)
