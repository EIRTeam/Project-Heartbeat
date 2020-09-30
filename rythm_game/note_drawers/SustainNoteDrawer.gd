extends "res://rythm_game/note_drawers/SingleNoteDrawer.gd"

var press_count = 0

var pressed = false

onready var note_graphic2 = get_node("Note2")


func _init():
	sine_drawer = preload("res://rythm_game/SineDrawerSustain.gd").new()
	disable_trail_margin = true
func set_connected_notes(val):
	.set_connected_notes(val)
	sine_drawer.show()
func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type, connected_notes.size() > 0, true)
	target_graphic.set_note_type(note_data, connected_notes.size() > 0)
	$Note2.set_note_type(note_data.note_type, connected_notes.size() > 0, true)
func _on_note_judged(judgement, prevent_free = false):
	if not prevent_free:
		._on_note_judged(judgement, false)
		return
	if judgement >= HBJudge.JUDGE_RATINGS.FINE:
		pressed = true
		connected_notes = [note_data]
		show_note_hit_effect()
		note_graphic.hide()
		set_process_unhandled_input(true)
	else:
		._on_note_judged(judgement, false)
func draw_trail(time: float):
	.draw_trail(time)
	if pressed:
		sine_drawer.time = 1.0
	var time_out = get_time_out()
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0) - note_data.get_duration()
	var t = (time_out_distance / time_out)
	sine_drawer.trail_position = t
	
func _on_game_size_changed():
	._on_game_size_changed()
	if game.time * 1000.0 < note_data.time + note_data.get_duration():
		$Note2.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	
func update_arm_position(time: float):
	if pressed:
		target_graphic.arm2_position = 0.0
	else:
		target_graphic.arm2_position = 1.0 - ((note_data.time - time*1000) / get_time_out())
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0) - note_data.get_duration()
	target_graphic.arm_position = (time_out_distance / get_time_out())
	
func update_graphic_positions_and_scale(time: float):
	.update_graphic_positions_and_scale(time)
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0) - note_data.get_duration()
	note_graphic2.position = game.remap_coords(HBUtils.calculate_note_sine(time_out_distance/get_time_out(), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance))
	if time * 1000.0 > (note_data.time + note_data.get_duration()):
		var disappereance_time = note_data.end_time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		note_graphic2.scale = Vector2(new_scale, new_scale)
	

func handle_input(event: InputEvent, time: float):
	if event is InputEventAction:
		for action in note_data.get_input_actions():
			if pressed and event.is_action_released(action):
				var result = .judge_note_input(event, time-(note_data.get_duration()/1000.0))
				var rating = HBJudge.JUDGE_RATINGS.WORST
				get_tree().set_input_as_handled()
				if result.has_rating:
					rating = result.resulting_rating
				emit_signal("notes_judged", [note_data], rating, false)
				._on_note_judged(rating)
				game.add_score(HBNoteData.NOTE_SCORES[rating])
				if rating >= game.judge.JUDGE_RATINGS.FINE:
					game.play_note_sfx()
				set_process_unhandled_input(false)
		
func _on_game_time_changed(time: float):
	if not is_queued_for_deletion():
		if not pressed:
			._on_game_time_changed(time)
		else:
			update_graphic_positions_and_scale(time)
			if time >= (note_data.end_time + game.judge.get_target_window_msec()) / 1000.0:
				emit_signal("notes_judged", [note_data], HBJudge.JUDGE_RATINGS.WORST, false)
				emit_signal("note_removed")
				queue_free()
				
func _on_unhandled_action_released(event, event_uid):
	handle_input(event, game.time)
				
func _handle_unhandled_input(event: InputEvent):
	if not pressed:
		._handle_unhandled_input(event)
	else:
		handle_input(event, game.time)

func reset_note_state():
	pressed = false
