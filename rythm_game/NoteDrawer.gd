extends Node2D
var note_data: HBNoteData = HBNoteData.new()
var game
var NOTE_SCORES = {
	HBJudge.JUDGE_RATINGS.COOL: 500,
	HBJudge.JUDGE_RATINGS.FINE: 250,
	HBJudge.JUDGE_RATINGS.SAFE: 100,
	HBJudge.JUDGE_RATINGS.SAD: 50,
	HBJudge.JUDGE_RATINGS.WORST: 0
}
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
	var angle_cos = -cos(deg2rad(note_data.entry_angle))
	var angle_sin = -sin(deg2rad(note_data.entry_angle))
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
	var length = 0
	for distance in ts:
		if not length and distance > 0:
			length = distance
			continue
		if distance > 0 and distance < length:
			length = distance
	var point = Vector2(px+length*angle_cos, py+length*angle_sin)

	return point

func judge_note_input(event: InputEvent, time: float, released = false):
	# Judging tapped keys
	var out_judgement = -1
	for action in game.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
		var event_result = event.is_action_pressed(action) and not event.is_echo()
		if released:
			print("CHECK RELEASED FOR " + action + " RESULT: " + str(event.is_action_released(action)))
			event_result = event.is_action_released(action)
		if event_result:
			var closest_note = game.get_closest_note_of_type(note_data.note_type)
			if closest_note == note_data:
				var judgement = game.judge.judge_note(time, closest_note.time/1000.0)
				if not judgement:
					judgement = game.judge.judge_note(time, closest_note.time+closest_note.get_duration()/1000.0)
				if judgement:
					print("JUDGED!", judgement," ", time, " ", closest_note.time/1000.0)
					out_judgement = judgement
			break
	return out_judgement

func _on_game_time_changed(time: float):
	pass

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")
	

func get_notes():
	return [note_data]
