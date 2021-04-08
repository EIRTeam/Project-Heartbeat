extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var spinbox = get_node("Spinbox")
onready var toggle_negative_button = get_node("ToggleNegativeButton")
func sync_value(value):
	spinbox.set_block_signals(true)
	spinbox.value = value
	spinbox.set_block_signals(false)
	
func _ready():
	spinbox.connect("value_changed", self, "_on_Spinbox_value_changed")
	toggle_negative_button.hide()
func emit_value_changed_signal():
	emit_signal("value_changed", int(spinbox.value))
	emit_signal("value_change_committed")

func _on_Spinbox_value_changed(value):
	emit_value_changed_signal()
	spinbox.release_focus()

func set_params(params):
	if params.has("min"):
		spinbox.min_value = params.min
	if params.has("max"):
		spinbox.max_value = params.max
	if params.has("step"):
		spinbox.step = params.step
	if params.has("show_toggle_negative_button"):
		toggle_negative_button.visible = params.show_toggle_negative_button


func _on_ToggleNegativeButton_pressed():
	spinbox.value *= -1
