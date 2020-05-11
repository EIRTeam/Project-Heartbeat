extends "res://rythm_game/NoteDrawer.gd"

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
var pickable = true setget set_pickable
export(float) var target_scale_modifier = 1.0
const TRAIL_RESOLUTION = 19

var connected_note_judgements = {}

var gradient = Gradient.new()
var grad_texture = GradientTexture.new()
var leading_grad_texture = GradientTexture.new()

func set_connected_notes(val):
	.set_connected_notes(val)
	if connected_notes.size() > 1:
		_on_note_type_changed()
		$Line2D.hide()
		$Line2D2.hide()
		$LineLeading.hide()
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
	_on_game_size_changed()
	
var cached_amplitude
var cached_starting_pos
func _on_game_size_changed():
	cached_amplitude = game.remap_coords(Vector2(1, 1)).x * note_data.oscillation_amplitude
	cached_starting_pos = game.remap_coords(get_initial_position())
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	if game.time * 1000.0 < note_data.time:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	generate_trail_points()
func update_graphic_positions_and_scale(time: float):
	target_graphic.position = game.remap_coords(note_data.position)
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
	# Movement along wave
	var oscillation_amplitude = cached_amplitude
	var starting_pos = cached_starting_pos

	note_graphic.position = game.remap_coords(HBUtils.calculate_note_sine(time_out_distance/get_time_out(), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance))
#	note_graphic.position = HBUtils.sin_pos_interp(starting_pos, target_graphic.position, oscillation_amplitude, note_data.oscillation_frequency, time_out_distance/get_time_out())
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		note_graphic.scale = Vector2(new_scale, new_scale)
#	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	target_graphic.arm_position = 1.0 - ((note_data.time - time*1000) / get_time_out())
	draw_trail(time)
	.update_graphic_positions_and_scale(time)
	
enum GRADIENT_OFFSETS {
	COLOR_EMPTY1,
	COLOR_EMPTY2,
	COLOR_EARLY,
	COLOR_LATE
}
	
func set_trail_color():
	gradient = Gradient.new()
	var color_late = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	var color_early = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	color_late.a = 0.0
	color_early.a = 0.5
	
	var color_empty = color_early
	color_empty.a = 0.0
	
	gradient.set_color(GRADIENT_OFFSETS.COLOR_EMPTY1, color_empty)
	gradient.set_color(GRADIENT_OFFSETS.COLOR_EMPTY2, color_early)
	gradient.add_point(1.0, color_early)
	gradient.add_point(1.0, color_late.contrasted())

	# I am not sure why but this fuckign piece of shit breaks in the editor if we don't
	# set all values to 1.0, what the fuck
	gradient.set_offset(GRADIENT_OFFSETS.COLOR_EMPTY1, 0.0)
	gradient.set_offset(GRADIENT_OFFSETS.COLOR_EMPTY2, 1.0)
	gradient.set_offset(GRADIENT_OFFSETS.COLOR_EARLY, 1.0)
	gradient.set_offset(GRADIENT_OFFSETS.COLOR_LATE, 1.0)

	$Line2D.texture = grad_texture
	$Line2D2.texture = grad_texture
	grad_texture.gradient = gradient
	grad_texture.width = 1024

	# Lead line gradient
	if UserSettings.user_settings.leading_trail_enabled:
		var gradient_lead = Gradient.new()
	
		var color_lead = IconPackLoader.get_color(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
		color_lead.a = 0.2
		gradient_lead.set_color(0, color_lead.lightened(0.25))
		gradient_lead.set_color(1, color_lead.lightened(0.5))
		gradient_lead.add_point(2, color_empty)
		gradient_lead.add_point(3, color_empty)
		
		gradient_lead.set_offset(0, 0.0)
		gradient_lead.set_offset(1, 1.0)
		gradient_lead.set_offset(2, 1.0)
		gradient_lead.set_offset(3, 1.0)
		
	
		leading_grad_texture.gradient = gradient_lead
	
		var leading_trail_disabled_types = [
			HBNoteData.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE,
			HBNoteData.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE
		]
		if note_data.note_type in leading_trail_disabled_types:
			$LineLeading.hide()
		else:
			$LineLeading.show()
			$LineLeading.texture = leading_grad_texture
			leading_grad_texture.width = 512

#	else:
#	for point in range(TRAIL_RESOLUTION):
#		var hue = point/float(TRAIL_RESOLUTION-1)
#		var col = Color.from_hsv(hue, 0.75, 1.0, hue * 0.75)
#		gradient.add_point(1.0-hue, col)
func generate_trail_points():
	var points = PoolVector2Array()
	var points2 = PoolVector2Array()
	
	points.resize(TRAIL_RESOLUTION)
	points2.resize(TRAIL_RESOLUTION)
	
	#var trail_margin = IconPackLoader.get_trail_margin(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type)) * (note_data.distance/1200.0)
	var time_out = get_time_out()
	for i in range(TRAIL_RESOLUTION):
		var t_trail_time = time_out * (i / float(TRAIL_RESOLUTION-1))
		var t = t_trail_time / time_out

		var point1_internal = HBUtils.calculate_note_sine(t, note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance)
		var point1 = game.remap_coords(point1_internal)
		var point2 = game.remap_coords(HBUtils.calculate_note_sine(t, note_data.position, note_data.entry_angle , note_data.oscillation_frequency, note_data.oscillation_amplitude * 0.7, note_data.distance))
		
		points.set(TRAIL_RESOLUTION - i - 1, point1)
		points2.set(TRAIL_RESOLUTION - i - 1, point2)
		
	$Line2D2.width = 6 * game.get_note_scale()
	$Line2D.width = 6 * game.get_note_scale()
	$LineLeading.width = 6 * game.get_note_scale()
	$Line2D.points = points
	$Line2D2.points = points2
	$LineLeading.points = points
func draw_trail(time: float):
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
	# Trail will be time_out / 2 behind
	var time_out = get_time_out()
	var points = PoolVector2Array()
	var points2 = PoolVector2Array()
	# How much margin we leave for the trail from the note center, this prevents
	# the trail from leaking into notes with holes in the middl
	var trail_margin = IconPackLoader.get_trail_margin(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type)) * (note_data.distance/1200.0)
	var oscillation_amplitude = game.remap_coords(Vector2.ONE).x * note_data.oscillation_amplitude
	
	var t = clamp((time_out_distance / time_out) - trail_margin, 0.0, 1.0)
	t = 1.0 - t
	var grad = grad_texture.gradient
	
	grad.set_offset(GRADIENT_OFFSETS.COLOR_EMPTY1, t)
	grad.set_offset(GRADIENT_OFFSETS.COLOR_EMPTY2, t)
	grad.set_offset(GRADIENT_OFFSETS.COLOR_EARLY, t)

	if UserSettings.user_settings.leading_trail_enabled:
		var leading_grad = leading_grad_texture.gradient
		var leading_t = clamp(t-trail_margin-trail_margin, 0.0, 1.0)
		leading_grad.set_offset(0, leading_t)
		leading_grad.set_offset(1, leading_t)
		leading_grad.set_offset(2, leading_t)
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
