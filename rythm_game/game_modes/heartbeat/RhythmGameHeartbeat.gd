extends HBRhythmGameBase

class_name HBRhythmGame

signal max_hold
signal hold_score_changed
signal show_slide_hold_score
signal end_intro_skip_period
signal score_added(added_score)
signal hold_released
signal hold_released_early
signal hold_started(held_notes)

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

var hit_effect_sfx_player: AudioStreamPlayer
var hit_effect_slide_sfx_player: AudioStreamPlayer
var slide_chain_loop_sfx_player: AudioStreamPlayer
var slide_chain_success_sfx_player: AudioStreamPlayer
var slide_chain_fail_sfx_player: AudioStreamPlayer
var double_note_sfx_player: AudioStreamPlayer

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
	
	#var trail_margin = IconPackLoader.get_trail_margin(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type)) * (note_data.distance/1200.0)
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
	
func _process_timing_points_into_groups(points):
	# Group related notes for performance reasons, so we can precompute stuff
	var timing_points_grouped = []
	var last_notes = []
	var group_position = 0
	var extra_notes = []
	
	for i in range(points.size()):
		var own_extra_notes = []
		var point = points[i]
		if point is HBBaseNote:
			if point is HBNoteData:
				if point.is_slide_hold_piece():
					continue
				if point.is_slide_note():
					if point in slide_hold_chains:
						own_extra_notes = slide_hold_chains[point].pieces
			var should_make_group = i == timing_points.size()-1 \
					or timing_points[i+1].time != point.time

			if should_make_group:
				var group = make_group(last_notes + [point], own_extra_notes + extra_notes, group_position, point.time)
				group_position += 1
				last_notes = []
				own_extra_notes = []
				extra_notes = []
				timing_points_grouped.append(group)
			if not should_make_group:
				extra_notes += own_extra_notes
				last_notes.append(point)
	return timing_points_grouped
	
func kill_active_slide_chains():
	for chain in active_slide_hold_chains:
		chain.sfx_player.queue_free()
	active_slide_hold_chains = []
	delete_rogue_notes()
func _set_timing_points(points):
	kill_active_slide_chains()

	._set_timing_points(points)
	
func _game_ready():
	._game_ready()
	hit_effect_sfx_player = _create_sfx_player(preload("res://sounds/sfx/tmb3.wav"), 0)
	hit_effect_slide_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_note.wav"), 0)
	slide_chain_loop_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_hold_start.wav"), 4, "EchoSFX")
	slide_chain_success_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_hold_ok.wav"), 4, "EchoSFX")
	slide_chain_fail_sfx_player = _create_sfx_player(preload("res://sounds/sfx/slide_hold_fail.wav"), 4, "EchoSFX")
	double_note_sfx_player = _create_sfx_player(preload("res://sounds/sfx/double_note.wav"), 2.0, "EchoSFX")
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
#	audio_stream_player.play()
#	audio_stream_player_voice.play()


func _input(event):
	if event is InputEventHB:
		
		# Note SFX
		for type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
			var action_pressed = false
			var actions = HBGame.NOTE_TYPE_TO_ACTIONS_MAP[type]
			for action in actions:
				if event.action == action and event.pressed and not event.is_echo():
					var slide_types = [HBNoteData.NOTE_TYPE.SLIDE_LEFT, HBNoteData.NOTE_TYPE.SLIDE_RIGHT, HBNoteData.NOTE_TYPE.HEART]
					play_note_sfx(type in slide_types)
					action_pressed = true
					break
			if action_pressed:
				break
		for type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
			if event.action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[type] and type in held_notes:
				if not event.event_uid in held_note_event_map[type]:
					held_note_event_map[type].append(event.event_uid)


func _on_unhandled_action_release(action, event_uid):
	for note_type in held_notes:
		if event_uid in held_note_event_map[note_type]:
			held_note_event_map[note_type].erase(event_uid)
			if action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_type] and held_note_event_map[note_type].size() <= 0:
				hold_release()
				emit_signal("hold_released_early")
				break


func get_closest_notes():
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = get_note_drawer(note_c).note_data
		if note is HBSustainNote and get_note_drawer(note_c).pressed:
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
		play_sfx(hit_effect_sfx_player)
	else:
		play_sfx(hit_effect_slide_sfx_player)

func create_note_drawer(timing_point: HBBaseNote):
	var note_drawer = .create_note_drawer(timing_point)
	if timing_point is HBNoteData:
		if timing_point.is_slide_note():
			note_drawer.slide_chain_master = timing_point in slide_hold_chains
	game_input_manager.connect("unhandled_release", note_drawer, "_on_unhandled_action_released")
	return note_drawer

func set_game_input_manager(manager: HBGameInputManager):
	.set_game_input_manager(manager)
	manager.connect("unhandled_release", self, "_on_unhandled_action_release")

func set_game_ui(ui: HBRhythmGameUIBase):
	.set_game_ui(ui)
	connect("hold_started", ui, "_on_hold_started")
	connect("hold_released_early", ui, "_on_hold_released_early")
	connect("hold_released", ui, "_on_hold_released")
	connect("max_hold", ui, "_on_max_hold")
	connect("hold_score_changed", ui, "_on_hold_score_changed")
	connect("show_slide_hold_score", ui, "_on_show_slide_hold_score")

func _process_game(_delta):

	._process_game(_delta)

	# Hold combo increasing and shit
	if held_notes.size() > 0:
		var max_time = current_hold_start_time + (MAX_HOLD / 1000.0)
		current_hold_score = ((time - current_hold_start_time) * 1000.0) * held_notes.size()

		if time >= max_time:
			current_hold_score = int(current_hold_score + accumulated_hold_score)
			emit_signal("max_hold")
			emit_signal("hold_score_changed", current_hold_score + MAX_HOLD)
			hold_release()
			add_hold_score(MAX_HOLD)
		else:
			emit_signal("hold_score_changed", current_hold_score + accumulated_hold_score)
	# handles held slide hold chains
	for ii in range(active_slide_hold_chains.size() - 1, -1, -1):
		var chain = active_slide_hold_chains[ii]
		var slide = chain.slide as HBNoteData
		var blue_notes = max(1, float(time - (chain.slide.time / 1000.0)) * BLUE_SLIDE_PIECES_PER_SECOND)
		var direction_pressed = false
		for action in slide.get_input_actions():
			if game_input_manager.is_action_held(action):
				direction_pressed = true
				break
		var chain_failed = false
		for i in range(chain.pieces.size() - 1, -1, -1):
			var piece = chain.pieces[i]
			var piece_drawer = get_note_drawer(piece) as HBNoteDrawer
			if i <= blue_notes and piece_drawer:
				if direction_pressed:
					piece_drawer.make_blue()
			
			if time * 1000.0 >= piece.time and piece_drawer:
				if not piece_drawer.blue and not direction_pressed and not previewing:
					chain_failed = true
					break
				add_slide_chain_score(SLIDE_HOLD_PIECE_SCORE)
				chain.accumulated_score += SLIDE_HOLD_PIECE_SCORE
				if piece_drawer:
					piece_drawer.show_note_hit_effect()
					piece_drawer.emit_signal("note_removed")
					piece_drawer.queue_free()
					emit_signal("show_slide_hold_score", piece.position, chain.accumulated_score, chain.pieces_hit >= chain.pieces.size())

				chain.pieces_hit += 1
		if chain_failed:
			for piece in chain.pieces:
				var drawer = get_note_drawer(piece)
				timing_points.erase(piece)
				if drawer:
					drawer.emit_signal("note_removed")
					drawer.queue_free()
				chain.sfx_player.queue_free()
				play_sfx(slide_chain_fail_sfx_player)
			active_slide_hold_chains.remove(ii)
		if chain.pieces_hit >= chain.pieces.size():
			chain.sfx_player.queue_free()
			play_sfx(slide_chain_success_sfx_player)
			active_slide_hold_chains.remove(ii)
	# autoplay code
	if Diagnostics.enable_autoplay or previewing:
		if not result.used_cheats:
			result.used_cheats = true
			Log.log(self, "Disabling leaderboard upload for cheated result")
		var actions_to_press = []
		var double_actions_to_press = []
		var actions_to_release = []
		for i in range(notes_on_screen.size() - 1, -1, -1):
			var note = notes_on_screen[i]
			if note is HBBaseNote and note.note_type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
				if note is HBSustainNote and get_note_drawer(note) and get_note_drawer(note).pressed:
					if time * 1000.0 > note.end_time:
						actions_to_release.append(note.get_input_actions()[0])
						play_note_sfx(note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT)
				elif time * 1000 > note.time:
					actions_to_press.append(note.get_input_actions()[0])
					play_note_sfx(note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT or note.note_type == HBBaseNote.NOTE_TYPE.SLIDE_RIGHT)
		for action in actions_to_release:
			var a = InputEventHB.new()
			a.action = action
			a.pressed = false
			
			Input.parse_input_event(a)
		for action in actions_to_press:
			var a = InputEventHB.new()
			
			
			# Double note device emulation
			game_input_manager.digital_action_tracking[action] = {}
			game_input_manager.digital_action_tracking[action][-1] = {}
			game_input_manager.digital_action_tracking[action][-1][0] = true
			game_input_manager.digital_action_tracking[action][-1][1] = true
			a.action = action
			
			a.pressed = true
			
			Input.parse_input_event(a)
			
#			game_input_manager.digital_action_tracking[action] = {}



# called when a note or group of notes is judged
# this doesn't take care of adding the score
func _on_notes_judged(notes: Array, judgement, wrong, judge_events={}):
	._on_notes_judged(notes, judgement, wrong)
	
	if not notes[0] is HBNoteData or (notes[0] is HBNoteData and not notes[0].is_slide_hold_piece()):
		if judgement == judge.JUDGE_RATINGS.WORST or wrong:
			add_score(0)
	
	for n in notes:
		if n.note_type in held_notes:
			emit_signal("hold_released_early")
			hold_release()
			break

	if judgement < judge.JUDGE_RATINGS.FINE or wrong:
		hold_release()
	else:
		for n in notes:
			if n is HBNoteData:
				n = n as HBNoteData
				if n.hold:
					var event: InputEventHB = judge_events[n]
					held_note_event_map[n.note_type] = [event.event_uid]
					start_hold(n.note_type)
	# Slide chain starting shenanigans
	for n in notes:
		if n is HBNoteData:
			if n.is_slide_note():
				if n in slide_hold_chains:
					if not wrong and judgement >= judge.JUDGE_RATINGS.FINE:
						var hold_player = slide_chain_loop_sfx_player.duplicate()
						add_child(hold_player)
						hold_player.play()
						hold_player.connect("finished", self, "_on_slide_hold_player_finished", [hold_player])

						var active_hold_chain = slide_hold_chains[n] as HBChart.SlideChain
						active_hold_chain.sfx_player = hold_player
						active_slide_hold_chains.append(active_hold_chain)
					else:
						# kill slide and younglings if we failed
						for piece in slide_hold_chains[n].pieces:
							if piece in notes_on_screen:
								var piece_drawer = get_note_drawer(piece)
								piece_drawer.emit_signal("note_removed")
								piece_drawer.queue_free()
								# It's not shitty if it works
								piece.set_meta("ignored", true)
	if notes[0] is HBDoubleNote and judgement >= HBJudge.JUDGE_RATINGS.FINE:
		var old_player = sfx_player_queue.pop_back()
		old_player.queue_free()
		remove_child(old_player)
		play_sfx(double_note_sfx_player, false)
# called when the initial slide is done, to swap it out for a slide loop
func _on_slide_hold_player_finished(hold_player: AudioStreamPlayer):
	hold_player.stream = preload("res://sounds/sfx/slide_hold_loop.wav")
	hold_player.seek(0)
	hold_player.volume_db = 4
	hold_player.play()

func restart():
	kill_active_slide_chains()
	hold_release()
	held_note_event_map = {}
	_potential_result = HBResult.new()
	.restart()

# used by the editor and practice mode to delete slide chain pieces that have no
# parent and sustain notes
func delete_rogue_notes(pos_override = null):
	.delete_rogue_notes(pos_override)
	var pos = time
	if pos_override:
		pos = pos_override
	var notes_to_remove = []
	for i in range(notes_on_screen.size() - 1, -1, -1):
		if notes_on_screen[i] is HBBaseNote:
			var group = notes_on_screen[i].get_meta("group") as NoteGroup
			for chain_starter in group.notes:
				if chain_starter is HBSustainNote:
					if chain_starter.time < pos * 1000.0:
						notes_to_remove.append(chain_starter)
				elif chain_starter is HBNoteData:
					if chain_starter.time < pos * 1000.0:
						if chain_starter.is_slide_note():
							if chain_starter in slide_hold_chains:
								notes_to_remove.append(chain_starter)
								var pieces = slide_hold_chains[chain_starter].pieces
								notes_to_remove += pieces
	for note in notes_to_remove:
		note.set_meta("ignored", true)
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
	for chain_m in slide_hold_chains:
		chain_m.set_meta("ignored", false)
		slide_hold_chains[chain_m].pieces_hit = 0
		for piece in slide_hold_chains[chain_m].pieces:
			piece.set_meta("ignored", false)
			
var _potential_result = HBResult.new()
func get_potential_result():
	return _potential_result

func add_score(score_to_add):
	if not previewing:
		_potential_result.score += 1000.0
	.add_score(score_to_add)
func add_hold_score(score_to_add):
	result.hold_bonus += score_to_add
	_potential_result.hold_bonus += score_to_add
	_potential_result.score -= 1000.0
	_potential_result.score += score_to_add
	add_score(score_to_add)


func add_slide_chain_score(score_to_add):
	result.slide_bonus += score_to_add
	_potential_result.slide_bonus += score_to_add
	_potential_result.score += score_to_add
	_potential_result.score -= 1000.0
	add_score(score_to_add)

func hold_release():
	if held_notes.size() > 0:
		add_hold_score(round(current_hold_score))
		accumulated_hold_score = 0
		held_notes = []
		current_hold_score = 0
	emit_signal("hold_released")


func start_hold(note_type, auto_juggle=false):
	if note_type in held_notes:
		hold_release()
	if held_notes.size() > 0:
		accumulated_hold_score += current_hold_score
	current_hold_score = 0
	current_hold_start_time = time
	held_notes.append(note_type)
	emit_signal("hold_started", held_notes)
	
