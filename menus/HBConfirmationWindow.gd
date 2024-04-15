@tool
extends Control

signal accept
signal cancel
@export var has_cancel: bool = true 
@export var has_accept: bool = true
@export var text: String  = "Are you sure you want to do this?": set = set_text
@export var accept_text: String  = "Yes": set = set_accept_text
@export var cancel_text: String  = "No": set = set_cancel_text
@onready var cancel_button = get_node("%CancelButton")
func _ready():
	hide()
	top_level = true
	_connect_button_signals()
	connect("cancel", Callable(self, "hide"))
	connect("accept", Callable(self, "hide"))
	if not has_cancel:
		%CancelButton.hide()
	if not has_accept:
		%AcceptButton.hide()
	if not Engine.is_editor_hint():
		cancel_button.set_meta("sfx", HBGame.menu_back_sfx)
		
func _input(event: InputEvent):
	if visible:
		if event.is_action_pressed("gui_cancel"):
			cancel.emit()
			hide()
			get_viewport().set_input_as_handled()
func _connect_button_signals():
	%AcceptButton.connect("pressed", Callable(self, "_on_accept_pressed"))
	%CancelButton.connect("pressed", Callable(self, "_on_cancel_pressed"))

func _on_accept_pressed():
	emit_signal("accept")

func _on_cancel_pressed():
	emit_signal("cancel")

func set_text(value):
	text = value
	%TextLabel.text = value
func set_accept_text(value):
	accept_text = value
	%AcceptButton.text = value
func set_cancel_text(value):
	cancel_text = value
	%CancelButton.text = value


func _on_Control_about_to_show():
	%ButtonContainer.grab_focus()
	if has_cancel:
		%ButtonContainer.select_button(cancel_button.get_index())
	else:
		%ButtonContainer.select_button(0)
func popup():
	_on_Control_about_to_show()
	show()
func popup_centered_ratio(ratio := 0.5):
	popup_centered()
func popup_centered():
	_on_Control_about_to_show()
	show()
	global_position = get_window().content_scale_size * 0.5 - size*0.5
