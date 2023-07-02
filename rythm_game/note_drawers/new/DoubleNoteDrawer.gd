extends HBNewNoteDrawer

class_name HBNewDoubleNoteDrawer
	
var current_note_sound: ShinobuSoundPlayer
var waiting_for_multi_judgement := false
var current_frame_held_count := 0
var processed_held_count := 0
	
func note_init():
	super.note_init()
	
func set_is_multi_note(val):
	super.set_is_multi_note(val)
	if is_inside_tree():
		note_graphics.set_note_type(note_data.note_type, val, true)
		note_target_graphics.set_note_type(note_data, val)
	is_multi_note = val
	
func handles_input(event: InputEventHB) -> bool:
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	var is_input_in_range: bool = abs((game.time_msec) - note_data.time) < game.judge.get_target_window_msec()
	return event.is_action_pressed(action) and is_input_in_range and not waiting_for_multi_judgement

func process_input(event: InputEventHB):
	if current_note_sound:
		current_note_sound.stop()
		current_note_sound.queue_free()
		current_note_sound = null
	# Slight hack, because since 0.17 we flush inputs at a fixed point instead of as they come, the count
	# of pressed actions might be 2 without passing through 1 ever if the input is frame perfect, which means
	# we wouldn't capture the second input event, this leads
	# to the empty note sound being played and the second event being passed to the next note if close enough,
	# to solve this, we store the last frame held count into processed_held_count and increment it every time we
	# process an input and use that instead of get_action_press_count, this way we will make sure to capture
	# both events, but only when needed the reasoning behind this approach is that this way we only consume
	# as many events are needed for the double note to be hit, leaving subsequent input events to be processed 
	# by other notes such as a very close note after this note
	processed_held_count += 1
	
	if processed_held_count >= 2:
		_on_note_pressed(event)
	else:
		var sound_name := "note_hit"
		if note_data.note_type == HBNoteData.NOTE_TYPE.HEART:
			sound_name = "slide_empty"
		if not game.is_sound_debounced(sound_name) and not UserSettings.user_settings.play_hit_sounds_only_when_hit:
			game.debounce_sound(sound_name)
			current_note_sound = HBGame.instantiate_user_sfx(sound_name)
			# We delay this by 32 ms to allow ~two frames before it starts playing the sound
			# becuase otherwise the sound is very noticeable after eirexe got a bigger pp and made
			# the audio engine faster
			current_note_sound.schedule_start_time(Shinobu.get_dsp_time() + 34)
			current_note_sound.start()
		game.add_child(current_note_sound)

func _on_note_pressed(event = null):
	var judgement := game.judge.judge_note(game.time_msec, note_data.time) as int
	if note_data.note_type == HBNoteData.NOTE_TYPE.HEART:
		judgement = max(HBJudge.JUDGE_RATINGS.FINE, judgement) # Heart notes always give at least a fine
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
	super.process_note(time_msec)
	
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	var new_held_count = game.game_input_manager.get_action_press_count(action)
	
	processed_held_count = current_frame_held_count
	current_frame_held_count = new_held_count
	
	if is_autoplay_enabled():
		if is_in_autoplay_schedule_range(time_msec, note_data.time) and not scheduled_autoplay_sound:
			var hit_sound := "double_heart_note_hit" if note_data.note_type == HBBaseNote.NOTE_TYPE.HEART else "double_note_hit"
			schedule_autoplay_sound(hit_sound, time_msec, note_data.time)
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
