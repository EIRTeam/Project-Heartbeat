extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

@onready var option_button = get_node("OptionButton")

var inputs: Array = []
var presets: Array = []
var changes_properties: bool = false

func sync_value(input_array: Array):
	inputs = input_array
	
	select_current()

func _ready():
	option_button.connect("item_selected", Callable(self, "_on_item_selected"))

func select_current():
	var last = inputs[0].get(property_name)
	for input in inputs:
		if input.get(property_name) != last:
			option_button.set_block_signals(true)
			option_button.select(-1)
			option_button.set_block_signals(false)
			
			return
	
	var selected = presets.find(last)
	
	option_button.set_block_signals(true)
	option_button.select(selected)
	option_button.set_block_signals(false)

func _on_item_selected(index: int):
	var values = {}
	for i in inputs.size():
		values[i] = presets[index]
	
	emit_signal("values_changed", values)
	emit_signal("value_change_committed")

func set_params(params: Dictionary):
	if params.has("values"):
		option_button.clear()
		presets.clear()
		
		for key in params.values.keys():
			option_button.add_item(key)
			presets.append(params.values[key])
		
		select_current()
