@tool
extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

@onready var spinbox = get_node("Spinbox")
@onready var angle_edit = get_node("AngleEdit")

func sync_value(input_array: Array):
	var min_angle = INF
	var max_angle = -INF
	for input in input_array:
		input.set(property_name, fmod(fmod(input.get(property_name), 360.0) + 360, 360.0))
		min_angle = min(min_angle, input.get(property_name))
		max_angle = max(max_angle, input.get(property_name))
	
	angle_edit.start_angle = min_angle
	angle_edit.end_angle = max_angle if max_angle != angle_edit.start_angle else min_angle
	spinbox.inputs = input_array

func _ready():
	spinbox.property_name = property_name
	spinbox.connect("values_changed", Callable(self, "_on_Spinbox_values_changed"))

func _on_angle_changed(value):
	value = fmod(fmod(value, 360.0) + 360, 360.0)
	spinbox.execute(String(value))
	emit_signal("values_changed", spinbox.get_values())

func _on_Spinbox_values_changed():
	var values = spinbox.get_values()
	
	var max_angle = values[0]
	for i in values.size():
		values[i] = fmod(fmod(values[i], 360.0) + 360, 360.0)
		max_angle = max(max_angle, values[i])
	
	angle_edit.start_angle = values[0]
	angle_edit.end_angle = max_angle if max_angle != values[0] else null
	angle_edit.update()
	
	emit_signal("values_changed", values)
	emit_signal("value_change_committed")
	spinbox.release_focus()

func _on_AngleEdit_angle_finished_changing():
	emit_signal("value_change_committed")
