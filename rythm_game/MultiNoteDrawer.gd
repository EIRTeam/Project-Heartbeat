extends "res://rythm_game/NoteDrawer.gd"

const NOTE_DRAWER_SCENE = preload("res://rythm_game/SingleNoteDrawer.tscn")

var _last_note_start_position
var _last_note_target_position

var notes = []
var timing_points = []


func _ready():
	_last_note_start_position = note_data.position
	_last_note_target_position = note_data.target_position
	create_notes()
	$Line2D.show()
	_on_note_type_changed()
func create_notes():
	for note in notes:
		note.queue_free()
	timing_points = note_data.get_simplified()

func _on_note_type_changed():
	._on_note_type_changed()
	$PositionEnd.set_note_type(note_data.note_type)
	$PositionStart.set_note_type(note_data.note_type)

func _on_game_time_changed(time: float):

	if timing_points.size() > 0:
		# Set preview line2d points:
		$Line2D.points[0] = game.remap_coords(note_data.position)
		$Line2D.points[1] = game.remap_coords(note_data.target_position)

		for i in range(timing_points.size() - 1, -1, -1):
			var point = timing_points[i]
			if time * 1000.0 >= (point.time-point.time_out):
				var note_found = false
				# Create the note only if it does not exist already...
				for note in notes:
					if note.note_data == point:
						note_found = true
						continue
				if not note_found:
					if game.judge.judge_note(time, point.time/1000.0) == game.judge.JUDGE_RATINGS.WORST:
						continue
					var note_drawer = NOTE_DRAWER_SCENE.instance()
					note_drawer.note_data = point
					note_drawer.game = game
					note_drawer.connect("note_judged", self, "_on_note_judged", [note_drawer])
					note_drawer.pickable = false
					add_child(note_drawer)
					notes.append(note_drawer)
					# Remove the note from the timing points so it doesn't get re-created
					if not game.editing:
						timing_points.remove(i)
					
	for i in range(notes.size() - 1, -1, -1):
		var note = notes[i]
		if game.editing:
			var note_i = float(timing_points.find(note.note_data))
			note.note_data.position = lerp(note_data.position, note_data.target_position, note_i/float(note_data.number_of_notes-1))
		note._on_game_time_changed(time)
	if game.editing:
		var scale = Vector2(game.get_note_scale(), game.get_note_scale())
		$PositionStart.position = game.remap_coords(note_data.position)
		$PositionEnd.position = game.remap_coords(note_data.target_position)
		$PositionStart.scale = scale
		$PositionEnd.scale = scale
	if time * 1000.0 < (note_data.time - note_data.time_out):
		emit_signal("note_removed")
		queue_free()
func _on_note_judged(judgement, note_drawer):
	notes.erase(note_drawer)
	emit_signal("note_judged", note_drawer.note_data, judgement)
	print("JUDGED NOT AT ", note_drawer.note_data.time)
	if timing_points.size() == 0 and notes.size() == 0:
		# My job is done here... uwu
		emit_signal("note_removed")
		print("KILL THE MULTI")
		queue_free()

func get_notes():
	var note_datas = []
	for note in notes:
		note_datas.append(note.note_data)
	return note_datas


func _on_selected():
	emit_signal("target_selected")


func _on_position_moved():
	note_data.position = game.inv_map_coords($PositionStart.position)
	note_data.target_position = game.inv_map_coords($PositionEnd.position)


func _on_position_finished_moving():
	note_data.position = game.inv_map_coords($PositionStart.position)
	note_data.target_position = game.inv_map_coords($PositionEnd.position)
	emit_signal("target_moved")
