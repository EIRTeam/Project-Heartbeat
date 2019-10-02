extends Node

const NoteTargetScene = preload("res://rythm_game/NoteTarget.tscn")
const NoteScene = preload("res://rythm_game/Note.tscn")


var NOTE_TYPE_TO_ACTIONS_MAP = {
	HBNoteData.NOTE_TYPE.RIGHT: ["ui_right"],
	HBNoteData.NOTE_TYPE.LEFT: ["ui_left"],
	HBNoteData.NOTE_TYPE.UP: ["ui_up"],
	HBNoteData.NOTE_TYPE.DOWN: ["ui_down"]
}

onready var audio_stream_player = get_node("AudioStreamPlayer")
const LOG_NAME = "RhythmGame"
var judge = preload("res://rythm_game/judge.gd").new()

var time_begin: int
var time_delay: float
var time: float

var timing_points = []

var notes_on_screen = []

const BASE_SIZE = Vector2(1920, 1080)
const MAX_SCALE = 1.5

var size = Vector2(1280, 720) setget set_size

var editing = false

signal note_updated(note)
signal note_selected(note)
func set_size(value):
	size = value
	for note in notes_on_screen:
		note.get_meta("note_target_graphic").position = remap_coords(note.position)

func _ready():
#	var note = HBNoteData.new()
#	note.time = 2000
#	timing_points.append(note)
#	play_song()
	pass

func get_note_scale():
	return get_playing_field_size().length() / BASE_SIZE.length()

func get_playing_field_size():
	var ratio = 16.0/9.0
	return Vector2(size.y*ratio, size.y)

func remap_coords(coords: Vector2):
	var field_size = get_playing_field_size()
	var pos = coords * field_size
	if abs(coords.x) > 1.0 or abs(coords.y) > 1.0 :
		Log.log(self, "remap_coords expects a max size of < 1.0 in any dimension, coords was %s" % var2str(coords), Log.LogLevel.WARN)
	return Vector2((size.x - field_size.x) / 2.0 + pos.x, pos.y)
	
func inv_map_coords(coords: Vector2):
	var field_size = get_playing_field_size()
	var x = (coords.x - ((size.x - field_size.x) / 2.0)) / get_playing_field_size().x
	return Vector2(x, coords.y / get_playing_field_size().y)
func play_song():
	time_begin = OS.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	$AudioStreamPlayer.play()

func get_closest_note_of_type(note_type: int):
	var closest_note = null
	for note in notes_on_screen:
		if note.note_type == note_type:
			if closest_note:
				if note.time < closest_note.time:
					closest_note = note
			else:
				closest_note = note
	return closest_note

func remove_note_from_screen(i):
	notes_on_screen[i].get_meta("note_graphic").queue_free()
	notes_on_screen[i].get_meta("note_target_graphic").queue_free()
	
	notes_on_screen.remove(i)
	
func remove_all_notes_from_screen():
	for i in range(notes_on_screen.size() - 1, -1, -1):
		remove_note_from_screen(i)
	
func update_note(note):
	var note_target_graphic = note.get_meta("note_target_graphic")
	note_target_graphic.distance = note.time - time * 1000.0
	note_target_graphic.update()
	var note_initial_position = note.get_meta("note_initial_position")
	var time_out_distance = note.time_out - (note.time - time*1000.0)
	note.get_meta("note_graphic").position = lerp(note_initial_position, note_target_graphic.position, time_out_distance/note.time_out)
	
	if time * 1000.0 > note.time:
		var disappereance_time = note.time + (judge.TARGET_WINDOW / 60.0 * 1000.0)
		var new_scale = (disappereance_time - time * 1000.0) / (judge.TARGET_WINDOW / 60.0 * 1000.0) * get_note_scale()
		if new_scale < 0:
			print(new_scale)
		note.get_meta("note_graphic").scale = Vector2(new_scale, new_scale)
	else:
		note.get_meta("note_graphic").scale = Vector2(get_note_scale(), get_note_scale())
	note.get_meta("note_target_graphic").scale = Vector2(get_note_scale(), get_note_scale())
	note.get_meta("note_target_graphic").position = remap_coords(note.position) # This makes moving targets in the editor work from the inspector, ugly but works
func _process(delta):
	if $AudioStreamPlayer.playing:
		# Obtain from ticks.
		time = (OS.get_ticks_usec() - time_begin) / 1000000.0
		# Compensate for latency.
		time -= time_delay
		# May be below 0 (did not being yet).
		time = max(0, time)
		$CanvasLayer/DebugLabel.text = HBUtils.format_time(int(time * 1000))
	
	# Adding visible notes
	
	for i in range(timing_points.size() - 1, -1, -1):
		var timing_point = timing_points[i]
		if timing_point is HBNoteData:
			if time * 1000.0 >= (timing_point.time-timing_point.time_out):
				if not timing_point in notes_on_screen:
					# Ignore very old notes (editor optimization)
					if judge.judge_note(time, timing_point.time/1000.0) == judge.JUDGE_RATINGS.WORST:
						break
					var target = NoteTargetScene.instance()
					target.note_data = timing_point
					target.time_out = timing_point.time_out
					target.game = self
					add_child(target)
					
					var note_scene = NoteScene.instance()
					target.position = remap_coords(note_scene.note_data.position)
					note_scene.note_data = timing_point
					add_child(note_scene)
					
					timing_point.set_meta("note_graphic", note_scene)
					timing_point.set_meta("note_target_graphic", target)
					timing_point.set_meta("note_initial_position", note_scene.position)
					
					
					# Connect signal to indicate a note has been move or selectedd by the user (in editing mode)
					if editing and timing_point is HBNoteData:
						target.connect("note_moved", self, "_on_note_moved", [timing_point])
						target.connect("note_selected", self, "_on_note_selected", [timing_point])
					
					notes_on_screen.append(timing_point)
				if not editing:
					timing_points.remove(i)
			
			
	for i in range(notes_on_screen.size() - 1, -1, -1):
		var note = notes_on_screen[i]
		update_note(note)
#		AUTOJUDGE: broken
#		if editing:
#			if judge.judge_note(time, note.time/1000.0) == judge.JUDGE_RATINGS.COOL:
#				var ev = InputEventAction.new()
#				ev.pressed = true
#				for type in NOTE_TYPE_TO_ACTIONS_MAP:
#					if type == note.note_type:
#						ev.action = NOTE_TYPE_TO_ACTIONS_MAP[type][0]
#						break
#				$HitEffect.play()
		
		# Killing notes after the user has run past them... TODO: make this produce a WORST rating
		if time >= (note.time + judge.get_target_window_msec()) / 1000.0 or time * 1000.0 < (note.time - note.time_out):
			remove_note_from_screen(i)

	# Judging tapped keys

	for type in NOTE_TYPE_TO_ACTIONS_MAP:
		var actions = NOTE_TYPE_TO_ACTIONS_MAP[type]
		for action in actions:
			if Input.is_action_just_pressed(action):
				$HitEffect.play()
				var closest_note = get_closest_note_of_type(type)
				if closest_note:
					var judgement = judge.judge_note(time, closest_note.time/1000.0)
					if judgement:
						print("JUDGED!", judgement," ", time, " ", closest_note.time/1000.0)
						remove_note_from_screen(notes_on_screen.find(closest_note))
				break
				
func _on_note_moved(note: HBNoteData):
	if editing:
		emit_signal("note_updated", note)
		
func _on_note_selected(note: HBNoteData):
	if editing:
		emit_signal("note_selected", note)
