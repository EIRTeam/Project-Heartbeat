extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var spinbox = get_node("Spinbox")

func sync_value(value):
	spinbox.disconnect("value_changed", self, "_on_Spinbox_value_changed")
	spinbox.value = value
	spinbox.connect("value_changed", self, "_on_Spinbox_value_changed")

func _ready():
	spinbox.connect("value_changed", self, "_on_Spinbox_value_changed")

func emit_value_changed_signal():
	emit_signal("value_changed", int(spinbox.value))
	emit_signal("value_change_committed")

func _on_Spinbox_value_changed(value):
	emit_value_changed_signal()
