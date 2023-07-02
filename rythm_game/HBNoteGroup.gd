class_name HBNoteGroup

# note_data: note_drawer map
var note_drawers := {}
var note_datas := []
# List of notes that have finished processing
var finished_notes := []

class HBNoteJudgementInfo:
	var time_msec: int
	var judgement: int
	var note_data: HBBaseNote
	var input_event: InputEventHB
	var wrong := false

# note_data: note_judgement info map, if a note is in here it means it has
# already been judged within the multi-system, it can still emit judgements though
var note_judgement_infos := {}

var game

var current_time_msec := 0

# final judgement is the final judgement when judging multiple notes, otherwise it's the same as
# judgement_infos[0].judgement
# judgement_target_time is the note's time in the case of normal notes, or end_time in the case of sustains
signal notes_judged(final_judgement, judgement_infos, judgement_target_time, wrong)

const LaserRenderer = preload("res://rythm_game/Laser.tscn")
var laser_renderer: MultiLaser

var center = Vector2.ZERO

var last_laser_positions := {}

func _point_sort(a, b):
	if (a.x - center.x >= 0 && b.x - center.x < 0):
		return true;
	if (a.x - center.x < 0 && b.x - center.x >= 0):
		return false;
	if (a.x - center.x == 0 && b.x - center.x == 0):
		if (a.y - center.y >= 0 || b.y - center.y >= 0):
			return a.y > b.y
		return b.y > a.y

	# compute the cross product of vectors (center -> a) x (center -> b)
	var det = (a.x - center.x) * (b.y - center.y) - (b.x - center.x) * (a.y - center.y)
	if (det < 0):
		return true
	if (det > 0):
		return false

	# points a and b are on the same line from the center
	# check which point is closer to the center
	var d1 = (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y)
	var d2 = (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y)
	return d1 > d2

func update_multi_note_renderer():
	var scale_x = 1.0
	if note_datas.size() > 1:
		var points := []
		for note_data in note_datas:
			var note_drawer: HBNewNoteDrawer = note_drawers.get(note_data)
			if note_drawer:
				points.append(note_drawer.note_graphics.position)
				last_laser_positions[note_data] = note_drawer.note_graphics.position
			else:
				points.append(last_laser_positions.get(note_data, Vector2.ZERO))
		center = Vector2.ZERO
		for point in points:
			center += point
		center /= float(points.size())
		points = Array(points)
		points.sort_custom(Callable(self, "_point_sort"))
		if note_datas.size() > 2:
			points.append(points[0])
		laser_renderer.positions = points
		laser_renderer.width_scale = 1.0
		laser_renderer.show()

# Returns true if the group is done
func process_group(time_msec: int) -> bool:
	if game.game_mode == 1:
		finished_notes.clear()
		note_judgement_infos.clear()
		if laser_renderer:
			if time_msec > get_hit_time_msec():
				laser_renderer.hide()
			else:
				laser_renderer.show()
	current_time_msec = time_msec
	for nd in note_datas:
		var note_data := nd as HBBaseNote
		if note_data in finished_notes:
			continue
		if note_data.time - note_data.get_time_out(game.get_note_speed_at_time(note_data.time)) <= time_msec:
			var note_drawer
			if not note_data in note_drawers:
				note_drawer = create_note_drawer(note_data)
			else:
				note_drawer = note_drawers[note_data]
			note_drawer.process_note(time_msec)
	
	var should_finish := note_datas.size() == finished_notes.size()
	if note_judgement_infos.size() != note_datas.size() and note_datas.size() > 1:
		if not laser_renderer and note_drawers.size() > 0:
			laser_renderer = LaserRenderer.instantiate()
			var base_points := []
			base_points.resize(note_datas.size() + (1 if note_datas.size() > 2 else 0))
			base_points.fill(Vector2.ZERO)
			laser_renderer.positions = base_points
			_on_note_add_node_to_layer("Laser", laser_renderer)
			laser_renderer.show()
			last_laser_positions.clear()
			update_multi_note_renderer()
		else:
			update_multi_note_renderer()
	elif laser_renderer:
		laser_renderer.queue_free()
		laser_renderer = null
	
	if should_finish:
		finished_notes.clear()
	
	return should_finish

# Called by the game each frame to process new input events, returns false if the input should pass through
# this group
func process_input(event: InputEventHB) -> bool:
	var will_consume_input := finished_notes.size() != note_datas.size()
	var input_was_consumed_by_note := false
	# HACK: We ignore slide left and right to prevent the user
	# from getting a wrong on slides when using the heart action
	var heart_bypass_hack := false
	var is_analog_event: bool = event.is_action_pressed("slide_left") or event.is_action_pressed("slide_right") or event.is_action_pressed("heart_note")
	var is_input_in_range: bool = abs(game.time_msec - get_hit_time_msec()) < game.judge.get_target_window_msec()
	
	var is_macro = event.actions.size() > 1
	var is_multi = note_datas.size() > 1
	var has_note_type = false

	for note in note_datas:
		var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note.note_type][0] as String
		if action in event.actions:
			has_note_type = true
			break
	
	# In multi notes, when a note type is pressed that is in the list of notes contained we disable wrongs
	# in general
	var single_in_multi_wrong_bypass = has_note_type and (is_multi and not is_macro)
	
	if is_input_in_range and not is_analog_event and event.is_pressed() and not single_in_multi_wrong_bypass:
		# We count how many inputs in this event are normal non-analog notes, to check if the amount of inputs is higher than our note count
		# this is to prevent "cheater" macros with too many note inputs assigned, however we only do this check on notes that have not been judged
		# Note: this check should only be done for note groups that contain non-analog notes
		# We should, hoever, ignore if the the action is not a macro
		var non_analog_note_input_count := 0
		for action in event.actions:
			if not action in ["slide_left", "slide_right", "heart_note"]:
				non_analog_note_input_count += 1
		
		var non_analog_note_count := 0
		for note in note_datas:
			if not note in note_judgement_infos:
				var is_analog_note: bool = note.note_type in [HBBaseNote.NOTE_TYPE.HEART, HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_RIGHT]
				if not is_analog_note:
					non_analog_note_count += 1
		if non_analog_note_count > 0 and non_analog_note_input_count > note_datas.size():
			_on_wrong()
			game._play_empty_note_sound(event)
			return true
	
	# For pressed inputs we first figure out if any of our notes will accept it
	for i in range(note_drawers.size()-1, -1, -1):
		var note := note_drawers.keys()[i] as HBBaseNote
		var note_drawer := note_drawers[note] as HBNewNoteDrawer
		if note_drawer.handles_input(event) and not note in finished_notes:
			note_drawer.process_input(event)
			input_was_consumed_by_note = true
			break
		if not note.note_type == HBBaseNote.NOTE_TYPE.HEART:
			if (event.is_action_pressed("heart_note")):
				heart_bypass_hack = true
				
		# Same but the other way around for hearts
		if note.note_type == HBBaseNote.NOTE_TYPE.HEART:
			if (event.is_action_pressed("slide_left") or event.is_action_pressed("slide_right")):
				heart_bypass_hack = true
		# Make normal note ignore slides and vice versa
		if not note.note_type == HBBaseNote.NOTE_TYPE.HEART and not (note is HBNoteData and note.is_slide_note()):
			if is_analog_event:
				heart_bypass_hack = true
		elif not is_analog_event:
			heart_bypass_hack = true
	
	if event.is_pressed() and note_judgement_infos.size() != note_datas.size():
		if not input_was_consumed_by_note and is_input_in_range:
			if not heart_bypass_hack and not single_in_multi_wrong_bypass:
				# we got a wrong, pass it to the game
				_on_wrong()
				game._play_empty_note_sound(event)
				input_was_consumed_by_note = true
	
	return input_was_consumed_by_note

# if true means any input not handled by this must be ignored, this is used for
# preventing future groups from receiving input before the previous ones have
# processed their primary input
func is_blocking_input():
	return note_judgement_infos.size() < note_datas.size()

func is_finished() -> bool:
	return finished_notes.size() == note_datas.size()

# Rules of judgement calculation for multi notes:
# The judgement will be the judgement that has the most count
# unless one of the judgements is safe, sad or worst, in which case the worst of the three
# will be the judgement
# returns -1 if no rating is possible from the current information
func calculate_judgement(judgement_infos: Array) -> int:
	var judgement_counts := {}
	for i in range(judgement_infos.size()):
		var judgement_info := judgement_infos[i] as HBNoteJudgementInfo
		if not judgement_info.judgement in judgement_counts:
			judgement_counts[judgement_info.judgement] = 0
		judgement_counts[judgement_info.judgement] += 1
	
	if judgement_counts.has(HBJudge.JUDGE_RATINGS.WORST):
		return HBJudge.JUDGE_RATINGS.WORST
	elif judgement_counts.has(HBJudge.JUDGE_RATINGS.SAD):
		return HBJudge.JUDGE_RATINGS.SAD
	elif judgement_counts.has(HBJudge.JUDGE_RATINGS.SAFE):
		return HBJudge.JUDGE_RATINGS.SAFE
	elif judgement_counts.get(HBJudge.JUDGE_RATINGS.FINE, 0) > judgement_counts.get(HBJudge.JUDGE_RATINGS.COOL, 0):
		return HBJudge.JUDGE_RATINGS.FINE
	elif judgement_counts.get(HBJudge.JUDGE_RATINGS.COOL, 0) > 0:
		return HBJudge.JUDGE_RATINGS.COOL
	return -1
		
func _on_wrong():
	for judgement in note_judgement_infos.values():
		judgement.wrong = true
	# Calculate the "average" judgement (see calculate_judgement above)
	var final_judgement := game.judge.judge_note(game.time_msec, note_datas[0].time) as int
	if note_judgement_infos.size() > 0:
		var c := calculate_judgement(note_judgement_infos.values())
		if c != -1:
			final_judgement = c
	for note in note_datas:
		var drawer := note_drawers.get(note, null) as HBNewNoteDrawer
		if drawer:
			drawer._on_wrong(final_judgement)
		if not note in note_judgement_infos:
			var note_judgement_info := HBNoteJudgementInfo.new()
			note_judgement_info.note_data = note
			note_judgement_info.time_msec = current_time_msec
			note_judgement_info.judgement = final_judgement
			note_judgement_infos[note] = note_judgement_info
		_on_note_finished(note)
	emit_signal("notes_judged", final_judgement, note_judgement_infos.values(), get_hit_time_msec(), true)

func create_note_drawer(note_data: HBBaseNote):
	var note_drawer = note_data.get_drawer_new().instantiate()
	note_drawer.game = game
	note_drawer.note_data = note_data
	note_drawers[note_data] = note_drawer
	note_drawer.connect("add_node_to_layer", Callable(self, "_on_note_add_node_to_layer"))
	note_drawer.connect("remove_node_from_layer", Callable(self, "_on_note_remove_node_from_layer"))
	game.game_ui.get_notes_node().add_child(note_drawer)
	note_drawer.is_multi_note = note_datas.size() > 1
	note_drawer.note_init()
	note_drawer.connect("judged", Callable(self, "_on_note_judged").bind(note_data))
	note_drawer.connect("finished", Callable(self, "_on_note_finished").bind(note_data))
	return note_drawer
				
func _on_note_add_node_to_layer(layer_name: String, node: Node):
	game.game_ui.get_drawing_layer_node(layer_name).add_child(node)

func _on_note_remove_node_from_layer(layer_name: String, node: Node):
	game.game_ui.get_drawing_layer_node(layer_name).remove_child(node)

# Independent means that a note judgement should be independent of the multi system, for example for
# slide chains or the second hit of a sustain note
# judgement, independent, target_time, event
func _on_note_judged(judgement: int, independent: bool, judgement_target_time: int, input_event: InputEventHB, note_data: HBBaseNote):
	var judgement_info := HBNoteJudgementInfo.new()
	judgement_info.judgement = judgement
	judgement_info.time_msec = current_time_msec
	judgement_info.note_data = note_data
	judgement_info.input_event = input_event
	if not independent:
		note_judgement_infos[note_data] = judgement_info
		if note_judgement_infos.size() == note_datas.size():
			var multi_judgement := calculate_judgement(note_judgement_infos.values())
			if note_datas.size() > 1:
				game.add_score(HBNoteData.NOTE_SCORES[multi_judgement])
				for note_drawer in note_drawers.values():
					note_drawer._on_multi_note_judged(multi_judgement)
			emit_signal("notes_judged", multi_judgement, note_judgement_infos.values(), get_hit_time_msec(), false)
	else:
		emit_signal("notes_judged", judgement, [judgement_info], judgement_target_time, false)

func _on_note_finished(note_data: HBBaseNote):
	var drawer := note_drawers.get(note_data) as HBNewNoteDrawer
	if drawer:
		drawer.queue_free()
		note_drawers.erase(note_data)
	if not note_data in finished_notes:
		finished_notes.append(note_data)
				
func get_start_time_msec() -> int:
	var t := 0
	if note_datas.size() > 0:
		t = note_datas[0].time - note_datas[0].get_time_out(game.get_note_speed_at_time(note_datas[0].time))
		for note_data in note_datas:
			var time_out = note_data.get_time_out(game.get_note_speed_at_time(note_data.time))
			t = min(t, note_data.time - time_out)
	return t

func get_end_time_msec() -> int:
	var t := 0
	if note_datas.size() > 0:
		t = note_datas[0].time
		for note_data in note_datas:
			if note_data is HBBaseNote:
				t = max(t, note_data.time)
			if note_data is HBNoteData and note_data.is_slide_note():
				if note_data in game.slide_hold_chains:
					for slide in game.slide_hold_chains[note_data].pieces:
						t = max(t, slide.time)
	return t

func get_hit_time_msec() -> int:
	var t := 0
	if note_datas.size() > 0:
		t = note_datas[0].time
	return t

func add_note_to_group(note: HBBaseNote):
	note_datas.append(note)

func remove_note_from_group(note: HBBaseNote):
	if note in note_datas:
		var note_drawer = note_drawers.get(note)
		if note_drawer:
			note_drawer.queue_free()

func _notification(what: int):
	if what == NOTIFICATION_PREDELETE:
		for note_drawer in note_drawers.values():
			if not note_drawer.is_queued_for_deletion():
				note_drawer.queue_free()
		note_drawers.clear()

# Called by editor, resets all group info
func reset_group():
	finished_notes.clear()
	for note_drawer in note_drawers.values():
		if not note_drawer.is_queued_for_deletion():
			note_drawer.queue_free()
	note_drawers.clear()
	last_laser_positions.clear()
	note_judgement_infos.clear()
	if laser_renderer:
		laser_renderer.queue_free()
		laser_renderer = null

func notify_rollback():
	for drawer in note_drawers.values():
		drawer._on_rollback()
