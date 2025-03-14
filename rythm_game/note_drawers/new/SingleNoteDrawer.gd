extends HBNewNoteDrawer
	
var waiting_for_multi_judgement := false
	
func handles_input(event: InputEventHB) -> bool:
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	var is_input_in_range: bool = abs(event.game_time - note_data.time * 1000) < game.judge.get_target_window_usec()
	return event.is_action_pressed(action) and is_input_in_range and not waiting_for_multi_judgement
	
func process_input(event: InputEventHB):
	_on_note_pressed(event)

func _on_note_pressed(event: InputEventHB = null):
	var game_time := event.game_time if event else game.time_usec
	var judgement := game.judge.judge_note_usec(game_time, note_data.time * 1000) as int
	if note_data.note_type == HBNoteData.NOTE_TYPE.HEART:
		judgement = max(HBJudge.JUDGE_RATINGS.FINE, judgement) # Heart notes always give at least a fine
	if not is_autoplay_enabled():
		var sfx_type := "note_hit"
		if note_data.note_type == HBBaseNote.NOTE_TYPE.HEART:
			sfx_type = "heart_hit"
		fire_and_forget_user_sfx(sfx_type)
	
	assert(is_autoplay_enabled() or event)
	if not event and is_autoplay_enabled() and note_data is HBNoteData:
		# fake event for autoplay
		var fake_event := InputEventHB.new()
		event = fake_event
		event.game_time = game_time
		event.event_uid = note_data.note_type
		
	
	emit_signal("judged", judgement, false, note_data.time, event)
	
	if not is_multi_note:
		game.add_score(HBNoteData.NOTE_SCORES[judgement])
		emit_signal("finished")
	else:
		hide()
		waiting_for_multi_judgement = true
	if judgement >= HBJudge.JUDGE_RATINGS.FINE:
		show_note_hit_effect(note_data.position)

func process_note(time_usec: int):
	super.process_note(time_usec)
	
	var note_time_usec := note_data.time * 1000
	
	if is_autoplay_enabled():
		if not scheduled_autoplay_sound:
			if is_in_autoplay_schedule_range(time_usec / 1000, note_data.time):
				var is_heart: bool = note_data.note_type == HBBaseNote.NOTE_TYPE.HEART
				schedule_autoplay_sound("heart_hit" if is_heart else "note_hit", time_usec / 1000, note_data.time)
		if time_usec >= note_time_usec:
			_on_note_pressed()
	if time_usec > note_time_usec + game.judge.get_target_window_usec() and not waiting_for_multi_judgement:
		emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.time, null)
		emit_signal("finished")

func _on_multi_note_judged(judgement: int):
	emit_signal("finished")
