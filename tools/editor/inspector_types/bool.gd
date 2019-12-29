extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

func set_value(value):
	$CheckBox.pressed = value


func emit_value_changed_signal():
	emit_signal("value_changed", $CheckBox.pressed)
	emit_signal("value_committed")

func _on_Spinbox_toggled(button_pressed):
	emit_value_changed_signal()
