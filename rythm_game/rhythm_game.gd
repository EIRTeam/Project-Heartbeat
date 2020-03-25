extends Node

class_name HBRhythmGame

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

const HEART_POWER_UNDER_TINT = Color("2d1b61")
const HEART_POWER_OVER_TINT = Color("4f30ae")
const HEART_POWER_PROGRESS_TINT = Color("a877f0")
const HEART_INDICATOR_MISSED = Color("4f30ae")
const HEART_INDICATOR_DECREASING = Color("77c3f0")

var input_lag_compensation = 0

var result = HBResult.new()

onready var audio_stream_player = get_node("AudioStreamPlayer")
onready var audio_stream_player_voice = get_node("AudioStreamPlayerVocals")
onready var rating_label : Label = get_node("RatingLabel")
onready var notes_node = get_node("Notes")
onready var score_counter = get_node("Control/HBoxContainer/HBoxContainer/Label")
onready var author_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongAuthor")
onready var song_name_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/SongName")
onready var difficulty_label = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/DifficultyLabel")
onready var heart_power_prompt_animation_player = get_node("Prompts/HeartPowerPromptAnimationPlayer")
onready var clear_bar = get_node("Control/ClearBar")
onready var hold_indicator = get_node("UnderNotesUI/Control/HoldIndicator")
onready var heart_power_indicator = get_node("Control/HBoxContainer/HeartPowerTextureProgress")
onready var circle_text_rect = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer/CircleImage")
onready var latency_display = get_node("Control/LatencyDisplay")
onready var slide_hold_score_text = get_node("AboveNotesUI/Control/SlideHoldScoreText")
var judge = preload("res://rythm_game/judge.gd").new()

var time_begin: int
var time_delay: float
var time: float
var current_combo = 0
var timing_points = [] setget set_timing_points

var _sfx_played_this_cycle = false

var notes_on_screen = []
var current_song: HBSong = HBSong.new()
var current_difficulty: String = ""
const LOG_NAME = "RhythmGame"
const BASE_SIZE = Vector2(1920, 1080)
const MAX_SCALE = 1.5
const MAX_NOTE_SFX = 4
const MAX_HOLD = 3300 # miliseconds
const WRONG_COLOR = "#ff6524"
const SLIDE_HOLD_PIECE_SCORE = 10


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
signal note_judged(judgement)

var held_notes = []
var current_hold_score = 0.0
var current_hold_start_time = 0.0
var accumulated_hold_score = 0.0 # for when you hit another hold note after holding one

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

func set_size(value):
	size = value
	$UnderNotesUI/Control.rect_size = value
	$AboveNotesUI/Control.rect_size = value

func set_modifiers(modifiers: Array):
	# TODO
	pass

func set_timing_points(points):
	timing_points = points
	slide_hold_chains = []
	for chain in active_slide_hold_chains:
		chain.sfx_player.queue_free()
	active_slide_hold_chains = []
	# When timing points change, we might introduce new BPM change events
	if editing:
		for point in points:
			if point.time <= time:
				if point is HBBPMChange:
					current_bpm = point.bpm
			else:
				break
	slide_hold_chains = HBChart.get_slide_hold_chains(timing_points)
func _ready():
	rating_label.hide()
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	connect("note_judged", latency_display, "_on_note_judged")
	set_current_combo(0)
	update_heart_power_ui()
	heart_power_indicator.tint_over = HEART_POWER_OVER_TINT
	slide_hold_score_text._game = self
func _on_viewport_size_changed():
	$Viewport.size = self.rect_size
		
	var hbox_container2 = get_node("Control/HBoxContainer/VBoxContainer/Panel/MarginContainer/VBoxContainer/HBoxContainer")
	if circle_text_rect.texture:
		var image = circle_text_rect.texture.get_data() as Image
		var ratio = image.get_width() / image.get_height()
		var new_size = Vector2(hbox_container2.rect_size.y * ratio, hbox_container2.rect_size.y)
		new_size.x = clamp(new_size.x, 0, 250)
		circle_text_rect.rect_min_size = new_size
func set_song(song: HBSong, difficulty: String, assets = null):
	current_song = song
	heart_power_indicator.value = 0
	heart_power = 0
	clear_bar.value = 0.0
	score_counter.score = 0
	rating_label.hide()
	audio_stream_player.seek(0)
	audio_stream_player_voice.seek(0)
	result = HBResult.new()
	current_combo = 0
	rating_label.hide()
	current_bpm = song.bpm
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
	var chart : HBChart
	if song is HBPPDSong:
		chart = PPDLoader.PPD2HBChart(chart_path, song.bpm)
	else:
		var file = File.new()
		file.open(chart_path, File.READ)
		var result = JSON.parse(file.get_as_text()).result
		chart = HBChart.new()

		chart.deserialize(result)
	
	timing_points = chart.get_timing_points()
	
	# Find slide hold chains
	slide_hold_chains = HBChart.get_slide_hold_chains(timing_points)
	active_slide_hold_chains = []
	var max_score = chart.get_max_score()
	clear_bar.max_value = max_score
	result.max_score = max_score
	current_difficulty = difficulty
	play_song()
func get_note_scale():
	return UserSettings.user_settings.note_size * ((get_playing_field_size().length() / BASE_SIZE.length()) * 0.95)

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
	play_from_pos(0)
#	time_begin = OS.get_ticks_usec()
#	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
#	audio_stream_player.play()
#	audio_stream_player_voice.play()

func _input(event):
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
	if event.is_action_pressed("activate_heart_power") and not event.is_echo():
		activate_heart_power()
	# Slide hold release shenanigans
	var slide_types = [HBNoteData.NOTE_TYPE.SLIDE_LEFT, HBNoteData.NOTE_TYPE.SLIDE_RIGHT]
	for slide_type in slide_types:
		for action in NOTE_TYPE_TO_ACTIONS_MAP[slide_type]:
			if event.is_action_released(action) and not event.is_echo():
				for i in range(active_slide_hold_chains.size() - 1, -1, -1):
					var active_hold_chain = active_slide_hold_chains[i]
					if active_hold_chain.slide_note.note_type == slide_type:
						for piece in active_hold_chain.pieces:
							var note_drawer = piece.get_meta("note_drawer")
							note_drawer.emit_signal("note_removed")
							note_drawer.queue_free()
						active_hold_chain.sfx_player.queue_free()
						active_slide_hold_chains.remove(i)
						play_sfx($SlideChainFailSFX)
				
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

func get_closest_notes():
	var closest_notes = []
	for note_c in notes_on_screen:
		var note = note_c.get_meta("note_drawer").note_data
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
	
func play_sfx(player: AudioStreamPlayer):
	if not _sfx_played_this_cycle:
		var new_player := player.duplicate() as AudioStreamPlayer
		add_child(new_player)
		new_player.play(0)
		new_player.connect("finished", new_player, "queue_free")
		_sfx_played_this_cycle = true
func play_note_sfx(slide=false):
	if not slide:
		play_sfx($HitEffect)
	else:
		play_sfx($HitEffectSlide)
	
func hookup_multi_notes(notes: Array):
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
		
		# User entered compensation
		time -= UserSettings.user_settings.lag_compensation / 1000.0
		
		# May be below 0 (did not being yet).
		time = max(0, time)
	$CanvasLayer/DebugLabel.text = HBUtils.format_time(int(time * 1000))
	$CanvasLayer/DebugLabel.text += "\nNotes on screen: " + str(notes_on_screen.size())
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
			if time * 1000.0 < (timing_point.time + input_lag_compensation-timing_point.get_time_out(current_bpm)):
				break
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
								if timing_point is HBNoteData and not timing_point.note_type in HBNoteData.NO_MULTI_LIST:
									multi_notes.append(timing_point)
						elif multi_notes.size() > 1:
							hookup_multi_notes(multi_notes)
						else:
							multi_notes = [timing_point]
					elif timing_point is HBNoteData and not timing_point.note_type in HBNoteData.NO_MULTI_LIST:
						multi_notes.append(timing_point)
				
				# Ensure that we delete any hold piece that doesn't have parent when previewing
				if previewing:
					for timing_point in notes_on_screen:
						if timing_point is HBNoteData and timing_point.is_slide_hold_piece():
							var parent_found = false
							for chain_starter in slide_hold_chains:
								if timing_point in slide_hold_chains[chain_starter]:
									if not chain_starter in notes_on_screen:
										for i in range(active_slide_hold_chains.size() - 1, -1, -1):
											var active_chain = active_slide_hold_chains[i]
											if timing_point in active_chain.pieces:
												parent_found = true
									else:
										parent_found = true
							if not parent_found:
								var note_drawer = timing_point.get_meta("note_drawer")
								note_drawer.emit_signal("note_removed")
								note_drawer.queue_free()
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
		current_hold_score = ((time - current_hold_start_time) * 1000.0) * held_notes.size()
		
		if time >= max_time:
			current_hold_score = int(current_hold_score + accumulated_hold_score)
			add_hold_score(MAX_HOLD)
			
			hold_indicator.current_score = current_hold_score
			hold_release()
			
			hold_indicator.show_max_combo(MAX_HOLD)
			
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
				var piece_drawer = piece.get_meta("note_drawer") as HBNoteDrawer
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
		
	if Diagnostics.enable_autoplay or previewing:
		if not result.used_cheats:
			result.used_cheats = true
			Log.log(self, "Disabling leaderboard upload for cheated result")
		for i in range(notes_on_screen.size() - 1, -1, -1):
			var note = notes_on_screen[i]
			if note is HBNoteData and note.note_type in NOTE_TYPE_TO_ACTIONS_MAP:
				if time*1000 > note.time:
					var a = InputEventAction.new()
					a.action = NOTE_TYPE_TO_ACTIONS_MAP[note.note_type][0]
					a.pressed = true
					play_note_sfx(note.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT or note.note_type == HBNoteData.NOTE_TYPE.SLIDE_RIGHT)
					Input.parse_input_event(a)

func set_current_combo(combo: int):
	current_combo = combo
	
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
		

func get_heart_power_points_per_note():
	return 100.0 / current_song.bpm

# Heart power activation for half phase is minimum 4 seconds, otherwise it's 1/8th of the max power points
func get_heart_power_duration():
	return max(round(50000/(pow(current_song.bpm, 2.0))), 4)

func increase_heart_power():
	var old_heart_power = heart_power
	heart_power += get_heart_power_points_per_note()
	heart_power = clamp(heart_power, 0, MAX_HEART_POWER)
	if old_heart_power < MAX_HEART_POWER/2.0 and heart_power > MAX_HEART_POWER/2.0:
		heart_power_prompt_animation_player.play("HeartPowerAvailable")
	update_heart_power_ui()
	
	
func update_heart_power_ui():
	heart_power_indicator.value = heart_power / MAX_HEART_POWER
	if heart_power_enabled:
		heart_power_indicator.tint_progress = HEART_INDICATOR_DECREASING
	else:
		heart_power_indicator.tint_progress = HEART_POWER_PROGRESS_TINT
	
func _on_notes_judged(notes: Array, judgement, wrong):
	var note = notes[0] as HBNoteData
	# Some notes might be considered more than 1 at the same time? connected ones aren't
	var notes_hit = 1
	if not editing or previewing:
		# Rating graphic
		if note.note_type in held_notes:
			hold_release()
		if judgement < judge.JUDGE_RATINGS.FINE or wrong:
			# Missed a note
			if UserSettings.user_settings.enable_voice_fade:
				audio_stream_player_voice.volume_db = -90
			set_current_combo(0)
			# make the heart power indicator darker to indicate that a perfect
			# is not possible anymore
			heart_power_indicator.tint_over = HEART_INDICATOR_MISSED
			hold_release()
		else:
			increase_heart_power()
			set_current_combo(current_combo + notes_hit)
			audio_stream_player_voice.volume_db = 0
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
					
					var active_hold_chain = {
						"pieces": slide_hold_chains[note],
						"slide_note": note,
						"sfx_player": hold_player,
						"is_playing_loop": false,
						"accumulated_score": 0
					}
					active_slide_hold_chains.append(active_hold_chain)
				else:
					# kill slide and younglings if we failed
					for piece in slide_hold_chains[note]:
						if piece in notes_on_screen:
							var piece_drawer = piece.get_meta("note_drawer")
							piece_drawer.emit_signal("note_removed")
							piece_drawer.queue_free()
						else:
							timing_points.remove(timing_points.find(piece))
		
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
		var judgement_info = {
			"judgement": judgement,
			"target_time": notes[0].time,
			"time": int(time*1000)
		}
		emit_signal("note_judged", judgement_info)

func _on_slide_hold_player_finished(hold_player: AudioStreamPlayer):
	hold_player.stream = preload("res://sounds/sfx/slide_hold_loop.wav")
	hold_player.seek(0)
	hold_player.volume_db = 4
	hold_player.play()

func _on_note_removed(note):
	remove_note_from_screen(notes_on_screen.	find(note))
				
func pause_game():
	audio_stream_player.stream_paused = true
	audio_stream_player_voice.stream_paused = true
	get_tree().paused = true
func resume():
	get_tree().paused = false
	play_from_pos(audio_stream_player.get_playback_position())
	
func restart():
	get_tree().paused = false
	set_song(SongLoader.songs[current_song.id], current_difficulty)
	audio_stream_player_voice.volume_db = 0
	set_current_combo(0)
	heart_power_indicator.tint_over = HEART_POWER_OVER_TINT
	
func play_from_pos(position: float):
	audio_stream_player.stream_paused = false
	audio_stream_player_voice.stream_paused = false
	audio_stream_player.play()
	audio_stream_player_voice.play()
	audio_stream_player.seek(position)
	audio_stream_player_voice.seek(position)
	time_begin = OS.get_ticks_usec() - int(position * 1000000.0)
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
func add_score(score_to_add):
	if not previewing:
		result.score += score_to_add
		score_counter.score = result.score
		clear_bar.value = result.get_capped_score()
		if heart_power_enabled:
			result.heart_power_bonus += score_to_add * 0.5

func add_hold_score(score_to_add):
	result.hold_bonus += score_to_add
	add_score(score_to_add)
	
func add_slide_chain_score(score_to_add):
	result.slide_bonus += score_to_add
	add_score(score_to_add)
func _on_AudioStreamPlayer_finished():
	emit_signal("song_cleared", result)

func hold_release():
	if held_notes.size() > 0:
		add_hold_score(round(current_hold_score))
		print("END hold ", current_hold_score)
		accumulated_hold_score = 0
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
