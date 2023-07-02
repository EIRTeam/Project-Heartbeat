extends HBRhythmGameBase

class_name HBRhythmGame

signal max_hold
signal hold_score_changed
signal shown_slide_hold_score
signal hold_released
signal hold_released_early
signal hold_started(held_notes)
signal game_over

const LOG_NAME = "RhythmGameHeartbeat"
const MAX_HOLD = 3300  # miliseconds
const WRONG_COLOR = "#ff6524"
const SLIDE_HOLD_PIECE_SCORE = 10
const TRAIL_RESOLUTION = 60

# Notes currently being held (modern style)
var held_notes = []
# Map of notes currently being held, mapped as note_tpye -> event uid
var held_note_event_map = {}
var current_hold_score: int = 0
var current_hold_start_time: int = 0
var accumulated_hold_score: int = 0  # for when you hit another hold note after already holding

const STARTING_HEALTH_VALUE = 50
var health := STARTING_HEALTH_VALUE
var fail_combo := 0

# List of slide hold note chains
# It's a list key, contains an array of slide notes
# hold pieces.
var slide_hold_chains = {}

var precalculated_note_trails = {}

var health_system_enabled := true

func precalculate_note_trails(points):
	precalculated_note_trails = {}
	var prev_point: HBBaseNote = null
	for point in points:
		if point is HBBaseNote:
			if prev_point:
				var comparison_properties = ["oscillation_amplitude", "oscillation_frequency",
				"entry_angle", "distance"]
				var equal_so_far = true
				for property in comparison_properties:
					if point.get(property) != prev_point.get(property):
						equal_so_far = false
						break
				if equal_so_far and point.get_time_out(get_note_speed_at_time(point.time)) == prev_point.get_time_out(get_note_speed_at_time(prev_point.time)):
					precalculated_note_trails[point] = precalculated_note_trails[prev_point]
				else:
					precalculated_note_trails[point] = _precalculate_note_trail(point)
			else:
				precalculated_note_trails[point] = _precalculate_note_trail(point)
			prev_point = point
	
func _precalculate_note_trail(note_data: HBBaseNote):
	var points = PackedVector2Array()
	var points2 = PackedVector2Array()
	
	points.resize(TRAIL_RESOLUTION)
	points2.resize(TRAIL_RESOLUTION)
	
	var offset = -note_data.position
	
	var time_out = note_data.get_time_out(get_note_speed_at_time(note_data.time))
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

func _set_timing_points(points):
	super._set_timing_points(points)

func _game_ready():
	super._game_ready()
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

func set_chart(chart: HBChart):
	slide_hold_chains = chart.get_slide_hold_chains()
	_potential_result = HBResult.new()
	_potential_result.max_score = chart.get_max_score()
	super.set_chart(chart)

func set_song(song: HBSong, difficulty: String, assets = null, modifiers = []):
	super.set_song(song, difficulty, assets, modifiers)
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
	super._process_input(event)

func _on_unhandled_action_release(action, event_uid):
	for note_type in held_notes:
		if event_uid in held_note_event_map[note_type]:
			if action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_type]:
				held_note_event_map[note_type].erase(event_uid)
				if held_note_event_map[note_type].size() <= 0:
					hold_release()
					emit_signal("hold_released_early")
					break

# plays note SFX automatically
func play_note_sfx(slide = false):
	if not sfx_enabled:
		return
	
	if not slide:
		sfx_pool.play_sfx("note_hit")
	else:
		sfx_pool.play_sfx("slide_empty")

func set_game_input_manager(manager: HBGameInputManager):
	super.set_game_input_manager(manager)
	manager.connect("unhandled_release", Callable(self, "_on_unhandled_action_release"))

func set_game_ui(ui: HBRhythmGameUIBase):
	super.set_game_ui(ui)
	if not health_system_enabled:
		ui.set_health(100, false)
	connect("hold_started", Callable(ui, "_on_hold_started"))
	connect("hold_released_early", Callable(ui, "_on_hold_released_early"))
	connect("hold_released", Callable(ui, "_on_hold_released"))
	connect("max_hold", Callable(ui, "_on_max_hold"))
	connect("hold_score_changed", Callable(ui, "_on_hold_score_changed"))
	connect("shown_slide_hold_score", Callable(ui, "_on_show_slide_hold_score"))

func show_slide_hold_score(piece_position, accumulated_score, is_end):
	emit_signal("show_slide_hold_score", piece_position, accumulated_score, is_end)

func _pre_process_game():
	super._pre_process_game()
	# Hold combo increasing and shit
	if held_notes.size() > 0:
		var max_time = current_hold_start_time + MAX_HOLD
		var curr_hold_time = min(time_msec, max_time)
		current_hold_score = max(((curr_hold_time - current_hold_start_time)) * held_notes.size(), 0)
		if time_msec >= max_time:
			current_hold_score = int(current_hold_score + accumulated_hold_score)
			emit_signal("max_hold")
			emit_signal("hold_score_changed", accumulated_hold_score + current_hold_score + MAX_HOLD)
			hold_release()
			add_hold_score(MAX_HOLD)
		else:
			emit_signal("hold_score_changed", current_hold_score + accumulated_hold_score)

func _process_game(_delta):
	super._process_game(_delta)

	# autoplay code
	if game_mode == GAME_MODE.AUTOPLAY:
		if not result.used_cheats:
			result.used_cheats = true
			Log.log(self, "Disabling leaderboard upload for cheated result")
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
	super._on_notes_judged_new(final_judgement, judgements, judgement_target_time, wrong)
	
	if health_system_enabled:
		if final_judgement < HBJudge.JUDGE_RATINGS.FINE or wrong:
			remove_health()
		else:
			increase_health()
	
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
					start_hold(n.note_type, false, n.time - fine_window_ms)
	if not editing:
		var start_time = current_song.start_time
		var end_time = audio_playback.get_length_msec()
		if current_song.end_time > 0:
			end_time = current_song.end_time
			
		var current_duration = audio_playback.get_length_msec()
		current_duration -= start_time
		current_duration -= audio_playback.get_length_msec() - end_time
		
		var progress: float = time_msec - start_time
		progress = progress / float(current_duration)
		

		var point := Vector2(progress * 100.0, result.get_percentage() * 100.0)
		if final_judgement < judge.JUDGE_RATINGS.FINE or wrong:
			result._combo_break_points.append(point)
		result._percentage_graph.append(point)
		result._song_end_time = end_time

func restart():
	hold_release()
	held_note_event_map = {}
	_potential_result = HBResult.new()
	fail_combo = 0
	if health_system_enabled:
		health = 50
		game_ui.set_health(50, false)
	super.restart()

var _potential_result = HBResult.new()
func get_potential_result():
	return _potential_result

func add_score(score_to_add):
	_potential_result.score += 1000.0
	super.add_score(score_to_add)
func add_hold_score(score_to_add):
	result.hold_bonus += score_to_add
	_potential_result.hold_bonus += score_to_add
	_potential_result.score += score_to_add
	super.add_score(score_to_add)


func add_slide_chain_score(score_to_add):
	result.slide_bonus += score_to_add
	_potential_result.slide_bonus += score_to_add
	_potential_result.score += score_to_add
	super.add_score(score_to_add)

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
	super._on_game_finished()

func start_hold(note_type, auto_juggle=false, hold_start_time := time_msec):
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
		
		
		var pos := slide_note_array.bsearch_custom(note, self._sort_notes_by_time)
		pos = min(pos, max(slide_note_array.size()-1, 0))
		if pos < slide_note_array.size():
			var slide_note := slide_note_array[pos] as HBBaseNote
			if slide_note.time > note.time and pos > 0:
				pos -= 1
				slide_note = slide_note_array[pos]
			if slide_note.time < note.time:
				var slide_chain: HBChart.SlideChain = slide_hold_chains.get(slide_note)
				if not slide_chain:
					slide_chain = HBChart.SlideChain.new()
					slide_chain.slide = slide_note
					slide_hold_chains[slide_note] = slide_chain
				slide_chain.pieces.append(note)
				slide_chain.pieces.sort_custom(Callable(self, "_sort_notes_by_time"))
				editor_orphaned_subnotes.remove_at(i)

func editor_add_timing_point(point: HBTimingPoint, sort_groups: bool = true):
	if point is HBBaseNote:
		var note_data: HBBaseNote = point
		
		if note_data is HBNoteData:
			if note_data.is_slide_note():
				var intersecting_chains := get_intersecting_slide_chains(point.time)
				
				for slide_chain in intersecting_chains:
					var is_of_the_same_type: bool = slide_chain.slide.note_type == point.note_type
					if is_of_the_same_type:
						slide_hold_chains.erase(slide_chain.slide)
						editor_orphaned_subnotes.append_array(slide_chain.pieces)
				
				if note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
					editor_left_slide_notes.insert(editor_left_slide_notes.bsearch_custom(note_data, self._sort_notes_by_time), note_data)
				elif note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT:
					editor_right_slide_notes.insert(editor_right_slide_notes.bsearch_custom(note_data, self._sort_notes_by_time), note_data)
				
				if editor_orphaned_subnotes.size() > 0:
					editor_unorphan_subnotes()
			elif note_data.is_slide_hold_piece():
				editor_orphaned_subnotes.append(point)
				editor_unorphan_subnotes()
				
				return
	
	super.editor_add_timing_point(point, sort_groups)

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
						if slide_chain.pieces.size() == 0:
							slide_hold_chains.erase(slide_chain.slide)
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
	super.editor_remove_timing_point(point)

func editor_clear_notes():
	super.editor_clear_notes()
	for slide in slide_hold_chains:
		slide.set_meta("editor_group", null)
	slide_hold_chains.clear()
	editor_orphaned_subnotes.clear()
	editor_left_slide_notes.clear()
	editor_right_slide_notes.clear()
