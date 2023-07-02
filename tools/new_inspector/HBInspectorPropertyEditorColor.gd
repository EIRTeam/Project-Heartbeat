extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorColor

@onready var color_button := ColorPickerButton.new()

func _init_inspector():
	super._init_inspector()
	await self.ready
	vbox_container.add_child(color_button)
	color_button.size_flags_horizontal = SIZE_EXPAND_FILL
	color_button.size_flags_vertical = SIZE_EXPAND_FILL
	color_button.connect("color_changed", Callable(self, "_on_color_changed"))

func set_property_data(data: Dictionary):
	super.set_property_data(data)
	

func _on_color_changed(col: Color):
	value = col
	emit_signal("value_changed", col)

func set_value(val):
	super.set_value(val)
	if is_inside_tree():
		color_button.set_block_signals(true)
		color_button.color = val
		color_button.set_block_signals(false)
