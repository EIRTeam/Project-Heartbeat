extends Control

export(float) var minimum = 0.0
export(float) var maximum = 10
export(float) var step = 1
var debounce_step = null
export(String) var postfix = ""

var steps_per_second = 5 # steps per second when holding a button

const INITIAL_MOVE_DEBOUNCE_T = 0.3
var initial_move_debounce = INITIAL_MOVE_DEBOUNCE_T

const MOVE_DEBOUNCE_T = 0.1
var move_debounce = MOVE_DEBOUNCE_T

var value = 0 setget set_value
signal changed(option)

onready var text_label = get_node("OptionRange/HBoxContainer/Label")
onready var option_label = get_node("OptionRange/HBoxContainer/Control/OptionLabel")
var hover_style
var normal_style
signal hover
var text setget set_text
var text_overrides = {}
var percentage = false
func _init():
	normal_style = StyleBoxEmpty.new()
	hover_style = preload("res://styles/PanelStyleTransparentHover.tres")
	
func hover():
	$OptionRange.add_stylebox_override("panel", hover_style)
	emit_signal("hover")

func stop_hover():
	$OptionRange.add_stylebox_override("panel", normal_style)

func set_text(value):
	text_label.text = value

func set_value(val):
	value = val
	if int(value) in text_overrides:
		option_label.text = text_overrides[int(value)]
	else:
		if percentage:
			option_label.text = ("%.1f" % (val*100.0)) + postfix
		else:
			option_label.text = str(value) + postfix

func _ready():
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	stop_hover()
	
func _process(delta):
	if not Input.is_action_pressed("gui_left") and not Input.is_action_pressed("gui_right"):
		set_process(false) # just in case
		
	var stp = step
	if debounce_step:
		stp = debounce_step
	var old_initial_debonce = initial_move_debounce
	if initial_move_debounce > 0.0:
		initial_move_debounce = max(initial_move_debounce-delta, 0.0)
		if old_initial_debonce > 0.0 and initial_move_debounce <= 0.0:
			var new_val = value
			if Input.is_action_pressed("gui_left"):
				new_val = value + step - stp
			elif Input.is_action_pressed("gui_right"):
				new_val = value - step + stp
			set_value(stepify(clamp(new_val, minimum, maximum), step))
			emit_signal("changed", value)
	else:
		if move_debounce > 0.0:
			if Input.is_action_pressed("gui_left") or Input.is_action_pressed("gui_right"):
				move_debounce = max(move_debounce-delta, 0.0)
		else:
			move_debounce = MOVE_DEBOUNCE_T
			var option_change = 0

			if Input.is_action_pressed("gui_left"):
				option_change = -stp
			if Input.is_action_pressed("gui_right"):
				option_change = stp
			if option_change != 0:
				set_value(stepify(clamp(value+option_change, minimum, maximum), step))
				emit_signal("changed", value)
	
func _gui_input(event):
	var option_change = 0
	if event.is_action_pressed("gui_left"):
		option_change = -step
		initial_move_debounce = INITIAL_MOVE_DEBOUNCE_T
		move_debounce = MOVE_DEBOUNCE_T
		set_process(true)
		get_tree().set_input_as_handled()
	elif event.is_action_pressed("gui_right"):
		option_change = step
		initial_move_debounce = INITIAL_MOVE_DEBOUNCE_T
		move_debounce = MOVE_DEBOUNCE_T
		set_process(true)
		get_tree().set_input_as_handled()
	elif event.is_action_released("gui_left") or event.is_action_released("gui_right"):
		set_process(false)
	if option_change != 0:
		set_value(stepify(clamp(value+option_change, minimum, maximum), step))
		emit_signal("changed", value)


