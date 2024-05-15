extends HBUIComponent

class_name HBUISkipIntroIndicator

var stylebox: StyleBox = HBUIStyleboxFlat.new(): set = set_stylebox
var font := HBUIFont.new(): set = set_font

@onready var base_container := PanelContainer.new()

@onready var labels := [
	Label.new(),
	Label.new(),
	Label.new()
]

@onready var prompt_input_action_1 := InputGlyphRect.new()
@onready var prompt_input_action_2 := InputGlyphRect.new()

var tween: Tween

var _starting_margin_left := 0

func _ready():
	super._ready()
	prompt_input_action_1.action_name = "note_up"
	prompt_input_action_2.action_name = "note_left"
	prompt_input_action_1.action_text = ""
	prompt_input_action_2.action_text = ""
	labels[0].text = tr("Press ")
	var plus := "+" # Hack to prevent translation
	labels[1].text = plus
	labels[2].text = tr("to skip the intro")
	
	for label in labels:
		label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	
	var hb := HBoxContainer.new()
	
	add_child(base_container)
	
	base_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	base_container.add_child(hb)
	
	hb.add_child(labels[0])
	hb.add_child(prompt_input_action_1)
	hb.add_child(labels[1])
	hb.add_child(prompt_input_action_2)
	hb.add_child(labels[2])
	
	set_stylebox(stylebox)
	set_font(font)
	
func set_font(val):
	font = val
	if is_inside_tree():
		for label in labels:
			set_control_font_override(label, "font", font)

func set_stylebox(val):
	stylebox = val
	if is_inside_tree():
		base_container.add_theme_stylebox_override("panel", stylebox)

func _get_property_list():
	var list := []
	register_subresource_to_plist(list, "stylebox")
	return list

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["font"] = serialize_font(font, resource_storage)
	out_dict["stylebox"] = serialize_stylebox(stylebox, resource_storage)
	return out_dict
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	deserialize_font(dict.get("font", {}), font, cache)
	stylebox = deserialize_stylebox(dict.get("stylebox", {}), cache)
	store_margin_left()
	
func store_margin_left():
	_starting_margin_left = offset_left

static func get_component_id() -> String:
	return "skip_intro_indicator"
	
static func get_component_name() -> String:
	return "Skip Intro Indicator"

func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"font", "stylebox"
	])
	return whitelist

func _set_appear_progress(progress: float):
	position.x = lerp((_starting_margin_left-base_container.size.x), float(_starting_margin_left), progress)

func appear():
	if tween:
		tween.kill()
		tween = null
	show()
	tween = create_tween()
	tween.tween_method(self._set_appear_progress, 0.0, 1.0, 1.0) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)

func disappear():
	if tween:
		tween.kill()
		tween = null
	tween = create_tween()
	tween.tween_method(self._set_appear_progress, 1.0, 0.0, 1.0) \
		.set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(self.hide)
