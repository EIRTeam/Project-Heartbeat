tool
extends "res://tools/editor/inspector_types/EditorInspectorType.gd"


func set_value(value):
	if $Spinbox.is_connected("value_changed", self, "_on_Spinbox_value_changed"):
#		$Spinbox.disconnect("value_changed", self, "_on_Spinbox_value_changed")
		$Spinbox.value = value
		$AngleEdit.angle = value
#		$Spinbox.connect("value_changed", self, "_on_Spinbox_value_changed")

func emit_value_changed_signal():
	emit_signal("value_changed", $AngleEdit.angle)

func _on_angle_changed(angle):
	$Spinbox.value = angle
	emit_value_changed_signal()


func _on_Spinbox_value_changed(value):
	$AngleEdit.angle = value


func _on_AngleEdit_angle_finished_changing():
	emit_signal("value_committed")
