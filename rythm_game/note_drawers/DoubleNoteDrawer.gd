extends "res://rythm_game/SingleNoteDrawer.gd"

var press_count = 0

func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type, connected_notes.size() > 0, true)
	target_graphic.set_note_type(note_data.note_type, connected_notes.size() > 0, false, true)

func judge_note_input(event: InputEvent, time: float, release = false):
	if press_count > 1:
		return .judge_note_input(event, time, release)
	else:
		return JudgeInputResult.new()

func handle_input(event: InputEvent, time: float):
	var result = .judge_note_input(event, time, false)
	
	for action in game.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
		if event.is_action_released(action):
			press_count = 0
#			print("RELEASED", HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
		
	if result.has_rating:
#		print("ADD PRESS")
		press_count += 1
		
