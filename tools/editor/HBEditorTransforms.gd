extends MarginContainer

class_name HBEditorTransforms

class ArrangeTransformation:
	extends EditorTransformation
	
	var mode_info := {
		
	}
	
	var angle = 0.0
	var reverse := false
	var toggle_autoangle := false
	
	static func _order_timing_points(a: HBTimingPoint, b: HBTimingPoint):
		return a.time < b.time
	
	func get_time_as_eight(time: int) -> float:
		return editor.get_time_as_eight(time)
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		if not notes or notes.size() < 2:
			return {}
		
		notes.sort_custom(Callable(self, "_order_timing_points"))
		
		var separation: Vector2 = Vector2.ZERO
		var slide_separation: Vector2 = Vector2.ZERO
		var eight_separation = UserSettings.user_settings.editor_arrange_separation
		
		if angle != null:
			separation.x = eight_separation * cos(angle)
			separation.y = eight_separation * sin(angle)
			
			slide_separation.x = 32 * cos(angle)
			slide_separation.y = 32 * sin(angle)
			
			if not angle in [0.0, PI/2, PI, 3*PI/2]:
				var quadrant = 0
				if angle > PI and angle < 3*PI/2:
					quadrant = 1
				elif angle > PI/2 and angle < PI:
					quadrant = 2
				elif angle > 0 and angle < PI/2:
					quadrant = 3
				
				match mode_info.mode:
					HBUserSettings.EDITOR_ARRANGE_MODES.DISTANCE:
						separation.x = mode_info.diagonal_step.x
						separation.y = -mode_info.diagonal_step.y
						
						if quadrant in [1, 2]:
							separation.x = -separation.x
						if quadrant in [2, 3]:
							separation.y = -separation.y
					HBUserSettings.EDITOR_ARRANGE_MODES.FAKE_SLOPE:
						separation.x = eight_separation
						separation.y = -mode_info.vertical_step
						
						if quadrant in [1, 2]:
							separation.x = -separation.x
						if quadrant in [2, 3]:
							separation.y = -separation.y
			
			if reverse:
				separation = -separation
				slide_separation = -slide_separation
		
		# Never remove these, it makes the mikuphile mad
		var direction = Vector2.ZERO
		if abs(direction.x) > 0 and abs(direction.y) > 0:
			pass
		
		var pos_compensation: Vector2
		var time_compensation := 0
		var slide_index := 0
		
		var anchor = notes[0]
		if reverse:
			anchor = notes[-1]
			notes.reverse()
		
		pos_compensation = anchor.position
		time_compensation = anchor.time
		
		if anchor is HBSustainNote and reverse:
			time_compensation = anchor.end_time
		
		for note_data in notes:
			if note_data is HBBaseNote:
				# Real snapping hours
				var eight_diff = get_time_as_eight(note_data.time) - \
								 get_time_as_eight(time_compensation)
				
				if reverse and note_data is HBSustainNote:
					eight_diff = get_time_as_eight(note_data.end_time) - \
								 get_time_as_eight(time_compensation)
				
				if note_data is HBNoteData and note_data.is_slide_note():
					if slide_index > 1:
						eight_diff = max(1, eight_diff)
					
					slide_index = 1
				elif note_data is HBNoteData and slide_index and note_data.is_slide_hold_piece():
					slide_index += 1
				elif slide_index:
					if slide_index > 1:
						eight_diff = max(1, eight_diff)
					
					slide_index = 0
				
				var new_pos = pos_compensation + (separation * eight_diff)
				
				if note_data is HBNoteData and note_data.is_slide_hold_piece() and slide_index:
					if slide_index == 2:
						new_pos = pos_compensation + separation / 2
					else:
						new_pos = pos_compensation + slide_separation
				
				transformation_result[note_data] = {
					"position": new_pos,
				}
				
				pos_compensation = new_pos
				if note_data is HBSustainNote:
					if reverse:
						time_compensation = note_data.time
					else:
						time_compensation = note_data.end_time
				else:
					time_compensation = note_data.time
		
		var autoangle_enabled := UserSettings.user_settings.editor_auto_angle
		if toggle_autoangle:
			autoangle_enabled = not autoangle_enabled
		
		if autoangle_enabled:
			for i in range(notes.size()):
				var note_data = notes[i]
				
				if note_data is HBBaseNote:
					var _i = i
					if reverse:
						_i = -i - 1
					
					var new_angle_params = autoangle(notes[_i], transformation_result[notes[0]].position, angle, reverse)
					
					transformation_result[note_data]["entry_angle"] = new_angle_params[0]
					transformation_result[note_data]["oscillation_frequency"] = new_angle_params[1]
		
		return transformation_result
	
	func autoangle(note: HBBaseNote, new_pos: Vector2, arrange_angle, reverse: bool):
		if arrange_angle != null:
			var new_angle: float
			var oscillation_frequency = abs(note.oscillation_frequency)
			
			# Normalize the arrange angle to be between 0 and 2PI
			arrange_angle = fmod(fmod(arrange_angle, 2*PI) + 2*PI, 2*PI)
			
			# Get the quadrant and rotated quadrant
			var quadrant = int(arrange_angle / (PI/2.0))
			var rotated_quadrant = int((arrange_angle + PI/4.0) / (PI/2.0)) % 4
			
			new_angle = arrange_angle + PI/2.0
			
			if rotated_quadrant in [1, 3]:
				new_angle += PI if quadrant in [0, 1] else 0.0
				
				var left_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(0, 0), Vector2(0, 1080))
				var right_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(1920, 0), Vector2(1920, 1080))
				
				var left_distance = new_pos.distance_to(left_point)
				var right_distance = new_pos.distance_to(right_point)
				
				# Point towards closest side
				new_angle += PI if right_distance > left_distance else 0.0
			else:
				new_angle += PI if quadrant in [1, 2] else 0.0
				
				var top_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(0, 0), Vector2(1920, 0))
				var bottom_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(0, 1080), Vector2(1920, 1080))
				
				var top_distance = new_pos.distance_to(top_point)
				var bottom_distance = new_pos.distance_to(bottom_point)
				
				# Point towards furthest side
				new_angle += PI if top_distance > bottom_distance else 0.0
			
			var positive_quadrants = []
			
			if new_pos.x > 960:
				positive_quadrants.append(3)
			else:
				positive_quadrants.append(1)
			
			if new_pos.y > 540:
				positive_quadrants.append(2)
			else:
				positive_quadrants.append(0)
			
			var is_negative_quadrant = not rotated_quadrant in positive_quadrants
			var is_odd = fposmod(oscillation_frequency, 2.0) != 0
			
			if is_negative_quadrant:
				oscillation_frequency = -oscillation_frequency
			if is_odd:
				oscillation_frequency = -oscillation_frequency
			
			oscillation_frequency *= sign(note.oscillation_amplitude)
			if reverse:
				oscillation_frequency = -oscillation_frequency
			return [fmod(rad_to_deg(new_angle), 360.0), oscillation_frequency]
		else:
			return [note.entry_angle, note.oscillation_frequency]

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
		
		notes.reverse()
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
		
		var biggest := 1920
		var smallest := 0
		if local:
			notes.sort_custom(Callable(self, "_sort_by_x_pos"))
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
			notes.sort_custom(Callable(self, "_sort_by_y_pos"))
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
		notes.sort_custom(Callable(self, "_sort_by_x_pos"))
		
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
			final_pos = final_pos.rotated(deg_to_rad(rotation))
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
		var time_diff = editor.get_time_as_eight(a.time) - editor.get_time_as_eight(b.time)
		
		return time_diff
	
	func transform_notes(notes: Array):
		var transformation_result = {}
	
		notes.sort_custom(Callable(self, "_sort_by_time"))
		if backwards:
			notes.reverse()
		
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
			var min_angle = deg_to_rad(notes[0].entry_angle) as float
			var max_angle = deg_to_rad(notes[-1].entry_angle) as float
			
			var min_time = notes[0].time
			var max_time = notes[-1].time
			
			for note in notes:
				var t = 0
				if float(max_time - min_time) > 0:
					t = float(note.time - min_time) / float(max_time - min_time)
				
				var new_angle = rad_to_deg(lerp_angle(min_angle, max_angle, t))
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
	var separation := 96
	var eights_per_circle := 16
	var entry_angle_offset := 0.0
	# -1 for outside, 1 for inside
	var inside = -1
	
	func set_epr(_epr: int):
		self.eights_per_circle = _epr
	
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
		var time_offset = editor.get_time_as_eight(notes[0].time)
		
		var radius = separation * eights_per_circle / TAU
		var start_rev = 0.0
		var center = notes[0].position
		
		if center.y > 540:
			start_rev = 0.5
			center.y -= radius
		else:
			center.y += radius
		
		if not notes[0].pos_modified:
			center = Vector2(960, 540)
		
		var angle_offset = (start_rev + 0.75) * TAU
		
		for n in notes:
			# Time of the current note, as an eight
			var t = editor.get_time_as_eight(n.time) - time_offset - sustain_compensation
			
			# Compensate for sustain notes
			if n is HBSustainNote:
				sustain_compensation += editor.get_time_as_eight(n.end_time) - editor.get_time_as_eight(n.time)
			
			# Angle in the circle (in revolutions)
			var angle = t / float(eights_per_circle) * TAU
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

# Code by Steven
# Original comments:

# Catenary arcs will create a symmetric arc between two points A and B with a specific length L.
# This allows you to pick a starting and ending point that will snap to the grid while
# also keeping all note spacing proper based on the separation in beats. :D
# If the ratio between the distance of A and B and the length L of the line that connects
# them is sufficiently small, it will be very close to a large radius circular arrangement.
# If it isn't, it creates an effect that looks like a parabola.

# Extra comment by Lino:
# I have 0 clue how this works. It makes brain go melty.
# Thank god I didnt get into mathematics.
# Anyways, I changed the variables to be more descriptive and updated the code style.
# You are welcome, future me.
# - Lino, 26/07/23

class ArcInterpolationTransform:
	extends EditorTransformation

	### Configurable Constants
	const PRECISION = 1e-2  	# = 1/100th of a pixel
	const APPROX_START = 8192.0 # where approximation starts
	const MAX_ITERATIONS = 20   # to prevent crashing if an oopsie is made
	### ----------------------
	
	var direction: int  		# 1 = clockwise, -1 = counterclockwise
	var angle_direction: int    # 1 = outside, -1 = inside
	
	func _init(_direction: int, _angle_direction: int):
		self.direction = _direction
		self.angle_direction = _angle_direction
	
	static func _sort_by_time(a: HBBaseNote, b: HBBaseNote):
		return a.time < b.time
	
	func approximate_arc_constant(arc_length: float, max_distance: float) -> float:
		var arc_const: float = APPROX_START
		var k := arc_const / 2
		var error := arc_length - arc_const * sinh(max_distance / arc_const)
		
		var i := 0
		while abs(error) > PRECISION and i < MAX_ITERATIONS:
			arc_const -= sign(error) * k
			error = arc_length - arc_const * sinh(max_distance / arc_const)
			k /= 2
			
			i += 1
		
		return arc_const / 2.0

	func pos_around_arc(last_pos: float, distance: float, arc_const: float) -> Vector2:
		var x = arc_const * HBUtils.asinh((distance + arc_const * sinh(last_pos / arc_const)) / arc_const)
		var y = arc_const * cosh(x / arc_const)
		return Vector2(x, y)
	
	func angle_span(D: float, a: float) -> float:
		# finds the circle between A, B, & global_min (C)
		# returns the arc length of the circle between A & B
		var global_min = pos_around_arc(0.0, 0.0, a)
		var A = Vector2(-D/2, 0)
		var AC = A.distance_to(global_min)
		var radius = AC*AC/2/abs(global_min.y)
		var center = Vector2(0, sign(global_min.y)*radius + global_min.y)
		return abs(center.angle_to_point(A) - center.angle_to_point(global_min))*360.0/PI
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		for n in notes:
			if not n is HBBaseNote:
				notes.erase(n)
		notes.sort_custom(self._sort_by_time)
		
		if notes.size() < 3:
			return {}
		
		var new_freq := -2 * -self.direction * self.angle_direction
		
		var start: HBBaseNote = notes[0]
		var end: HBBaseNote = notes[-1]
		
		var eight_separation = UserSettings.user_settings.editor_arrange_separation
		
		var max_distance := float(start.position.distance_to(end.position))
		var beats: float = editor.get_length_in_beats(notes)
		var arc_length: float = beats * eight_separation
		
		# arc_length must be greater than a straight line between the start and end
		# if we dont cap it, it will crash
		if max_distance + eight_separation / 8 >= arc_length:
			max_distance = arc_length - eight_separation / 8
		
		var arc_const := approximate_arc_constant(arc_length, max_distance)
		var theta = PI + end.position.angle_to_point(start.position)
		
		var total_angle := deg_to_rad(angle_span(arc_length, arc_const) * 2.0)
		total_angle = max(total_angle, PI/2)
		
		var starting_angle := start.position.angle_to_point(end.position)
		starting_angle += self.direction * (self.angle_direction * PI/2 - total_angle * 0.5)
		var last_angle := starting_angle
		
		var last_beat: float = editor.get_time_as_eight(start.time)
		
		var last_pos := pos_around_arc(-max_distance / 2, 0.0, arc_const)
		var shift = -last_pos   # No idea tbh
		
		for i in notes.size():
			var n: HBBaseNote = notes[i]
			var current_beat: float = editor.get_time_as_eight(n.time)
			
			last_pos = pos_around_arc(last_pos.x, (current_beat - last_beat) * eight_separation, arc_const)
			
			var pos: Vector2 = ((last_pos + shift) * Vector2(1, self.direction)).rotated(theta)
			pos += start.position
			
			var angle: float = rad_to_deg(last_angle + self.direction * ((current_beat - last_beat) / beats) * total_angle)
			
			transformation_result[n] = {
				"position": pos,
				"entry_angle": fmod(angle + 360, 360),
				"oscillation_frequency": new_freq,
			}
			
			last_beat = current_beat
			if n is HBSustainNote:
				last_beat = editor.get_time_as_eight(n.end_time)
			
			last_angle = deg_to_rad(angle)
		
		return transformation_result

class MultiPresetTemplate:
	extends EditorTransformation
	
	var direction = 1
	
	var note_map = [HBNoteData.NOTE_TYPE.UP, HBNoteData.NOTE_TYPE.LEFT, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.RIGHT]
	
	enum GROUP_TYPE {
		ALL_NOTES,
		OPPOSING_SLIDES,
		SIMILAR_SLIDES,
		INVALID
	}
	
	func _init(dir):
		direction = dir
	
	static func sort_by_note_type(a: HBBaseNote, b: HBBaseNote) -> bool:
		return a.note_type < b.note_type
	
	static func sort_by_relative_type(a: HBBaseNote, b: HBBaseNote) -> bool:
		return a.get_meta("relative_type") < b.get_meta("relative_type")
	
	func check_group(group: Array) -> int:
		var type = null
		var last_slide_type = null
		
		for note in group:
			if note.note_type in note_map:
				if type and type != GROUP_TYPE.ALL_NOTES:
					return GROUP_TYPE.INVALID
				
				type = GROUP_TYPE.ALL_NOTES
			elif note is HBNoteData and note.is_slide_note():
				if type == GROUP_TYPE.ALL_NOTES:
					return GROUP_TYPE.INVALID
				
				if last_slide_type:
					if last_slide_type != note.note_type and group.size() == 2:
						type = GROUP_TYPE.OPPOSING_SLIDES
					else:
						type = GROUP_TYPE.SIMILAR_SLIDES
				
				last_slide_type = note.note_type
			else:
				return GROUP_TYPE.INVALID
		
		return type
	
	func check_note_is_valid(n: HBBaseNote) -> bool:
		if n is HBNoteData:
			return n.is_slide_note() or n.note_type in note_map
		
		return n.note_type in note_map
	
	func get_anchor(group: Array) -> HBBaseNote:
		group.sort_custom(Callable(self, "sort_by_note_type"))
		
		return group[0]
	
	func process_type(n: HBBaseNote, anchor: HBBaseNote, group_type: int) -> int:
		return 0
	
	func process_position(n: HBBaseNote, anchor: HBBaseNote) -> Vector2:
		var pos = anchor.position as Vector2
		pos.x = 240 + 480 * n.get_meta("relative_type")
		
		return pos
	
	func process_angle(n: HBBaseNote, notes_at_time: Array, group_type: int) -> float:
		var angle: float
		var type = n.get_meta("relative_type")
		
		if group_type == GROUP_TYPE.ALL_NOTES:
			if notes_at_time.size() == 2:
				var index = notes_at_time.find(n)
				
				angle = 110.0 if index == 0 else 70.0
			else:
				angle = 110.0 if type < 2 else 70.0
		elif group_type == GROUP_TYPE.OPPOSING_SLIDES:
			if notes_at_time.size() == 2:
				angle = 110.0 if type % 2 else 70.0
			else:
				angle = 110.0 if type >= 2 else 70.0
		elif group_type == GROUP_TYPE.SIMILAR_SLIDES:
			angle = 110.0 if type >= 2 else 70.0
		
		return angle
	
	func modify_angle(a: float) -> float:
		if direction == 1:
			return -a
		else:
			return a
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
		notes.sort_custom(Callable(self, "sort_by_note_type"))
		
		var note_groups := {}
		for note in notes:
			if not note_groups.has(note.time):
				note_groups[note.time] = []
			
			if note is HBBaseNote:
				note_groups[note.time].append(note)
		
		for time in note_groups.keys():
			var group = note_groups[time]
			var extended_group := []
			
			for note in get_notes_at_time(time):
				if not check_note_is_valid(note):
					continue
				
				extended_group.append(note)
			
			var group_type := check_group(extended_group)
			if extended_group.size() == 1 or group_type == GROUP_TYPE.INVALID:
				continue
			
			var anchor = get_anchor(group)
			
			for note in extended_group:
				var type = process_type(note, anchor, group_type)
				note.set_meta("relative_type", type)
			
			extended_group.sort_custom(Callable(self, "sort_by_relative_type"))
			
			for note in extended_group:
				var pos = process_position(note, anchor)
				
				var angle = process_angle(note, extended_group, group_type)
				
				angle = modify_angle(angle)
				
				transformation_result[note] = {
					"position": pos,
					"entry_angle": angle,
					"oscillation_frequency": 0.0,
					"distance": 880
				}
		
		return transformation_result

class VerticalMultiPreset:
	extends MultiPresetTemplate
	
	func _init(dir):
		super(dir)
		pass
	
	func process_type(n: HBBaseNote, anchor: HBBaseNote, group_type: int) -> int:
		var relative_type = n.note_type - anchor.note_type
		
		if n.get_meta("second_layer", false) and not anchor.get_meta("second_layer", false):
			relative_type += 2
		elif not n.get_meta("second_layer", false) and anchor.get_meta("second_layer", false):
			relative_type -= 2
		
		return relative_type
	
	func process_position(n: HBBaseNote, anchor: HBBaseNote) -> Vector2:
		var pos = anchor.position as Vector2
		pos.y += 96 * n.get_meta("relative_type")
		
		return pos
	
	func process_angle(n: HBBaseNote, group: Array, group_type: int) -> float:
		var angle: float
			
		if group.size() == 2:
			var index = group.find(n)
			
			angle = -45.0 if index == 0 else 45.0
		else:
			var sum = 0
			for note in group:
				sum += note.get_meta("relative_type")
			
			var average = sum / group.size()
			angle = -45.0 if n.get_meta("relative_type") <= average else 45.0
		
		return angle
	
	func modify_angle(a: float) -> float:
		if self.direction == -1:
			a = fmod((-a + 180.0), 360.0)
		
		return a

class StraightVerticalMultiPreset:
	extends VerticalMultiPreset
	
	func _init(dir = 1):
		super(dir)
		pass
	
	func check_group(group: Array) -> int:
		if group.size() > 2:
			return GROUP_TYPE.INVALID
		
		return super.check_group(group)
	
	func modify_angle(a: float) -> float:
		if a > 180.0 or a < 0:
			return 270.0
		
		return 90.0

class HorizontalMultiPreset:
	extends MultiPresetTemplate
	
	func _init(dir):
		super(dir)
		pass
	
	func process_type(n: HBBaseNote, anchor: HBBaseNote, group_type: int) -> int:
		var type := 0
		
		if group_type == GROUP_TYPE.ALL_NOTES:
			type = note_map.find(n.note_type)
		elif group_type == GROUP_TYPE.OPPOSING_SLIDES:
			if n.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
				type = 2
				
				if n.get_meta("second_layer", false):
					type -= 2
			elif n.note_type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
				type = 1
				
				if n.get_meta("second_layer", false):
					type += 2
			
		elif group_type == GROUP_TYPE.SIMILAR_SLIDES:
			if n.get_meta("second_layer", false):
				type += 1
			
			if n.note_type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT:
				type += 2
		
		return type

class DiagonalMultiPreset:
	extends HorizontalMultiPreset
	
	func _init(dir = 1):
		super(dir)
		pass
	
	func check_group(group: Array) -> int:
		if group.size() > 2:
			return GROUP_TYPE.INVALID
		
		return super.check_group(group)
	
	static func get_center_distance(position: Vector2) -> float:
		return abs(540 - position.y)
	
	static func sort_by_center_distance(a: HBBaseNote, b: HBBaseNote) -> bool:
		return get_center_distance(a.position) > get_center_distance(b.position)
	
	func get_anchor(group: Array) -> HBBaseNote:
		group.sort_custom(Callable(self, "sort_by_center_distance"))
		
		return group[0]
	
	func process_position(n: HBBaseNote, anchor: HBBaseNote) -> Vector2:
		var pos := n.position
		pos.x = 240 + 480 * n.get_meta("relative_type")
		
		if n != anchor:
			pos.y = 1080 - anchor.position.y
		
		n.set_meta("new_pos", pos)
		return pos
	
	func process_angle(n: HBBaseNote, group: Array, group_type: int) -> float:
		var anchor = group[0]
		var other = group[1]
		
		var anchor_x = 240 + 480 * anchor.get_meta("relative_type")
		var other_x = 240 + 480 * other.get_meta("relative_type")
		var center = Vector2((anchor_x + other_x) / 2.0, 540)
		
		return 180 - rad_to_deg(center.angle_to_point(n.get_meta("new_pos")))

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
				for note in get_notes_at_time(time):
					if note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
						extended_group.append(note)
				
				if extended_group.size() != 4:
					continue
			
			note_groups[time].sort_custom(Callable(self, "sort_by_center_distance"))
			
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
				for note in get_notes_at_time(time):
					if note.note_type in [HBBaseNote.NOTE_TYPE.UP, HBBaseNote.NOTE_TYPE.DOWN, HBBaseNote.NOTE_TYPE.LEFT, HBBaseNote.NOTE_TYPE.RIGHT]:
						extended_group.append(note)
				
				if extended_group.size() != 4:
					continue
			
			note_groups[time].sort_custom(Callable(self, "sort_by_distance"))
			
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
				for note in get_notes_at_time(time):
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
			
			note_groups[time].sort_custom(Callable(self, "sort_by_distance"))
			
			var distance := 276.0
			for note in note_groups[time]:
				if note.pos_modified and check_area(note.note_type, note.position):
					distance = get_distance(note.note_type, note.position)
					break
			
			if extended_group:
				note_groups[time] = extended_group
			
			note_groups[time].sort_custom(Callable(self, "sort_by_note_type"))
			
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
