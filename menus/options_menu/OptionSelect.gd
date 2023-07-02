extends "Option.gd"

@onready var option_button := get_node("HBoxContainer/HBoxContainer/OptionButton")

var options = ["No", "Yes"]
var options_pretty = []
var selected_option = -1
var text : set = set_text

func set_text(value):
	text = value
	$HBoxContainer/Label.text = value

func set_value(val):
	value = val
	var i = options.find(val)
	if is_inside_tree():
		if i != -1:
			option_button.set_block_signals(true)
			option_button.selected_item = i
			selected_option = i as int
			option_button.set_block_signals(false)

func _ready():
	focus_mode = Control.FOCUS_ALL
	for option_i in range(options.size()):
		var option_text := str(options[option_i])
		var option_value = options[option_i]
		if options_pretty.size() > option_i:
			option_text = options_pretty[option_i]
		option_button.add_item(option_text, option_value)
	set_value(value)
	option_button.connect("selected", Callable(self, "_on_option_selected"))

func _on_option_selected(id):
	var options_str := []
	for option in options:
		options_str.append(option as String)
	var i := options_str.find(id) as int
	if i != -1:
		selected_option = i
	
func hover():
	super.hover()
	option_button.hover()
func stop_hover():
	if is_inside_tree():
		option_button.stop_hover()
	
func _gui_input(event):
	if event.is_action_pressed("gui_accept"):
		get_viewport().set_input_as_handled()
		option_button._on_pressed()

func _on_OptionButton_selected(id):
	change_value(id)
	value = id
	emit_signal("back")

func _on_OptionButton_back():
	emit_signal("back")
