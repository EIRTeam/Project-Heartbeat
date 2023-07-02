extends HBUIComponent

class_name HBUIScoreCounter

var score = 0: set = set_score

var _display_score = 0.0

const SCORE_MAX_OUT_TIME = 0.5 # How much time it takes for the score to be applied

var increase_speed = 2000.0 # points per second

@onready var label := HBUIDynamicLabel.new()

var font := HBUIFont.new(): set = set_font

func set_font(val):
	font = val
	if is_inside_tree():
		set_control_font(label, "font", font)

func set_score(val):
	score = val
	var diff = score - _display_score
	increase_speed = diff / SCORE_MAX_OUT_TIME
	set_process(true)

func _ready():
	super._ready()
	label.text = "%0*d" % [7, 0]
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.vertical_alignment =VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	set_process(false)
	label.clip_text = true
	set_font(font)
func _process(delta):
	if _display_score < score:
		var speed = increase_speed + (increase_speed * _display_score / score)
		_display_score += delta * speed
		_display_score = clamp(_display_score, 0, score)
		label.text = "%0*d" % [7, int(_display_score)]
	else:
		label.text = "%0*d" % [7, score]

static func get_component_id() -> String:
	return "score_counter"
	
static func get_component_name() -> String:
	return "Score Counter"

func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"font"
	])
	return whitelist

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["font"] = serialize_font(font, resource_storage)
	return out_dict
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	deserialize_font(dict.get("font", {}), font, cache)
