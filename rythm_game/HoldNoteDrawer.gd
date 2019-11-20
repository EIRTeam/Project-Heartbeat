extends "res://rythm_game/NoteDrawer.gd"

onready var target_graphic = get_node("HoldNoteTarget")
onready var note_graphic = get_node("Note")
onready var trailing_note_graphic = get_node("NoteTrailing")
var pickable = true setget set_pickable
var holding = false
export(float) var target_scale_modifier = 1.0
var held_bonus_score = 0
const TRAIL_RESOLUTION = 32 # points per second
const INCREMENT_SCORE_BY = 10.0
func set_pickable(value):
	pickable = value
	$NoteTarget.input_pickable = value

func _ready():
	_on_note_type_changed()
	$AnimationPlayer.play("note_appear")
	target_graphic.get_node("Particles2D").emitting = true
	set_trail_color()
	
func update_graphic_positions_and_scale(time: float):

	target_graphic.position = game.remap_coords(note_data.position)
	var time_out_distance = note_data.time_out - (note_data.time - time*1000.0)
	# Movement along wave
	var oscillation_amplitude = game.remap_coords(Vector2(1, 1)).x * note_data.oscillation_amplitude
	var starting_pos = game.remap_coords(get_initial_position())
#		var t_original = ((time_out_distance - trail_time) + t_trail_time) / note_data.time_out
	
	note_graphic.position = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, time_out_distance/note_data.time_out)
	trailing_note_graphic.position = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, (time_out_distance-note_data.get_duration())/note_data.time_out)
	# Scale for first note
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		new_scale = clamp(new_scale, 0.0, 1.0)
		note_graphic.scale = Vector2(new_scale, new_scale)
	else:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
		
	if holding:
		note_graphic.scale = Vector2(0, 0)
		
	# Scale for trailing note
	if time * 1000.0 > note_data.time + note_data.get_duration():
		var disappereance_time = note_data.time + game.judge.get_target_window_msec() + note_data.get_duration()
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		trailing_note_graphic.scale = Vector2(new_scale, new_scale)
	else:
		trailing_note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
		
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	target_graphic.arm_position = 1.0 - ((note_data.time - time*1000) / note_data.time_out)
	target_graphic.arm_position_2 = 1.0 - (((note_data.time+note_data.duration) - time*1000) / note_data.time_out)
	draw_trail(time)
	
func set_trail_color():
	var gradient = Gradient.new()
	var gradient_back = Gradient.new()
#	var back_color = Color(note_data.NOTE_COLORS[note_data.note_type].color)
	var back_color = Color(note_data.NOTE_COLORS[note_data.note_type].color)
	back_color.a = 1.0
	gradient_back.set_color(0, back_color)
	gradient_back.set_color(1, back_color)
	var color1 = Color("#272646")
	var color2 = Color("#272646")
	color1.a = 1.0
	color2.a = 1.0
	gradient.set_color(0, color1)
	gradient.set_color(1, color2)
	$Line2D.gradient = gradient_back
	$Line2D2.gradient = gradient
	$Line2D3.default_color = Color.white
	
func draw_trail(time: float):
	var time_out_distance = note_data.time_out - (note_data.time - time*1000.0)
	# Trail will be time_out / 2 behind
	var trail_time = note_data.duration
	var points = PoolVector2Array()
	var trail_res = int((TRAIL_RESOLUTION / float(note_data.time_out)) * (note_data.get_duration() + game.judge.get_target_window_msec()))
	var trail_max = 1.0
	if not holding:
		trail_max = 1.0 + game.judge.get_target_window_msec() / float(note_data.time_out)
	for i in range(trail_res):
		var starting_pos = game.remap_coords(get_initial_position())
		var t_trail_time = trail_time * (i / float(trail_res-1))
		var t_original = ((time_out_distance - trail_time) + t_trail_time) / note_data.time_out
		var t = clamp(t_original, -1.0, trail_max)
		var oscillation_amplitude = game.remap_coords(Vector2(1.0, 1)).x * note_data.oscillation_amplitude
		var point = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, t, note_data.oscillation_phase_shift)
		points.append(point)
		if t_original >= trail_max:
			break
	$Line2D2.width = 15 * game.get_note_scale()
	$Line2D.width = 30 * game.get_note_scale()
	$Line2D3.width = 40 * game.get_note_scale()
	$Line2D.points = points
	$Line2D2.points = points
	$Line2D3.points = points
func _on_note_type_changed():
	note_graphic.set_note_type(note_data.note_type)
	trailing_note_graphic.set_note_type(note_data.note_type)
	target_graphic.set_note_type(note_data.note_type)
	set_trail_color()

#func judge_note_input(event: InputEvent, time: float):
#	# Judging tapped keys
#	var actions = game.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]
#	for action in actions:
#		if event.is_action_pressed(action) and event.is_echo():
#			var closest_note = game.get_closest_note_of_type(note_data.note_type)
#			if closest_note == note_data:
#				var judgement = game.judge.judge_note(time, closest_note.time/1000.0)
#				if judgement:
#					if judgement > game.judge.JUDGE_RATINGS.SAFE:
#						print("JUDGED! HoldStart", judgement," ", time, " ", closest_note.time/1000.0)
#						holding = true
#						emit_signal("note_judged", note_data, judgement)
#					else:
#						print("JUDGED! HoldStartFail", judgement," ", time, " ", closest_note.time/1000.0)
#						emit_signal("note_judged", note_data, judgement)
#						emit_signal("note_removed")
#						queue_free()
#			break
#		if holding:
#			if event.is_action_released(action) and not event.is_echo():
#				var judgement = game.judge.judge_note(time, (note_data.time+note_data.duration)/1000.0)
#				if not judgement:
#					judgement = game.judge.JUDGE_RATINGS.WORST
#				else:
#					game.play_note_sfx()
#				print("JUDGED! HoldEnd", judgement," ", time, " ", (note_data.time+note_data.duration)/1000.0)
#				emit_signal("note_judged", note_data, judgement)
#				emit_signal("note_removed")
#				queue_free()
#				set_process_unhandled_input(false)
#				break

func _unhandled_input(event):
	if not holding:
		# When not holding, judge the first part of the note
		var judgement = judge_note_input(event, game.time)
		if judgement != -1:
			emit_signal("note_judged", note_data, judgement)
			holding = true
			game.add_score(NOTE_SCORES[judgement])
			get_tree().set_input_as_handled()
	else:
		var judgement = judge_note_input(event, game.time-note_data.duration/1000.0, true)
		
		if judgement == -1:
			for action in game.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
				if event.is_action_released(action):
					judgement = HBJudge.JUDGE_RATINGS.WORST
					break
		if judgement != -1:
			emit_signal("note_judged", note_data, judgement)
			holding = true
			get_tree().set_input_as_handled()
			set_process_unhandled_input(false)
			game.play_note_sfx()
			# Ensure that if the user passes they get the full bonus score
			game.add_score(NOTE_SCORES[judgement] + (int(note_data.get_duration() / 10.0) - held_bonus_score))
			queue_free()
func _on_game_time_changed(time: float):
	
	update_graphic_positions_and_scale(time)
	if not is_queued_for_deletion():
		# Score string and other magic
		if holding:
			var next_score = note_data.duration - (note_data.time + note_data.duration - int(time*1000))
			next_score = next_score / 10.0
			next_score = clamp(int(next_score), 0, int(note_data.get_duration() / 10.0))
			next_score = int(next_score / INCREMENT_SCORE_BY) * INCREMENT_SCORE_BY
			if next_score != held_bonus_score:
				var score_diff = next_score-held_bonus_score
				game.add_score(score_diff)
				held_bonus_score = next_score
				$HoldNoteTarget/ScoreLabel.show()
				$HoldNoteTarget/ScoreLabel.text = "+" + str(next_score)
		# Killing notes after the user has run past them... TODO: make this produce a WORST rating
		if time >= (note_data.time + game.judge.get_target_window_msec()) / 1000.0 or time * 1000.0 < (note_data.time - note_data.time_out):
			if not game.editing and not holding:
				emit_signal("note_judged", note_data, game.judge.JUDGE_RATINGS.WORST)
				emit_signal("note_removed")
				queue_free()
		if time >= (note_data.time + game.judge.get_target_window_msec() + note_data.get_duration()) / 1000.0 or time * 1000.0 < (note_data.time - note_data.time_out):
				emit_signal("note_judged", note_data, game.judge.JUDGE_RATINGS.WORST)
				emit_signal("note_removed")
				queue_free()

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")

func get_notes():
	return [note_data]
