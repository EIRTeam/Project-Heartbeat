extends Control
var editor
class_name HBEditorWidget

# Emitted by child classes
# warning-ignore:unused_signal
signal property_changed(property_name, old_value, new_value)

func _ready():
	pass

func _widget_area_input(event: InputEvent):
	pass
