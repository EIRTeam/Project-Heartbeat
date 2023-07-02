extends HBUIComponent

class_name HBUIHoldIndicator

var hold_count_font := HBUIFont.new(): set = set_hold_count_font
var main_font := HBUIFont.new(): set = set_main_font
var max_hold_bonus_font := HBUIFont.new(): set = set_max_hold_bonus_font
var score_font := HBUIFont.new(): set = set_score_font

var main_stylebox: StyleBox = HBUIStyleboxFlat.new(): set = set_main_stylebox
var max_hold_bonus_stylebox: StyleBox = HBUIStyleboxFlat.new(): set = set_max_hold_bonus_stylebox

var max_hold_bonus_min_width := 0.0: set = set_max_hold_bonus_min_width

@onready var vbox_container := VBoxContainer.new()
@onready var main_panel := PanelContainer.new()
@onready var hold_count_label := Label.new()
@onready var score_label := Label.new()
@onready var bonus_label := Label.new()

@onready var max_hold_bonus_container := PanelContainer.new()
@onready var max_hold_bonus_label := Label.new()

@onready var hold_note_icons_container = HBoxContainer.new()

var icon_nodes := {}
var current_holds = []: set = set_current_holds
var current_score = 0: set = set_current_score

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
	score_label.text = "+" + ("%.0f" % val)
	disappear_cooldown_t = DISAPPEAR_COOLDOWN

func set_main_stylebox(val):
	main_stylebox = val
	if is_inside_tree():
		main_panel.add_theme_stylebox_override("panel", main_stylebox)

func set_max_hold_bonus_stylebox(val):
	max_hold_bonus_stylebox = val
	if is_inside_tree():
		max_hold_bonus_container.add_theme_stylebox_override("panel", max_hold_bonus_stylebox)

func set_hold_count_font(val):
	hold_count_font = val
	if is_inside_tree():
		set_control_font_override(hold_count_label, "font", val)
		_on_resized()

func set_score_font(val):
	score_font = val
	if is_inside_tree():
		set_control_font_override(score_label, "font", val)
		_on_resized()
func set_main_font(val):
	main_font = val
	if is_inside_tree():
		set_control_font_override(bonus_label, "font", val)
		_on_resized()

func set_max_hold_bonus_font(val):
	max_hold_bonus_font = val
	if is_inside_tree():
		set_control_font_override(max_hold_bonus_label, "font", val)
		_on_resized()

func set_max_hold_bonus_min_width(val):
	max_hold_bonus_min_width = val
	if is_inside_tree():
		max_hold_bonus_container.custom_minimum_size.x = val

func _ready():
	super._ready()
	bonus_label.text = "QUADRUPLE BONUS"
	score_label.text = "+1000"
	hold_count_label.text = "4"
	max_hold_bonus_label.text = "Max Hold Bonus! +3300"
	
	vbox_container.connect("resized", Callable(self, "_on_vbox_container_resized"))
	
	vbox_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	add_child(vbox_container)
	
	vbox_container.add_child(main_panel)
	
	var main_panel_hb := HBoxContainer.new()
	main_panel.add_child(main_panel_hb)
	add_child(hold_count_label)
	main_panel_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	main_panel_hb.add_theme_constant_override("separation", 20)
	main_panel_hb.add_child(bonus_label)
	main_panel_hb.add_child(hold_note_icons_container)
	main_panel_hb.add_child(score_label)
	var max_combo_hb := HBoxContainer.new()
	max_combo_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	
	max_combo_hb.add_child(max_hold_bonus_container)
	vbox_container.add_child(max_combo_hb)
	
	max_hold_bonus_container.add_child(max_hold_bonus_label)
	max_hold_bonus_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	bonus_label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	score_label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	hold_note_icons_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hold_count_label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	max_hold_bonus_label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	max_hold_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	connect("resized", Callable(self, "_on_resized"))

	for type_name in HBNoteData.NOTE_TYPE:
		var type = HBNoteData.NOTE_TYPE[type_name]
		var texture_rect = TextureRect.new()
		texture_rect.expand = true
		texture_rect.texture = ResourcePackLoader.get_graphic("%s_note.png" % [HBGame.NOTE_TYPE_TO_STRING_MAP[type]])
		texture_rect.custom_minimum_size = Vector2(35, 35)
		texture_rect.show()
		hold_note_icons_container.add_child(texture_rect)
		icon_nodes[type_name] = texture_rect
	set_process(false)
	
	set_hold_count_font(hold_count_font)
	set_main_font(main_font)
	set_max_hold_bonus_font(max_hold_bonus_font)
	set_main_stylebox(main_stylebox)
	set_max_hold_bonus_stylebox(max_hold_bonus_stylebox)
	set_score_font(score_font)
	set_max_hold_bonus_min_width(max_hold_bonus_min_width)
	call_deferred("_on_resized")

func fit_hold_count_label():
	var test_f := hold_count_font
	if hold_count_label.has_meta("font_font_override"):
		test_f = hold_count_label.get_meta("font_font_override")
	var size := test_f.get_string_size(hold_count_label.text)
	hold_count_label.size = size
	hold_count_label.position.x = -size.x * 0.5
	hold_count_label.position.y = (main_panel.size.y - size.y) * 0.5

func _on_vbox_container_resized():
	custom_minimum_size = vbox_container.get_minimum_size()

func _on_resized():
	fit_hold_count_label()
	
	for texture_rect in icon_nodes.values():
		texture_rect.custom_minimum_size = Vector2.ZERO
		texture_rect.size = Vector2.ZERO
		texture_rect.update_minimum_size()
	update_minimum_size()
	for texture_rect in icon_nodes.values():
		texture_rect = texture_rect as TextureRect
		texture_rect.custom_minimum_size.x = hold_note_icons_container.size.y
		texture_rect.size.x = hold_note_icons_container.size.y
		texture_rect.size.y = hold_note_icons_container.size.y
	_on_vbox_container_resized()
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
	
	pivot_offset = (size - Vector2(0, max_hold_bonus_container.size.y) ) / 2.0
	
	max_appear_t += max_appear_t_inc * delta
	max_appear_t = clamp(max_appear_t, 0.0, APPEAR_T)
	max_hold_bonus_container.modulate.a = max_appear_t / APPEAR_T
	
func appear():
	appear_t_inc = 1.0
	scale_t_inc = 1.0
	disappear_cooldown_t = DISAPPEAR_COOLDOWN
	_on_resized()
	set_process(true)
func show_max_combo(combo):
	max_hold_bonus_label.text = "Max Hold Bonus! %d" % combo
	max_appear_t_inc = 1.0
	scale_t_inc = 1.0
	disappear_cooldown_t = DISAPPEAR_COOLDOWN
	set_process(true)
	
func disappear():
	appear_t_inc = -1.0
	max_appear_t_inc = -1.0
	scale_t_inc = -1.0
	set_process(true)

static func get_component_id() -> String:
	return "hold_indicator"
	
static func get_component_name() -> String:
	return "Hold Indicator"

func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"main_font", "max_hold_bonus_font", "hold_count_font", "score_font",
		"main_stylebox", "max_hold_bonus_stylebox", "max_hold_bonus_min_width"
	])
	return whitelist

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["main_font"] = serialize_font(main_font, resource_storage)
	out_dict["max_hold_bonus_font"] = serialize_font(max_hold_bonus_font, resource_storage)
	out_dict["score_font"] = serialize_font(score_font, resource_storage)
	out_dict["hold_count_font"] = serialize_font(hold_count_font, resource_storage)
	out_dict["main_stylebox"] = serialize_stylebox(main_stylebox, resource_storage)
	out_dict["max_hold_bonus_stylebox"] = serialize_stylebox(max_hold_bonus_stylebox, resource_storage)
	out_dict["max_hold_bonus_min_width"] = max_hold_bonus_min_width
	return out_dict
	
func _get_property_list():
	var list := []
	
	register_subresource_to_plist(list, "main_stylebox")
	register_subresource_to_plist(list, "max_hold_bonus_stylebox")
	
	return list
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	deserialize_font(dict.get("main_font", {}), main_font, cache)
	deserialize_font(dict.get("max_hold_bonus_font", {}), max_hold_bonus_font, cache)
	deserialize_font(dict.get("score_font", {}), score_font, cache)
	deserialize_font(dict.get("hold_count_font", {}), hold_count_font, cache)
	main_stylebox = deserialize_stylebox(dict.get("main_stylebox", {}), cache)
	max_hold_bonus_stylebox = deserialize_stylebox(dict.get("max_hold_bonus_stylebox", {}), cache)
	max_hold_bonus_min_width = dict.get("max_hold_bonus_min_width", 0)
