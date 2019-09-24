extends "res://editor/inspector_types/EditorInspectorType.gd"

func _ready():
	pass

func set_value(value):
	$OptionButton.clear()
	for item in 


func emit_value_changed_signal():
	emit_signal("value_changed", $Spinbox.value)


func _on_Spinbox_value_changed(value):
	emit_value_changed_signal()
