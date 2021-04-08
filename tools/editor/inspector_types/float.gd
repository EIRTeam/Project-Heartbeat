extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

onready var spin_box = get_node("Spinbox")
onready var toggle_negative_button = get_node("ToggleNegativeButton")
func sync_value(value):
	spin_box.set_block_signals(true)
	spin_box.value = value
	spin_box.set_block_signals(false)
func _ready():
	spin_box.connect("value_changed", self, "_on_Spinbox_value_changed")
	toggle_negative_button.hide()
func emit_value_changed_signal():
	emit_signal("value_changed", float(spin_box.value))
	emit_signal("value_change_committed")

func _on_Spinbox_value_changed(value):
	spin_box.release_focus()
	emit_value_changed_signal()


func _on_ToggleNegativeButton_pressed():
	spin_box.value *= -1

func set_params(params):
	if params.has("min"):
		spin_box.min_value = params.min
	if params.has("max"):
		spin_box.max_value = params.max
	if params.has("step"):
		spin_box.step = params.step
	if params.has("show_toggle_negative_button"):
		toggle_negative_button.visible = params.show_toggle_negative_button
