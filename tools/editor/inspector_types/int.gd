extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

@onready var spinbox = get_node("Spinbox")
@onready var toggle_negative_button = get_node("ToggleNegativeButton")

func sync_value(input_array):
	spinbox.inputs = input_array

func _ready():
	spinbox.property_name = property_name
	spinbox.connect("values_changed", Callable(self, "_on_Spinbox_values_changed"))
	toggle_negative_button.hide()

func _on_Spinbox_values_changed():
	var values = spinbox.get_values()
	for input in values:
		values[input] = int(values[input])
	
	emit_signal("values_changed", values)
	emit_signal("value_change_committed")

func set_params(params):
	if params.has("min"):
		spinbox.min = params.min
	if params.has("max"):
		spinbox.max = params.max
	if params.has("suffix"):
		spinbox.suffix = params.suffix
	if params.has("show_toggle_negative_button"):
		toggle_negative_button.visible = params.show_toggle_negative_button

func _on_ToggleNegativeButton_pressed():
	spinbox.execute("-1 * note." + property_name)
