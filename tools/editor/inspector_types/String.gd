extends "res://tools/editor/inspector_types/EditorInspectorType.gd"

@onready var line_edit = get_node("LineEdit")

var inputs: Array
var default: bool

func sync_value(input_array: Array):
	line_edit.set_block_signals(true)
	inputs = input_array
	
	line_edit.text = input_array[0].get(property_name)
	for input in input_array:
		if input.get(property_name) != line_edit.text:
			line_edit.text = "Multiple Values..."
			break
	
	line_edit.set_block_signals(false)

func _ready():
	line_edit.connect("text_submitted", Callable(self, "_on_lineedit_value_changed"))
	line_edit.connect("focus_entered", Callable(self, "_on_lineedit_focus_entered"))

func _on_lineedit_value_changed(value):
	if value == "Multiple Values...":
		return
	
	var values = {}
	for i in inputs.size():
		values[i] = value
	
	emit_signal("values_changed", values)
	emit_signal("value_change_committed")
	line_edit.release_focus()

func _on_lineedit_focus_entered():
	if line_edit.text == "Multiple Values...":
		line_edit.text = ""

func set_params(params):
	if params.has("default"):
		line_edit.placeholder_text = params.default
		default = true
