extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

@onready var numerator_spinbox = get_node("NumeratorSpinbox")
@onready var denominator_spinbox = get_node("DenominatorSpinbox")

func sync_value(input_array):
	numerator_spinbox.inputs = input_array
	denominator_spinbox.inputs = input_array
	
	queue_redraw()

func _ready():
	numerator_spinbox.property_name = property_name
	denominator_spinbox.property_name = property_name
	numerator_spinbox.connect("values_changed", Callable(self, "_on_Spinbox_values_changed"))
	denominator_spinbox.connect("values_changed", Callable(self, "_on_Spinbox_values_changed"))

func _on_Spinbox_values_changed():
	var values = {}
	var numerator_values = numerator_spinbox.get_values()
	var denominator_values = denominator_spinbox.get_values()
	for input in numerator_values:
		values[input] = {
			"numerator": int(numerator_values[input]),
			"denominator": int(denominator_values[input]),
		}
	
	emit_signal("values_changed", values)
	emit_signal("value_change_committed")
