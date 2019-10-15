extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

func set_value(value):
	$XSpinbox.value = value.x
	$YSpinbox.value = value.y


func emit_value_changed_signal():
	emit_signal("value_changed", Vector2($XSpinbox.value, $YSpinbox.value))

func _on_XSpinbox_value_changed(value):
	emit_value_changed_signal()

func _on_YSpinbox_value_changed(value):
	emit_value_changed_signal()
