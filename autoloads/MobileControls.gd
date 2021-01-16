extends Control

onready var button_template = get_node("HBoxContainer/Button")
var NOTE_TYPE_TO_ACTIONS_MAP = {}

var input_manager setget set_input_manager

func set_input_manager(val):
	$NoteDetector.input_manager = val

func _ready():
	HBGame.NOTE_TYPE_TO_ACTIONS_MAP = HBGame.NOTE_TYPE_TO_ACTIONS_MAP
	var buttons = [HBNoteData.NOTE_TYPE.UP, HBNoteData.NOTE_TYPE.LEFT, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.RIGHT]
	for button in buttons:
		var temp = button_template.duplicate()
		temp.get_node("ColorRect/TextureRect").texture = IconPackLoader.get_graphic(HBUtils.find_key(HBNoteData.NOTE_TYPE, button), "note")
		var col = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, button))
		col.a = 0.1
		temp.get_node("ColorRect").color = col
		temp.connect("pressed", self, "_on_button_pressed", [button])
		temp.show()
		$HBoxContainer.add_child(temp)
	$NoteDetector.set_process_input(false)

func simulate_action(action, pressed = false):
	var a = InputEventAction.new()
	a.action = action
	a.pressed = pressed
	Input.parse_input_event(a)
func _on_button_pressed(button):
	simulate_action(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[button][0], true)
	simulate_action(HBGame.NOTE_TYPE_TO_ACTIONS_MAP[button][0])
func generate():
	pass


func _switch_modes():
	$HBoxContainer.visible = !$HBoxContainer.visible
	$VBoxContainer.visible = !$VBoxContainer.visible
	$VBoxContainer2.visible = !$VBoxContainer2.visible
	$NoteDetector.set_process_input($HBoxContainer.visible)


func _on_gui_action_up(act_name):
	simulate_action(act_name)

func _on_gui_action_down(act_name):
	simulate_action(act_name, true)
