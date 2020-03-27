extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var x_spinbox = get_node("XSpinbox")
onready var y_spinbox = get_node("YSpinbox")

func sync_value(value):
	x_spinbox.disconnect("changed", self, "emit_value_changed_signal")
	y_spinbox.disconnect("changed", self, "emit_value_changed_signal")
	x_spinbox.value = value.x
	x_spinbox.value = value.y
	x_spinbox.connect("changed", self, "emit_value_changed_signal")
	y_spinbox.connect("changed", self, "emit_value_changed_signal")
func _ready():
	x_spinbox.connect("changed", self, "emit_value_changed_signal")
	y_spinbox.connect("changed", self, "emit_value_changed_signal")
func emit_value_changed_signal():
	emit_signal("value_changed", Vector2(x_spinbox.value, y_spinbox.value))
	emit_signal("value_change_committed")
func _on_XSpinbox_value_changed(value):
	emit_value_changed_signal()

func _on_YSpinbox_value_changed(value):
	emit_value_changed_signal()
