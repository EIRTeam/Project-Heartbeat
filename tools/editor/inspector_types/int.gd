extends "res://tools/editor/inspector_types/EditorInspectorType.gd"
var ignore_next_value_change = false
func set_value(value):
	ignore_next_value_change = true
	$Spinbox.value = value


func emit_value_changed_signal():

	emit_signal("value_changed", int($Spinbox.value))
	emit_signal("value_committed")

func _on_Spinbox_value_changed(value):
	if ignore_next_value_change:
		ignore_next_value_change = false
		return
	emit_value_changed_signal()
