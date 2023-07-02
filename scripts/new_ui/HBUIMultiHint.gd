extends HBUIComponent

class_name HBUIMultiHint

var directions_map := {}

const DIRECTIONS = [HBNoteData.NOTE_TYPE.RIGHT, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.LEFT, HBNoteData.NOTE_TYPE.UP]

var off_texture: Texture2D: set = set_off_texture
var on_texture: Texture2D: set = set_on_texture
var stylebox: StyleBox = HBUIStyleboxFlat.new(): set = set_stylebox

var center_offset := 70: set = set_center_offset

var panel := Panel.new()

var texture_width := 128.0: set = set_texture_width
var texture_height := 128.0: set = set_texture_height

func set_texture_width(val):
	texture_width = val
	update_texture_rect_positions()

func set_texture_height(val):
	texture_height = val
	update_texture_rect_positions()

func set_on_texture(val):
	on_texture = val
	update_texture_rects()
	update_texture_rect_positions()

func set_off_texture(val):
	off_texture = val
	update_texture_rects()
	update_texture_rect_positions()

func set_stylebox(val):
	stylebox = val
	panel.add_theme_stylebox_override("panel", stylebox)

func set_center_offset(val):
	center_offset = val
	update_texture_rect_positions()

func update_texture_rects():
	if is_inside_tree():
		if directions_map.size() > 0:
			for i in range(DIRECTIONS.size()):
				var direction := DIRECTIONS[i] as int
				var off_texture_rect := directions_map[direction]["off"] as TextureRect
				var on_texture_rect := directions_map[direction]["on"] as TextureRect
				if off_texture:
					off_texture_rect.texture = off_texture
				if on_texture:
					on_texture_rect.texture = on_texture

func update_texture_rect_positions():
	if is_inside_tree():
		if directions_map.size() > 0:
			for i in range(DIRECTIONS.size()):
				var direction := DIRECTIONS[i] as int
				var off_texture_rect := directions_map[direction]["off"] as TextureRect
				var on_texture_rect := directions_map[direction]["on"] as TextureRect
				var texture_rect_size = Vector2(texture_width, texture_height)
				
				if off_texture:
					var new_position = Vector2.RIGHT.rotated(deg_to_rad(90 * i)) * center_offset
					off_texture_rect.size = texture_rect_size
					off_texture_rect.position = (size * 0.5) + new_position - (texture_rect_size / 2.0)
				if on_texture:
					var new_position = Vector2.RIGHT.rotated(deg_to_rad(90 * i)) * center_offset
					on_texture_rect.size = texture_rect_size
					on_texture_rect.position = (size * 0.5) + new_position - (texture_rect_size / 2.0)

func get_hb_inspector_whitelist() -> Array:
	var whitelist := super.get_hb_inspector_whitelist()
	whitelist.append_array([
		"stylebox", "on_texture", "off_texture", "center_offset", "texture_width", "texture_height"
	])
	return whitelist

static func get_component_id() -> String:
	return "multi_hint"

static func get_component_name() -> String:
	return "Multi Note Hint"

func _get_property_list():
	var list := []
	register_texture_to_plist(list, "off_texture")
	register_texture_to_plist(list, "on_texture")
	register_subresource_to_plist(list, "stylebox")
	return list

func _ready():
	super._ready()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	for i in range(DIRECTIONS.size()):
		var direction := DIRECTIONS[i] as int
		var on_texture_rect := TextureRect.new()
		var off_texture_rect := TextureRect.new()
		off_texture_rect.expand = true
		on_texture_rect.expand = true
		on_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		off_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(off_texture_rect)
		off_texture_rect.hide()
		add_child(on_texture_rect)
		on_texture_rect.hide()
		directions_map[direction] = {}
		directions_map[direction]["off"] = off_texture_rect
		directions_map[direction]["on"] = on_texture_rect
		

	set_center_offset(center_offset)
	set_on_texture(on_texture)
	set_off_texture(off_texture)
	set_stylebox(stylebox)
	set_texture_height(texture_height)
	set_texture_width(texture_width)
	
	panel.connect("resized", Callable(self, "_on_panel_resized"))
	call_deferred("_on_panel_resized")
	directions_map[HBNoteData.NOTE_TYPE.UP].on.show()
	directions_map[HBNoteData.NOTE_TYPE.LEFT].on.show()
	directions_map[HBNoteData.NOTE_TYPE.RIGHT].off.show()
	directions_map[HBNoteData.NOTE_TYPE.DOWN].off.show()
	
func _to_dict(resource_storage: HBInspectorResourceStorage) -> Dictionary:
	var out_dict := super._to_dict(resource_storage)
	out_dict["on_texture"] = resource_storage.get_texture_name(on_texture)
	out_dict["off_texture"] = resource_storage.get_texture_name(off_texture)
	out_dict["stylebox"] = serialize_stylebox(stylebox, resource_storage)
	out_dict["center_offset"] = center_offset
	out_dict["texture_width"] = texture_width
	out_dict["texture_height"] = texture_height
	return out_dict

func _from_dict(dict: Dictionary, cache: HBSkinResourcesCache):
	super._from_dict(dict, cache)
	on_texture = cache.get_texture(dict.get("on_texture", ""))
	off_texture = cache.get_texture(dict.get("off_texture", ""))
	stylebox = deserialize_stylebox(dict.get("stylebox", {}), cache, stylebox)
	center_offset = dict.get("center_offset", center_offset)
	texture_height = dict.get("texture_height", texture_height)
	texture_width = dict.get("texture_width", texture_width)

func show_notes(notes):
	show()
	for direction in directions_map.values():
		direction.off.show()
		direction.on.hide()
	for note in notes:
		if note is HBBaseNote and note.note_type in directions_map:
			directions_map[note.note_type].on.show()
			directions_map[note.note_type].off.hide()
		else:
			hide()
			break

func _on_panel_resized():
	update_texture_rect_positions()
