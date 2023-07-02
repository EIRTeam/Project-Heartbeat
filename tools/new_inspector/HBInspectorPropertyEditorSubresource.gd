extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorSubresource

var resource_storage: HBInspectorResourceStorage

@onready var inspector = preload("res://tools/new_inspector/new_inspector.tscn").instantiate()

@onready var type_change_option_button := OptionButton.new()

func _init_inspector():
	super._init_inspector()
	await self.ready
	vbox_container.add_child(type_change_option_button)
	type_change_option_button.hide()
	vbox_container.add_child(inspector)
	inspector.resource_storage = resource_storage
	inspector.connect("value_changed", Callable(self, "_on_value_changed"))
	inspector.custom_minimum_size.y = 200
	inspector.name = "SubInspector"
	type_change_option_button.connect("item_selected", Callable(self, "_on_change_type_item_selected"))

func _on_value_changed(value):
	emit_signal("value_changed", value)

func _on_change_type_item_selected(selection: int):
	var target = type_change_option_button.get_item_metadata(selection)
	var new_value = target.new()
	set_value(new_value)
	emit_signal("value_changed", new_value)

func set_value(val):
	super.set_value(val)
	if is_inside_tree():
		# HACK...
		if val is StyleBox:
			type_change_option_button.set_block_signals(true)
			type_change_option_button.show()
			type_change_option_button.clear()
			type_change_option_button.add_item("Flat")
			type_change_option_button.add_item("Texture2D")
			type_change_option_button.set_item_metadata(0, HBUIStyleboxFlat)
			type_change_option_button.set_item_metadata(1, HBUIStyleboxTexture)
			if val is HBUIStyleboxFlat:
				type_change_option_button.select(0)
			else:
				type_change_option_button.select(1)
			type_change_option_button.set_block_signals(false)
		inspector.inspect(val)

func can_collapse() -> bool:
	return true
