extends MarginContainer

class_name HBEditorTransforms

signal show_transform(transformation)
signal hide_transform()
signal apply_transform(transformation)

onready var vertical_transform

onready var button_container = get_node("ScrollContainer/SyncButtonContainer")

var use_stage_center := false setget set_use_stage_center

var editor: HBEditor

func set_use_stage_center(val):
	use_stage_center = val
	editor.song_editor_settings.set("transforms_use_center", val)

class FlipHorizontallyTransformation:
	extends EditorTransformation
	
	var local := false
	
	const note_type_change_map = {
		HBBaseNote.NOTE_TYPE.SLIDE_LEFT: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT,
		HBBaseNote.NOTE_TYPE.SLIDE_RIGHT: HBBaseNote.NOTE_TYPE.SLIDE_LEFT,
		HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT: HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT,
		HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT: HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT,
	}
	
	func _init(_local: bool = false):
		local = _local
	
	func _sort_by_x_pos(a: HBBaseNote, b: HBBaseNote):
		return a.position.x > b.position.x
	
	func _get_chains(notes: Array):
		var chains = []
		var current_chain = []
		
		notes.invert()
		for note in notes:
			if note is HBNoteData:
				if note.is_slide_note():
					if current_chain.size() >= 1:
						chains.append(current_chain)
					current_chain = [note]
				elif note.is_slide_hold_piece():
					if current_chain.size() > 0:
						current_chain.append(note)
		if current_chain.size() > 0:
			chains.append(current_chain)
		return chains
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		if not notes:
			return {}
		
		for n in notes:
			if not n is HBBaseNote:
				notes.erase(n)
		
		var chains = _get_chains(notes)
		
		var biggest := 1920
		var smallest := 0
		if local:
			notes.sort_custom(self, "_sort_by_x_pos")
			biggest = notes[-1].position.x
			smallest = notes[0].position.x
		
		for n in notes:
			var note = n as HBBaseNote
			var note_type = note_type_change_map[n.note_type] if n.note_type in note_type_change_map else n.note_type
			
			transformation_result[n] = {
				"position": Vector2(biggest - note.position.x + smallest, note.position.y),
				"entry_angle": fmod((180 - note.entry_angle), 360),
				"oscillation_frequency": -note.oscillation_frequency,
				"note_type": note_type
			}
		
		return transformation_result

class FlipVerticallyTransformation:
	extends EditorTransformation
	
	var local := false
	
	func _init(_local: bool = false):
		local = _local
	
	func _sort_by_y_pos(a: HBBaseNote, b: HBBaseNote):
		return a.position.y > b.position.y
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		if not notes:
			return {}
		
		for n in notes:
			if not n is HBBaseNote:
				notes.erase(n)
		
		var biggest := 1080
		var smallest := 0
		if local:
			notes.sort_custom(self, "_sort_by_y_pos")
			biggest = notes[-1].position.y
			smallest = notes[0].position.y
		
		for n in notes:
			var note = n as HBBaseNote
			transformation_result[n] = {
				"position": Vector2(note.position.x, biggest - note.position.y + smallest),
				"entry_angle": -note.entry_angle,
				"oscillation_frequency": -note.oscillation_frequency
			}
		return transformation_result

class RotateTransformation:
	extends EditorTransformation
	
	enum {
		PIVOT_MODE_RELATIVE_CENTER,
		PIVOT_MODE_RELATIVE_LEFT,
		PIVOT_MODE_RELATIVE_RIGHT,
		PIVOT_MODE_ABSOLUTE,
	}
	
	var rotation = 0.0
	var pivot_mode = PIVOT_MODE_RELATIVE_CENTER
	
	func _init(_pivot_mode):
		self.pivot_mode = _pivot_mode
	
	func _sort_by_x_pos(a: HBBaseNote, b: HBBaseNote):
		return a.position.x < b.position.x
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		if not notes:
			return {}
		
		for n in notes:
			if not n is HBBaseNote:
				notes.erase(n)
		notes.sort_custom(self, "_sort_by_x_pos")
		
		var center: Vector2
		if pivot_mode == PIVOT_MODE_RELATIVE_CENTER:
			center = get_center_for_notes(notes)
		if pivot_mode == PIVOT_MODE_RELATIVE_LEFT:
			center = notes[0].position
		if pivot_mode == PIVOT_MODE_RELATIVE_RIGHT:
			center = notes[-1].position
		elif pivot_mode == PIVOT_MODE_ABSOLUTE:
			center = Vector2(1920, 1080) / 2.0
		
		for n in notes:
			var final_pos = n.position as Vector2
			final_pos = final_pos - center
			final_pos = final_pos.rotated(deg2rad(rotation))
			final_pos += center
			transformation_result[n] = {
				"position": final_pos,
				"entry_angle": fmod(n.entry_angle + rotation, 360)
			}
		
		return transformation_result

class IncrementAnglesTransform:
	extends EditorTransformation
	
	var backwards: bool
	var invert: bool
	
	var straight_increment: int
	var diagonal_increment: int
	
	func _init(_backwards: bool = false, _invert: bool = false):
		backwards = _backwards
		invert = _invert
	
	func _sort_by_time(a: HBBaseNote, b: HBBaseNote):
		return a.time < b.time
	
	func get_beat_diff(a: HBBaseNote, b: HBBaseNote):
		var timing_map = editor.get_normalized_timing_map()
		var time_diff = editor._linear_bound(timing_map, a.time) - editor._linear_bound(timing_map, b.time)
		
		return time_diff
	
	func transform_notes(notes: Array):
		var transformation_result = {}
	
		notes.sort_custom(self, "_sort_by_time")
		if backwards:
			notes.invert()
		
		if notes.size() > 1:
			var previous_note := notes[0] as HBBaseNote
			var previous_angle = notes[0].entry_angle
			var reference_angle = int(fmod(notes[0].entry_angle + 360, 360.0))
			transformation_result[previous_note] = {}
			
			for i in range(1, notes.size()):
				var note = notes[i] as HBBaseNote
				var beat_diff = get_beat_diff(note, previous_note)
				
				var increment = diagonal_increment * beat_diff
				if note.position.x == previous_note.position.x or note.position.y == previous_note.position.y:
					increment = straight_increment * beat_diff
				
				# Figure out if we should increase or decrease the angle
				if note.position.x < previous_note.position.x:
					increment *= -1
				if reference_angle < 180:
					increment *= -1
				if invert:
					increment *= -1
				
				transformation_result[note] = {
					"entry_angle": int(fmod(previous_angle + increment, 360.0))
				}
				
				previous_note = note
				previous_angle = int(fmod(previous_angle + increment + 360, 360.0))
		
		return transformation_result

class InterpolateAngleTransform:
	extends EditorTransformation
		
	func transform_notes(notes: Array):
		var transformation_result = {}
		if notes.size() > 2:
			var min_angle = deg2rad(notes[0].entry_angle) as float
			var max_angle = deg2rad(notes[-1].entry_angle) as float
			
			var min_time = notes[0].time
			var max_time = notes[-1].time
			
			for note in notes:
				var t = 0
				if float(max_time - min_time) > 0:
					t = float(note.time - min_time) / float(max_time - min_time)
				
				var new_angle = rad2deg(lerp_angle(min_angle, max_angle, t))
				new_angle = fmod(new_angle + 360, 360.0)
				transformation_result[note] = {
					"entry_angle": new_angle
				}
		
		return transformation_result

class InterpolateDistanceTransform:
	extends EditorTransformation
		
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		if notes.size() > 2:
			var min_distance = notes[-1].distance as float
			var max_distance = notes[0].distance as float
			
			var min_time = notes[-1].time
			var max_time = notes[0].time
			
			for note in notes:
				var t = 0
				if float(max_time - min_time) > 0:
					t = (note.time - min_time) / float(max_time - min_time)
				
				var new_distance = lerp(min_distance, max_distance, t)
				
				transformation_result[note] = {
					"distance": new_distance
				}
		
		return transformation_result

class FlipAngleTransform:
	extends EditorTransformation
		
	func transform_notes(notes: Array):
		var transformation_result = {}

		for note in notes:
			transformation_result[note] = {
				"entry_angle": fmod(note.entry_angle + 180.0, 360.0),
				"oscillation_frequency": -note.oscillation_frequency
			}
		
		return transformation_result

class FlipOscillationTransform:
	extends EditorTransformation
		
	func transform_notes(notes: Array):
		var transformation_result = {}

		for note in notes:
			transformation_result[note] = {
				"oscillation_frequency": -note.oscillation_frequency
			}
		
		return transformation_result

class MakeCircleTransform:
	extends EditorTransformation
	
	var direction: int
	var separation := 96 setget set_separation
	var eigths_per_circle := 16 setget set_epr
	var entry_angle_offset := 0.0
	var start_note := 0 setget set_start_note
	# -1 for outside, 1 for inside
	var inside = -1 setget set_inside
	
	func set_separation(val):
		separation = val
	
	func set_epr(val):
		eigths_per_circle = val
	
	func set_start_note(val):
		start_note = val
	
	func set_inside(val):
		if val:
			entry_angle_offset = 0.5 * TAU
			inside = 1
		else:
			entry_angle_offset = 0
			inside = -1
	
	func _init(_direction: int, _inside: bool = false):
		direction = _direction
		
		if _inside:
			entry_angle_offset = 0.5 * TAU
			inside = 1
		else:
			entry_angle_offset = 0
			inside = -1
	
	# Revolutions to degrees
	func rev2deg(revs):
		return revs * TAU / 360
	
	func transform_notes(notes: Array):
		if not notes:
			return {}
		
		var transformation_result = {}
		
		var sustain_compensation = 0
		var time_offset
		
		var radius = separation * eigths_per_circle / TAU
		var start_rev = 0.0
		var center
		
		var normalized_timing_map = editor.get_normalized_timing_map()
		
		if start_note < notes.size():
			time_offset = editor._linear_bound(normalized_timing_map, notes[start_note].time)
			center = notes[start_note].position
		else:
			time_offset = editor._linear_bound(normalized_timing_map, notes[0].time)
			center = notes[0].position
		
		if center.y > 540:
			start_rev = 0.5
			center.y -= radius
		else:
			center.y += radius
		
		var angle_offset = (start_rev + 0.75) * TAU
		
		for n in notes:
			# Time of the current note, as an eight
			var t = editor._linear_bound(normalized_timing_map, n.time) - time_offset - sustain_compensation
			
			# Compensate for sustain notes
			if n is HBSustainNote:
				sustain_compensation += editor._linear_bound(normalized_timing_map, n.end_time) - editor._linear_bound(normalized_timing_map, n.time)
			
			# Angle in the circle (in revolutions)
			var angle = t / float(eigths_per_circle) * TAU
			angle *= direction
			angle += angle_offset
			
			# Position of the note
			var pos = Vector2((cos(angle) * radius) + center.x, (sin(angle) * radius) + center.y)
			
			var entry_angle = (angle + entry_angle_offset) / TAU * 360
			
			# Populate the transformation matrix
			transformation_result[n] = {
				"position": pos,
				"entry_angle": fmod(entry_angle, 360),
				"oscillation_frequency": abs(n.oscillation_frequency) * direction * inside
			}
		
		return transformation_result

class MultiPresetTemplate:
	extends EditorTransformation
	
	var direction = 1
	
	func _init(dir):
		direction = dir
	
	func get_notes_at_time(t: int):
		var points = editor.get_notes_at_time(t)
		var result = []
		
		for point in points:
			if point is HBBaseNote:
				result.append(point)
		
		return result
	
	static func sort_by_note_type(a, b):
		return a.note_type < b.note_type
	
	func check_note_is_valid(n):
		pass
	
	func process_type(n, notes):
		pass
	
	func process_position(n, type, notes):
		var pos = notes[0].position as Vector2
		pos.x = 240 + 480 * type
		
		return pos
	
	func modify_angle(a):
		if direction == 1:
			return -a
		else:
			return a
	
	func process_angle(n, type, notes_at_time):
		var angle: float
			
		if notes_at_time.size() == 2:
			var index = notes_at_time.find(n)
			
			angle = 110.0 if index == 0 else 70.0
		else:
			angle = 110.0 if type < 2 else 70.0
		
		return angle
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		notes.sort_custom(self, "sort_by_note_type")
		
		for n in notes:
			if not check_note_is_valid(n):
				continue
			
			var notes_at_time = get_notes_at_time(n.time)
			notes_at_time.sort_custom(self, "sort_by_note_type")
			
			if notes_at_time.size() == 1:
				continue
			
			var type = process_type(n, notes)
			
			var pos = process_position(n, type, notes_at_time)
			
			var angle = process_angle(n, type, notes_at_time)
			
			angle = modify_angle(angle)
			
			transformation_result[n] = {
				"position": pos,
				"entry_angle": angle,
				"oscillation_frequency": 0.0,
				"distance": 880
			}
		
		return transformation_result

class VerticalMultiPreset:
	extends MultiPresetTemplate
	
	var note_map = [HBNoteData.NOTE_TYPE.UP, HBNoteData.NOTE_TYPE.LEFT, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.RIGHT]
	
	func _init(dir).(dir):
		pass
	
	func check_note_is_valid(n):
		return n.note_type in note_map
	
	func process_type(n, notes):
		var pos = Vector2(n.position.x, notes[0].position.y)
		var relative_type = n.note_type - notes[0].note_type
		
		return relative_type
	
	func process_position(n, type, notes):
		var pos = Vector2(notes[0].position.x, notes[0].position.y)
		pos.y += 96 * type
		
		return pos
	
	func process_angle(n, type, notes_at_time):
		var angle: float
			
		if notes_at_time.size() == 2:
			var index = notes_at_time.find(n)
			
			angle = -45.0 if index == 0 else 45.0
		else:
			angle = -45.0 if type < 2 else 45.0
		
		return angle
	
	func modify_angle(a):
		if self.direction == -1:
			a = fmod((-a + 180.0), 360.0)
		
		return a

class HorizontalMultiPreset:
	extends MultiPresetTemplate
	
	var note_map = [HBNoteData.NOTE_TYPE.UP, HBNoteData.NOTE_TYPE.LEFT, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.RIGHT]
	
	func _init(dir).(dir):
		pass
	
	func check_note_is_valid(n):
		return n.note_type in note_map
	
	func process_type(n, notes):
		return note_map.find(n.note_type)

class SliderMultiPreset:
	extends MultiPresetTemplate
	
	# Dont ask
	var note_map_normal = [0, 1, 3, 2]
	var note_map_inner = [3, 2, 0, 1]
	var note_map
	var inner = 0
	
	func _init(dir, inr).(dir):
		inner = inr
		note_map = note_map_inner if inner else note_map_normal
	
	func check_note_is_valid(n):
		return n.is_slide_note()
	
	func process_type(n, notes):
		var point
		for p in editor.selected:
			if p.data == n:
				point = p
				break
		
		var layer = 1 if "2" in point._layer.layer_name else 0
		
		var type = (n.note_type - 4) * 2
		type += layer
		
		var index = note_map.find(type)
		
		return index
	
	func process_angle(n, type, notes_at_time):
		return 110.0 if type < 2 else 70.0
	
	func modify_angle(a):
		if direction == 1:
			a = -a
		
		if inner:
			return a
		else:
			return fmod((-a + 180), 360)

class QuadPreset:
	extends EditorTransformation
	
	var inside := false
	
	func _init(_inside: bool = false):
		inside = _inside
	
	static func sort_by_center_distance(a, b):
		return a.position.distance_to(Vector2(960, 540)) > b.position.distance_to(Vector2(960, 540))
	
	func check_corner(note_type, position: Vector2):
		if note_type == HBBaseNote.NOTE_TYPE.UP:
			return position.x < 960 and position.y < 540
		if note_type == HBBaseNote.NOTE_TYPE.LEFT:
			return position.x > 960 and position.y < 540
		if note_type == HBBaseNote.NOTE_TYPE.DOWN:
			return position.x < 960 and position.y > 540
		if note_type == HBBaseNote.NOTE_TYPE.RIGHT:
			return position.x > 960 and position.y > 540
		
		return false
	
	func get_position(note_type, anchor: Vector2):
		if note_type == HBBaseNote.NOTE_TYPE.UP:
			return anchor
		if note_type == HBBaseNote.NOTE_TYPE.LEFT:
			return Vector2(1920 - anchor.x, anchor.y)
		if note_type == HBBaseNote.NOTE_TYPE.DOWN:
			return Vector2(anchor.x, 1080 - anchor.y)
		if note_type == HBBaseNote.NOTE_TYPE.RIGHT:
			return Vector2(1920, 1080) - anchor
		
		return null
	
	func get_anchor(note_type, position: Vector2):
		if note_type == HBBaseNote.NOTE_TYPE.UP:
			return position
		if note_type == HBBaseNote.NOTE_TYPE.LEFT:
			return Vector2(1920 - position.x, position.y)
		if note_type == HBBaseNote.NOTE_TYPE.DOWN:
			return Vector2(position.x, 1080 - position.y)
		if note_type == HBBaseNote.NOTE_TYPE.RIGHT:
			return Vector2(1920, 1080) - position
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		var note_groups = {}
		for note in notes:
			if not note_groups.has(note.time):
				note_groups[note.time] = []
			
			if note is HBBaseNote and note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
				note_groups[note.time].append(note)
		
		for time in note_groups.keys():
			var extended_group = []
			
			if note_groups[time].size() < 4:
				for note in editor.get_notes_at_time(time):
					if note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
						extended_group.append(note)
				
				if extended_group.size() != 4:
					continue
			
			note_groups[time].sort_custom(self, "sort_by_center_distance")
			
			var anchor := Vector2(240, 240)
			for note in note_groups[time]:
				if note.pos_modified and check_corner(note.note_type, note.position):
					anchor = get_anchor(note.note_type, note.position)
					break
			
			if extended_group:
				note_groups[time] = extended_group
			
			for note in note_groups[time]:
				var pos = get_position(note.note_type, anchor)
				
				var angle = 225 + 90 * note.note_type
				if note.note_type in [HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.RIGHT]:
					angle = 315 - 90 * note.note_type
				
				if inside:
					angle += 180
				
				if pos:
					transformation_result[note] = {
						"position": pos,
						"entry_angle": angle,
						"oscillation_frequency": 0.0,
						"distance": 1360 if inside else 880
					}
		
		return transformation_result

class SidewaysQuadPreset:
	extends EditorTransformation
	
	func sort_by_distance(a, b):
		return get_distance(a.note_type, a.position) > get_distance(b.note_type, b.position)
	
	func check_area(note_type, position: Vector2):
		if note_type == HBBaseNote.NOTE_TYPE.UP:
			return position.y < 540
		if note_type == HBBaseNote.NOTE_TYPE.LEFT:
			return position.x < 960
		if note_type == HBBaseNote.NOTE_TYPE.DOWN:
			return position.y > 540
		if note_type == HBBaseNote.NOTE_TYPE.RIGHT:
			return position.x > 960
		
		return false
	
	func get_distance(note_type, position: Vector2):
		if note_type == HBBaseNote.NOTE_TYPE.UP:
			return 540 - position.y
		if note_type == HBBaseNote.NOTE_TYPE.LEFT:
			return 960 - position.x
		if note_type == HBBaseNote.NOTE_TYPE.DOWN:
			return position.y - 540
		if note_type == HBBaseNote.NOTE_TYPE.RIGHT:
			return position.x - 960
	
	func get_position(note_type, distance: float):
		if note_type == HBBaseNote.NOTE_TYPE.UP:
			return Vector2(960, 540 - distance)
		if note_type == HBBaseNote.NOTE_TYPE.LEFT:
			return Vector2(960 - distance, 540)
		if note_type == HBBaseNote.NOTE_TYPE.DOWN:
			return Vector2(960, 540 + distance)
		if note_type == HBBaseNote.NOTE_TYPE.RIGHT:
			return Vector2(960 + distance, 540)
		
		return null
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		var note_groups = {}
		for note in notes:
			if not note_groups.has(note.time):
				note_groups[note.time] = []
			
			if note is HBBaseNote and note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
				note_groups[note.time].append(note)
		
		for time in note_groups.keys():
			var extended_group = []
			
			if note_groups[time].size() < 4:
				for note in editor.get_notes_at_time(time):
					if note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
						extended_group.append(note)
				
				if extended_group.size() != 4:
					continue
			
			note_groups[time].sort_custom(self, "sort_by_distance")
			
			var distance := 216.0
			for note in note_groups[time]:
				if note.pos_modified and check_area(note.note_type, note.position):
					distance = get_distance(note.note_type, note.position)
					break
			
			if extended_group:
				note_groups[time] = extended_group
			
			for note in note_groups[time]:
				var pos = get_position(note.note_type, distance)
				
				var angle = 90 * (note.note_type - 1)
				if note.note_type in [HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
					angle = 180 - angle
				
				if pos:
					transformation_result[note] = {
						"position": pos,
						"entry_angle": angle,
						"oscillation_frequency": 0.0,
						"distance": 960
					}
		
		return transformation_result


class TrianglePreset:
	extends EditorTransformation
	
	var inverted: bool
	var left: bool  	# Ugly "global" var hack, beware future me 
	
	func _init(_inverted: bool = false):
		inverted = _inverted
	
	func sort_by_distance(a, b):
		return get_distance(a.note_type, a.position) > get_distance(b.note_type, b.position)
	
	func sort_by_note_type(a, b):
		return a.note_type < b.note_type
	
	func check_area(note_type, position: Vector2):
		var in_area: bool
		var notes_bottom = [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN] if self.left else [HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]
		var notes_top = [HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT] if self.left else [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN]
		
		if note_type in notes_bottom:
			in_area = position.y > 540
		elif note_type in notes_top:
			in_area = position.y < 540
		
		if self.inverted:
			in_area = not in_area
		
		return in_area
	
	func get_distance(note_type, position: Vector2):
		var distance: int
		var notes_bottom = [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN] if self.left else [HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]
		var notes_top = [HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT] if self.left else [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN]
		
		if note_type in notes_bottom:
			distance = (position.y - 540)
		elif note_type in notes_top:
			distance = (540 - position.y)
		
		if self.inverted:
			distance = -distance
		
		return distance
	
	func get_position(note_type, distance: float):
		var notes_bottom = [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN] if self.left else [HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]
		var notes_top = [HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT] if self.left else [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN]
		var position = Vector2(240 + 480 * note_type, 0)
		
		if self.inverted:
			distance = -distance
		
		if note_type in notes_bottom:
			position.y = 540 + distance
		elif note_type in notes_top:
			position.y = 540 - distance
		
		return position
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		var note_groups = {}
		for note in notes:
			if not note_groups.has(note.time):
				note_groups[note.time] = []
			
			if note is HBBaseNote and note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
				note_groups[note.time].append(note)
		
		for time in note_groups.keys():
			var extended_group = []
			
			if note_groups[time].size() < 3:
				for note in editor.get_notes_at_time(time):
					if note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
						extended_group.append(note)
				
				if extended_group.size() != 3:
					continue
			
			var note_types := []
			if extended_group:
				for note in extended_group:
					note_types.append(note.note_type)
			else:
				for note in note_groups[time]:
					note_types.append(note.note_type)
			
			if HBBaseNote.NOTE_TYPE.UP in note_types and HBBaseNote.NOTE_TYPE.LEFT in note_types and HBBaseNote.NOTE_TYPE.DOWN in note_types:
				self.left = true
			else:
				self.left = false
			
			note_groups[time].sort_custom(self, "sort_by_distance")
			
			var distance := 276.0
			for note in note_groups[time]:
				if note.pos_modified and check_area(note.note_type, note.position):
					distance = get_distance(note.note_type, note.position)
					break
			
			if extended_group:
				note_groups[time] = extended_group
			
			note_groups[time].sort_custom(self, "sort_by_note_type")
			
			for i in range(note_groups[time].size()):
				var note = note_groups[time][i] as HBBaseNote
				
				var pos = get_position(note.note_type, distance)
				var angle = 135 * (i + 1)
				
				if inverted:
					angle *= -1
				
				if pos:
					transformation_result[note] = {
						"position": pos,
						"entry_angle": angle,
						"oscillation_frequency": 0.0,
						"distance": 880
					}
		
		return transformation_result
