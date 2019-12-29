extends "res://tools/editor/inspector_types/EditorInspectorType.gd"
var ignore_next_value_change = 0
func set_value(value):
	ignore_next_value_change = 2
	$XSpinbox.value = value.x
	$YSpinbox.value = value.y


func emit_value_changed_signal():
	emit_signal("value_changed", Vector2($XSpinbox.value, $YSpinbox.value))
	emit_signal("value_committed")
func _on_XSpinbox_value_changed(value):
	if ignore_next_value_change > 0:
		ignore_next_value_change -= 1
	else:
		emit_value_changed_signal()

func _on_YSpinbox_value_changed(value):
	if ignore_next_value_change > 0:
		ignore_next_value_change -= 1
	else:
		emit_value_changed_signal()
