extends MarginContainer

signal show_transform(transformation)
signal hide_transform()
signal apply_transform(transformation)

onready var vertical_transform

onready var button_container = get_node("ScrollContainer/SyncButtonContainer")

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
		for i in range(notes.size()-1, -1, -1):
			var note = notes[i]
			if note is HBNoteData:
				if note.is_slide_note():
					if current_chain.size() >= 1:
						chains.append(current_chain)
					current_chain = [note]
				elif note.is_slide_hold_piece():
					if current_chain.size() > 0:
						current_chain.append(note)
		if current_chain.size() > 1:
			chains.append(current_chain)
		return chains
	func transform_notes(notes: Array):
		var transformation_result = {}
		var chains = _get_chains(notes)
		var note_type_change_map = {
			HBBaseNote.NOTE_TYPE.SLIDE_LEFT: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT,
			HBBaseNote.NOTE_TYPE.SLIDE_RIGHT: HBBaseNote.NOTE_TYPE.SLIDE_LEFT,
			HBBaseNote.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE: HBBaseNote.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE,
			HBBaseNote.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE: HBBaseNote.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
		}
		
		if chains.size() > 0:
			for chain in chains:
				var chain_slide_note_pos = chain[0].position
				for note in chain:
					if note is HBNoteData:
						if note.is_slide_note() or note.is_slide_hold_piece():
							var new_note_x = note.position.x - (note.position.x - chain_slide_note_pos.x) * 2
							transformation_result[note] = {
								"position": Vector2(new_note_x, note.position.y),
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
func make_button(button_text, transformation: EditorTransformation, disable_pressed = false) -> Button:
	var button = Button.new()
	button.text = button_text
	button.connect("mouse_entered", self, "emit_signal", ["show_transform", transformation])
	button.connect("mouse_exited", self, "hide_transform")
	if not disable_pressed:
		button.connect("pressed", self, "apply_transform")
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
	
var rotate_transformation = RotateTransformation.new()
	
var angle_slider = HSlider.new()

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
	
	var rotate_label_hbox_container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = "Rotate targets: "
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var spinbox = SpinBox.new()
	spinbox.editable = false
	spinbox.max_value = 180.0
	spinbox.min_value = -180.0
	spinbox.suffix = "º"
	spinbox.connect("value_changed", self, "set_rotation")

	rotate_label_hbox_container.add_child(label)
	rotate_label_hbox_container.add_child(spinbox)
	
	angle_slider.min_value = -180.0
	angle_slider.max_value = 180.0
	angle_slider.tick_count = 9
	angle_slider.ticks_on_borders = true
	angle_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	angle_slider.connect("mouse_entered", self, "emit_signal", ["show_transform", rotate_transformation])
	angle_slider.connect("mouse_exited", self, "emit_signal", ["hide_transform"])
	
	angle_slider.share(spinbox)
	
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
	
	
	
func set_rotation(value):
	rotate_transformation.rotation = value
	emit_signal("show_transform", rotate_transformation)

func _on_negate_angle_pressed():
	angle_slider.value = -angle_slider.value

func _toggle_angle_absolute_pivot(pressed: bool):
	rotate_transformation.absolute_pivot = pressed
	emit_signal("show_transform", rotate_transformation)
