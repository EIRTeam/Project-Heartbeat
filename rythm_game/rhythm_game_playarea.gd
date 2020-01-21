extends Node

const NoteTargetScene = preload("res://rythm_game/NoteTarget.tscn")
const NoteScene = preload("res://rythm_game/Note.tscn")
const NoteDrawer = preload("res://rythm_game/SingleNoteDrawer.tscn")

var NOTE_TYPE_TO_ACTIONS_MAP = {
	HBNoteData.NOTE_TYPE.RIGHT: ["note_b"],
	HBNoteData.NOTE_TYPE.LEFT: ["note_x"],
	HBNoteData.NOTE_TYPE.UP: ["note_y"],
	HBNoteData.NOTE_TYPE.DOWN: ["note_a"],
	HBNoteData.NOTE_TYPE.SLIDE_LEFT: ["tap_left"],
	HBNoteData.NOTE_TYPE.SLIDE_RIGHT: ["tap_right"]
}

var hit_effect_queue = []

var input_lag_compensation = 0

var result = HBResult.new()

onready var audio_stream_player = get_node("AudioStreamPlayer")
onready var rating_label : Label = get_node("RatingLabel")
onready var notes_node = get_node("Notes")
onready var score_counter = get_node("Control/HBoxContainer/HBoxContainer/Label")
onready var author_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/VBoxContainer/HBoxContainer/SongAuthor")
onready var song_name_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/VBoxContainer/HBoxContainer/SongName")
onready var difficulty_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/VBoxContainer/HBoxContainer/DifficultyLabel")
onready var combo_multiplier_label = get_node("Control/HBoxContainer/ComboTextureProgress/ComboMultiplierLabel")
onready var combo_texture_progress = get_node("Control/HBoxContainer/ComboTextureProgress")
onready var heart_power_progress_bar = get_node("Control/TextureProgress")
onready var heart_power_prompt_animation_player = get_node("Prompts/HeartPowerPromptAnimationPlayer")
onready var clear_bar = get_node("Control/ClearBar")
onready var hold_indicator = get_node("UnderNotesUI/Control/HoldIndicator")

var judge = preload("res://rythm_game/judge.gd").new()

var time_begin: int
var time_delay: float
var time: float
var current_combo = 0
var timing_points = [] setget set_timing_points

var _sfx_played_this_cycle = false

var notes_on_screen = []
var current_song: HBSong = HBSong.new()
const LOG_NAME = "RhythmGame"
const BASE_SIZE = Vector2(1920, 1080)
const MAX_SCALE = 1.5
const MAX_NOTE_SFX = 4
const NOTES_PER_COMBO_MULTIPLIER = 16.0
const MAX_COMBO_MULTIPLIER = 2
const MAX_HOLD = 3300 # miliseconds

var size = Vector2(1280, 720) setget set_size
var editing = false
var previewing = false


var current_bpm = 180.0

var current_heart_power_duration = 0.0
var current_heart_power_to_remove = 0.0
var current_starting_heart_power = 0.0
var heart_power_enabled = false
var heart_power = 0.0
var current_heart_power_start_time = 0.0
const MAX_HEART_POWER = 100.0
signal time_changed(time)
signal song_cleared(results)
signal heart_power_activate
signal heart_power_end
signal held_notes_changed(held_notes)

var held_notes = []
var current_hold_score = 0.0
var current_hold_start_time = 0.0
var accumulated_hold_score = 0.0 # for when you hit another hold note after holding one
func set_size(value):
	size = value
	$UnderNotesUI/Control.rect_size = value

func set_timing_points(points):
	timing_points = points
	# When timing points change, we might introduce new BPM change events
	if editing:
		for point in points:
			if point.time <= time:
				if point is HBBPMChange:
					current_bpm = point.bpm
			else:
				break

func _ready():
#	var note = HBNoteData.new()
#	note.time = 2000
#	timing_points.append(note)
	rating_label.hide()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	
	hit_effect_queue.append($HitEffect)
	for i in range(MAX_NOTE_SFX-1):
		var new_sfx = $HitEffect.duplicate()
		add_child(new_sfx)
		hit_effect_queue.append(new_sfx)
	set_current_combo(0)
	update_heart_power_ui()
	update_combo_multiplier_ui()
	combo_texture_progress.max_value = NOTES_PER_COMBO_MULTIPLIER
func _on_viewport_size_changed():
	print(get_viewport().size)
	$Viewport.size = self.rect_size
	
func set_song(song: HBSong, difficulty: String):
	current_song = song
	audio_stream_player.seek(0)
	result = HBResult.new()
	result.song_id = song.id
	result.difficulty = difficulty
	current_combo = 0
	rating_label.hide()
	current_bpm = song.bpm
	$AudioStreamPlayer.stream = song.get_audio_stream()
	song_name_label.text = song.title
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
	difficulty_label.text = "[%s]" % difficulty
	var chart_path = song.get_chart_path(difficulty)
	var chart : HBChart
	if song is HBPPDSong:
		chart = PPDLoader.PPD2HBChart(chart_path)
	else:
		var file = File.new()
		file.open(chart_path, File.READ)
		var result = JSON.parse(file.get_as_text()).result
		chart = HBChart.new()

		chart.deserialize(result)
	
	timing_points = chart.get_timing_points()
	var max_score = chart.get_max_score()
	clear_bar.max_value = max_score
	result.max_score = max_score
	play_song()
func get_note_scale():
	return (get_playing_field_size().length() / BASE_SIZE.length()) * 0.95

func get_playing_field_size():
	var ratio = 16.0/9.0
	return Vector2(size.y*ratio, size.y)

func remap_coords(coords: Vector2):
	var field_size = get_playing_field_size()
	coords = coords / BASE_SIZE
	var pos = coords * field_size
	coords.x = (size.x - field_size.x) / 2.0 + pos.x
	coords.y = pos.y
	return coords
	
func inv_map_coords(coords: Vector2):
	var field_size = get_playing_field_size()
	var x = (coords.x - ((size.x - field_size.x) / 2.0)) / get_playing_field_size().x * BASE_SIZE.x
	var y = (coords.y - ((size.y - field_size.y) / 2.0)) / get_playing_field_size().y * BASE_SIZE.y
	return Vector2(x, y)
func play_song():
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	audio_stream_player.play()

func _unhandled_input(event):
	$Viewport.unhandled_input(event)
	if event.is_action_pressed("activate_heart_power") and not event.is_echo():
		activate_heart_power()
	if event is InputEventAction:
		if not event.is_pressed() and not event.is_echo():
			for note_type in held_notes:
				if event.action in NOTE_TYPE_TO_ACTIONS_MAP[note_type]:
					hold_release()
					break
func get_closest_notes_of_type(note_type: int) -> Array:
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = note_c.get_meta("note_drawer").note_data
		if note.note_type == note_type:
			var time_diff = abs(note.time + note.get_duration() - time * 1000.0)
			if closest_notes.size() > 0:
				if time_diff < abs(closest_notes[0].time - time * 1000.0):
					closest_notes = [note]
				time_diff = abs(note.time + note.get_duration() - time * 1000.0)
				if time_diff < abs(closest_notes[0].time - time * 1000.0):
					closest_notes.append(note)
				elif note.time == closest_notes[0].time:
					closest_notes.append(note)
			else:
				closest_notes = [note]
	return closest_notes

func remove_note_from_screen(i):
	notes_on_screen.remove(i)
	
func remove_all_notes_from_screen():
	for i in range(notes_on_screen.size() - 1, -1, -1):
		notes_on_screen[i].get_meta("note_drawer").free()
	notes_on_screen = []
	
func play_note_sfx():
	if not _sfx_played_this_cycle:
		var curr_effect = hit_effect_queue[0]
		curr_effect.play()
		hit_effect_queue.pop_front()
		hit_effect_queue.push_back(curr_effect)
		_sfx_played_this_cycle = true
	
func hookup_multi_notes(notes: Array):
	print("HOOKING UP %d notes" % [notes.size()])
	for note in notes:
		var note_drawer = note.get_meta("note_drawer")
		note_drawer.connected_notes = notes
		note_drawer.note_master = false
	notes[0].get_meta("note_drawer").note_master = true
	
func _process(delta):
	_sfx_played_this_cycle = false
	if audio_stream_player.playing:
		# Obtain current time from ticks, offset by the time we began playing music.
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		time = time * audio_stream_player.pitch_scale
		# Compensate for latency.
		time -= time_delay
		# May be below 0 (did not being yet).
		time = max(0, time)
	$CanvasLayer/DebugLabel.text = HBUtils.format_time(int(time * 1000))
	$CanvasLayer/DebugLabel.text += "\nNotes on screen: " + str(notes_on_screen.size())
	# Note SFX
	for type in NOTE_TYPE_TO_ACTIONS_MAP:
		var action_pressed = false
		var actions = NOTE_TYPE_TO_ACTIONS_MAP[type]
		for action in actions:
			if Input.is_action_just_pressed(action):
				play_note_sfx()
				action_pressed = true
				break
		if action_pressed:
			break
	# Heart power stuff
	if heart_power_enabled:
		if time - current_heart_power_start_time >= current_heart_power_duration:
			heart_power_enabled = false
			heart_power = current_starting_heart_power - current_heart_power_to_remove
			emit_signal("heart_power_end")
			update_heart_power_ui()
		else:
			var hp_progress = (time - current_heart_power_start_time) / current_heart_power_duration
			heart_power = current_starting_heart_power - (current_heart_power_to_remove * hp_progress)
			update_heart_power_ui()
	# Adding visible notes
	var multi_notes = []
	for i in range(timing_points.size() - 1, -1, -1):
		var timing_point = timing_points[i]
		if timing_point is HBNoteData:
			
			if time * 1000.0 >= (timing_point.time + input_lag_compensation-timing_point.get_time_out(current_bpm)):
				if not timing_point in notes_on_screen:
					# Prevent older notes from being re-created
					if judge.judge_note(time + input_lag_compensation, (timing_point.time + timing_point.get_duration())/1000.0) == judge.JUDGE_RATINGS.WORST:
						continue
					var note_drawer
					
						
					
					note_drawer = timing_point.get_drawer().instance()
					note_drawer.note_data = timing_point
					note_drawer.game = self
					notes_node.add_child(note_drawer)
					note_drawer.connect("notes_judged", self, "_on_notes_judged")
					note_drawer.connect("note_removed", self, "_on_note_removed", [timing_point])
					connect("heart_power_activate", note_drawer, "_on_heart_power_activated")
					connect("heart_power_end", note_drawer, "_on_heart_power_end")
					timing_point.set_meta("note_drawer", note_drawer)
					notes_on_screen.append(timing_point)
					connect("time_changed", note_drawer, "_on_game_time_changed")
					if multi_notes.size() > 0:
						if multi_notes[0].time == timing_point.time:
							if not timing_point is HBHoldNoteData:
								multi_notes.append(timing_point)
						elif multi_notes.size() > 1:
							hookup_multi_notes(multi_notes)
						else:
							multi_notes = [timing_point]
						
					else:
						multi_notes.append(timing_point)
				if not editing or previewing:
					timing_points.remove(i)

	if timing_points.size() == 0:
		var file = File.new()
		file.open("user://testresult.json", File.WRITE)
		file.store_string(JSON.print(result.serialize(), "  "))
	emit_signal("time_changed", time+input_lag_compensation)
	if multi_notes.size() > 1:
		hookup_multi_notes(multi_notes)
		
	# Hold combo
	if held_notes.size() > 0:
		var max_time = current_hold_start_time + (MAX_HOLD/1000.0)
		print(max_time * 1000.0)
		if time >= max_time:
			current_hold_score = ((time - current_hold_start_time) * 1000.0) * held_notes.size() * get_combo_multiplier()
			current_hold_score = int(current_hold_score + accumulated_hold_score)
			add_score(MAX_HOLD) # Add score extra for max combo OwO
			
			hold_indicator.current_score = current_hold_score
			hold_release()
			
			hold_indicator.show_max_combo(MAX_HOLD)
			
		else:
			current_hold_score = ((time - current_hold_start_time) * 1000.0) * held_notes.size() * get_combo_multiplier()
			hold_indicator.current_score = current_hold_score + accumulated_hold_score
	if Diagnostics.enable_autoplay or previewing:
		for i in range(notes_on_screen.size() - 1, -1, -1):
			var note = notes_on_screen[i]
			if note is HBNoteData:
				if time*1000 > note.time:
					var a = InputEventAction.new()
					a.action = NOTE_TYPE_TO_ACTIONS_MAP[note.note_type][0]
					a.pressed = true
					play_note_sfx()
					Input.parse_input_event(a)
func get_combo_multiplier() -> int:
	var m = 1
	if heart_power_enabled:
		m = 2
	return int(1 + clamp((current_combo / NOTES_PER_COMBO_MULTIPLIER), 0, MAX_COMBO_MULTIPLIER-1)) * m

func update_combo_multiplier_ui():
	var combo_multiplier = get_combo_multiplier()
	if combo_multiplier > 1:
		combo_multiplier_label.show()
		combo_multiplier_label.text = "x" + str(combo_multiplier)
	else:
		combo_multiplier_label.hide()
	if current_combo < int(NOTES_PER_COMBO_MULTIPLIER) * 2:
		combo_texture_progress.value = current_combo % int(NOTES_PER_COMBO_MULTIPLIER)
	else:
		combo_texture_progress.value = int(NOTES_PER_COMBO_MULTIPLIER) * 2

func set_current_combo(combo: int):
	current_combo = combo
	update_combo_multiplier_ui()
	
func activate_heart_power():
	if not heart_power_enabled:
		if heart_power >= MAX_HEART_POWER / 2.0:
			var activation_duration = get_heart_power_duration()
			var hp_points_to_use = MAX_HEART_POWER
			if heart_power < MAX_HEART_POWER:
				activation_duration = activation_duration / 2.0
				hp_points_to_use = hp_points_to_use / 2.0
			current_heart_power_start_time = time
			current_heart_power_duration = activation_duration
			current_heart_power_to_remove = hp_points_to_use
			current_starting_heart_power = heart_power
			heart_power_enabled = true
			emit_signal("heart_power_activate")
			heart_power_prompt_animation_player.play("HeartPowerEnabled")
			update_combo_multiplier_ui()
		

func get_heart_power_points_per_note():
	return 100 / current_song.bpm

# Heart power activation for half phase is minimum 4 seconds, otherwise it's 1/8th of the max power points
func get_heart_power_duration():
	return max(round(500000/(pow(current_song.bpm, 2.0))), 4)

func increase_heart_power():
	var old_heart_power = heart_power
	heart_power += get_heart_power_points_per_note()
	
	heart_power = clamp(heart_power, 0, MAX_HEART_POWER)
	if old_heart_power < MAX_HEART_POWER/2.0 and heart_power > MAX_HEART_POWER/2.0:
		heart_power_prompt_animation_player.play("HeartPowerAvailable")
	update_heart_power_ui()
	
	
func update_heart_power_ui():
	heart_power_progress_bar.value = heart_power / MAX_HEART_POWER
	heart_power_progress_bar.decreasing = heart_power_enabled
	
func _on_notes_judged(notes: Array, judgement):
	var note = notes[0]
	# Some notes might be considered more than 1 at the same time? connected ones aren't
	var notes_hit = 1
	if not editing or previewing:
		# Rating graphic
		if note.note_type in held_notes:
			hold_release()
		if judgement < judge.JUDGE_RATINGS.FINE:
			set_current_combo(0)
			hold_release()
		else:
#			if not heart_power_enabled and get_combo_multiplier() >= MAX_COMBO_MULTIPLIER and current_combo > NOTES_PER_COMBO_MULTIPLIER * MAX_COMBO_MULTIPLIER:
			increase_heart_power()
			set_current_combo(current_combo + notes_hit)
			result.notes_hit += notes_hit
			
			for note in notes:
				note = note as HBNoteData
				if note.hold:
					start_hold(note.note_type)
			
		
		result.note_ratings[judgement] += notes_hit
		result.total_notes += notes_hit
		if current_combo > result.max_combo:
			result.max_combo = current_combo

		
		# We average the notes position so that multinote ratings are centered
		var avg_pos = Vector2()
		for n in notes:
			avg_pos += n.position
		avg_pos = avg_pos / float(notes.size())
		
		rating_label.get_node("AnimationPlayer").play("rating_appear")
		rating_label.add_color_override("font_color", Color(HBJudge.RATING_TO_COLOR[judgement]))
		$RatingLabel.add_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[judgement])
		rating_label.text = judge.JUDGE_RATINGS.keys()[judgement]
		if current_combo > 1:
			rating_label.text += " " + str(current_combo)
		rating_label.rect_size = rating_label.get_combined_minimum_size()
		rating_label.rect_position = remap_coords(avg_pos) - rating_label.get_combined_minimum_size() / 2
		rating_label.rect_position.y -= 64
		if not previewing:
			rating_label.show()
		else:
			rating_label.hide()
func _on_note_removed(note):
	remove_note_from_screen(notes_on_screen.find(note))
				
func pause_game():
	audio_stream_player.stream_paused = true
	get_tree().paused = true
func resume():
	get_tree().paused = false
	play_from_pos(audio_stream_player.get_playback_position())
	
func restart():
	get_tree().paused = false
	set_song(SongLoader.songs[result.song_id], result.difficulty)
	set_current_combo(0)
	
func play_from_pos(position: float):
	audio_stream_player.stream_paused = false

	audio_stream_player.play()
	audio_stream_player.seek(position)
	time_begin = OS.get_ticks_usec() - int(position * 1000000.0)
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
func add_score(score_to_add):
	print("adding ", score_to_add)
	if not previewing:
		result.score += score_to_add * get_combo_multiplier()
#		print(score_to_add * get_combo_multiplier())
		score_counter.score = result.score
		clear_bar.value = result.score
		if heart_power_enabled:
			result.heart_power_bonus += score_to_add * (get_combo_multiplier() / 2.0)

func _on_AudioStreamPlayer_finished():
	emit_signal("song_cleared", result)

func hold_release():
	add_score(current_hold_score)
	print("END hold ", current_hold_score)
	held_notes = []
	current_hold_score = 0
	hold_indicator.disappear()

func start_hold(note_type):
	if note_type in held_notes:
		hold_release()
	if held_notes.size() > 0:
		accumulated_hold_score += current_hold_score
	current_hold_score = 0
	current_hold_start_time = time
	held_notes.append(note_type)
	hold_indicator.current_holds = held_notes
	hold_indicator.appear()
