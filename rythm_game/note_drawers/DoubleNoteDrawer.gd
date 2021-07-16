extends "res://rythm_game/note_drawers/SingleNoteDrawer.gd"

const DOUBLE_NOTE_HIT_SFX = "double_note_hit"

func _init():
	note_scale = 1.1

func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type, connected_notes.size() > 0, true)
	target_graphic.set_note_type(note_data)

func judge_note_input(event: InputEvent, time: float):
	var total = 0
	for action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
		total += game.game_input_manager.get_action_press_count(action)
		#total += HBTapHandler.get_action_held_count(action)
	for action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
		if event.is_action_pressed(action) and total >= 2:
			return .judge_note_input(event, time)
	return JudgeInputResult.new()

func handle_input(event: InputEvent, time: float):
	pass

func handles_hit_sfx_playback() -> bool:
	var judgement = game.judge.judge_note(game.time, note_data.time / 1000.0)
	if judgement:
		return judgement >= HBJudge.JUDGE_RATINGS.SAFE
	return false
	
func get_hit_sfx() -> String:
	var total = 0
	for action in HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
		total += game.game_input_manager.get_action_press_count(action)
	if total >= 2:
		return DOUBLE_NOTE_HIT_SFX
	else:
		return ""
