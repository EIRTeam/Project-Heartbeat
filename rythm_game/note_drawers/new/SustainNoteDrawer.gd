extends HBNewNoteDrawer

class_name HBSustainNoteDrawer

onready var note_graphic2 = get_node("Note2")

var pressed := false

var sustain_loop: ShinobuSoundPlayer

# Sustains always have a trail, so we override this behavior
func set_enable_trail(val):
	enable_trail = val

func set_is_multi_note(val):
	.set_is_multi_note(val)
	if is_inside_tree():
		note_graphic2.set_note_type(note_data.note_type, val)

func note_init():
	.note_init()
	sine_drawer = SineDrawerSustain.new()
	sine_drawer.game = game
	sine_drawer.note_data = note_data
	bind_node_to_layer(sine_drawer, "Trails")

func handles_input(event: InputEventHB):
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	if pressed:
		if not event.is_pressed():
			var is_input_in_range: bool = abs((game.time * 1000.0) - note_data.end_time) < game.judge.get_target_window_msec()
			return event.is_action_released(action)
	else:
		var is_input_in_range: bool = abs((game.time * 1000.0) - note_data.time) < game.judge.get_target_window_msec()
		return event.is_action_pressed(action) and is_input_in_range
	return false

func process_input(event: InputEventHB):
	if pressed:
		_on_end_release(event)
	else:
		_on_pressed(event)
		
func _on_end_release(event := null):
	var judgement := game.judge.judge_note(game.time, note_data.end_time/1000.0) as int
	judgement = max(judgement, 0)
	emit_signal("judged", judgement, true, note_data.end_time, event)
	emit_signal("finished")
	if judgement >= HBJudge.JUDGE_RATINGS.FINE:
		if not is_autoplay_enabled():
			fire_and_forget_user_sfx("sustain_note_release")
		show_note_hit_effect(note_data.position)
	game.add_score(HBNoteData.NOTE_SCORES[judgement])

func _on_pressed(event = null, judge := true):
	note_graphics.hide()
	pressed = true
	if not sustain_loop:
		sustain_loop = HBGame.instantiate_user_sfx("sustain_note_loop")
		sustain_loop.looping_enabled = true
		add_child(sustain_loop)
		sustain_loop.start()
	if not is_autoplay_enabled():
		fire_and_forget_user_sfx("note_hit")
	var judgement := game.judge.judge_note(game.time, note_data.time/1000.0) as int
	if judge:
		emit_signal("judged", judgement, false, note_data.time, event)
	if not is_multi_note:
		game.add_score(HBNoteData.NOTE_SCORES[judgement])
		if judgement < HBJudge.JUDGE_RATINGS.FINE:
			emit_signal("finished")
		if judgement >= HBJudge.JUDGE_RATINGS.FINE:
			show_note_hit_effect(note_data.position)

func update_arm_position(time_msec: int):
	var time_out := note_data.get_time_out(game.get_bpm_at_time(note_data.time))
	if pressed:
		note_target_graphics.arm2_position = 0.0
	else:
		note_target_graphics.arm2_position = 1.0 - ((note_data.time - time_msec) / float(time_out))
	var time_out_distance = time_out - (note_data.time - time_msec) - note_data.get_duration()
	note_target_graphics.arm_position = max(time_out_distance / float(time_out), 0.0)

func is_in_editor_mode():
	return game.game_mode == 1

func process_note(time_msec: int):
	.process_note(time_msec)
	
	if is_autoplay_enabled():
		if not scheduled_autoplay_sound:
			var target_time := note_data.time if not pressed else note_data.end_time
			if is_in_autoplay_schedule_range(time_msec, target_time):
				var note_sfx := "note_hit" if not pressed else "sustain_note_release"
				schedule_autoplay_sound(note_sfx, time_msec, target_time)
		if time_msec > note_data.time and not pressed:
			_on_pressed()
			return
		elif time_msec > note_data.end_time and pressed:
			_on_end_release()
			return
			
	if is_in_editor_mode():
		if time_msec > note_data.time:
			pressed = true
			note_graphics.hide()
		else:
			pressed = false
			note_graphics.show()
		if sustain_loop:
			sustain_loop.queue_free()
			sustain_loop = null
	# Handle note going out of range
	if pressed:
		if time_msec > note_data.end_time + game.judge.get_target_window_msec():
			emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.end_time, null)
			emit_signal("finished")
	else:
		if time_msec > note_data.time + game.judge.get_target_window_msec():
			# Judge note independently once, that way it will count as 2 worsts
			emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, true, note_data.time, null)
			emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.time, null)
			emit_signal("finished")
	if sustain_loop:
		var duration_progress := (time_msec - note_data.time) / float(note_data.end_time - note_data.time)
		sustain_loop.pitch_scale = 1.0 + duration_progress * 0.1

func update_graphic_positions_and_scale(time_msec: int):
	.update_graphic_positions_and_scale(time_msec)
	var time_out := note_data.get_time_out(game.get_bpm_at_time(note_data.time))
	
	var time_out_distance = time_out - (note_data.time - time_msec) - note_data.get_duration()
	note_graphic2.position = HBUtils.calculate_note_sine(time_out_distance/float(time_out), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance)
	note_graphic2.scale = Vector2.ONE * UserSettings.user_settings.note_size
	if time_msec > note_data.end_time:
		var disappereance_time = note_data.end_time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time_msec) / float(game.judge.get_target_window_msec()) * game.get_note_scale()
		new_scale = max(new_scale, 0.0)
		note_graphic2.scale = Vector2(new_scale, new_scale) * UserSettings.user_settings.note_size
	update_arm_position(time_msec)

func draw_trail(time_msec: int):
	.draw_trail(time_msec)
	if pressed:
		sine_drawer.time = 1.0
	var time_out = note_data.get_time_out(game.get_bpm_at_time(note_data.time))
	var time_out_distance = time_out - (note_data.time - time_msec) - note_data.get_duration()
	var t = (time_out_distance / float(time_out))
	sine_drawer.trail_position = t

func _on_rollback():
	if pressed:
		emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, true, note_data.end_time, null)
		emit_signal("finished")

func _on_multi_note_judged(judgement: int):
	if judgement >= HBJudge.JUDGE_RATINGS.FINE:
		_on_pressed(null, false)
	else:
		emit_signal("finished")
		return
