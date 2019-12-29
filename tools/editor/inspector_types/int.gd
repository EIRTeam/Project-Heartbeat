extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

func set_value(value):
	$Spinbox.value = value


func emit_value_changed_signal():
	emit_signal("value_changed", int($Spinbox.value))
	emit_signal("value_committed")

func _on_Spinbox_value_changed(value):
	emit_value_changed_signal()
