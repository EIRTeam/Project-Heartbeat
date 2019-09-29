extends Node

const NoteTargetScene = preload("res://rythm_game/NoteTarget.tscn")
const NoteScene = preload("res://rythm_game/Note.tscn")


var NOTE_TYPE_TO_ACTIONS_MAP = {
	HBNoteData.NOTE_TYPE.RIGHT: ["ui_right"],
	HBNoteData.NOTE_TYPE.LEFT: ["ui_left"],
	HBNoteData.NOTE_TYPE.UP: ["ui_up"],
	HBNoteData.NOTE_TYPE.DOWN: ["ui_down"]
}

var judge = preload("res://rythm_game/judge.gd").new()

var time_begin: int
var time_delay: float
var time: float

var timing_points = []

var notes_on_screen = []

func _ready():
	var chart = HBChart.new()
	var note1 = HBNoteData.new()
	note1.time = 2000
	var note2 = HBNoteData.new()
	note2.time = 3000
	
	chart.layers.append({"items": [note1, note2]})
	timing_points = chart.get_timing_points()
	play_song()

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
	notes_on_screen[i].get_meta("note_graphic").free()
	notes_on_screen[i].get_meta("note_target_graphic").free()
	
	notes_on_screen.remove(i)
	
func update_note(note):
	var note_target_graphic = note.get_meta("note_target_graphic")
	note_target_graphic.distance = note.time - time * 1000.0
	note_target_graphic.update()
	var note_initial_position = note.get_meta("note_initial_position")
	var time_out_distance = note.time_out - (note.time - time*1000.0)
	note.get_meta("note_graphic").position = lerp(note_initial_position, note_target_graphic.position, time_out_distance/note.time_out)
	if time * 1000.0 > note.time:
		var disappereance_time = note.time + (judge.TARGET_WINDOW / 60.0 * 1000.0)
		var new_scale = (disappereance_time - time * 1000.0) / (judge.TARGET_WINDOW / 60.0 * 1000.0)
		if new_scale < 0:
			print(new_scale)
		note.get_meta("note_graphic").scale = Vector2(new_scale, new_scale)
	
func _process(delta):
	# Obtain from ticks.
	time = (OS.get_ticks_usec() - time_begin) / 1000000.0
	# Compensate for latency.
	time -= time_delay
	# May be below 0 (did not being yet).
	time = max(0, time)
	$CanvasLayer/DebugLabel.text = HBUtils.format_time(int(time * 1000))
	
	for i in range(timing_points.size() - 1, -1, -1):
		var timing_point = timing_points[i]
		if timing_point is HBNoteData:
			print("POINT")
			if timing_point.time-timing_point.time_out >= time * 1000.0:
				var note = NoteScene.instance()
				var target = NoteTargetScene.instance()
				add_child(note)
				add_child(target)
				target.time_out = timing_point.time_out
				print("ADDING NOTE")
				timing_point.set_meta("note_graphic", note)
				timing_point.set_meta("note_target_graphic", target)
				timing_point.set_meta("note_initial_position", note.position)
				
				notes_on_screen.append(timing_point)
				timing_points.remove(i)
			
	for i in range(notes_on_screen.size() - 1, -1, -1):
		
		var note = notes_on_screen[i]
		update_note(note)
		if judge.judge_note(time, note.time / 1000.0) == judge.JUDGE_RATINGS.WORST:
			print("died of old age...")
			remove_note_from_screen(i)

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
