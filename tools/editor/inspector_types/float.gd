extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var spin_box = get_node("Spinbox")

func sync_value(value):
	spin_box.disconnect("value_changed", self, "_on_Spinbox_value_changed")
	spin_box.value = value
	spin_box.connect("value_changed", self, "_on_Spinbox_value_changed")
func _ready():
	spin_box.connect("value_changed", self, "_on_Spinbox_value_changed")

func emit_value_changed_signal():
	emit_signal("value_changed", float(spin_box.value))
	emit_signal("value_change_committed")

func _on_Spinbox_value_changed(value):
	emit_value_changed_signal()
