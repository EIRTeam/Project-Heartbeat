extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

func set_value(value):
	$OptionButton.select(value)


func emit_value_changed_signal():
	print($OptionButton.selected)
	emit_signal("value_changed", $OptionButton.selected)

func _on_OptionButton_item_selected(id):
	emit_value_changed_signal()
