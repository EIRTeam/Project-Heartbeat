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

const PROMPT_INPUT_ACTION_SCENE = preload("res://third_party/joypad_support/Prompts/PromptInputAction.tscn")

@onready var prompt_input_action_1 := PROMPT_INPUT_ACTION_SCENE.instantiate()
@onready var prompt_input_action_2 := PROMPT_INPUT_ACTION_SCENE.instantiate()

@onready var tween := Threen.new()

var _starting_margin_left := 0

func _ready():
	super._ready()
	prompt_input_action_1.input_action = "note_up"
	prompt_input_action_2.input_action = "note_left"
	labels[0].text = tr("Press ")
	labels[1].text = "+"
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
	
	add_child(tween)
	

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

func appear():
	tween.remove_all()
	show()
	position.x = _starting_margin_left - base_container.size.x
	tween.interpolate_property(self, "position:x", _starting_margin_left-base_container.size.x, _starting_margin_left, 1.0, Threen.TRANS_CUBIC, Threen.EASE_OUT, 1.0)
	tween.start()

func disappear():
	tween.remove_all()
	tween.interpolate_property(self, "position:x", _starting_margin_left, _starting_margin_left-base_container.size.x, 1.0, Threen.TRANS_CUBIC, Threen.EASE_OUT)
	tween.start()
