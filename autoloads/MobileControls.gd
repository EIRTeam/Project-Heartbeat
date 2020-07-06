extends Control

onready var button_template = get_node("HBoxContainer/Button")
var NOTE_TYPE_TO_ACTIONS_MAP = {}
func _ready():
	var g = HBRhythmGame.new()
	NOTE_TYPE_TO_ACTIONS_MAP = g.NOTE_TYPE_TO_ACTIONS_MAP
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

func simulate_action(action):
	var a = InputEventAction.new()
	a.action = action
	a.pressed = true
	Input.parse_input_event(a)
func _on_button_pressed(button):
	simulate_action(NOTE_TYPE_TO_ACTIONS_MAP[button][0])
func generate():
	pass


func _switch_modes():
	$HBoxContainer.visible = !$HBoxContainer.visible
	$VBoxContainer.visible = !$VBoxContainer.visible
	$VBoxContainer2.visible = !$VBoxContainer2.visible
