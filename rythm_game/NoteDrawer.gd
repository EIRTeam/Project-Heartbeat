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
	z_index = VisualServer.CANVAS_ITEM_Z_MAX - (note_data.time % VisualServer.CANVAS_ITEM_Z_MAX)

func update_graphic_positions_and_scale(time: float):
	pass

func _on_note_type_changed():
	pass

func get_initial_position():
	return Vector2(1.0, 0.5)

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
						emit_signal("note_judged", judgement)
				break

func _on_game_time_changed(time: float):
	update_graphic_positions_and_scale(time)
	judge_note_input(time)
	# Killing notes after the user has run past them... TODO: make this produce a WORST rating
	if time >= (note_data.time + game.judge.get_target_window_msec()) / 1000.0 or time * 1000.0 < (note_data.time - note_data.time_out):
		emit_signal("note_judged", game.judge.JUDGE_RATINGS.WORST)


func _on_NoteTarget_note_moved():
	pass
	emit_signal("target_moved")

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")
	

func get_notes():
	return [note_data]
