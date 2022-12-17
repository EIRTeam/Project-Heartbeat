extends HBRhythmGameBase

class_name HBRhythmGame

signal max_hold
signal hold_score_changed
signal show_slide_hold_score
signal hold_released
signal hold_released_early
signal hold_started(held_notes)
signal game_over

const LOG_NAME = "RhythmGameHeartbeat"
const MAX_HOLD = 3300  # miliseconds
const WRONG_COLOR = "#ff6524"
const SLIDE_HOLD_PIECE_SCORE = 10
const TRAIL_RESOLUTION = 60

# Number of slide hold pieces that are turned blue per second on slide chains
const BLUE_SLIDE_PIECES_PER_SECOND = 93.75

# Notes currently being held (modern style)
var held_notes = []
# Map of notes currently being held, mapped as note_tpye -> event uid
var held_note_event_map = {}
var current_hold_score = 0.0
var current_hold_start_time = 0.0
var accumulated_hold_score = 0.0  # for when you hit another hold note after already holding

const STARTING_HEALTH_VALUE = 50
var health := STARTING_HEALTH_VALUE
var fail_combo := 0

# List of slide hold note chains
# It's a list key, contains an array of slide notes
# hold pieces.
var slide_hold_chains = {}

# List of slide hold note chains that are active
# It is an array of dictionaris, each dictionary contains a slide hold piece array
# (this array contains only remaining ones in the chain), this uses "pieces" as key
# it also has an AudioStreamPlayer for the loop, called sfx_player
# it finally contains a reference to the original slide note that starts the chain
# as slide_note
var active_slide_hold_chains = []

var precalculated_note_trails = {}

var health_system_enabled := true

func precalculate_note_trails(points):
	precalculated_note_trails = {}
	var prev_point: HBBaseNote = null
	for point in points:
		if point is HBBaseNote:
			if prev_point:
				var comparison_properties = ["oscillation_amplitude", "oscillation_frequency",
				"entry_angle"]
				var equal_so_far = true
				for property in comparison_properties:
					if point.get(property) != prev_point.get(property):
						equal_so_far = false
						break
				if equal_so_far and point.get_time_out(get_bpm_at_time(point.time)) == prev_point.get_time_out(get_bpm_at_time(prev_point.time)):
					precalculated_note_trails[point] = precalculated_note_trails[prev_point]
				else:
					precalculated_note_trails[point] = _precalculate_note_trail(point)
			else:
				precalculated_note_trails[point] = _precalculate_note_trail(point)
			prev_point = point
	
func _precalculate_note_trail(note_data: HBBaseNote):
	var points = PoolVector2Array()
	var points2 = PoolVector2Array()
	
	points.resize(TRAIL_RESOLUTION)
	points2.resize(TRAIL_RESOLUTION)
	
	var offset = -note_data.position
	
	var time_out = note_data.get_time_out(get_bpm_at_time(note_data.time))
	for i in range(TRAIL_RESOLUTION):
		var t_trail_time = time_out * (i / float(TRAIL_RESOLUTION-1))
		var t = (t_trail_time / time_out) * 2.25
		t = t - 0.25

		var point1_internal = HBUtils.calculate_note_sine(1.0 - t, note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance)
		var point1 = point1_internal + offset
		
		points.set(TRAIL_RESOLUTION - i - 1, point1)
	return {"points1": points}

func get_note_trail_points(note_data: HBBaseNote):
	if note_data in precalculated_note_trails:
		return precalculated_note_trails[note_data]
	else:
		return _precalculate_note_trail(note_data)

func make_group(notes: Array, extra_notes: Array, group_position, time):
	var group = .make_group(notes, extra_notes, group_position, time)
	
	var slide_count = 0
	var has_chain = false
	for note in group.notes:
		if note is HBNoteData:
			if note.is_slide_hold_piece():
				has_chain = true
				if slide_count > 1:
					break
			if note.is_slide_note():
				slide_count += 1
				if has_chain and slide_count > 1:
					break
	
	# Game disables some optimizations when simultaneous slide chains exist.
	if slide_count > 1 and has_chain:
		group.notes.sort_custom(self, "_sort_notes_by_appear_time")
	
	return group
	
#func _process_timing_points_into_groups(points):
#	# Group related notes for performance reasons, so we can precompute stuff
#	var timing_points_grouped = []
#	var last_notes = []
#	var group_position = 0
#	var extra_notes = []
#
#	for i in range(points.size()):
#		var own_extra_notes = []
#		var point = points[i]
#		if point is HBBaseNote:
#			if point is HBNoteData:
#				if point.is_slide_hold_piece():
#					continue
#			var should_make_group = i == timing_points.size()-1 \
#					or timing_points[i+1].time != point.time
#
#			if should_make_group:
#				var group = make_group(last_notes + [point], own_extra_notes + extra_notes, group_position, point.time)
#				group_position += 1
#				last_notes = []
#				own_extra_notes = []
#				extra_notes = []
#				timing_points_grouped.append(group)
#			if not should_make_group:
#				extra_notes += own_extra_notes
#				last_notes.append(point)
#	return timing_points_grouped
	
func kill_active_slide_chains():
	for note in notes_on_screen:
		if note in slide_hold_chains:
			var drawer = get_note_drawer(note)
			if drawer:
				if drawer.is_slide_chain_active():
					drawer.kill_note()
func _set_timing_points(points):
	._set_timing_points(points)
	
	
func _game_ready():
	._game_ready()
	sfx_pool.add_sfx("note_hit", UserSettings.user_settings.get_sound_volume_linear("note_hit"))
	sfx_pool.add_sfx("slide_hit", UserSettings.user_settings.get_sound_volume_linear("slide_hit"))
	sfx_pool.add_sfx("slide_empty", UserSettings.user_settings.get_sound_volume_linear("slide_empty"))
	sfx_pool.add_sfx("heart_hit", UserSettings.user_settings.get_sound_volume_linear("heart_hit"))
	sfx_pool.add_sfx("slide_chain_loop", UserSettings.user_settings.get_sound_volume_linear("slide_chain_loop"))
	sfx_pool.add_sfx("slide_chain_ok", UserSettings.user_settings.get_sound_volume_linear("slide_chain_ok"))
	sfx_pool.add_sfx("slide_chain_start", UserSettings.user_settings.get_sound_volume_linear("slide_chain_start"))
	sfx_pool.add_sfx("slide_chain_fail", UserSettings.user_settings.get_sound_volume_linear("slide_chain_fail"))
	sfx_pool.add_sfx("double_note_hit", UserSettings.user_settings.get_sound_volume_linear("double_note_hit"))
	sfx_pool.add_sfx("double_heart_note_hit", UserSettings.user_settings.get_sound_volume_linear("double_heart_note_hit"))
	#SLIDE: 9dbup
	
	# TODO: Bake in echo
	#sfx_pool.add_sfx("slide_chain_loop", 4 * UserSettings.user_settings.get_sound_volume_db("slide_chain_loop"), get_bus_for_sfx("slide_chain_loop"))
	#sfx_pool.add_sfx("slide_chain_ok", 4 * UserSettings.user_settings.get_sound_volume_db("slide_chain_ok"), get_bus_for_sfx("slide_chain_ok"))
	#sfx_pool.add_sfx("slide_chain_start", 4 * UserSettings.user_settings.get_sound_volume_db("slide_chain_start"), get_bus_for_sfx("slide_chain_start"))
	#sfx_pool.add_sfx("slide_chain_fail", 4 * UserSettings.user_settings.get_sound_volume_db("slide_chain_fail"), get_bus_for_sfx("slide_chain_fail"))
	#sfx_pool.add_sfx("double_note_hit", 2.0 * UserSettings.user_settings.get_sound_volume_db("double_note_hit"), get_bus_for_sfx("double_note_hit"))
	#sfx_pool.add_sfx("double_heart_note_hit", 2.0 * UserSettings.user_settings.get_sound_volume_db("double_heart_note_hit"), get_bus_for_sfx("double_heart_note_hit"))
	# double_note_sfx_player = _create_sfx_player(preload("res://sounds/sfx/double_note.wav"), 2.0, "EchoSFX")
	# hit_effect_sfx_player = _create_sfx_player(preload("res://sounds/sfx/tmb3.wav"), 0)
	# hit_effect_slide_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_note.wav"), 0)
	# slide_chain_loop_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_hold_start.wav"), 4, "EchoSFX")
	# slide_chain_success_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_hold_ok.wav"), 4, "EchoSFX")
	# slide_chain_fail_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_hold_fail.wav"), 4, "EchoSFX")
	# double_note_sfx_player = _create_sfx_player(preload("res://sounds/sfx/double_note.wav"), 2.0, "EchoSFX")
	
func set_chart(chart: HBChart):
	slide_hold_chains = chart.get_slide_hold_chains()
	active_slide_hold_chains = []
	_potential_result = HBResult.new()
	_potential_result.max_score = chart.get_max_score()
	.set_chart(chart)

func set_song(song: HBSong, difficulty: String, assets = null, modifiers = []):
	.set_song(song, difficulty, assets, modifiers)
	if not editing:
		precalculate_note_trails(timing_points)
	else:
		precalculated_note_trails = {}


#	time_begin = OS.get_ticks_usec()
#	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()

# This is cleared after every frame, to ensure we don't play two sounds coming from the same button
var _processed_event_uids = []

# This is to prevent the empty slide sound from being played when it shouldn't, the reason
# why it's not a bool is that we use the frame the heart hack was triggered (by a heart/slide
# sound being played from a note) and ignore all empty sound playbacks in that frame and the next one
# istg 
var _heart_hack_frame = 0
const HEART_HACK_TYPES = [HBBaseNote.NOTE_TYPE.SLIDE_LEFT, HBBaseNote.NOTE_TYPE.SLIDE_RIGHT, HBBaseNote.NOTE_TYPE.HEART]

func _process_input(event):
	if event is InputEventHB:
		for type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
			if event.action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[type] and type in held_notes:
				if not event.event_uid in held_note_event_map[type]:
					held_note_event_map[type].append(event.event_uid)
	._process_input(event)

func _on_unhandled_action_release(action, event_uid):
	for note_type in held_notes:
		if event_uid in held_note_event_map[note_type]:
			if action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_type]:
				held_note_event_map[note_type].erase(event_uid)
				if held_note_event_map[note_type].size() <= 0:
					hold_release()
					emit_signal("hold_released_early")
					break


func get_closest_notes():
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = get_note_drawer(note_c).note_data
		if (note is HBSustainNote and get_note_drawer(note_c).pressed) \
				or (note is HBNoteData and note.is_slide_note() and get_note_drawer(note_c).is_sliding()):
			continue
		if closest_notes.size() > 0:
			if closest_notes[0].time > note.time:
				closest_notes = [note]
			elif note.time == closest_notes[0].time:
				closest_notes.append(note)
		else:
			closest_notes = [note]
	return closest_notes

# plays note SFX automatically
func play_note_sfx(slide = false):
	if not slide:
		sfx_pool.play_sfx("note_hit")
	else:
		sfx_pool.play_sfx("slide_empty")
func create_note_drawer(timing_point: HBBaseNote):
	var note_drawer = .create_note_drawer(timing_point)
	if timing_point is HBNoteData:
		if timing_point.is_slide_note():
			note_drawer.slide_chain_master = timing_point in slide_hold_chains
	return note_drawer

func set_game_input_manager(manager: HBGameInputManager):
	.set_game_input_manager(manager)
	manager.connect("unhandled_release", self, "_on_unhandled_action_release")

func set_game_ui(ui: HBRhythmGameUIBase):
	.set_game_ui(ui)
	if not health_system_enabled:
		ui.set_health(100, false)
	connect("hold_started", ui, "_on_hold_started")
	connect("hold_released_early", ui, "_on_hold_released_early")
	connect("hold_released", ui, "_on_hold_released")
	connect("max_hold", ui, "_on_max_hold")
	connect("hold_score_changed", ui, "_on_hold_score_changed")
	connect("show_slide_hold_score", ui, "_on_show_slide_hold_score")

func show_slide_hold_score(piece_position, accumulated_score, is_end):
	emit_signal("show_slide_hold_score", piece_position, accumulated_score, is_end)

func _pre_process_game():
	._pre_process_game()

func _process_game(_delta):
	._process_game(_delta)

	# Hold combo increasing and shit
	if held_notes.size() > 0:
		var max_time = current_hold_start_time + (MAX_HOLD / 1000.0)
		var curr_hold_time = min(time, max_time)
		current_hold_score = max(((curr_hold_time - current_hold_start_time) * 1000.0) * held_notes.size(), 0)
		if time >= max_time:
			current_hold_score = int(current_hold_score + accumulated_hold_score)
			emit_signal("max_hold")
			emit_signal("hold_score_changed", accumulated_hold_score + current_hold_score + MAX_HOLD)
			hold_release()
			add_hold_score(MAX_HOLD)
		else:
			emit_signal("hold_score_changed", current_hold_score + accumulated_hold_score)
	var closest_notes = get_closest_notes()
	if closest_notes.size() > 0:
		if not closest_notes[0] is HBNoteData:
			MobileControls.set_input_mode(0)
		else:
			if closest_notes[0].is_slide_note():
				MobileControls.set_input_mode(1)
			else:
				MobileControls.set_input_mode(0)
	# autoplay code
	if game_mode == GAME_MODE.AUTOPLAY:
		if not result.used_cheats:
			result.used_cheats = true
			Log.log(self, "Disabling leaderboard upload for cheated result")
#		var actions_to_press = []
#		var actions_to_release = []
#		for i in range(notes_on_screen.size()-1, -1, -1):
#			var note = notes_on_screen[i]
#			if note is HBBaseNote and note.note_type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
#				if note is HBNoteData and note.is_slide_note() and get_note_drawer(note) and get_note_drawer(note).hit_first:
#					continue
#				if note is HBSustainNote and get_note_drawer(note) and get_note_drawer(note).pressed:
#					if time * 1000.0 > note.end_time:
#						actions_to_release.append(note.get_input_actions()[0])
##						play_note_sfx(note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT)
#				elif time * 1000 > note.time:
#					actions_to_press.append(note.get_input_actions()[0])
##					play_note_sfx(note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT)
#
#		for action in actions_to_release:
#			var a = InputEventHB.new()
#			a.action = action
#			a.pressed = false
#			a.event_uid = game_input_manager.get_event_uid(a)
#			a.triggered_actions_count = 1
#			Input.parse_input_event(a)
#			#game_input_manager.send_input(action, false)
#		game_input_manager.current_input_handled = false
#
#		for action in actions_to_press:
#			# Double note device emulation
#			game_input_manager.digital_action_tracking[action] = {}
#			game_input_manager.digital_action_tracking[action][-1] = {}
#			game_input_manager.digital_action_tracking[action][-1][0] = true
#			game_input_manager.digital_action_tracking[action][-1][1] = true
#			var a = InputEventHB.new()
#			a.action = action
#			a.actions = actions_to_press
#			a.pressed = true
#			a.triggered_actions_count = 1
#			a.event_uid = game_input_manager.get_event_uid(a)
#			Input.parse_input_event(a)
	_processed_event_uids = []

func remove_health():
	var old_health := health
	var fail_reduction = min(fail_combo, 4)
	health -= 5-fail_reduction
	health = max(health, 0)
	game_ui.set_health(health, true, old_health)
	fail_combo += 1
	if old_health == 0 and health == 0:
		emit_signal("game_over")
func increase_health():
	var old_health := health
	health += 1
	health = min(health, 100)
	game_ui.set_health(health, true, old_health)
	fail_combo = 0

func _on_notes_judged_new(final_judgement: int, judgements: Array, judgement_target_time: int, wrong: bool):
	._on_notes_judged_new(final_judgement, judgements, judgement_target_time, wrong)
	
	if health_system_enabled:
		if final_judgement < HBJudge.JUDGE_RATINGS.FINE or wrong:
			remove_health()
		else:
			increase_health()
	
#	for judgement in judgements:
#		if judgement.note_data.note_type in HEART_HACK_TYPES:
#			_heart_hack_frame = Engine.get_frames_drawn()
	
	if not judgements[0].note_data is HBNoteData or (judgements[0].note_data is HBNoteData and not judgements[0].note_data.is_slide_hold_piece()):
		if final_judgement == judge.JUDGE_RATINGS.WORST or wrong:
			add_score(0)
	for j in judgements:
		if j.note_data.note_type in held_notes:
			hold_release()
			emit_signal("hold_released_early")
			break

	if final_judgement < judge.JUDGE_RATINGS.FINE or wrong:
		hold_release()
		emit_signal("hold_released_early")
	else:
		for j in judgements:
			if j.note_data is HBNoteData:
				var n = j.note_data as HBNoteData
				if n.hold:
					var event = j.input_event
					if not n.note_type in held_note_event_map:
						held_note_event_map[n.note_type] = []
					held_note_event_map[n.note_type].clear()
					held_note_event_map[n.note_type].append(event.event_uid)
					# Holds start at (note time-FINE window) regardless of at what time you hit them
					var fine_window_ms = judge.get_window_for_rating(HBJudge.JUDGE_RATINGS.FINE)
					start_hold(n.note_type, false, (n.time - fine_window_ms) / 1000.0)
	if not editing:
		var start_time = current_song.start_time
		var end_time = audio_playback.get_length_msec()
		if current_song.end_time > 0:
			end_time = current_song.end_time
			
		var current_duration = audio_playback.get_length_msec()
		current_duration -= start_time
		current_duration -= audio_playback.get_length_msec() - end_time
		
		var progress: float = (time * 1000.0) - start_time
		progress = progress / float(current_duration)
		

		var point := Vector2(progress * 100.0, result.get_percentage() * 100.0)
		if final_judgement < judge.JUDGE_RATINGS.FINE or wrong:
			result._combo_break_points.append(point)
		result._percentage_graph.append(point)
		result._song_end_time = end_time

# called when a note or group of notes is judged
# this doesn't take care of adding the score
func _on_notes_judged(notes: Array, judgement, wrong, judge_events={}):
	._on_notes_judged(notes, judgement, wrong)
	
	if health_system_enabled:
		if judgement < HBJudge.JUDGE_RATINGS.FINE or wrong:
			remove_health()
		else:
			increase_health()
	
	for note in notes:
		if note.note_type in HEART_HACK_TYPES:
			_heart_hack_frame = Engine.get_frames_drawn()
	
	if not notes[0] is HBNoteData or (notes[0] is HBNoteData and not notes[0].is_slide_hold_piece()):
		if judgement == judge.JUDGE_RATINGS.WORST or wrong:
			add_score(0)
	for n in notes:
		if n.note_type in held_notes:
			hold_release()
			emit_signal("hold_released_early")
			break

	if judgement < judge.JUDGE_RATINGS.FINE or wrong:
		hold_release()
		emit_signal("hold_released_early")
	else:
		for n in notes:
			if n is HBNoteData:
				n = n as HBNoteData
				if n.hold:
					var event = judge_events[n]
					if not n.note_type in held_note_event_map:
						held_note_event_map[n.note_type] = []
					held_note_event_map[n.note_type].clear()
					held_note_event_map[n.note_type].append(event.event_uid)
					# Holds start at (note time-FINE window) regardless of at what time you hit them
					var fine_window_ms = judge.get_window_for_rating(HBJudge.JUDGE_RATINGS.FINE)
					start_hold(n.note_type, false, (n.time - fine_window_ms) / 1000.0)
	if not editing:
		var start_time = current_song.start_time
		var end_time = audio_playback.get_length_msec()
		if current_song.end_time > 0:
			end_time = current_song.end_time
			
		var current_duration = audio_playback.get_length_msec()
		current_duration -= start_time
		current_duration -= audio_playback.get_length_msec() - end_time
		
		var progress: float = (time * 1000.0) - start_time
		progress = progress / float(current_duration)
		

		var point := Vector2(progress * 100.0, result.get_percentage() * 100.0)
		if judgement < judge.JUDGE_RATINGS.FINE or wrong:
			result._combo_break_points.append(point)
		result._percentage_graph.append(point)
		result._song_end_time = end_time
	
func restart():
	kill_active_slide_chains()
	hold_release()
	held_note_event_map = {}
	_potential_result = HBResult.new()
	fail_combo = 0
	if health_system_enabled:
		health = 50
		game_ui.set_health(50, false)
	.restart()

# used by the editor and practice mode to delete slide chain pieces that have no
# parent and sustain notes
func delete_rogue_notes(pos = time):
	.delete_rogue_notes(pos)
	var notes_to_remove = []
	
	for i in range(notes_on_screen.size() - 1, -1, -1):
		if notes_on_screen[i] is HBBaseNote:
			var group = notes_on_screen[i].get_meta("group") as NoteGroup
			if group.time - group.precalculated_timeout > pos * 1000.0:
				notes_to_remove.append(notes_on_screen[i])
	for note in notes_to_remove:
		if note in notes_on_screen:
			remove_note_from_screen(notes_on_screen.find(note), false)

func remove_note_from_screen(i, update_last_hit = true):
	if i != -1:
		if not editing or previewing:
			if update_last_hit:
				if notes_on_screen[i].has_meta("group_position"):
					if not active_slide_hold_chains.size() > 0:
						var nhi = notes_on_screen[i].get_meta("group_position")
						if nhi < last_hit_index:
							last_hit_index = nhi
	.remove_note_from_screen(i, update_last_hit)
	
# Used by editor to reset hit notes and allow them to appear again
func reset_hit_notes():
	.reset_hit_notes()
			
var _potential_result = HBResult.new()
func get_potential_result():
	return _potential_result

func add_score(score_to_add):
	_potential_result.score += 1000.0
	.add_score(score_to_add)
func add_hold_score(score_to_add):
	result.hold_bonus += score_to_add
	_potential_result.hold_bonus += score_to_add
	_potential_result.score += score_to_add
	.add_score(score_to_add)


func add_slide_chain_score(score_to_add):
	result.slide_bonus += score_to_add
	_potential_result.slide_bonus += score_to_add
	_potential_result.score += score_to_add
	.add_score(score_to_add)

func hold_release():
	if held_notes.size() > 0:
		add_hold_score(round(current_hold_score + accumulated_hold_score))
		accumulated_hold_score = 0
		held_notes = []
		current_hold_score = 0
	emit_signal("hold_released")

func _on_game_finished():
	if not _finished:
		if not disable_ending:
			if not _prevent_finishing:
				hold_release()
				emit_signal("hold_released_early")
	._on_game_finished()

func start_hold(note_type, auto_juggle=false, hold_start_time := time):
	if note_type in held_notes:
		hold_release()
	if held_notes.size() > 0:
		accumulated_hold_score += current_hold_score
	current_hold_score = 0
	current_hold_start_time = hold_start_time
	held_notes.append(note_type)
	emit_signal("hold_started", held_notes)
	
# Used by the editor to invalidate slide chains
func get_intersecting_slide_chains(time_msec: int) -> Array:
	var intersecting := []
	for i in range(slide_hold_chains.size()):
		var slide_chain := slide_hold_chains.values()[i] as HBChart.SlideChain
		var chain_start := slide_chain.slide.time
		if time_msec < chain_start:
			continue
		
		for piece in slide_chain.pieces:
			var chain_end = piece.time
			if chain_end >= time_msec:
				intersecting.append(slide_chain)
				break
		
	return intersecting

var editor_orphaned_subnotes := [] 

var editor_left_slide_notes := []
var editor_right_slide_notes := []

# Grabs all slide chain pieces and tries to put them in a slide chain
func editor_unorphan_subnotes():
	for i in range(editor_orphaned_subnotes.size()-1, -1, -1):
		var note := editor_orphaned_subnotes[i] as HBBaseNote
		var slide_note_array := editor_right_slide_notes
		if note.note_type == HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT:
			slide_note_array = editor_left_slide_notes
		
		
		var pos := slide_note_array.bsearch_custom(note, self, "_sort_notes_by_time")
		pos = min(pos, max(slide_note_array.size()-1, 0))
		if pos < slide_note_array.size():
			var slide_note := slide_note_array[pos] as HBBaseNote
			var slide_chain: HBChart.SlideChain = slide_hold_chains.get(slide_note)
			if not slide_chain:
				slide_chain = HBChart.SlideChain.new()
				slide_chain.slide = slide_note
				slide_hold_chains[slide_note] = slide_chain
			slide_chain.pieces.append(note)
			slide_chain.pieces.sort_custom(self, "_sort_notes_by_time")
			editor_orphaned_subnotes.remove(i)

func editor_add_timing_point(point: HBTimingPoint):
	if point is HBBaseNote:
		var note_data: HBBaseNote = point
		if note_data is HBNoteData:
			if note_data.is_slide_note():
				if note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
					editor_left_slide_notes.insert(editor_left_slide_notes.bsearch_custom(note_data, self, "_sort_notes_by_time"), note_data)
				elif note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
					editor_right_slide_notes.insert(editor_right_slide_notes.bsearch_custom(note_data, self, "_sort_notes_by_time"), note_data)
				if editor_orphaned_subnotes.size() > 0:
					editor_unorphan_subnotes()
			elif note_data.is_slide_hold_piece():
				editor_orphaned_subnotes.append(point)
				editor_unorphan_subnotes()
				return
	.editor_add_timing_point(point)

func editor_remove_timing_point(point: HBTimingPoint):
	if point is HBNoteData:
		if point.is_slide_hold_piece():
			if point in editor_orphaned_subnotes:
				editor_orphaned_subnotes.erase(point)
			else:
				var intersecting_slide_chains := get_intersecting_slide_chains(point.time)
				
				for slide_chain in intersecting_slide_chains:
					var is_of_the_same_type: bool = slide_chain.slide.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT \
							and point.note_type == HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT
							
					is_of_the_same_type = is_of_the_same_type or (slide_chain.slide.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT \
							and point.note_type == HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT)
							
					if is_of_the_same_type:
						var prev_size: int = slide_chain.pieces.size()
						slide_chain.pieces.erase(point)
						if prev_size != slide_chain.pieces.size():
							slide_chain.slide.get_meta("editor_group").reset_group()
			return
		elif point.is_slide_note():
			if point.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
				editor_left_slide_notes.erase(point)
			else:
				editor_right_slide_notes.erase(point)
			var chain: HBChart.SlideChain = slide_hold_chains.get(point)
			if chain:
				slide_hold_chains.erase(chain.slide)
				editor_orphaned_subnotes.append_array(chain.pieces)
				editor_unorphan_subnotes()
	.editor_remove_timing_point(point)

func editor_clear_notes():
	.editor_clear_notes()
	for slide in slide_hold_chains:
		slide.set_meta("editor_group", null)
	slide_hold_chains.clear()
	editor_orphaned_subnotes.clear()
	editor_left_slide_notes.clear()
	editor_right_slide_notes.clear()
