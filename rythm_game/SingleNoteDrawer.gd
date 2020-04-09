extends "res://rythm_game/NoteDrawer.gd"

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
var pickable = true setget set_pickable
export(float) var target_scale_modifier = 1.0
const TRAIL_RESOLUTION = 19

var connected_note_judgements = {}
var trail_bounding_box : Rect2

func set_connected_notes(val):
	.set_connected_notes(val)
	if connected_notes.size() > 1:
		_on_note_type_changed()
		$Line2D.hide()
		$Line2D2.hide()
	else:
		$Line2D.show()
		$Line2D2.show()
		

func set_pickable(value):
	pickable = value
	$NoteTarget.input_pickable = value

func _ready():
	_on_note_type_changed()
	$AnimationPlayer.play("note_appear")
	$NoteTarget/Particles2D.emitting = true
	var trail_bounding_box_offset = game.BASE_SIZE / TRAIL_RESOLUTION
	var trail_bounding_box_size = game.BASE_SIZE + trail_bounding_box_offset * 4
	trail_bounding_box = Rect2(-trail_bounding_box_offset * 2, trail_bounding_box_size)
	

	
func update_graphic_positions_and_scale(time: float):
	target_graphic.position = game.remap_coords(note_data.position)

	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
	# Movement along wave
	var oscillation_amplitude = game.remap_coords(Vector2(1, 1)).x * note_data.oscillation_amplitude
	var starting_pos = game.remap_coords(get_initial_position())

	note_graphic.position = game.remap_coords(HBUtils.calculate_note_sine(time_out_distance/get_time_out(), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance))
#	note_graphic.position = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, time_out_distance/get_time_out())
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		note_graphic.scale = Vector2(new_scale, new_scale)
	else:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	target_graphic.arm_position = 1.0 - ((note_data.time - time*1000) / get_time_out())
	draw_trail(time)
	.update_graphic_positions_and_scale(time)
	
func set_trail_color():
	var gradient = Gradient.new()
	var color1 = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	var color2 = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	color1.a = 0.0
	color2.a = 0.5
	gradient.set_offset(0, 0)
	gradient.set_color(0, color2)
	gradient.set_color(1, color1.contrasted())

#	else:
#	for point in range(TRAIL_RESOLUTION):
#		var hue = point/float(TRAIL_RESOLUTION-1)
#		var col = Color.from_hsv(hue, 0.75, 1.0, hue * 0.75)
#		gradient.add_point(1.0-hue, col)
	$Line2D.gradient = gradient
	$Line2D2.gradient = gradient

func draw_trail(time: float):
	
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
	# Trail will be time_out / 2 behind
	var trail_time = get_time_out()
	var points = PoolVector2Array()
	var points2 = PoolVector2Array()
	# How much margin we leave for the trail from the note center, this prevents
	# the trail from leaking into notes with holes in the middl
	var trail_margin = IconPackLoader.get_trail_margin(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	var oscillation_amplitude = game.remap_coords(Vector2.ONE).x * note_data.oscillation_amplitude
	for i in range(TRAIL_RESOLUTION, -1, -1):
		var t_trail_time = trail_time * (i / float(TRAIL_RESOLUTION))
		var t = ((time_out_distance - trail_time) + t_trail_time) / trail_time

		t = t-trail_margin
		var point1_internal = HBUtils.calculate_note_sine(t, note_data.position, note_data.entry_angle - deg2rad(15), note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance)
		var point1 = game.remap_coords(point1_internal)
		var point2 = game.remap_coords(HBUtils.calculate_note_sine(t, note_data.position, note_data.entry_angle + deg2rad(15), note_data.oscillation_frequency, note_data.oscillation_amplitude * 0.8, note_data.distance))
		points2.append(point2)
		points.append(point1)
		if not trail_bounding_box.has_point(point1_internal):
			break

	$Line2D2.width = 6 * game.get_note_scale()
	$Line2D.width = 6 * game.get_note_scale()
	$Line2D.points = points
	$Line2D2.points = points2
func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type, connected_notes.size() > 0)
	target_graphic.set_note_type(note_data.note_type, connected_notes.size() > 0, note_data.hold)
	set_trail_color()
		

func _on_note_judged(judgement):
	
	if note_data.is_slide_note():
		if judgement >= game.judge.JUDGE_RATINGS.FINE:
			
			var particles = preload("res://graphics/effects/SlideParticles.tscn").instance()
			
			if note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
				particles.scale = Vector2(-1.0, 1.0)
			game.add_child(particles)
			particles.position = game.remap_coords(note_data.position)
	else:
		if judgement >= game.judge.JUDGE_RATINGS.FINE:
			show_note_hit_effect()
	queue_free()
	get_tree().set_input_as_handled()
	set_process_unhandled_input(false)

func _unhandled_input(event):
	print(is_processing_unhandled_input())
	# Master notes handle all the input
	if not event is InputEventAction and not event.is_action_pressed("tap_left") and not event.is_action_pressed("tap_right"):
		return
	if note_data.note_type in HBNoteData.NO_INPUT_LIST:
		return
	if not is_queued_for_deletion():
		var conn_notes = connected_notes
		if conn_notes.size() == 0:
			conn_notes = [note_data]
			
		var wrong = false
		var wrong_rating
		# get a list of actions that can happen amongst these connected notes, this
		# is used for wrong note detection
		var allowed_actions = []
		for note in conn_notes:
			if note.note_type in game.NOTE_TYPE_TO_ACTIONS_MAP:
				for action in game.NOTE_TYPE_TO_ACTIONS_MAP[note.note_type]:
					allowed_actions.append(action)
		for note in conn_notes:
			if event.is_pressed():
				if note in game.get_closest_notes():
					# Check for wrongs
					var found_input = false
					for action in allowed_actions:
						if event.is_action_pressed(action):
							found_input = true
							break
					# If the action was not amongs the allowed action of the connected
					# notes and our note is amongst the closest notes it means we got
					# a wrong
					if not found_input:
						# janky way of emulating the correct input and figuring out
						# what the rating would be, if we would get a rating it means
						# we got a wrong note
						var a = InputEventAction.new()
						a.action = game.NOTE_TYPE_TO_ACTIONS_MAP[note.note_type][0]
						a.pressed = true
						
						var input_judgement = game.get_note_drawer(note).judge_note_input(a, game.time)
						if input_judgement != -1:
							wrong_rating = input_judgement
							wrong = true
							get_tree().set_input_as_handled()
							break
					# Non-wrong note checks
					var input_judgement = game.get_note_drawer(note).judge_note_input(event, game.time)
					
					if input_judgement != -1:
						if not note in connected_note_judgements:
							connected_note_judgements[note] = input_judgement
							get_tree().set_input_as_handled()
							break
		# Note priority is the following:
		# If any of the notes hit returns worse, sad, or safe, that's the final rating
		# else, the final rating will be the rating that's been obtained the most
		# (so if you obtain 3 cools and 1 fine, it will result in a cool)
		if connected_note_judgements.size() == conn_notes.size() or wrong:
			var result_judgement = null
			var cools = 0
			var fines = 0
			
			for note in connected_note_judgements:
				var note_judgement = connected_note_judgements[note]
				if note_judgement < HBJudge.JUDGE_RATINGS.FINE:
					result_judgement = note_judgement
					break
				elif note_judgement == HBJudge.JUDGE_RATINGS.COOL:
					cools += 1
				elif result_judgement == HBJudge.JUDGE_RATINGS.FINE:
					fines += 1
			
			if not result_judgement:
				if cools > fines:
					result_judgement = HBJudge.JUDGE_RATINGS.COOL
				else:
					result_judgement = HBJudge.JUDGE_RATINGS.FINE
					
			if wrong:
				result_judgement = wrong_rating
					
			game.disconnect("time_changed", self, "_on_game_time_changed")

			
			# Make multinotes count
			if not wrong:
				game.add_score(HBNoteData.NOTE_SCORES[result_judgement])
			emit_signal("notes_judged", conn_notes, result_judgement, wrong)
			for note in conn_notes:
				var drawer = game.get_note_drawer(note)
				drawer._on_note_judged(result_judgement)
				drawer.emit_signal("note_removed")
#		if not event is InputEventJoypadMotion:
#			var actions = []
#			var input_judgement = judge_note_input(event, game.time)
#			if input_judgement != -1:
#				_on_note_judged(input_judgement)

func _on_game_time_changed(time: float):
	if not is_queued_for_deletion():
		._on_game_time_changed(time)
		update_graphic_positions_and_scale(time)
		var conn_notes = connected_notes
		if conn_notes.size() == 0:
			conn_notes = [note_data]
		if note_data.can_be_judged():
			if time >= (note_data.time + game.judge.get_target_window_msec()) / 1000.0 or time * 1000.0 < (note_data.time - get_time_out()):
				emit_signal("notes_judged", conn_notes, game.judge.JUDGE_RATINGS.WORST, false)
				emit_signal("note_removed")
				queue_free()
				
func get_note_graphic():
	return note_graphic
	
	
#func _draw():
#	draw_line(game.remap_coords(get_initial_position()), game.remap_coords(note_data.position), Color.blue, 2.0, true)

func get_notes():
	return [note_data]
	
func _on_heart_power_activated():
	set_trail_color()
	
func _on_heart_power_end():
	set_trail_color()
