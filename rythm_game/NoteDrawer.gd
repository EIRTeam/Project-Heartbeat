extends Node2D

var note_data: HBNoteData = HBNoteData.new()
var game

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
signal target_moved
signal target_selected

func _ready():
	note_data.connect("note_type_changed", self, "_on_note_type_changed")
	_on_note_type_changed()
	# HACKISH way to handle proper z ordering of notes, PD puts newer notes in front
	# VisualServer has a hard limit on how far you can take the Z, hence the hackish, should... work right?
	z_index = VisualServer.CANVAS_ITEM_Z_MAX - (note_data.time % VisualServer.CANVAS_ITEM_Z_MAX)

func update_graphic_positions(time: float):
	target_graphic.position = game.remap_coords(note_data.position)
	var time_out_distance = note_data.time_out - (note_data.time - time*1000.0)
	note_graphic.position = lerp(game.remap_coords(get_initial_position()), target_graphic.position, time_out_distance/note_data.time_out)
func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type)
	target_graphic.set_note_type(note_data.note_type)

func get_initial_position():
	return Vector2(1.0, 0.5)

func _on_game_time_changed(time: float):
	update_graphic_positions(time)
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.TARGET_WINDOW / 60.0 * 1000.0)
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.TARGET_WINDOW / 60.0 * 1000.0) * game.get_note_scale()
		note_graphic.scale = Vector2(new_scale, new_scale)
	else:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())


func _on_NoteTarget_note_moved():
	note_data.position = game.inv_map_coords(target_graphic.position)
	emit_signal("target_moved")

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")
