extends HBNewNoteDrawer

class_name HBNewDoubleNoteDrawer
	
var current_note_sound: ShinobuSoundPlayer
var waiting_for_multi_judgement := false
	
func note_init():
	.note_init()
	
func set_is_multi_note(val):
	.set_is_multi_note(val)
	if is_inside_tree():
		note_graphics.set_note_type(note_data.note_type, val, true)
		note_target_graphics.set_note_type(note_data, val)
	is_multi_note = val
	
func handles_input(event: InputEventHB) -> bool:
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	var is_input_in_range: bool = abs((game.time * 1000.0) - note_data.time) < game.judge.get_target_window_msec()
	return event.is_action_pressed(action) and is_input_in_range and not waiting_for_multi_judgement

func process_input(event: InputEventHB):
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	if current_note_sound:
		current_note_sound.stop()
		current_note_sound.queue_free()
		current_note_sound = null
	if game.game_input_manager.get_action_press_count(action) >= 2:
		_on_note_pressed(event)
	else:
		if not game.is_sound_debounced("note_hit") and not UserSettings.user_settings.play_hit_sounds_only_when_hit:
			game.debounce_sound("note_hit")
			current_note_sound = HBGame.instantiate_user_sfx("note_hit")
			current_note_sound.start()
		game.add_child(current_note_sound)

func _on_note_pressed(event = null):
	var judgement := game.judge.judge_note(game.time, note_data.time/1000.0) as int
	if not is_autoplay_enabled():
		if note_data.note_type == HBBaseNote.NOTE_TYPE.HEART:
			fire_and_forget_user_sfx("double_heart_note_hit")
		else:
			fire_and_forget_user_sfx("double_note_hit")
	emit_signal("judged", judgement, false, note_data.time, event)
	if not is_multi_note:
		game.add_score(HBNoteData.NOTE_SCORES[judgement])
		emit_signal("finished")
	else:
		waiting_for_multi_judgement = true
	if judgement >= HBJudge.JUDGE_RATINGS.FINE:
		show_note_hit_effect(note_data.position)

func process_note(time_msec: int):
	.process_note(time_msec)
	
	if is_autoplay_enabled():
		if is_in_autoplay_schedule_range(time_msec, note_data.time) and not scheduled_autoplay_sound:
			schedule_autoplay_sound("double_note_hit", time_msec, note_data.time)
		if time_msec > note_data.time:
			_on_note_pressed(null)
	
	if time_msec > note_data.time + game.judge.get_target_window_msec() and not waiting_for_multi_judgement:
		emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.time, null)
		emit_signal("finished")

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if current_note_sound:
			if not current_note_sound.is_at_stream_end():
				# If a hit sound is mid play we hand it over to the game to manage, so it doesn't stop playing
				# when this note is deleted
				remove_child(current_note_sound)
				game.track_sound(current_note_sound)

func _on_multi_note_judged(judgement: int):
	emit_signal("finished")
