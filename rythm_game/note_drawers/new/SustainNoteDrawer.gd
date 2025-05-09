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
	bind_node_to_layer(sine_drawer, &"Trails")

func handles_input(event: InputEventHB):
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	if pressed:
		if not event.is_pressed():
			var is_input_in_range: bool = abs(event.game_time - note_data.end_time * 1000) < game.judge.get_target_window_usec()
			return event.is_action_released(action)
	else:
		var is_input_in_range: bool = abs(event.game_time - note_data.time * 1000) < game.judge.get_target_window_usec()
		return event.is_action_pressed(action) and is_input_in_range
	return false

func process_input(event: InputEventHB):
	if pressed:
		_on_end_release(event)
	else:
		_on_pressed(event)
		
func _on_end_release(event = null):
	var time_usec := event.game_time if event else game.time_usec as int
	var judgement := game.judge.judge_note_usec(time_usec, note_data.end_time * 1000) as int
	judgement = max(judgement, 0)
	notify_release_judgement(judgement)
	emit_signal("finished")
	if judgement >= HBJudge.JUDGE_RATINGS.FINE:
		if not is_autoplay_enabled():
			fire_and_forget_user_sfx("sustain_note_release")
		show_note_hit_effect(note_data.position)
	if judgement != HBJudge.JUDGE_RATINGS.WORST:
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
	var time := game.time_usec
	if event:
		time = event.game_time
	var judgement := game.judge.judge_note_usec(time, note_data.time * 1000) as int
	if judge:
		if judgement < HBJudge.JUDGE_RATINGS.FINE:
			notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
		emit_signal("judged", judgement, false, note_data.time, event)
	if not is_multi_note:
		game.add_score(HBNoteData.NOTE_SCORES[judgement])
		if judgement < HBJudge.JUDGE_RATINGS.FINE:
			emit_signal("finished")
		if judgement >= HBJudge.JUDGE_RATINGS.FINE:
			show_note_hit_effect(note_data.position)

func update_arm_position(time_usec: int):
	var note_time_usec := note_data.time * 1000
	var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.time)) * 1000
	if pressed:
		note_target_graphics.arm2_position = 0.0
	else:
		note_target_graphics.arm2_position = 1.0 - ((note_time_usec - time_usec) / float(time_out))
	var time_out_distance = time_out - (note_time_usec - time_usec) - (note_data.get_duration() * 1000)
	note_target_graphics.arm_position = clamp(time_out_distance / float(time_out), 0.0, 1.0)

func is_in_editor_mode():
	return game.game_mode == 1

func process_note(time_usec: int):
	super.process_note(time_usec)
	var t_msec := time_usec / 1000
	var note_time_usec := note_data.time * 1000
	var note_end_time_usec := note_data.end_time * 1000 as int
	
	if is_autoplay_enabled():
		if not scheduled_autoplay_sound:
			var target_time: int = note_data.time if not pressed else note_data.end_time
			if is_in_autoplay_schedule_range(t_msec, target_time):
				var note_sfx := "note_hit" if not pressed else "sustain_note_release"
				schedule_autoplay_sound(note_sfx, t_msec, target_time)
		if time_usec > note_time_usec and not pressed:
			_on_pressed()
			if scheduled_autoplay_sound:
				get_tree().root.remove_child(scheduled_autoplay_sound)
				game.track_sound(scheduled_autoplay_sound)
				scheduled_autoplay_sound = null
			return
		elif time_usec > note_end_time_usec and pressed:
			_on_end_release()
			return
			
	if is_in_editor_mode():
		if time_usec > note_time_usec:
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
		if time_usec > note_end_time_usec + game.judge.get_target_window_usec():
			notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
			emit_signal("finished")
	else:
		if time_usec > note_time_usec + game.judge.get_target_window_usec():
			# Judge note independently once, that way it will count as 2 worsts
			emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.time, null)
			notify_release_judgement(HBJudge.JUDGE_RATINGS.WORST)
			emit_signal("finished")
	if sustain_loop:
		var duration_progress := (time_usec - note_time_usec) / float(note_end_time_usec - note_time_usec)
		sustain_loop.pitch_scale = 1.0 + duration_progress * 0.1

func update_graphic_positions_and_scale(time_usec: int):
	super.update_graphic_positions_and_scale(time_usec)
	var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.end_time)) * 1000
	
	var time_out_distance = time_out - (note_data.end_time * 1000 - time_usec) - note_data.get_duration() * 1000
	note_graphic2.position = calculate_note_position(note_data, note_data.end_time, time_usec)
	note_graphic2.scale = Vector2.ONE * UserSettings.user_settings.note_size
	if time_usec > note_data.end_time * 1000:
		var disappereance_time = note_data.end_time * 1000 + (game.judge.get_target_window_usec())
		var new_scale = (disappereance_time - time_usec) / float(game.judge.get_target_window_usec()) * game.get_note_scale()
		new_scale = max(new_scale, 0.0)
		note_graphic2.scale = Vector2(new_scale, new_scale) * UserSettings.user_settings.note_size
	update_arm_position(time_usec)

func draw_trail(time_usec: int):
	super.draw_trail(time_usec)
	if pressed:
		sine_drawer.time = 1.0
	var time_out = note_data.get_time_out(game.get_note_speed_at_time(note_data.time)) * 1000
	var time_out_distance = time_out - (note_data.time * 1000 - time_usec) - note_data.get_duration() * 1000
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
