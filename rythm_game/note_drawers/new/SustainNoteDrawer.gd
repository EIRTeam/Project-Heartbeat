extends HBNewNoteDrawer

class_name HBSustainNoteDrawer

@onready var note_graphic2 = get_node("Note2")

var pressed := false
var notified_release_judgement := false

var sustain_loop: ShinobuSoundPlayer

# Sustains always have a trail, so we override this behavior
func set_enable_trail(val):
	enable_trail = val

func set_is_multi_note(val):
	super.set_is_multi_note(val)
	if is_inside_tree():
		note_graphic2.set_note_type(note_data.note_type, val)

func note_init():
	super.note_init()
	sine_drawer = SineDrawerSustain.new()
	sine_drawer.game = game
	sine_drawer.note_data = note_data
	bind_node_to_layer(sine_drawer, "Trails")

func handles_input(event: InputEventHB):
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	if pressed:
		if not event.is_pressed():
			var is_input_in_range: bool = abs(game.time_msec - note_data.end_time) < game.judge.get_target_window_msec()
			return event.is_action_released(action)
	else:
		var is_input_in_range: bool = abs(game.time_msec - note_data.time) < game.judge.get_target_window_msec()
		return event.is_action_pressed(action) and is_input_in_range
	return false

func process_input(event: InputEventHB):
	if pressed:
		_on_end_release(event)
	else:
		_on_pressed(event)
		
func _on_end_release(event = null):
	var judgement := game.judge.judge_note(game.time_msec, note_data.end_time) as int
	judgement = max(judgement, 0)
	notify_release_judgement(judgement)
	emit_signal("finished")
	if judgement >= HBJudge.JUDGE_RATINGS.FINE:
		if not is_autoplay_enabled():
			fire_and_forget_user_sfx("sustain_note_release")
		show_note_hit_effect(note_data.position)
	game.add_score(HBNoteData.NOTE_SCORES[judgement])

func _on_pressed(event = null, judge := true):
	note_graphics.hide()
	pressed = true
	if not sustain_loop and game.sfx_enabled:
		sustain_loop = HBGame.instantiate_user_sfx("sustain_note_loop")
		sustain_loop.looping_enabled = true
		add_child(sustain_loop)
		sustain_loop.start()
	if not is_autoplay_enabled():
		fire_and_forget_user_sfx("note_hit")
	var judgement := game.judge.judge_note(game.time_msec, note_data.time) as int
	if judge:
		emit_signal("judged", judgement, false, note_data.time, event)
		if not pressed and judgement < HBJudge.JUDGE_RATINGS.FINE:
			notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
	if not is_multi_note:
		game.add_score(HBNoteData.NOTE_SCORES[judgement])
		if judgement < HBJudge.JUDGE_RATINGS.FINE:
			emit_signal("finished")
		if judgement >= HBJudge.JUDGE_RATINGS.FINE:
			show_note_hit_effect(note_data.position)

func update_arm_position(time_msec: int):
	var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.time))
	if pressed:
		note_target_graphics.arm2_position = 0.0
	else:
		note_target_graphics.arm2_position = 1.0 - ((note_data.time - time_msec) / float(time_out))
	var time_out_distance = time_out - (note_data.time - time_msec) - note_data.get_duration()
	note_target_graphics.arm_position = max(time_out_distance / float(time_out), 0.0)

func is_in_editor_mode():
	return game.game_mode == 1

func process_note(time_msec: int):
	super.process_note(time_msec)
	
	if is_autoplay_enabled():
		if not scheduled_autoplay_sound:
			var target_time: int = note_data.time if not pressed else note_data.end_time
			if is_in_autoplay_schedule_range(time_msec, target_time):
				var note_sfx := "note_hit" if not pressed else "sustain_note_release"
				schedule_autoplay_sound(note_sfx, time_msec, target_time)
		if time_msec > note_data.time and not pressed:
			_on_pressed()
			if scheduled_autoplay_sound:
				get_tree().root.remove_child(scheduled_autoplay_sound)
				game.track_sound(scheduled_autoplay_sound)
				scheduled_autoplay_sound = null
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
			notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
			emit_signal("finished")
	else:
		if time_msec > note_data.time + game.judge.get_target_window_msec():
			# Judge note independently once, that way it will count as 2 worsts
			emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.time, null)
			notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
			emit_signal("finished")
	if sustain_loop:
		var duration_progress := (time_msec - note_data.time) / float(note_data.end_time - note_data.time)
		sustain_loop.pitch_scale = 1.0 + duration_progress * 0.1

func update_graphic_positions_and_scale(time_msec: int):
	super.update_graphic_positions_and_scale(time_msec)
	var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.time))
	
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
	super.draw_trail(time_msec)
	if pressed:
		sine_drawer.time = 1.0
	var time_out = note_data.get_time_out(game.get_note_speed_at_time(note_data.time))
	var time_out_distance = time_out - (note_data.time - time_msec) - note_data.get_duration()
	var t = (time_out_distance / float(time_out))
	sine_drawer.trail_position = t

func _on_rollback():
	if pressed:
		notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
		emit_signal("finished")

func _on_multi_note_judged(judgement: int):
	if notified_release_judgement:
		emit_signal("finished")
	elif judgement < HBJudge.JUDGE_RATINGS.FINE:
		notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
		emit_signal("finished")

# Notifies a release judgement, if not done before
func notify_release_judgement(judgement: int):
	if not notified_release_judgement:
		notified_release_judgement = true
		emit_signal("judged", judgement, true, note_data.end_time, null)

func _on_wrong(_judgement: int):
	notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
	emit_signal("finished")
