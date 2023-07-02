extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

@onready var checkbox = get_node("CheckBox")

var inputs: Array

func sync_value(input_array: Array):
	checkbox.disconnect("toggled", Callable(self, "_on_checkbox_toggled"))
	inputs = input_array
	
	var sum = 0.0
	for input in input_array:
		sum += 1 if input.get(property_name) else 0
	checkbox.button_pressed = (sum / input_array.size()) > 0.5
	
	checkbox.connect("toggled", Callable(self, "_on_checkbox_toggled"))

func _ready():
	checkbox.connect("toggled", Callable(self, "_on_checkbox_toggled"))

func _on_checkbox_toggled(value):
	var values = {}
	for i in inputs.size():
		values[i] = value
	
	emit_signal("values_changed", values)
	emit_signal("value_change_committed")
