extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

@onready var x_spinbox = get_node("%XSpinbox")
@onready var y_spinbox = get_node("%YSpinbox")

func sync_value(input_array: Array):
	x_spinbox.inputs = input_array
	y_spinbox.inputs = input_array

func _ready():
	x_spinbox.property_name = property_name
	y_spinbox.property_name = property_name
	x_spinbox.connect("values_changed", Callable(self, "emit_value_changed_signal"))
	y_spinbox.connect("values_changed", Callable(self, "emit_value_changed_signal"))

func emit_value_changed_signal():
	var values = {}
	var x_values = x_spinbox.get_values()
	var y_values = y_spinbox.get_values()
	for i in x_values.size():
		values[i] = Vector2(x_values[i], y_values[i])
	
	emit_signal("values_changed", values)
	emit_signal("value_change_committed")
