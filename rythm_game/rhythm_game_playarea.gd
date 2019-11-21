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

onready var notes_node = get_node("Notes")
onready var score_counter = get_node("Control/HBoxContainer/HBoxContainer/Label")
var input_lag_compensation = 0

var result = HBResult.new()

onready var audio_stream_player = get_node("AudioStreamPlayer")
onready var rating_label : Label = get_node("RatingLabel")

onready var author_label = get_node("Control/HBoxContainer/Panel/VBoxContainer/HBoxContainer/SongAuthor")
onready var song_name_label = get_node("Control/HBoxContainer/Panel/VBoxContainer/HBoxContainer/SongName")

const LOG_NAME = "RhythmGame"
var judge = preload("res://rythm_game/judge.gd").new()

var time_begin: int
var time_delay: float
var time: float
var current_combo = 0
var timing_points = []

var _sfx_played_this_cycle = false

var notes_on_screen = []

var auto_play = true

const BASE_SIZE = Vector2(1920, 1080)
const MAX_SCALE = 1.5

var size = Vector2(1280, 720) setget set_size

var editing = false

const MAX_NOTE_SFX = 4

signal note_updated(note)
signal note_selected(note)
signal time_changed(time)
func set_size(value):
	size = value

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
func _on_viewport_size_changed():
	print(get_viewport().size)
	$Viewport.size = self.rect_size
	
func set_song(song: HBSong):
	result = HBResult.new()
	result.song_id = song.id
	$AudioStreamPlayer.stream = HBUtils.load_ogg(song.get_song_audio_res_path())
	song_name_label.text = song.title
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
	var chart_path = song.get_chart_path("easy")
	var file = File.new()
	file.open(chart_path, File.READ)
	var result = JSON.parse(file.get_as_text()).result
	
	var chart = HBChart.new()
	chart.deserialize(result)
	timing_points = chart.get_timing_points()
	play_song()
func get_note_scale():
	return (get_playing_field_size().length() / BASE_SIZE.length()) * 0.85

func get_playing_field_size():
	var ratio = 16.0/9.0
	return Vector2(size.y*ratio, size.y)

func remap_coords(coords: Vector2):
	var field_size = get_playing_field_size()
	var pos = coords * field_size
#	if abs(coords.x) > 1.0 or abs(coords.y) > 1.0 :
#		Log.log(self, "remap_coords expects a max size of < 1.0 in any dimension, coords was %s" % var2str(coords), Log.LogLevel.WARN)
	return Vector2((size.x - field_size.x) / 2.0 + pos.x, pos.y)
	
func inv_map_coords(coords: Vector2):
	var field_size = get_playing_field_size()
	var x = (coords.x - ((size.x - field_size.x) / 2.0)) / get_playing_field_size().x
	return Vector2(x, coords.y / get_playing_field_size().y)
func play_song():
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	audio_stream_player.play()

func _unhandled_input(event):
	$Viewport.unhandled_input(event)

func get_closest_note_of_type(note_type: int):
	var closest_note = null
	for note_c in notes_on_screen:
		# For multi-note support
		var notes = note_c.get_meta("note_drawer").get_notes()
		for note in notes:
			if note.note_type == note_type:
				var time_diff = abs(note.time - time * 1000.0)
				if closest_note:
					if time_diff < abs(closest_note.time - time * 1000.0):
						closest_note = note
					time_diff = abs(note.time + note.get_duration() - time * 1000.0)
					if time_diff < abs(closest_note.time - time * 1000.0):
						closest_note = note
				else:
					closest_note = note
	return closest_note

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
	
func _process(delta):
	if audio_stream_player.playing:
		# Obtain current time from ticks, offset by the time we began playing music.
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
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
	# Adding visible notes
	
	for i in range(timing_points.size() - 1, -1, -1):
		var timing_point = timing_points[i]
		if timing_point is HBNoteData:
			if time * 1000.0 >= (timing_point.time + input_lag_compensation-timing_point.time_out):
				if not timing_point in notes_on_screen:
					# Prevent older notes from being re-created
					if judge.judge_note(time + input_lag_compensation, (timing_point.time + timing_point.get_duration())/1000.0) == judge.JUDGE_RATINGS.WORST:
						continue
					var note_drawer
					note_drawer = timing_point.get_drawer().instance()
					note_drawer.note_data = timing_point
					note_drawer.game = self
					notes_node.add_child(note_drawer)
					note_drawer.connect("note_judged", self, "_on_note_judged")
					note_drawer.connect("note_removed", self, "_on_note_removed", [timing_point])
					timing_point.set_meta("note_drawer", note_drawer)
					notes_on_screen.append(timing_point)
					connect("time_changed", note_drawer, "_on_game_time_changed")
					
				if not editing:
					timing_points.remove(i)
	
	emit_signal("time_changed", time+input_lag_compensation)
	if auto_play:
		for i in range(notes_on_screen.size() - 1, -1, -1):
			var note = notes_on_screen[i]
			if note is HBNoteData:
				if judge.judge_note(time, note.time/1000.0) == judge.JUDGE_RATINGS.COOL:
					var a = InputEventAction.new()
					a.action = NOTE_TYPE_TO_ACTIONS_MAP[note.note_type][0]
					a.pressed = true
					play_note_sfx()
					Input.parse_input_event(a)
	_sfx_played_this_cycle = false
func _on_note_judged(note, judgement):
	if not editing:
		# Rating graphic
		if judgement < judge.JUDGE_RATINGS.FINE:
			current_combo = 0
		else:
			current_combo += 1
			result.notes_hit += 1
		
		
		result.note_ratings[judgement] += 1
		result.total_notes += 1
		if current_combo > result.max_combo:
			result.max_combo = current_combo
		var new_pos = remap_coords(note.position)
		
		var rating_to_color = {
			judge.JUDGE_RATINGS.COOL: "#ffd022",
			judge.JUDGE_RATINGS.FINE: "#4ebeff",
			judge.JUDGE_RATINGS.SAFE: "#00a13c",
			judge.JUDGE_RATINGS.SAD: "#57a9ff",
			judge.JUDGE_RATINGS.WORST: "#e470ff"
		}
		
		rating_label.get_node("AnimationPlayer").play("rating_appear")
		rating_label.add_color_override("font_color", Color(rating_to_color[judgement]))
		rating_label.text = judge.RATING_TO_TEXT_MAP[judgement]
		if current_combo > 1:
			rating_label.text += " " + str(current_combo)
		rating_label.rect_size = rating_label.get_combined_minimum_size()
		rating_label.rect_position = new_pos - rating_label.get_combined_minimum_size() / 2
		rating_label.rect_position.y -= 64
		rating_label.show()
func _on_note_removed(note):
	remove_note_from_screen(notes_on_screen.find(note))
				
func _on_note_moved(note: HBNoteData):
	if editing:
		emit_signal("note_updated", note)
		
func _on_note_selected(note: HBNoteData):
	if editing:
		emit_signal("note_selected", note)

func pause_game():
	audio_stream_player.stream_paused = true
	get_tree().paused = true
func resume():
	get_tree().paused = false
	play_from_pos(audio_stream_player.get_playback_position())
	
func play_from_pos(position: float):
	audio_stream_player.stream_paused = false

	audio_stream_player.play()
	audio_stream_player.seek(position)
	time_begin = OS.get_ticks_usec() - int(position * 1000000.0)
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
func add_score(score_to_add):
	result.score += score_to_add
	score_counter.score = result.score
