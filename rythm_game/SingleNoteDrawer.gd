extends "res://rythm_game/NoteDrawer.gd"

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
var pickable = true setget set_pickable

export(float) var target_scale_modifier = 1.0

func set_pickable(value):
	pickable = value
	$NoteTarget.input_pickable = value

func _ready():
	# HACKISH way to handle proper z ordering of notes, PD puts newer notes in front
	# VisualServer has a hard limit on how far you can take the Z, hence the hackish, should... work right?
	_on_note_type_changed()
	$AnimationPlayer.play("note_appear")
	print("APPEAR")
	
func update_graphic_positions_and_scale(time: float):
	target_graphic.position = game.remap_coords(note_data.position)
	var time_out_distance = note_data.time_out - (note_data.time - time*1000.0)
	note_graphic.position = lerp(game.remap_coords(get_initial_position()), target_graphic.position, time_out_distance/note_data.time_out)
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.TARGET_WINDOW / 60.0 * 1000.0)
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.TARGET_WINDOW / 60.0 * 1000.0) * game.get_note_scale()
		note_graphic.scale = Vector2(new_scale, new_scale)
	else:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	target_graphic.arm_position = -((note_data.time - time*1000) / note_data.time_out)
func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type)
	target_graphic.set_note_type(note_data.note_type)

func get_initial_position():
	return Vector2(1.0, 0.5)

func _on_game_time_changed(time: float):
	update_graphic_positions_and_scale(time)
	judge_note_input(time)
	# Killing notes after the user has run past them... TODO: make this produce a WORST rating
	if time >= (note_data.time + game.judge.get_target_window_msec()) / 1000.0 or time * 1000.0 < (note_data.time - note_data.time_out):
		emit_signal("note_judged", game.judge.JUDGE_RATINGS.WORST)
		emit_signal("note_removed")
		queue_free()
		


func _on_NoteTarget_note_moved():
	note_data.position = game.inv_map_coords(target_graphic.position)
	emit_signal("target_moved")

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")
	

func get_notes():
	return [note_data]
