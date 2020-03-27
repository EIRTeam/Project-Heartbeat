extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var x_spinbox = get_node("XSpinbox")
onready var y_spinbox = get_node("YSpinbox")

func sync_value(value):
	x_spinbox.disconnect("value_changed", self, "_on_XSpinbox_value_changed")
	y_spinbox.disconnect("value_changed", self, "_on_YSpinbox_value_changed")
	x_spinbox.value = value.x
	y_spinbox.value = value.y
	x_spinbox.connect("value_changed", self, "_on_XSpinbox_value_changed")
	y_spinbox.connect("value_changed", self, "_on_YSpinbox_value_changed")
func _ready():
	x_spinbox.connect("value_changed", self, "_on_XSpinbox_value_changed")
	y_spinbox.connect("value_changed", self, "_on_YSpinbox_value_changed")
func emit_value_changed_signal():
	emit_signal("value_changed", Vector2(x_spinbox.value, y_spinbox.value))
	emit_signal("value_change_committed")
func _on_XSpinbox_value_changed(value):
	emit_value_changed_signal()

func _on_YSpinbox_value_changed(value):
	emit_value_changed_signal()
