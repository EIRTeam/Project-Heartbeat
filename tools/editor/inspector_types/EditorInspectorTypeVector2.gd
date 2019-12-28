extends "res://tools/editor/inspector_types/EditorInspectorType.gd"
var ignore_next_value_change = false
func set_value(value):
	ignore_next_value_change = true
	$XSpinbox.value = value.x
	$YSpinbox.value = value.y


func emit_value_changed_signal():
	emit_signal("value_changed", Vector2($XSpinbox.value, $YSpinbox.value))

func _on_XSpinbox_value_changed(value):
	if not ignore_next_value_change:
		emit_value_changed_signal()
	else:
		ignore_next_value_change = false

func _on_YSpinbox_value_changed(value):
	if not ignore_next_value_change:
		emit_value_changed_signal()
	else:
		ignore_next_value_change = false
