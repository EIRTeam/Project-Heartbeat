extends "res://rythm_game/NoteDrawer.gd"

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
var pickable = true setget set_pickable

export(float) var target_scale_modifier = 1.0

const TRAIL_RESOLUTION = 32

func set_pickable(value):
	pickable = value
	$NoteTarget.input_pickable = value

func _ready():
	# HACKISH way to handle proper z ordering of notes, PD puts newer notes in front
	# VisualServer has a hard limit on how far you can take the Z, hence the hackish, should... work right?
	_on_note_type_changed()
	$AnimationPlayer.play("note_appear")
	$NoteTarget/Particles2D.emitting = true
	
func update_graphic_positions_and_scale(time: float):
	target_graphic.position = game.remap_coords(note_data.position)
	var time_out_distance = note_data.time_out - (note_data.time - time*1000.0)
	# Movement along wave
	var oscillation_amplitude = game.remap_coords(Vector2(1, 1)).x * note_data.oscillation_amplitude
	var starting_pos = game.remap_coords(get_initial_position())
	
	note_graphic.position = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, time_out_distance/note_data.time_out)
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		note_graphic.scale = Vector2(new_scale, new_scale)
	else:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	target_graphic.arm_position = -((note_data.time - time*1000) / note_data.time_out)
	draw_trail(time)
	
func set_trail_color():
	var gradient = Gradient.new()
	var color1 = Color(note_data.NOTE_COLORS[note_data.note_type].color)
	var color2 = Color(note_data.NOTE_COLORS[note_data.note_type].color)
	color1.a = 0.0
	color2.a = 0.5
	gradient.set_color(0, color1)
	gradient.set_color(1, color2)
	$Line2D.gradient = gradient
	$Line2D2.gradient = gradient
	
func draw_trail(time: float):
	var time_out_distance = note_data.time_out - (note_data.time - time*1000.0)
	# Trail will be time_out / 2 behind
	var trail_time = note_data.time_out/2.0
	$Line2D.clear_points()
	var points = PoolVector2Array()
	var points2 = PoolVector2Array()
	for i in range(TRAIL_RESOLUTION):
		var starting_pos = game.remap_coords(get_initial_position())
		var t_trail_time = trail_time * (i / float(TRAIL_RESOLUTION))
		var t = ((time_out_distance - trail_time) + t_trail_time) / note_data.time_out
		var oscillation_amplitude = game.remap_coords(Vector2(1.0, 1)).x * note_data.oscillation_amplitude
		var point1 = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, t, note_data.oscillation_phase_shift)
		var point2 = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, t, -note_data.oscillation_phase_shift)
		points2.append(point2)
		points.append(point1)
	$Line2D2.width = 6 * game.get_note_scale()
	$Line2D.width = 6 * game.get_note_scale()
	$Line2D.points = points
	$Line2D2.points = points2
func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type)
	target_graphic.set_note_type(note_data.note_type)
	set_trail_color()

func _on_game_time_changed(time: float):
	update_graphic_positions_and_scale(time)
	judge_note_input(time)
	# Killing notes after the user has run past them... TODO: make this produce a WORST rating
	if time >= (note_data.time + game.judge.get_target_window_msec()) / 1000.0 or time * 1000.0 < (note_data.time - note_data.time_out):
		emit_signal("note_judged", note_data, game.judge.JUDGE_RATINGS.WORST)
		emit_signal("note_removed")
		queue_free()

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")
	

func get_notes():
	return [note_data]
