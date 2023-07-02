extends TextureRect

const hold_hint_on_texture = preload("res://graphics/hold_hint_button_on.png")
const hold_hint_off_texture = preload("res://graphics/hold_hint_button_off.png")

var directions_map = {}
const CENTER_OFFSET = 70
func _ready():
	var directions = [HBNoteData.NOTE_TYPE.RIGHT, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.LEFT, HBNoteData.NOTE_TYPE.UP]
	hide()
	for i in range(directions.size()):
		var direction = directions[i]
		var off_texture_rect = TextureRect.new()
		add_child(off_texture_rect)
		off_texture_rect.texture = hold_hint_off_texture
		off_texture_rect.pivot_offset = hold_hint_off_texture.get_size() / 2.0
		var new_position = Vector2.RIGHT.rotated(deg_to_rad(90 * i)) * CENTER_OFFSET
		off_texture_rect.position = new_position
		
		var on_texture_rect = TextureRect.new()
		add_child(on_texture_rect)
		on_texture_rect.texture = hold_hint_on_texture
		on_texture_rect.pivot_offset = hold_hint_on_texture.get_size() / 2.0
		new_position = Vector2.RIGHT.rotated(deg_to_rad(90 * i)) * CENTER_OFFSET
		on_texture_rect.position = new_position
		
		directions_map[direction] = {}
		directions_map[direction]["off"] = off_texture_rect
		directions_map[direction]["on"] = on_texture_rect
		
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
			
