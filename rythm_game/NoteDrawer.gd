extends Node2D
class_name HBNoteDrawer
var note_data: HBNoteData = HBNoteData.new() setget set_note_data
var game

signal target_selected
signal notes_judged(notes, judgement, wrong)
signal note_removed

var connected_notes = [] setget set_connected_notes

var multi_note_line_renderers = []

var next_note = null
var note_master = true setget set_note_master # Master notes take care of multi-note stuff...

const Laser = preload("res://rythm_game/Laser.tscn")

func set_note_data(val):
	note_data = val
	$NoteTarget.note_data = note_data

func show_note_hit_effect():
	var effect_scene = preload("res://graphics/effects/NoteHitEffect.tscn")
	var effect = effect_scene.instance()
	game.add_child(effect)
	effect.position = game.remap_coords(note_data.position)
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
	game.connect("size_changed", self, "_on_game_size_changed")
	# (Not used anymore) HACKISH way to handle proper z ordering of notes, PD puts newer notes in front
	# VisualServer has a hard limit on how far you can take the Z, hence the hackish, should... work right?
	#z_index = 8 - (note_data.time % 8)
	# not used anymore, was causing issues

func _on_game_size_changed():
	pass

func update_graphic_positions_and_scale(time: float):
	if note_master:
		if connected_notes.size() > 1:
			var points = PoolVector2Array()
			for note in connected_notes:
				
				points.append(game.get_note_drawer(note).get_note_graphic().position)
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
	var px = note_data.position.x
	var py = note_data.position.y
	var angle_cos = -cos(deg2rad(note_data.entry_angle))
	var angle_sin = -sin(deg2rad(note_data.entry_angle))
	var length = note_data.distance
	var point = Vector2(px+length*angle_cos, py+length*angle_sin)

	return point

var _cached_time_out = null

func get_time_out():
	if not _cached_time_out:
		_cached_time_out = note_data.get_time_out(game.get_bpm_at_time(note_data.time))
	return _cached_time_out 

func judge_note_input(event: InputEvent, time: float, released = false):
	# Judging tapped keys
	var out_judgement = -1
	for action in game.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type]:
		var event_result = event.is_action_pressed(action) and not event.is_echo()
		if released:
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
			if game.get_note_drawer(note) != self:
				if not game.get_note_drawer(note).is_queued_for_deletion():
					game.get_note_drawer(note)._on_game_time_changed(time)

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
