tool
extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var spinbox = get_node("Spinbox")
onready var angle_edit = get_node("AngleEdit")
func sync_value(value):
	spinbox.disconnect("value_changed", self, "_on_Spinbox_value_changed")
	spinbox.value = value
	spinbox.connect("value_changed", self, "_on_Spinbox_value_changed")
	angle_edit.angle = value
	
func _ready():
	spinbox.connect("value_changed", self, "_on_Spinbox_value_changed")

func emit_value_changed_signal():
	emit_signal("value_changed", angle_edit.angle)

func _on_angle_changed(angle):
	spinbox.value = angle
	emit_value_changed_signal()

func _on_Spinbox_value_changed(value):
	angle_edit.angle = value
	emit_value_changed_signal()

func _on_AngleEdit_angle_finished_changing():
	emit_signal("value_change_committed")
