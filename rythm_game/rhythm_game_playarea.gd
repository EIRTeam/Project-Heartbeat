extends Node

const NoteTargetScene = preload("res://rythm_game/NoteTarget.tscn")
const NoteScene = preload("res://rythm_game/Note.tscn")
const NoteDrawer = preload("res://rythm_game/SingleNoteDrawer.tscn")

var NOTE_TYPE_TO_ACTIONS_MAP = {
	HBNoteData.NOTE_TYPE.RIGHT: ["note_b"],
	HBNoteData.NOTE_TYPE.LEFT: ["note_x"],
	HBNoteData.NOTE_TYPE.UP: ["note_y"],
	HBNoteData.NOTE_TYPE.DOWN: ["note_a"]
}

var input_lag_compensation = 0.1

onready var audio_stream_player = get_node("AudioStreamPlayer")
onready var rating_sprite = get_node("RatingSprite")
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
signal time_changed(time)
func set_size(value):
	size = value

func _ready():
#	var note = HBNoteData.new()
#	note.time = 2000
#	timing_points.append(note)
#	play_song()
	rating_sprite.hide()

func get_note_scale():
	return (get_playing_field_size().length() / BASE_SIZE.length()) * 0.90

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

func get_closest_note_of_type(note_type: int):
	var closest_note = null
	for note_c in notes_on_screen:
		# For multi-note support
		var notes = note_c.get_meta("note_drawer").get_notes()
		for note in notes:
			if note.note_type == note_type:
				if closest_note:
					if note.time < closest_note.time:
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
	$HitEffect.play()
	
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
					add_child(note_drawer)
					# Connect signal to indicate a note has been move or selectedd by the user (in editing mode)
					if editing and timing_point is HBNoteData:
						note_drawer.connect("target_moved", self, "_on_note_moved", [timing_point])
						note_drawer.connect("target_selected", self, "_on_note_selected", [timing_point])
					note_drawer.connect("note_judged", self, "_on_note_judged")
					note_drawer.connect("note_removed", self, "_on_note_removed", [timing_point])
					timing_point.set_meta("note_drawer", note_drawer)
					notes_on_screen.append(timing_point)
					connect("time_changed", note_drawer, "_on_game_time_changed")
					
				if not editing:
					timing_points.remove(i)
			
	emit_signal("time_changed", time+input_lag_compensation)
	for i in range(notes_on_screen.size() - 1, -1, -1):
		var note = notes_on_screen[i]
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

func _on_note_judged(note, judgement):
	if not editing:
		# Rating graphic
		
		var new_pos = remap_coords(note.position)
		
		var rating_to_graphic_width = {
			judge.JUDGE_RATINGS.COOL: 195,
			judge.JUDGE_RATINGS.FINE: 155,
			judge.JUDGE_RATINGS.SAFE: 195,
			judge.JUDGE_RATINGS.SAD: 155,
			judge.JUDGE_RATINGS.WORST: 256
		}
		
		rating_sprite.get_node("AnimationPlayer").play("rating_appear")
		rating_sprite.region_rect.position.y = 64*(4-judgement)
		rating_sprite.region_rect.size.x = rating_to_graphic_width[judgement]
		rating_sprite.position = new_pos
		rating_sprite.position.y -= 64
		rating_sprite.show()
func _on_note_removed(note):
	remove_note_from_screen(notes_on_screen.find(note))
				
func _on_note_moved(note: HBNoteData):
	if editing:
		emit_signal("note_updated", note)
		
func _on_note_selected(note: HBNoteData):
	if editing:
		emit_signal("note_selected", note)
