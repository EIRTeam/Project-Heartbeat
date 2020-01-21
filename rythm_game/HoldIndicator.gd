extends Control

var current_holds = [] setget set_current_holds
var current_score = 0 setget set_current_score
onready var icon_nodes = {
	HBNoteData.NOTE_TYPE.LEFT: get_node("Panel/MarginContainer/HBoxContainer/Left"),
	HBNoteData.NOTE_TYPE.RIGHT: get_node("Panel/MarginContainer/HBoxContainer/Right"),
	HBNoteData.NOTE_TYPE.UP: get_node("Panel/MarginContainer/HBoxContainer/Up"),
	HBNoteData.NOTE_TYPE.DOWN: get_node("Panel/MarginContainer/HBoxContainer/Down")
}

onready var current_score_label = get_node("Panel/MarginContainer/HBoxContainer/HBoxContainer/ScoreLabel")
onready var hold_count_label = get_node("Panel/MarginContainer/HBoxContainer/HoldCount")
onready var panel = get_node("Panel")
onready var animation_player = get_node("AnimationPlayer")
onready var max_combo_label = get_node("Panel2/Control/MarginContainer/HBoxContainer/MaxComboLabel")
onready var bonus_label = get_node("Panel/MarginContainer/HBoxContainer/BonusLabel")
const BONUS_TEXTS = {
	1: "SINGLE BONUS",
	2: "DOUBLE BONUS",
	3: "TRIPLE BONUS",
	4: "QADRUPLE BONUS"
}

func _ready():
	_on_resized()
	connect("resized", self, "_on_resized")
	animation_player.play("start")
	
func _on_resized():
	for texture_rect in icon_nodes.values():
		texture_rect = texture_rect as TextureRect
		texture_rect.rect_min_size.x = panel.rect_size.y
		texture_rect.rect_size.x = panel.rect_size.y

func set_current_holds(val):
	current_holds = val
	for note_type in icon_nodes:
		if note_type in current_holds:
			icon_nodes[note_type].show()
		else:
			icon_nodes[note_type].hide()
	hold_count_label.text = str(current_holds.size())
	bonus_label.text = BONUS_TEXTS[current_holds.size()]

func set_current_score(val):
	current_score = val
	current_score_label.text = "+" + ("%.0f" % val)

func appear():
	if modulate.a == 0:
		animation_player.play("appear")
		
func show_max_combo(combo):
	animation_player.play("appear_max")
	max_combo_label.text = "Max Hold Bonus! %d" % combo
	
func disappear():
	animation_player.play("disappear")
