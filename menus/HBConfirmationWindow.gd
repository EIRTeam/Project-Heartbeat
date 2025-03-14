@tool
extends Control

class_name HBConfirmationWindow

signal accept
signal cancel

enum ConfirmationWindowFocusStartsOn {
	FOCUS_STARTS_ON_ACCEPT,
	FOCUS_STARTS_ON_CANCEL
}

@export var has_cancel: bool = true 
@export var has_accept: bool = true
@export var text: String  = "Are you sure you want to do this?": set = set_text
@export var accept_text: String  = "Yes": set = set_accept_text
@export var cancel_text: String  = "No": set = set_cancel_text
@export var focus_starts_on := ConfirmationWindowFocusStartsOn.FOCUS_STARTS_ON_CANCEL
@onready var cancel_button = get_node("%CancelButton")
var tween: Tween
enum AnimationName {
	HIDE,
	POPUP
}

var current_animation := AnimationName.HIDE

func _ready():
	hide()
	top_level = true
	_connect_button_signals()
	connect("cancel", self.play_hide_animation)
	connect("accept", self.play_hide_animation)
	%CancelButton.visible = has_cancel
	%AcceptButton.visible = has_accept
	if not Engine.is_editor_hint():
		cancel_button.set_meta("sfx", HBGame.menu_back_sfx)
		
func _input(event: InputEvent):
	if visible:
		if event.is_action_pressed("gui_cancel"):
			if has_cancel:
				if (not tween or not tween.is_running()) or current_animation != AnimationName.HIDE:
					_on_cancel_pressed()
			else:
				_on_accept_pressed()
			get_viewport().set_input_as_handled()
func _connect_button_signals():
	%AcceptButton.connect("pressed", Callable(self, "_on_accept_pressed"))
	%CancelButton.connect("pressed", Callable(self, "_on_cancel_pressed"))

func _on_accept_pressed():
	emit_signal("accept")

func _on_cancel_pressed():
	emit_signal("cancel")
	play_hide_animation()

func set_text(value):
	text = value
	if not is_node_ready():
		await ready
	%TextLabel.text = value
	%TextLabel.visible = !text.is_empty()
		
func set_accept_text(value):
	accept_text = value
	%AcceptButton.text = value
func set_cancel_text(value):
	cancel_text = value
	%CancelButton.text = value

func _on_Control_about_to_show():
	%ButtonContainer.grab_focus()
	if has_cancel and focus_starts_on == ConfirmationWindowFocusStartsOn.FOCUS_STARTS_ON_CANCEL:
		%ButtonContainer.select_button(cancel_button.get_index())
	else:
		%ButtonContainer.select_button(0)
func popup():
	scale = Vector2.ONE
	_on_Control_about_to_show()
	show()
	play_popup_animation()

		
func play_popup_animation():
	pivot_offset = size * 0.5
	if tween:
		tween.kill()
	current_animation = AnimationName.POPUP
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_BACK) \
		.from(Vector2.ZERO)
	
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.25) \
		.from(0.0)
func play_hide_animation():
	pivot_offset = size * 0.5
	if tween:
		tween.kill()
	current_animation = AnimationName.HIDE
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25) \
		.set_ease(Tween.EASE_IN) \
		.set_trans(Tween.TRANS_BACK) \
		.from(Vector2.ONE)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25) \
		.from(1.0)
	tween.tween_callback(self.hide)
	tween.tween_callback(self.set.bind("scale", Vector2.ONE))
		
func add_button(_text: String) -> HBHovereableButton:
	var button := HBHovereableButton.new()
	button.text = _text
	%ButtonContainer.add_child(button)
	return button
func popup_centered_ratio(ratio := 0.5):
	popup_centered()
func popup_centered():
	scale = Vector2.ONE
	_on_Control_about_to_show()
	show()
	var center := get_window().get_visible_rect().get_center()
	global_position = center - size*0.5
	play_popup_animation()
