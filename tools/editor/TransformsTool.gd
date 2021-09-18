extends MarginContainer

signal show_transform(transformation)
signal hide_transform()
signal apply_transform(transformation)

onready var vertical_transform

onready var button_container = get_node("ScrollContainer/SyncButtonContainer")

var use_stage_center := false setget set_use_stage_center

var editor: HBEditor

func set_use_stage_center(val):
	use_stage_center = val
	editor.song_editor_settings.transforms_use_center = val

class FlipHorizontallyTransformation:
	extends EditorTransformation
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		for n in notes:
			var note = n as HBBaseNote
			transformation_result[n] = {
				"position": Vector2(1920 - note.position.x, note.position.y),
				"entry_angle": fmod((180 - note.entry_angle), 360),
				"oscillation_frequency": -note.oscillation_frequency
			}
		return transformation_result

class FlipSlideChainsTransformation:
	extends EditorTransformation
	
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
		var chains = _get_chains(notes)
		var center = get_center_for_notes(notes)
		var note_type_change_map = {
			HBBaseNote.NOTE_TYPE.SLIDE_LEFT: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT,
			HBBaseNote.NOTE_TYPE.SLIDE_RIGHT: HBBaseNote.NOTE_TYPE.SLIDE_LEFT,
			HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT: HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT,
			HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT: HBBaseNote.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT,
		}
		
		for chain in chains:
			for note in chain:
				var relative_x = center.x - note.position.x
				transformation_result[note] = {
					"position": Vector2(center.x + relative_x, note.position.y),
					"entry_angle": fmod((180 - note.entry_angle), 360),
					"oscillation_frequency": -note.oscillation_frequency,
					"note_type": note_type_change_map[note.note_type]
				}
		return transformation_result

class FlipVerticallyTransformation:
	extends EditorTransformation
	
	func transform_notes(notes: Array):
		var transformation_result = {}
		for n in notes:
			var note = n as HBBaseNote
			transformation_result[n] = {
				"position": Vector2(note.position.x, 1080 - note.position.y),
				"entry_angle": -note.entry_angle,
				"oscillation_frequency": -note.oscillation_frequency
			}
		return transformation_result

class RotateTransformation:
	extends EditorTransformation
	
	var rotation = 0.0
	var absolute_pivot = false
	
	func transform_notes(notes: Array):
		var center = get_center_for_notes(notes)
		var transformation_result = {}
		
		if absolute_pivot:
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
			var min_time = notes[-1].time
			var max_time = notes[0].time
			for note in notes:
				var t = 0
				if float(max_time-min_time) > 0:
					t = (note.time - min_time) / float(max_time - min_time)
				var new_angle = lerp(min_angle, max_angle, t)
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
	var start_rev := 0.0 setget set_start_rev
	# -1 for outside, 1 for inside
	var inside = -1
	
	func set_separation(val):
		separation = val
	
	func set_epr(val):
		eigths_per_circle = val
	
	func set_start_note(val):
		start_note = val
	
	func set_start_rev(val):
		start_rev = val
	
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
		
		var center = get_center_for_notes(notes)
		
		var sustain_compensation = 0
		
		var time_offset
		
		if start_note < notes.size():
			time_offset = notes[start_note].time if notes else 0
		else:
			time_offset = notes[notes.size() - 1].time if notes else 0
		
		var angle_offset = (start_rev + 0.75) * TAU
		var radius = separation * eigths_per_circle / TAU
		
		var beats_per_circle = eigths_per_circle / 2
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

var use_stage_center_cb = CheckBox.new()

var rotate_transformation = RotateTransformation.new()
var make_circle_transform_left = MakeCircleTransform.new(-1)
var make_circle_transform_right = MakeCircleTransform.new(1)

var angle_slider = HSlider.new()
var circle_size_spinbox = SpinBox.new()
var circle_use_inside_button = CheckBox.new()
var circle_separation_spinbox = SpinBox.new()

var advanced_settings_button = CheckBox.new()
var advanced_settings_hbox_container = HBoxContainer.new()

func _ready():
	var flip_label = Label.new()
	flip_label.text = "Flip notes:"
	
	button_container.add_child(flip_label)
	
	add_button_row(
		make_button("Flip horizontally", FlipHorizontallyTransformation.new()),
		make_button("Flip vertically", FlipVerticallyTransformation.new())
	)
	
	
	button_container.add_child(make_button("Flip slide chains", FlipSlideChainsTransformation.new()))
	
	button_container.add_child(HSeparator.new())
	
	use_stage_center_cb.text = "Use stage center"
	use_stage_center_cb.connect("toggled", self, "set_use_stage_center")
	button_container.add_child(use_stage_center_cb)
	
	button_container.add_child(HSeparator.new())
	
	var rotate_label_hbox_container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "Rotate targets: "
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var spinbox = SpinBox.new()
	spinbox.editable = true
	spinbox.max_value = 180.0
	spinbox.min_value = -180.0
	spinbox.suffix = "º"
	angle_slider.share(spinbox)
	
	spinbox.connect("value_changed", self, "set_rotation")

	rotate_label_hbox_container.add_child(label)
	rotate_label_hbox_container.add_child(spinbox)
	
	angle_slider.min_value = -180.0
	angle_slider.max_value = 180.0
	angle_slider.tick_count = 9
	angle_slider.ticks_on_borders = true
	angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	angle_slider.connect("mouse_entered", self, "emit_signal", ["_show_transform", rotate_transformation])
	angle_slider.connect("mouse_exited", self, "emit_signal", ["hide_transform"])
	
	button_container.add_child(rotate_label_hbox_container)
	button_container.add_child(angle_slider)
	
	var apply_rotation_button = make_button("Apply", rotate_transformation)
	var reset_button = make_button("Reset", rotate_transformation, true)
	reset_button.connect("pressed", angle_slider, "set_value", [0])
	
	add_button_row(apply_rotation_button, reset_button)
	
	var negate_angle_button = make_button("Negate angle", rotate_transformation, true)
	negate_angle_button.connect("pressed", self, "_on_negate_angle_pressed")
	
	var toggle_absolute_pivot = make_button("Absolute pivot", rotate_transformation, true)
	toggle_absolute_pivot.toggle_mode = true
	toggle_absolute_pivot.connect("toggled", self, "_toggle_angle_absolute_pivot")
	
	add_button_row(negate_angle_button, toggle_absolute_pivot)
	
	button_container.add_child(HSeparator.new())
	
	button_container.add_child(make_button("Interpolate positions", InterpolatePositionsTransform.new()))
	button_container.add_child(make_button("Interpolate angle", InterpolateAngleTransform.new()))
	
	button_container.add_child(HSeparator.new())
	
	button_container.add_child(make_button("Flip angle", FlipAngleTransform.new()))
	
	button_container.add_child(HSeparator.new())
	
	var circle_settings_hbox_container = HBoxContainer.new()
	
	var circle_size_label = Label.new()
	circle_size_label.text = "Circle size: "
	
	circle_size_spinbox.editable = true
	circle_size_spinbox.max_value = 64
	circle_size_spinbox.min_value = 1
	circle_size_spinbox.step = 1
	circle_size_spinbox.value = 16
	circle_size_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	circle_settings_hbox_container.add_child(circle_size_label)
	circle_settings_hbox_container.add_child(circle_size_spinbox)
	
	var circle_separation_label = Label.new()
	circle_separation_label.text = "Separation: "
	
	circle_separation_spinbox.editable = true
	circle_separation_spinbox.max_value = 123213123123
	circle_separation_spinbox.min_value = 1
	circle_separation_spinbox.value = 96
	circle_separation_spinbox.step = 1.0
	circle_separation_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	circle_separation_spinbox.connect("value_changed", make_circle_transform_left, "set_separation")
	circle_separation_spinbox.connect("value_changed", make_circle_transform_right, "set_separation")
	circle_separation_spinbox.connect("value_changed", self, "_set_separation")
	
	var circle_size_slider = HSlider.new()
	circle_size_slider.min_value = 1
	circle_size_slider.max_value = 64
	circle_size_slider.step = 1
	circle_size_slider.value = 16
	circle_size_slider.tick_count = 9
	circle_size_slider.ticks_on_borders = true
	circle_size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	circle_size_slider.share(circle_size_spinbox)
	
	circle_size_slider.connect("value_changed", make_circle_transform_left, "set_epr")
	circle_size_slider.connect("value_changed", make_circle_transform_right, "set_epr")
	
	circle_size_spinbox.connect("value_changed", make_circle_transform_left, "set_epr")
	circle_size_spinbox.connect("value_changed", make_circle_transform_left, "set_epr")
	circle_size_spinbox.connect("value_changed", self, "_set_size")
	
	circle_settings_hbox_container.add_child(circle_separation_label)
	circle_settings_hbox_container.add_child(circle_separation_spinbox)
	button_container.add_child(circle_settings_hbox_container)
	button_container.add_child(circle_size_slider)
	
	var other_settings_hbox_container = HBoxContainer.new()
	
	circle_use_inside_button.text = "From inside"
	circle_use_inside_button.connect("toggled", make_circle_transform_left, "set_inside")
	circle_use_inside_button.connect("toggled", make_circle_transform_right, "set_inside")
	circle_use_inside_button.connect("toggled", self, "_set_inside")
	
	advanced_settings_button.text = "I know what I'm doing"
	advanced_settings_button.connect("toggled", self, "_toggle_advanced_options")
	
	other_settings_hbox_container.add_child(circle_use_inside_button)
	other_settings_hbox_container.add_child(advanced_settings_button)
	
	button_container.add_child(other_settings_hbox_container)
	
	var starting_note_label = Label.new()
	starting_note_label.text = "Starting note: "
	
	var starting_note_spinbox = SpinBox.new()
	starting_note_spinbox.editable = true
	starting_note_spinbox.max_value = 123213123123
	starting_note_spinbox.min_value = 1
	starting_note_spinbox.value = 1
	starting_note_spinbox.step = 1.0
	starting_note_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	starting_note_spinbox.connect("value_changed", make_circle_transform_left, "set_start_note")
	starting_note_spinbox.connect("value_changed", make_circle_transform_right, "set_start_note")
	
	var starting_rev_label = Label.new()
	starting_rev_label.text = "Starting turn: "
	
	var starting_rev_spinbox = SpinBox.new()
	starting_rev_spinbox.editable = true
	starting_rev_spinbox.max_value = 1.0
	starting_rev_spinbox.min_value = 0.0
	starting_rev_spinbox.value = 0.0
	starting_rev_spinbox.step = 0.01
	starting_rev_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	starting_rev_spinbox.connect("value_changed", make_circle_transform_left, "set_start_rev")
	starting_rev_spinbox.connect("value_changed", make_circle_transform_right, "set_start_rev")
	
	advanced_settings_hbox_container.add_child(starting_note_label)
	advanced_settings_hbox_container.add_child(starting_note_spinbox)
	advanced_settings_hbox_container.add_child(starting_rev_label)
	advanced_settings_hbox_container.add_child(starting_rev_spinbox)
	advanced_settings_hbox_container.hide()
	
	button_container.add_child(advanced_settings_hbox_container)
	
	var make_circle_left_button = make_button("Make circle left", make_circle_transform_left)
	var make_circle_right_button = make_button("Make circle right", make_circle_transform_right)
	
	add_button_row(make_circle_left_button, make_circle_right_button)

func _toggle_advanced_options(pressed: bool):
	if pressed:
		advanced_settings_hbox_container.show()
	else:
		advanced_settings_hbox_container.hide()
	
	editor.song_editor_settings.circle_advanced_mode = pressed

func set_rotation(value):
	rotate_transformation.rotation = value
	_show_transform(rotate_transformation)

func _on_negate_angle_pressed():
	angle_slider.value = -angle_slider.value

func _toggle_angle_absolute_pivot(pressed: bool):
	rotate_transformation.absolute_pivot = pressed
	_show_transform(rotate_transformation)

func _show_transform(transform: EditorTransformation):
	transform.use_stage_center = use_stage_center
	transform.bpm = editor.get_bpm()
	emit_signal("show_transform", transform)

func _set_size(value):
	editor.song_editor_settings.circle_size = value

func _set_inside(value):
	editor.song_editor_settings.circle_from_inside = value

func _set_separation(value):
	editor.song_editor_settings.circle_separation = value

func _unhandled_input(event):
	if event is InputEventKey:
		if event.is_action_pressed("editor_flip_h"):
			emit_signal("apply_transform", FlipHorizontallyTransformation.new())
		if event.is_action_pressed("editor_flip_v"):
			emit_signal("apply_transform", FlipVerticallyTransformation.new())
		
		if event.is_action_pressed("editor_make_circle_c"):
			make_circle_transform_right.bpm = editor.get_bpm()
			emit_signal("apply_transform", make_circle_transform_right)
		if event.is_action_pressed("editor_make_circle_cc"):
			make_circle_transform_left.bpm = editor.get_bpm()
			emit_signal("apply_transform", make_circle_transform_left)
		
		if event.is_action("editor_circle_size_bigger") and event.pressed:
			circle_size_spinbox.value += 1
		if event.is_action("editor_circle_size_smaller") and event.pressed:
			circle_size_spinbox.value -= 1
		
		if event.is_action_pressed("editor_circle_inside"):
			circle_use_inside_button.set_pressed(not circle_use_inside_button.is_pressed())


func load_settings():
	use_stage_center_cb.pressed = editor.song_editor_settings.transforms_use_center
	circle_use_inside_button.pressed = editor.song_editor_settings.circle_from_inside
	circle_size_spinbox.value = editor.song_editor_settings.circle_size
	circle_separation_spinbox.value = editor.song_editor_settings.circle_separation
	advanced_settings_button.pressed = editor.song_editor_settings.circle_advanced_mode
