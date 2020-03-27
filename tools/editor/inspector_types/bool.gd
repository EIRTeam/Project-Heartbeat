extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var checkbox = get_node("CheckBox")

func sync_value(value):
	checkbox.disconnect("toggled", self, "_on_checkbox_toggled")
	checkbox.pressed = value
	checkbox.connect("toggled", self, "_on_checkbox_toggled")

func _ready():
	checkbox.connect("toggled", self, "_on_checkbox_toggled")

func _on_checkbox_toggled(value):
	emit_signal("value_changed", value)
	emit_signal("value_change_committed")
