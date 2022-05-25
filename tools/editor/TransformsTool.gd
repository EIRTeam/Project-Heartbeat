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
	
	func _sort_by_y_pos(a: HBBaseNote, b: HBBaseNote):
		return a.position.y > b.position.y
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		
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

class InterpolatePositionsTransform:
	extends EditorTransformation
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		if notes.size() > 2:
			var min_position = notes[-1].position as Vector2
			var max_position = notes[0].position as Vector2
			var min_time = notes[-1].time
			var max_time = notes[0].time
			for note in notes:
				var new_pos = note.position as Vector2
				var t = 0
				if float(max_time-min_time) > 0:
					t = (note.time - min_time) / float(max_time - min_time)
				new_pos = min_position.linear_interpolate(max_position, t)
				transformation_result[note] = {
					"position": new_pos
				}
		return transformation_result
		
class InterpolateAngleTransform:
	extends EditorTransformation
		
	func transform_notes(notes: Array):
		var transformation_result = {}
		if notes.size() > 2:
			var min_angle = notes[-1].entry_angle as float
			var max_angle = notes[0].entry_angle as float
			min_angle = fmod(min_angle + 360, 360.0)
			max_angle = fmod(max_angle + 360, 360.0)
			
			var min_time = notes[-1].time
			var max_time = notes[0].time
			
			for note in notes:
				var t = 0
				if float(max_time-min_time) > 0:
					t = (note.time - min_time) / float(max_time - min_time)
				
				var new_angle = lerp(min_angle, max_angle, t)
				new_angle = fmod(new_angle + 360, 360.0)
				transformation_result[note] = {
					"entry_angle": new_angle
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

class MakeCircleTransform:
	extends EditorTransformation
	
	var direction: int
	var separation := 96 setget set_separation
	var eigths_per_circle := 16 setget set_epr
	var entry_angle_offset := 0.0
	var start_note := 0 setget set_start_note
	# -1 for outside, 1 for inside
	var inside = -1
	
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
	
	func _init(_direction: int):
		direction = _direction
	
	# Revolutions to degrees
	func rev2deg(revs):
		return revs * TAU / 360
	
	func transform_notes(notes: Array):
		notes.invert()
		
		var transformation_result = {}
		
		var sustain_compensation = 0
		var time_offset
		
		var radius = separation * eigths_per_circle / TAU
		var start_rev = 0.0
		var center
		
		if start_note < notes.size():
			time_offset = notes[start_note].time if notes else 0
			center = notes[start_note].position
		else:
			time_offset = notes[notes.size() - 1].time if notes else 0
			center = notes[notes.size() - 1].position
		
		if center.y > 540:
			start_rev = 0.5
			center.y -= radius
		else:
			center.y += radius
		
		var angle_offset = (start_rev + 0.75) * TAU
		var beats_per_circle = ceil(eigths_per_circle / 2.0)
		var ms_per_beat = 60 * 1000 / bpm
		
		for n in notes:
			# Beat of the current note
			var t = n.time - time_offset - sustain_compensation
			var beat = t / ms_per_beat
			
			# Compensate for sustain notes
			if n is HBSustainNote:
				sustain_compensation += n.end_time - n.time
			
			# Angle in the circle (in revolutions)
			var angle = beat / beats_per_circle * TAU
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

func make_button(button_text, transformation: EditorTransformation, disable_pressed = false) -> Button:
	var button = Button.new()
	button.text = button_text
	button.connect("mouse_entered", self, "_show_transform", [transformation])
	button.connect("mouse_exited", self, "hide_transform")
	if not disable_pressed:
		button.connect("pressed", self, "apply_transform", [transformation])
	return button
	
func apply_transform(transformation):
	emit_signal("apply_transform", transformation)
	
func hide_transform():
	emit_signal("hide_transform")
	
func add_button_row(button, button2):
	var hbox_container = HBoxContainer.new()
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button2.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox_container.add_child(button)
	hbox_container.add_child(button2)
	button_container.add_child(hbox_container)

func _ready():
	button_container.add_child(make_button("Interpolate positions", InterpolatePositionsTransform.new()))
	button_container.add_child(make_button("Interpolate angle", InterpolateAngleTransform.new()))
	
	button_container.add_child(HSeparator.new())
	
	button_container.add_child(make_button("Flip angle", FlipAngleTransform.new()))

func _show_transform(transform: EditorTransformation):
	transform.use_stage_center = use_stage_center
	transform.bpm = editor.get_bpm()
	emit_signal("show_transform", transform)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_action("editor_interpolate_angle", true) and event.pressed and not event.echo:
			emit_signal("apply_transform", InterpolateAngleTransform.new())
