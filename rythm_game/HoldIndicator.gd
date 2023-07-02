extends Control

var current_holds = []: set = set_current_holds
var current_score = 0: set = set_current_score
var icon_nodes = {}

@onready var current_score_label = get_node("Panel/MarginContainer/HBoxContainer/HBoxContainer/ScoreLabel")
@onready var hold_count_label = get_node("Panel/HoldCount")
@onready var panel = get_node("Panel")
@onready var max_combo_label = get_node("MaxComboContainer/Control/MarginContainer/HBoxContainer/MaxComboLabel")
@onready var max_combo_container = get_node("MaxComboContainer")
@onready var bonus_label = get_node("Panel/MarginContainer/HBoxContainer/BonusLabel")
@onready var hold_note_icons_container = get_node("Panel/MarginContainer/HBoxContainer/HoldNoteIcons")
const APPEAR_T = 0.15
const APPEAR_LEAD_IN = 0.1
const SCALE_T = 0.15
const DISAPPEAR_COOLDOWN = 1.5
var disappear_cooldown_t = 0.0
var appear_t = 0.0
var appear_t_inc = 0.0
var max_appear_t = 0.0
var max_appear_t_inc = 0.0
var scale_t = 0.0
var scale_t_inc = 0.0

const BONUS_TEXTS = {
	1: "SINGLE BONUS",
	2: "DOUBLE BONUS",
	3: "TRIPLE BONUS",
	4: "QUADRUPLE BONUS"
}

func _ready():
	for type_name in HBNoteData.NOTE_TYPE:
		var type = HBNoteData.NOTE_TYPE[type_name]
		var texture_rect = TextureRect.new()
		texture_rect.expand = true
		texture_rect.texture = ResourcePackLoader.get_graphic("%s_note.png" % [HBGame.NOTE_TYPE_TO_STRING_MAP[type]])
		texture_rect.custom_minimum_size = Vector2(35, 35)
		texture_rect.show()
		hold_note_icons_container.add_child(texture_rect)
		icon_nodes[type_name] = texture_rect
	connect("resized", Callable(self, "_on_resized"))
	call_deferred("_on_resized")
	set_process(false)
	
func _on_resized():
	for texture_rect in icon_nodes.values():
		texture_rect = texture_rect as TextureRect
		texture_rect.custom_minimum_size.x = panel.size.y
		texture_rect.size.x = panel.size.y
		texture_rect.size.y = panel.size.y
	$Panel/MarginContainer.size = $Panel.size

func set_current_holds(val):
	current_holds = val
	for note_type in icon_nodes:
		if HBNoteData.NOTE_TYPE[note_type] in current_holds:
			icon_nodes[note_type].show()
		else:
			icon_nodes[note_type].hide()
	hold_count_label.text = str(current_holds.size())
	bonus_label.text = BONUS_TEXTS[current_holds.size()]

func set_current_score(val):
	current_score = val
	current_score_label.text = "+" + ("%.0f" % val)
	disappear_cooldown_t = DISAPPEAR_COOLDOWN

func _process(delta):
	disappear_cooldown_t -= delta
	if disappear_cooldown_t <= 0.0:
		disappear()
	
	
	appear_t += appear_t_inc * delta
	appear_t = clamp(appear_t, 0.0, APPEAR_T + APPEAR_LEAD_IN)
	modulate.a = clamp(appear_t - APPEAR_LEAD_IN, 0.0, APPEAR_T + APPEAR_LEAD_IN) / APPEAR_T
	scale_t += scale_t_inc * delta
	scale_t = clamp(scale_t, 0.0, SCALE_T)
	scale.y = scale_t / SCALE_T
	
	pivot_offset = (size - Vector2(0, max_combo_container.size.y) ) / 2.0
	
	max_appear_t += max_appear_t_inc * delta
	max_appear_t = clamp(max_appear_t, 0.0, APPEAR_T)
	max_combo_container.modulate.a = max_appear_t / APPEAR_T
func appear():
	appear_t_inc = 1.0
	scale_t_inc = 1.0
	disappear_cooldown_t = DISAPPEAR_COOLDOWN
	_on_resized()
func show_max_combo(combo):
	max_combo_label.text = "Max Hold Bonus! %d" % combo
	max_appear_t_inc = 1.0
	scale_t_inc = 1.0
	disappear_cooldown_t = DISAPPEAR_COOLDOWN
func disappear():
	appear_t_inc = -1.0
	max_appear_t_inc = -1.0
	scale_t_inc = -1.0
