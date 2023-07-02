extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorEnum

@onready var option_button := OptionButton.new()

func _init_inspector():
	super._init_inspector()
	await self.ready
	vbox_container.add_child(option_button)
	option_button.connect("item_selected", Callable(self, "_on_item_selected"))

func set_property_data(data: Dictionary):
	super.set_property_data(data)
	option_button.clear()
	assert(data.get("hint", 0) == PROPERTY_HINT_ENUM)
	var enum_hints := (data.get("hint_string", "") as String).split(",")
	option_button.set_block_signals(true)
	for i in range(enum_hints.size()):
		option_button.add_item(enum_hints[i], i)
	if value:
		option_button.select(value)
	option_button.set_block_signals(false)
	

func _on_item_selected(val: int):
	value = val
	emit_signal("value_changed", val)

func set_value(val):
	super.set_value(val)
	if is_inside_tree():
		option_button.set_block_signals(true)
		option_button.select(val)
		option_button.set_block_signals(false)
