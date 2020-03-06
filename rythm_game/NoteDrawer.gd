extends Node2D
var note_data: HBNoteData = HBNoteData.new()
var game

signal target_selected
signal notes_judged(notes, judgement, wrong)
signal note_removed

var connected_notes = [] setget set_connected_notes

var multi_note_line_renderers = []

var next_note = null
var note_master = true setget set_note_master # Master notes take care of multi-note stuff...

const Laser = preload("res://rythm_game/Laser.tscn")

func set_note_master(val):
	note_master = val
	if val == false:
		if game.is_connected("time_changed", self, "_on_game_time_changed"):
			game.disconnect("time_changed", self, "_on_game_time_changed")
		set_process_unhandled_input(false)
	else:
		set_process_unhandled_input(true)
		game.connect("time_changed", self, "_on_game_time_changed")
		

func set_connected_notes(val):
	connected_notes = val
	if connected_notes.size() > 1:
		if multi_note_line_renderers.size() == 0:
			var laser1 = Laser.instance()
			multi_note_line_renderers.append(laser1)
			add_child(laser1)
			move_child(laser1, 0)
			
			var laser2 = Laser.instance()
			multi_note_line_renderers.append(laser2)
			add_child(laser2)
			move_child(laser2, 1)
			
			laser2.timescale += 1
			laser2.frequency = 5
			laser2.phase_shift = 90
func _ready():
#	z_index = 0
	note_data.connect("note_type_changed", self, "_on_note_type_changed")
	# HACKISH way to handle proper z ordering of notes, PD puts newer notes in front
	# VisualServer has a hard limit on how far you can take the Z, hence the hackish, should... work right?
	#z_index = 8 - (note_data.time % 8)
	# not used anymore, was causing issues

func update_graphic_positions_and_scale(time: float):
	if note_master:
		if connected_notes.size() > 1:
			var points = PoolVector2Array()
			for note in connected_notes:
				points.append(note.get_meta("note_drawer").get_note_graphic().position)
			points.append(get_note_graphic().position)
			points = Geometry.convex_hull_2d(points)
			if connected_notes.size() <= 2:
				points.remove(points.size()-1)
			for renderer in multi_note_line_renderers:
				renderer.positions = points
				renderer.show()

func _on_note_type_changed():
	pass

func get_initial_position():
#	var x1 = 0
#	var y1 = 0
#	var x2 = 1.0
#	var y2 = 1.0
	
	var px = note_data.position.x
	var py = note_data.position.y
	
#	var ts = []
#	if angle_cos != 0:
#		ts.append((x1-px)/angle_cos)
#		ts.append((x2-px)/angle_cos)
#	if angle_sin != 0:
#		ts.append((y1-py)/angle_sin)
#		ts.append((y2-py)/angle_sin)
#	var length = 0
#	for distance in ts:
#		if not length and distance > 0:
#			length = distance
#			continue
#		if distance > 0 and distance < length:
#			length = distance
	
	# We used to make the notes come from the corner, but we realised we are idiots and we don't need this anymore
	
#	length = clamp(length, note_data.distance, note_data.distance)
	var angle_cos = -cos(deg2rad(note_data.entry_angle))
	var angle_sin = -sin(deg2rad(note_data.entry_angle))
	var length = note_data.distance
	var point = Vector2(px+length*angle_cos, py+length*angle_sin)

	return point

func get_time_out():
	if note_data.auto_time_out:
		return int((60.0  / game.current_bpm * (1 + 3) * 1000.0))
	else:
		return note_data.time_out

func judge_note_input(event: InputEvent, time: float, released = false):
	# Judging tapped keys
	var out_judgement = -1
	for action in game.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
		var event_result = event.is_action_pressed(action) and not event.is_echo()
		if released:
#			print("CHECK RELEASED FOR " + action + " RESULT: " + str(event.is_action_released(action)))
			event_result = event.is_action_released(action)
		if event_result:
			var closest_notes = game.get_closest_notes_of_type(note_data.note_type)
			if note_data in closest_notes:
				var judgement = game.judge.judge_note(time, note_data.time/1000.0)
				if not judgement:
					judgement = game.judge.judge_note(time, note_data.time+note_data.get_duration()/1000.0)
				if judgement:
					print("JUDGED!", judgement," ", time, " ", note_data.time/1000.0)
					out_judgement = judgement
			break
	return out_judgement

func _on_game_time_changed(time: float):
	if note_master:
		for note in connected_notes:
			if note.get_meta("note_drawer") != self:
				if not note.get_meta("note_drawer").is_queued_for_deletion():
					note.get_meta("note_drawer")._on_game_time_changed(time)

func _on_NoteTarget_note_selected():
	emit_signal("target_selected")

func get_note_graphic():
	pass

func get_notes():
	return [note_data]

func _on_heart_power_activated():
	pass
func _on_heart_power_end():
	pass
