extends Node2D
class_name HBNoteDrawer
var note_data: HBBaseNote = HBNoteData.new() setget set_note_data
var game

# warning-ignore:unused_signal
signal notes_judged(notes, judgement, wrong)
# warning-ignore:unused_signal
signal note_removed

var connected_notes = [] setget set_connected_notes
var multi_note_line_renderers = []

var next_note = null
var note_master = true setget set_note_master # Master notes take care of multi-note stuff...

var layer_bound_node_datas = []

const Laser = preload("res://rythm_game/Laser.tscn")

class JudgeInputResult:
	var wrong = false
	var has_rating = false
	var resulting_rating = -1

class LayerBoundNodeData:
	var node: Node2D
	var remote_transform = null
	var source_transform = source_transform
	var layer_name: String
	var node_self_visibility = false # for storing the old visibility of the node
	
	func _on_node_self_visibility_changed():
		node_self_visibility = node.visible

func set_note_data(val):
	note_data = val
#	$NoteTarget.note_data = note_data

func add_bind_to_tree(data):
	var ui_node = game.game_ui.get_drawing_layer_node(data.layer_name)
	ui_node.add_child(data.node)
	if data.remote_transform:
		data.remote_transform.remote_path = data.node.get_path()

# If true, this note drawer takes care of playing the SFX by itself
func handles_hit_sfx_playback() -> bool:
	return false

# see handles_hit_sfx_playback
func get_hit_sfx() -> String:
	return ""

func show_note_hit_effect():
	var effect_scene = preload("res://graphics/effects/NoteHitEffect.tscn")
	var effect = effect_scene.instance()
	var s = game.get_note_scale()
	effect.scale = Vector2(s, s)
	game.game_ui.get_drawing_layer_node("HitParticles").add_child(effect)
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
		
func bind_node_to_layer(node: Node2D, layer_name: String, source_transform = null):
	var data := LayerBoundNodeData.new()
	data.node = node
	data.layer_name = layer_name
	
	if source_transform is NodePath:
		var remote_transform = RemoteTransform2D.new()
		data.remote_transform = remote_transform
		data.source_transform = source_transform
	data.node_self_visibility = node.visible
	node.connect("visibility_changed", data, "_on_node_self_visibility_changed")
	if is_inside_tree():
		add_bind_to_tree(data)
	
	layer_bound_node_datas.append(data)

func set_connected_notes(val):
	connected_notes = val
	if connected_notes.size() > 1:
		if multi_note_line_renderers.size() == 0:
			var laser = Laser.instance()
			multi_note_line_renderers.append(laser)
			bind_node_to_layer(laser, "Laser")
		update_multi_note_renderers()
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

var center = Vector2.ZERO

func _point_sort(a, b):
	if (a.x - center.x >= 0 && b.x - center.x < 0):
		return true;
	if (a.x - center.x < 0 && b.x - center.x >= 0):
		return false;
	if (a.x - center.x == 0 && b.x - center.x == 0):
		if (a.y - center.y >= 0 || b.y - center.y >= 0):
			return a.y > b.y
		return b.y > a.y

	# compute the cross product of vectors (center -> a) x (center -> b)
	var det = (a.x - center.x) * (b.y - center.y) - (b.x - center.x) * (a.y - center.y)
	if (det < 0):
		return true
	if (det > 0):
		return false

	# points a and b are on the same line from the center
	# check which point is closer to the center
	var d1 = (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y)
	var d2 = (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y)
	return d1 > d2

func update_multi_note_renderers():
	if not is_queued_for_deletion():
		var scale_x = (game.remap_coords(Vector2(1.0, 1.0)) - game.remap_coords(Vector2.ZERO)).x
		if note_master:
			if connected_notes.size() > 1:
				var points = PoolVector2Array()
				for note in connected_notes:
					var dr = game.get_note_drawer(note)
					if dr and not dr.is_queued_for_deletion():
						points.append(game.get_note_drawer(note).get_note_graphic().position)
#				points.append(get_note_graphic().position)
				center = Vector2.ZERO
				for point in points:
					center += point
				center /= float(points.size())
				points = Array(points)
				points.sort_custom(self, "_point_sort")
				if connected_notes.size() > 2:
					points.append(points[0])
				for renderer in multi_note_line_renderers:
					renderer.positions = points
					renderer.width_scale = scale_x
					renderer.show()

func update_graphic_positions_and_scale(time: float):
	if note_master:
		update_multi_note_renderers()

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

# Used for notes that specially handle multiple inputs (like doubles), only called
# once per input event
func handle_input(event: InputEvent, time: float):
	pass

func judge_note_input(event: InputEvent, time: float) -> JudgeInputResult:
	# Judging tapped keys
	var result = JudgeInputResult.new()
	for action in note_data.get_input_actions():
		var event_result = event.is_action(action) and not event.is_echo()
		if event_result:
			var closest_notes = game.get_closest_notes_of_type(note_data.note_type)
			if note_data in closest_notes:
				var judgement = game.judge.judge_note(time, note_data.time/1000.0)
				if judgement:
					result.resulting_rating = judgement
					result.has_rating = true
			break
	return result

func _on_game_time_changed(time: float):
	if note_master:
		for note in connected_notes:
			var drawer = game.get_note_drawer(note)
			if drawer:
				if not drawer.note_master:
					if not drawer.is_queued_for_deletion():
						drawer._on_game_time_changed(time)

func get_note_graphic():
	pass

func _on_unhandled_action_released(event, event_uid):
	pass

func reset_note_state():
	pass
