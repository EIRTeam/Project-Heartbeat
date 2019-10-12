extends "res://editor/inspector_types/EditorInspectorType.gd"

func set_value(value):
	$Spinbox.value = value


func emit_value_changed_signal():
	emit_signal("value_changed", float($Spinbox.value))


func _on_Spinbox_value_changed(value):
	emit_value_changed_signal()
