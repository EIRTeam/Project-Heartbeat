extends "Option.gd"

var text = "": set = set_text
# warning-ignore:unused_signal
signal pressed
signal canceled

@onready var command_line_popup: HBCommandLineEditPopup = get_node("%CommandLineEditPopup")
@onready var button_container: HBSimpleMenu = get_node("%ButtonContainer")
@onready var edit_button: HBHovereableButton = get_node("%EditButton")
@onready var preview_label: Label = get_node("%PreviewLabel")

func set_value(val):
	value = val
	_update_preview_label()

func set_text(val):
	text = val
	$HBoxContainer/Label.text = val

func _on_lines_entered(lines: Array[String]):
	value = lines
	changed.emit(lines)

func _ready():
	command_line_popup.hide()
	pressed.connect(_on_pressed)
	command_line_popup.lines_entered.connect(_on_lines_entered)
	command_line_popup.canceled.connect(func():
		canceled.emit()
	)
	edit_button.pressed.connect(pressed.emit)
	
func _on_pressed():
	command_line_popup.lines = value
	command_line_popup.popup()

func hover():
	super.hover()
	button_container._on_focus_entered()

func stop_hover():
	super.stop_hover()
	if is_inside_tree():
		button_container._on_focus_exited()
 
func _update_preview_label():
	if is_inside_tree():
		preview_label.text = " ".join(PackedStringArray(value))
