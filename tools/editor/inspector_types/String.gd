extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var line_edit = get_node("LineEdit")

func sync_value(value):
	print("SYNC TO ", value)
	line_edit.set_block_signals(true)
	line_edit.text = value
	line_edit.set_block_signals(false)

func _ready():
	line_edit.connect("text_entered", self, "_on_lineedit_value_changed")

func emit_value_changed_signal():
	emit_signal("value_changed", line_edit.text)
	emit_signal("value_change_committed")

func _on_lineedit_value_changed(value):
	emit_value_changed_signal()

func set_params(params):
	pass
