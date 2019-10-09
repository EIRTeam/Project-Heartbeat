extends Node2D

var note_data: HBNoteData = HBNoteData.new()
var game

signal target_moved
signal target_selected
signal note_judged(judgement)
signal note_removed
func _ready():
	note_data.connect("note_type_changed", self, "_on_note_type_changed")
	# HACKISH way to handle proper z ordering of notes, PD puts newer notes in front
	# VisualServer has a hard limit on how far you can take the Z, hence the hackish, should... work right?
	#z_index = 8 - (note_data.time % 8)
	# not used anymore, was causing issues

func update_graphic_positions_and_scale(time: float):
	pass

func _on_note_type_changed():
	pass

func get_initial_position():
	var angle_cos = -cos(deg2rad(note_data.angle))
	var angle_sin = -sin(deg2rad(note_data.angle))
	var x1 = 0
	var y1 = 0
	var x2 = 1.0
	var y2 = 1.0
	
	var px = note_data.position.x
	var py = note_data.position.y
	
	var ts = []
	if angle_cos != 0:
		ts.append((x1-px)/angle_cos)
		ts.append((x2-px)/angle_cos)
	if angle_sin != 0:
		ts.append((y1-py)/angle_sin)
		ts.append((y2-py)/angle_sin)
	var length
	for distance in ts:
		if not length and distance > 0:
			length = distance
			continue
		if distance > 0 and distance < length:
			length = distance
	var point = Vector2(px+length*angle_cos, py+length*angle_sin)

	return point

func judge_note_input(time: float):
	# Judging tapped keys
	for type in game.NOTE_TYPE_TO_ACTIONS_MAP:
		var actions = game.NOTE_TYPE_TO_ACTIONS_MAP[type]
		for action in actions:
			if Input.is_action_just_pressed(action):
				var closest_note = game.get_closest_note_of_type(type)
				if closest_note == note_data:
					print("SELF")
					var judgement = game.judge.judge_note(time, closest_note.time/1000.0)
					if judgement:
						print("JUDGED!", judgement," ", time, " ", closest_note.time/1000.0)
						emit_signal("note_judged", note_data, judgement)
						emit_signal("note_removed")
						queue_free()
				break

func _on_game_time_changed(time: float):
	update_graphic_positions_and_scale(time)
	judge_note_input(time)
	# Killing notes after the user has run past them... TODO: make this produce a WORST rating
	if time >= (note_data.time + game.judge.get_target_window_msec()) / 1000.0 or time * 1000.0 < (note_data.time - note_data.time_out):
		emit_signal("note_judged", note_data, game.judge.JUDGE_RATINGS.WORST)


func _on_NoteTarget_note_moved():
	pass
	emit_signal("target_moved")

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")
	

func get_notes():
	return [note_data]
