extends HBUIComponent

class_name HBUISongDifficultyLabel

onready var hbox_container := HBoxContainer.new()
onready var difficulty_label := HBUIDynamicLabel.new()
onready var modifiers_label := HBUIDynamicLabel.new()

var difficulty_font := HBUIFont.new() setget set_difficulty_font
var modifiers_font := HBUIFont.new() setget set_modifiers_font
var element_separation := 4 setget set_element_separation

func set_difficulty(difficulty: String):
	difficulty_label.text = "[%s]" % [difficulty]

func set_modifiers_name_list(modifiers: PoolStringArray):
	if modifiers.size() > 0:
		modifiers_label.text = " - " + modifiers.join(" + ")
	else:
		modifiers_label.text = ""
func set_element_separation(val):
	element_separation = val
	if is_inside_tree():
		hbox_container.add_constant_override("separation", element_separation)

func set_difficulty_font(val):
	difficulty_font = val
	if is_inside_tree():
		set_control_font(difficulty_label, "font", difficulty_font)

func set_modifiers_font(val):
	modifiers_font = val
	if is_inside_tree():
		set_control_font(modifiers_label, "font", modifiers_font)

static func get_component_id() -> String:
	return "song_difficulty"
	
static func get_component_name() -> String:
	return "Song Difficulty Label"

func get_hb_inspector_whitelist() -> Array:
	var whitelist := .get_hb_inspector_whitelist()
	whitelist.append_array([
		"modifiers_font", "difficulty_font", "element_separation"
	])
	return whitelist

func _ready():
	modifiers_label.text = "Nightcore"
	difficulty_label.text = "[EXTREME]"
	difficulty_label.uppercase = true
	modifiers_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modifiers_label.clip_text = true
	difficulty_label.valign = Label.VALIGN_BOTTOM
	modifiers_label.valign = Label.VALIGN_BOTTOM
	
	add_child(hbox_container)
	hbox_container.add_child(difficulty_label)
	hbox_container.add_child(modifiers_label)
	hbox_container.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	
	difficulty_font.use_filter = true
	difficulty_font.use_mipmaps = true
	
	modifiers_font.use_filter = true
	modifiers_font.use_mipmaps = true
	
	set_element_separation(element_separation)
	set_modifiers_font(modifiers_font)
	set_difficulty_font(difficulty_font)

func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := ._to_dict(resource_storage)
	out_dict["modifiers_font"] = serialize_font(modifiers_font, resource_storage)
	out_dict["difficulty_font"] = serialize_font(difficulty_font, resource_storage)
	out_dict["element_separation"] = element_separation
	return out_dict
	
func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	._from_dict(dict, cache)
	deserialize_font(dict.get("difficulty_font", {}), difficulty_font, cache)
	deserialize_font(dict.get("modifiers_font", {}), modifiers_font, cache)
	element_separation = dict.get("element_separation", 4)
