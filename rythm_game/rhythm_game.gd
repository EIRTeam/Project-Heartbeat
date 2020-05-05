extends Node

class_name HBRhythmGame

signal time_changed(time)
signal song_cleared(results)
signal note_judged(judgement)

const NoteTargetScene = preload("res://rythm_game/NoteTarget.tscn")
const NoteScene = preload("res://rythm_game/Note.tscn")
const NoteDrawer = preload("res://rythm_game/SingleNoteDrawer.tscn")
const HEART_POWER_UNDER_TINT = Color("2d1b61")
const HEART_POWER_OVER_TINT = Color("4f30ae")
const HEART_POWER_PROGRESS_TINT = Color("a877f0")
const HEART_INDICATOR_MISSED = Color("4f30ae")
const HEART_INDICATOR_DECREASING = Color("77c3f0")

const LOG_NAME = "RhythmGame"
const BASE_SIZE = Vector2(1920, 1080)
const MAX_SCALE = 1.5
const MAX_NOTE_SFX = 4
const MAX_HOLD = 3300  # miliseconds
const WRONG_COLOR = "#ff6524"
const SLIDE_HOLD_PIECE_SCORE = 10
const INTRO_SKIP_MARGIN = 5000 # the time before the first note we warp to when doing intro skip 

var NOTE_TYPE_TO_ACTIONS_MAP = {HBNoteData.NOTE_TYPE.RIGHT: ["note_right"], HBNoteData.NOTE_TYPE.LEFT: ["note_left"], HBNoteData.NOTE_TYPE.UP: ["note_up"], HBNoteData.NOTE_TYPE.DOWN: ["note_down"], HBNoteData.NOTE_TYPE.SLIDE_LEFT: ["tap_left"], HBNoteData.NOTE_TYPE.SLIDE_RIGHT: ["tap_right"]}
var timing_points = [] setget _set_timing_points
var result = HBResult.new()
var judge = preload("res://rythm_game/judge.gd").new()
var time_begin: int
var time_delay: float
var time: float
var current_combo = 0
var disable_intro_skip = false

# Notes currently being shown to the user
var notes_on_screen = []
var current_song: HBSong = HBSong.new()
var current_difficulty: String = ""

# size for scaling
var size = Vector2(1280, 720) setget set_size

# editor stuff
var editing = false
var previewing = false

# Contains a dictionary that maps HBTimingPoint -> its drawer (if it has one)
var timing_point_to_drawer_map = {}

# Notes currently being held (modern style)
var held_notes = []
var current_hold_score = 0.0
var current_hold_start_time = 0.0
var accumulated_hold_score = 0.0  # for when you hit another hold note after already holding

# Initial BPM
var base_bpm = 180.0

# List of slide hold note chains
# It's a list key, contains an array of slide notes
# hold pieces.
var slide_hold_chains = []

# List of slide hold note chains that are active
# It is an array of dictionaris, each dictionary contains a slide hold piece array
# (this array contains only remaining ones in the chain), this uses "pieces" as key
# it also has an AudioStreamPlayer for the loop, called sfx_player
# it finally contains a reference to the original slide note that starts the chain
# as slide_note
var active_slide_hold_chains = []

var modifiers = []

var closest_multi_notes = []

var earliest_note_time = 0

# cached values for speed
var playing_field_size
var playing_field_size_length

# If we've played an sfx in this cycle
var _sfx_played_this_cycle = false
var _intro_skip_enabled = false
# Prevents the song from finishing once
var _prevent_finishing = false
var _finished = false
var _song_volume = 0.0
onready var audio_stream_player: AudioStreamPlayer = get_node("AudioStreamPlayer")
onready var audio_stream_player_voice: AudioStreamPlayer = get_node("AudioStreamPlayerVocals")
onready var rating_label: Label = get_node("RatingLabel")
onready var notes_node = get_node("Notes")
onready var score_counter = get_node("Control/HBoxContainer/HBoxContainer/Label")
onready var author_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongAuthor")
onready var song_name_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongName")
onready var difficulty_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer2/DifficultyLabel")
onready var clear_bar = get_node("Control/ClearBar")
onready var hold_indicator = get_node("UnderNotesUI/Control/HoldIndicator")
onready var heart_power_indicator = get_node("Control/HBoxContainer/HeartPowerTextureProgress")
onready var circle_text_rect = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/CircleImage")
onready var circle_text_rect_margin_container = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer")
onready var latency_display = get_node("Control/LatencyDisplay")
onready var slide_hold_score_text = get_node("AboveNotesUI/Control/SlideHoldScoreText")
onready var modifiers_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer2/ModifierLabel")
onready var multi_hint = get_node("UnderNotesUI/Control/MultiHint")
onready var intro_skip_info_animation_player = get_node("UnderNotesUI/Control/SkipContainer/AnimationPlayer")
onready var intro_skip_ff_animation_player = get_node("UnderNotesUI/Control/Label/IntroSkipFastForwardAnimationPlayer")
func cache_playing_field_size():
	playing_field_size = Vector2(size.y * 16.0 / 9.0, size.y)
	playing_field_size_length = playing_field_size.length()


func set_size(value):
	size = value
	cache_playing_field_size()
	$UnderNotesUI/Control.rect_size = value
	$AboveNotesUI/Control.rect_size = value

var bpm_changes = {}

func get_bpm_at_time(time):
	var current_time = null
	for c_t in bpm_changes:
		if (current_time == null and c_t <= time) or (c_t <= time and c_t > current_time):
			current_time = c_t
	if current_time == null:
		return base_bpm
	return bpm_changes[current_time]


func _set_timing_points(points):
	timing_points = points
	slide_hold_chains = []
	for chain in active_slide_hold_chains:
		chain.sfx_player.queue_free()
	active_slide_hold_chains = []
	# When timing points change, we might introduce new BPM change events
	bpm_changes = {}
	if editing:
		for point in timing_points:
			if point is HBBPMChange:
				bpm_changes[point.time] = point.bpm
	slide_hold_chains = HBChart.get_slide_hold_chains(timing_points)


func _ready():
	rating_label.hide()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	connect("note_judged", latency_display, "_on_note_judged")
	set_current_combo(0)
	slide_hold_score_text._game = self
	$UnderNotesUI/Control/SkipContainer/Panel/HBoxContainer/TextureRect.texture = IconPackLoader.get_icon(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.LEFT), "note")
	$UnderNotesUI/Control/SkipContainer/Panel/HBoxContainer/TextureRect2.texture = IconPackLoader.get_icon(HBUtils.find_key(HBNoteData.NOTE_TYPE, HBNoteData.NOTE_TYPE.UP), "note")
	
	# Despite using end time audio stream player's finished signal is used as fallback just in case
	
	audio_stream_player.connect("finished", self, "_on_game_finished")

func _on_viewport_size_changed():
	$Viewport.size = self.rect_size

	var hbox_container2 = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer")
	if circle_text_rect.texture:
		var image = circle_text_rect.texture.get_data() as Image
		var ratio = image.get_width() / image.get_height()
		var new_size = Vector2(hbox_container2.rect_size.y * ratio, hbox_container2.rect_size.y)
		new_size.x = clamp(new_size.x, 0, 250)
		circle_text_rect_margin_container.rect_min_size = new_size
	cache_playing_field_size()


func set_chart(chart: HBChart):
	clear_bar.value = 0.0
	score_counter.score = 0
	rating_label.hide()
	audio_stream_player.seek(0)
	audio_stream_player_voice.seek(0)
	result = HBResult.new()
	current_combo = 0
	rating_label.hide()
	var tp = chart.get_timing_points()
	for modifier in modifiers:
		modifier._preprocess_timing_points(tp)
	_set_timing_points(tp)
	# Find slide hold chains
	active_slide_hold_chains = []
	var max_score = chart.get_max_score()
	clear_bar.max_value = max_score
	result.max_score = max_score


func set_song(song: HBSong, difficulty: String, assets = null, modifiers = []):
	self.modifiers = modifiers
	current_song = song
	base_bpm = song.bpm
	if assets:
		audio_stream_player.stream = assets.audio
		if song.voice:
			audio_stream_player_voice.stream = assets.voice
	else:
		audio_stream_player.stream = song.get_audio_stream()

		var circle_logo_path = song.get_song_circle_logo_image_res_path()
		if circle_logo_path:
			circle_text_rect.show()
			var image = HBUtils.image_from_fs(circle_logo_path)
			var it = ImageTexture.new()
			it.create_from_image(image, Texture.FLAGS_DEFAULT)
			circle_text_rect.texture = it
			_on_viewport_size_changed() 
		if song.voice:
			audio_stream_player_voice.stream = song.get_voice_stream()
	song_name_label.text = song.get_visible_title()
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
	difficulty_label.text = "[%s]" % difficulty
	var chart_path = song.get_chart_path(difficulty)
	var chart: HBChart
	if song is HBPPDSong:
		chart = PPDLoader.PPD2HBChart(chart_path, song.bpm)
	else:
		var file = File.new()
		file.open(chart_path, File.READ)
		var result = JSON.parse(file.get_as_text()).result
		chart = HBChart.new()

		chart.deserialize(result)
	current_difficulty = difficulty
	
	var modifiers_string = PoolStringArray()

	for modifier in modifiers:
		var modifier_instance = modifier
		modifier_instance._init_plugin()
		modifier_instance._pre_game(song, self)
		modifiers_string.append(modifier_instance.get_modifier_list_name())
	if modifiers.size() > 0:
		modifiers_label.text = " - " + modifiers_string.join(" + ")
	else:
		modifiers_label.text = ""

	set_chart(chart)
	earliest_note_time = -1
	for i in range(timing_points.size() - 1, -1, -1):
		var point = timing_points[i]
		if point is HBNoteData:
			earliest_note_time = point.time
			break
	if current_song.allows_intro_skip and not disable_intro_skip:
		if earliest_note_time > current_song.intro_skip_min_time:
			intro_skip_info_animation_player.play("appear")
			_intro_skip_enabled = true
		else:
			Log.log(self, "Disabling intro skip")
			_intro_skip_enabled = false
	audio_stream_player.stream_paused = true
	audio_stream_player_voice.stream_paused = true
	
	if current_song.id in UserSettings.user_settings.per_song_settings:
		var user_song_settings = UserSettings.user_settings.per_song_settings[current_song.id] as HBPerSongSettings
		_song_volume = linear2db(song.volume * user_song_settings.volume)
	else:
		_song_volume = linear2db(song.volume)
	audio_stream_player.volume_db = _song_volume
	audio_stream_player_voice.volume_db = _song_volume
func get_note_scale():
	return UserSettings.user_settings.note_size * ((playing_field_size_length / BASE_SIZE.length()) * 0.95)


func remap_coords(coords: Vector2):
	coords = coords / BASE_SIZE
	var pos = coords * playing_field_size
	coords.x = (size.x - playing_field_size.x) * 0.5 + pos.x
	coords.y = pos.y
	return coords


func inv_map_coords(coords: Vector2):
	var x = (coords.x - ((size.x - playing_field_size.x) / 2.0)) / playing_field_size.x * BASE_SIZE.x
	var y = (coords.y - ((size.y - playing_field_size.y) / 2.0)) / playing_field_size.y * BASE_SIZE.y
	return Vector2(x, y)


func play_song():

	play_from_pos(max(current_song.start_time/1000.0, 0.0))


#	time_begin = OS.get_ticks_usec()
#	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
#	audio_stream_player.play()
#	audio_stream_player_voice.play()


func _input(event):
	if event.is_action_pressed(NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.UP][0]) or event.is_action_pressed(NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.LEFT][0]):
		if Input.is_action_pressed(NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.UP][0]) and Input.is_action_pressed(NOTE_TYPE_TO_ACTIONS_MAP[HBNoteData.NOTE_TYPE.LEFT][0]):
			if current_song.allows_intro_skip and _intro_skip_enabled and audio_stream_player.playing:
				if time*1000.0 < earliest_note_time - INTRO_SKIP_MARGIN:
					_intro_skip_enabled = false
					intro_skip_info_animation_player.play("disappear")
					intro_skip_ff_animation_player.play("animate")
					play_from_pos((earliest_note_time - INTRO_SKIP_MARGIN) / 1000.0)
	if event is InputEventAction:
		# Note SFX
		for type in NOTE_TYPE_TO_ACTIONS_MAP:
			var action_pressed = false
			var actions = NOTE_TYPE_TO_ACTIONS_MAP[type]
			for action in actions:
				if event.action == action and event.pressed and not event.is_echo():
					play_note_sfx(type == HBNoteData.NOTE_TYPE.SLIDE_LEFT or type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT)
					action_pressed = true
					break
			if action_pressed:
				break


func _unhandled_input(event):
	$Viewport.unhandled_input(event)
	# Slide hold release shenanigans
	var slide_types = [HBNoteData.NOTE_TYPE.SLIDE_LEFT, HBNoteData.NOTE_TYPE.SLIDE_RIGHT]
	for slide_type in slide_types:
		for action in NOTE_TYPE_TO_ACTIONS_MAP[slide_type]:
			if event.is_action_released(action) and not event.is_echo():
				for i in range(active_slide_hold_chains.size() - 1, -1, -1):
					var active_hold_chain = active_slide_hold_chains[i]
					if active_hold_chain.slide_note.note_type == slide_type:
						for piece in active_hold_chain.pieces:
							var drawer = get_note_drawer(piece)
							timing_points.erase(piece)
							if drawer:
								drawer.emit_signal("note_removed")
								drawer.queue_free()
						active_hold_chain.sfx_player.queue_free()
						active_slide_hold_chains.remove(i)
						play_sfx($SlideChainFailSFX)

	if event is InputEventAction:
		if not event.is_pressed() and not event.is_echo():
			for note_type in held_notes:
				if event.action in NOTE_TYPE_TO_ACTIONS_MAP[note_type]:
					hold_release()
					# When you release a hold it disappears instantly
					hold_indicator.disappear()
					break

			

func get_closest_notes_of_type(note_type: int) -> Array:
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = get_note_drawer(note_c).note_data
		if note.note_type == note_type:
			var time_diff = abs(note.time + note.get_duration() - time * 1000.0)
			if closest_notes.size() > 0:
				if closest_notes[0].time > note.time:
					closest_notes = [note]
				elif note.time == closest_notes[0].time:
					closest_notes.append(note)
			else:
				closest_notes = [note]
	return closest_notes


func get_closest_notes():
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = get_note_drawer(note_c).note_data
		if closest_notes.size() > 0:
			if closest_notes[0].time > note.time:
				closest_notes = [note]
			elif note.time == closest_notes[0].time:
				closest_notes.append(note)
		else:
			closest_notes = [note]
	return closest_notes


func remove_all_notes_from_screen():
	for i in range(notes_on_screen.size() - 1, -1, -1):
		get_note_drawer(notes_on_screen[i]).free()
	notes_on_screen = []

# Plays the provided sfx creating a clone of an audio player (maybe we should
# use the AudioServer for this...
func play_sfx(player: AudioStreamPlayer):
	if not _sfx_played_this_cycle:
		var new_player := player.duplicate() as AudioStreamPlayer
		add_child(new_player)
		new_player.play(0)
		new_player.connect("finished", new_player, "queue_free")
		_sfx_played_this_cycle = true

# plays note SFX automatically
func play_note_sfx(slide = false):
	if not slide:
		play_sfx($HitEffect)
	else:
		play_sfx($HitEffectSlide)

# Connects multi notes to their respective master notes
func hookup_multi_notes(notes: Array):
	for note in notes:
		var note_drawer = get_note_drawer(note)
		note_drawer.connected_notes = notes
		note_drawer.note_master = false
	get_note_drawer(notes[0]).note_master = true

# returns the note drawer for the given timing point
func get_note_drawer(timing_point):
	var drawer = null
	if timing_point_to_drawer_map.has(timing_point):
		drawer = timing_point_to_drawer_map[timing_point]
	return drawer

# creates and connects a new note drawer
func create_note_drawer(timing_point: HBNoteData):
	var note_drawer
	note_drawer = timing_point.get_drawer().instance()
	note_drawer.note_data = timing_point
	note_drawer.game = self
	notes_node.add_child(note_drawer)
	note_drawer.connect("notes_judged", self, "_on_notes_judged")
	note_drawer.connect("note_removed", self, "_on_note_removed", [timing_point])
	timing_point_to_drawer_map[timing_point] = note_drawer
	notes_on_screen.append(timing_point)
	connect("time_changed", note_drawer, "_on_game_time_changed")


func _process(_delta):
	_sfx_played_this_cycle = false

	var latency_compensation = UserSettings.user_settings.lag_compensation
	if current_song.id in UserSettings.user_settings.per_song_settings:
		latency_compensation += UserSettings.user_settings.per_song_settings[current_song.id].lag_compensation

	if audio_stream_player.playing and (not editing or previewing):
		# Obtain current time from ticks, offset by the time we began playing music.
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		time = time * audio_stream_player.pitch_scale
		# Compensate for latency.
		time -= time_delay

		# User entered compensation
		time -= latency_compensation / 1000.0

		# May be below 0 (did not being yet).
		time = max(0, time)
		if not editing:
			var end_time = audio_stream_player.stream.get_length() * 1000.0
			if current_song.end_time > 0:
				end_time = float(current_song.end_time)
			if time*1000.0 >= end_time and not _finished:
				_on_game_finished()
#	$CanvasLayer/DebugLabel.text = HBUtils.format_time(int(time * 1000))
#	$CanvasLayer/DebugLabel.text += "\nNotes on screen: " + str(notes_on_screen.size())
	# Adding visible notes
	var multi_notes = []
	var offset = 0
	for i in range(timing_points.size() - 1, -1, -1):
		var timing_point = timing_points[i]
		if timing_point is HBNoteData:
			# Ignore timing points that are not happening now
			if time * 1000.0 < (timing_point.time - timing_point.get_time_out(get_bpm_at_time(timing_point.time))):
				continue
			if time * 1000.0 >= (timing_point.time - timing_point.get_time_out(get_bpm_at_time(timing_point.time))):
				if not timing_point in notes_on_screen:
					# Prevent older notes from being re-created, although this shouldn't happen...
					if judge.judge_note(time, (timing_point.time + timing_point.get_duration()) / 1000.0) == judge.JUDGE_RATINGS.WORST:
						continue
					create_note_drawer(timing_point)
					# multi-note detection
					if multi_notes.size() > 0:
						if multi_notes[0].time == timing_point.time:
							if not timing_point is HBHoldNoteData:
								if timing_point is HBNoteData and not timing_point.note_type in HBNoteData.NO_MULTI_LIST:
									multi_notes.append(timing_point)
						elif multi_notes.size() > 1:
							hookup_multi_notes(multi_notes)
							multi_notes = [timing_point]
						else:
							multi_notes = [timing_point]
					elif timing_point is HBNoteData and not timing_point.note_type in HBNoteData.NO_MULTI_LIST:
						multi_notes.append(timing_point)
				if not editing or previewing:
					timing_points.remove(i)
	emit_signal("time_changed", time)
	if multi_notes.size() > 1:
		hookup_multi_notes(multi_notes)

	# Hold combo increasing and shit
	if held_notes.size() > 0:
		var max_time = current_hold_start_time + (MAX_HOLD / 1000.0)
		current_hold_score = ((time - current_hold_start_time) * 1000.0) * held_notes.size()

		if time >= max_time:
			current_hold_score = int(current_hold_score + accumulated_hold_score)
			hold_indicator.show_max_combo(MAX_HOLD)
			hold_indicator.current_score = current_hold_score + MAX_HOLD
			add_hold_score(MAX_HOLD)
			hold_release()
		else:
			hold_indicator.current_score = current_hold_score + accumulated_hold_score
	# handles held slide hold chains
	for ii in range(active_slide_hold_chains.size() - 1, -1, -1):
		var chain = active_slide_hold_chains[ii]
		for i in range(chain.pieces.size() - 1, -1, -1):
			var piece = chain.pieces[i]
			if time * 1000.0 >= piece.time:
				add_slide_chain_score(SLIDE_HOLD_PIECE_SCORE)
				chain.accumulated_score += SLIDE_HOLD_PIECE_SCORE
				var piece_drawer = get_note_drawer(piece) as HBNoteDrawer
				if piece_drawer:
					piece_drawer.show_note_hit_effect()
					piece_drawer.emit_signal("note_removed")
					piece_drawer.queue_free()
					slide_hold_score_text.show_at_point(piece.position, chain.accumulated_score, chain.pieces.size() == 1)

				chain.pieces.remove(i)
		var show_max_slide_text = false
		if chain.pieces.size() == 0:
			show_max_slide_text = true
			chain.sfx_player.queue_free()
			play_sfx($SlideChainSuccessSFX)
			active_slide_hold_chains.remove(ii)
	# autoplay code
	if Diagnostics.enable_autoplay or previewing:
		if not result.used_cheats:
			result.used_cheats = true
			Log.log(self, "Disabling leaderboard upload for cheated result")
		for i in range(notes_on_screen.size() - 1, -1, -1):
			var note = notes_on_screen[i]
			if note is HBNoteData and note.note_type in NOTE_TYPE_TO_ACTIONS_MAP:
				if time * 1000 > note.time:
					var a = InputEventAction.new()
					a.action = NOTE_TYPE_TO_ACTIONS_MAP[note.note_type][0]
					a.pressed = true
					play_note_sfx(note.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT or note.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT)
					Input.parse_input_event(a)
	var new_closest_multi_notes = []
	var last_note_time = 0
	for note in notes_on_screen:
		if note is HBNoteData:
			if note.time == last_note_time:
				new_closest_multi_notes.append(note)
			elif new_closest_multi_notes.size() > 1:
				break
			else:
				new_closest_multi_notes = [note]
			last_note_time = note.time
	if UserSettings.user_settings.enable_multi_hint:
		if new_closest_multi_notes.size() > 1:
			if not new_closest_multi_notes[0] in closest_multi_notes:
				closest_multi_notes = new_closest_multi_notes
				multi_hint.show_notes(new_closest_multi_notes)
#				hold_hint.show()
		
	if new_closest_multi_notes.size() < 2:
		multi_hint.hide()
		
	closest_multi_notes = new_closest_multi_notes
	if _intro_skip_enabled:
		if time*1000.0 >= earliest_note_time - INTRO_SKIP_MARGIN:
			intro_skip_info_animation_player.play("disappear")
			_intro_skip_enabled = false
func set_current_combo(combo: int):
	current_combo = combo

# called when a note or group of notes is judged
# this doesn't take care of adding the score
func _on_notes_judged(notes: Array, judgement, wrong):
	var note = notes[0] as HBNoteData

	# Simultaneous slides are a special case...
	# we have to process each note individually
	for n in notes:
		if n != note and n.is_slide_note():
			_on_notes_judged([n], judgement, wrong)
	# Some notes might be considered more than 1 at the same time? connected ones aren't
	var notes_hit = 1
	if not editing or previewing:
		# Rating graphic
		if note.note_type in held_notes:
			hold_release()
			hold_indicator.disappear()
		if judgement < judge.JUDGE_RATINGS.FINE or wrong:
			# Missed a note
			if UserSettings.user_settings.enable_voice_fade:
				audio_stream_player_voice.volume_db = -90
			set_current_combo(0)
			hold_release()
			hold_indicator.disappear()
		else:
			set_current_combo(current_combo + notes_hit)
			audio_stream_player_voice.volume_db = _song_volume
			result.notes_hit += notes_hit

			for note in notes:
				note = note as HBNoteData
				if note.hold:
					start_hold(note.note_type)

		if not wrong:
			result.note_ratings[judgement] += notes_hit
		else:
			result.wrong_note_ratings[judgement] += notes_hit

		result.total_notes += notes_hit

		if current_combo > result.max_combo:
			result.max_combo = current_combo

		# Slide chain starting shenanigans
		if note.is_slide_note():
			if note in slide_hold_chains:
				if not wrong and judgement >= judge.JUDGE_RATINGS.FINE:
					var hold_player = $SlideChainLoopSFX.duplicate()
					add_child(hold_player)
					hold_player.play()
					hold_player.connect("finished", self, "_on_slide_hold_player_finished", [hold_player])

					var active_hold_chain = {"pieces": slide_hold_chains[note], "slide_note": note, "sfx_player": hold_player, "is_playing_loop": false, "accumulated_score": 0}
					active_slide_hold_chains.append(active_hold_chain)
				else:
					# kill slide and younglings if we failed
					for piece in slide_hold_chains[note]:
						if piece in notes_on_screen:
							var piece_drawer = get_note_drawer(piece)
							piece_drawer.emit_signal("note_removed")
							piece_drawer.queue_free()
						else:
							var i = timing_points.find(piece)
							if i != -1:
								timing_points.remove(i)

		# We average the notes position so that multinote ratings are centered
		var avg_pos = Vector2()
		for n in notes:
			avg_pos += n.position
		avg_pos = avg_pos / float(notes.size())
		rating_label.show_rating()
		rating_label.get_node("AnimationPlayer").play("rating_appear")
		if not wrong:
			rating_label.add_color_override("font_color", Color(HBJudge.RATING_TO_COLOR[judgement]))
			rating_label.add_color_override("font_outline_modulate", HBJudge.RATING_TO_COLOR[judgement])
			rating_label.text = judge.JUDGE_RATINGS.keys()[judgement]
		else:
			rating_label.add_color_override("font_color", Color(WRONG_COLOR))
			rating_label.add_color_override("font_outline_modulate", WRONG_COLOR)
			rating_label.text = judge.RATING_TO_WRONG_TEXT_MAP[judgement]
		if current_combo > 1:
			rating_label.text += " " + str(current_combo)
		rating_label.rect_position = remap_coords(avg_pos) - rating_label.rect_size / 2
		rating_label.rect_position.y -= 64
		if not previewing:
			rating_label.show()
		else:
			rating_label.hide()
		var judgement_info = {"judgement": judgement, "target_time": notes[0].time, "time": int(time * 1000)}

		emit_signal("note_judged", judgement_info)

# called when the initial slide is done, to swap it out for a slide loop
func _on_slide_hold_player_finished(hold_player: AudioStreamPlayer):
	hold_player.stream = preload("res://sounds/sfx/slide_hold_loop.wav")
	hold_player.seek(0)
	hold_player.volume_db = 4
	hold_player.play()

# removes a note from screen (and from the timing points list if not in the editor)
func remove_note_from_screen(i):
	if i != -1:
		if not editing or previewing:
			timing_points.erase(notes_on_screen[i])
		notes_node.remove_child(get_note_drawer(notes_on_screen[i]))
		notes_on_screen.remove(i)

func _on_note_removed(note):
	remove_note_from_screen(notes_on_screen.find(note))

func pause_game():
	audio_stream_player.stream_paused = true
	audio_stream_player_voice.stream_paused = true
	get_tree().paused = true

func resume():
	get_tree().paused = false
	play_from_pos(audio_stream_player.get_playback_position())


func restart():
	_prevent_finishing = true
	remove_all_notes_from_screen()
	hold_release()
	get_tree().paused = false
	set_song(SongLoader.songs[current_song.id], current_difficulty, null, modifiers)
	audio_stream_player_voice.volume_db = _song_volume
	set_current_combo(0)
	notes_on_screen = []
	rating_label.hide()
	time = current_song.start_time / 1000.0
	audio_stream_player.stream_paused = true
	audio_stream_player_voice.stream_paused = true

func play_from_pos(position: float):
	print("PLAYING FROM", position)
	audio_stream_player.stream_paused = false
	audio_stream_player_voice.stream_paused = false
	audio_stream_player.play()
	audio_stream_player_voice.play()
	audio_stream_player.seek(position)
	audio_stream_player_voice.seek(position)
	time_begin = OS.get_ticks_usec() - int((position / audio_stream_player.pitch_scale) * 1000000.0)
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()

# used by the editor and practice mode to delete slide chain pieces that have no
# parent
func delete_rogue_slide_chain_pieces(pos_override = null):
	var pos = time
	if pos_override:
		pos = pos_override
	var notes_to_remove = []
	for i in range(timing_points.size() - 1, -1, -1):
		var chain_starter = timing_points[i]
		if chain_starter is HBNoteData:
			if chain_starter.time < pos_override * 1000.0:
				if chain_starter.is_slide_note():
					if chain_starter in slide_hold_chains:
						var pieces = slide_hold_chains[chain_starter]
						notes_to_remove += pieces
	for note in notes_to_remove:
		if note in notes_on_screen:
			remove_note_from_screen(notes_on_screen.find(note))
		else:
			timing_points.erase(note)


func add_score(score_to_add):
	if not previewing:
		result.score += score_to_add
		score_counter.score = result.score
		clear_bar.value = result.get_capped_score()


func add_hold_score(score_to_add):
	result.hold_bonus += score_to_add
	add_score(score_to_add)


func add_slide_chain_score(score_to_add):
	result.slide_bonus += score_to_add
	add_score(score_to_add)

func _on_game_finished():
	if not _finished:
		if not _prevent_finishing:
			for modifier in modifiers:
				modifier._post_game(current_song, self)
			emit_signal("song_cleared", result)
			_finished = true
		else:
			_prevent_finishing = false


func hold_release():
	if held_notes.size() > 0:
		add_hold_score(round(current_hold_score))
		accumulated_hold_score = 0
		held_notes = []
		current_hold_score = 0


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
