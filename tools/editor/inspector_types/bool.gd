extends "res://tools/editor/inspector_types/EditorInspectorType.gd"
var ignore_next_value_change = false
func set_value(value):
	ignore_next_value_change = false
	$CheckBox.pressed = value


func emit_value_changed_signal():
	emit_signal("value_changed", $CheckBox.pressed)
	emit_signal("value_committed")

func _on_Spinbox_toggled(button_pressed):
	if ignore_next_value_change:
		ignore_next_value_change = false
		return
	emit_value_changed_signal()
