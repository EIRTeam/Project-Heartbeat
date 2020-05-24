extends "res://rythm_game/note_drawers/NoteDrawer.gd"

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
var pickable = true setget set_pickable
export(float) var target_scale_modifier = 1.0
const TRAIL_RESOLUTION = 19

var connected_note_judgements = {}

var gradient = Gradient.new()
var grad_texture = GradientTexture.new()
var leading_grad_texture = GradientTexture.new()

var sine_drawer = SineDrawerCPU.new()

func set_connected_notes(val):
	.set_connected_notes(val)
	if connected_notes.size() > 1:
		_on_note_type_changed()
		sine_drawer.hide()
	else:
		sine_drawer.show()

func set_pickable(value):
	pickable = value
	$NoteTarget.input_pickable = value

func _ready():
	_on_note_type_changed()
	$AnimationPlayer.play("note_appear")
	$NoteTarget/Particles2D.emitting = true
	sine_drawer.note_data = note_data
	sine_drawer.time_out = get_time_out()
	sine_drawer.game = game
	add_child(sine_drawer)
	move_child(sine_drawer, 0)
	_on_game_size_changed()
var cached_amplitude
var cached_starting_pos
func _on_game_size_changed():
	cached_amplitude = game.remap_coords(Vector2(1, 1)).x * note_data.oscillation_amplitude
	cached_starting_pos = game.remap_coords(get_initial_position())
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	if game.time * 1000.0 < note_data.time:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	sine_drawer._on_resized()
func update_graphic_positions_and_scale(time: float):
	target_graphic.position = game.remap_coords(note_data.position)
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
	# Movement along wave
	var oscillation_amplitude = cached_amplitude
	var starting_pos = cached_starting_pos

	note_graphic.position = game.remap_coords(HBUtils.calculate_note_sine(time_out_distance/get_time_out(), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance))
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
func generate_trail_points():
	sine_drawer.generate_trail_points()
func draw_trail(time: float):
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
	# Trail will be time_out / 2 behind
	var time_out = get_time_out()
	var points = PoolVector2Array()
	var points2 = PoolVector2Array()
	# How much margin we leave for the trail from the note center, this prevents
	# the trail from leaking into notes with holes in the middle
	
	var oscillation_amplitude = game.remap_coords(Vector2.ONE).x * note_data.oscillation_amplitude

	var t = clamp((time_out_distance / time_out), 0.0, 1.25)
	var trail_margin = IconPackLoader.get_trail_margin(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type)) * (note_data.distance/1200.0)
	sine_drawer.time = t-trail_margin
	sine_drawer.trail_margin = trail_margin
func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type, connected_notes.size() > 0)
	target_graphic.set_note_type(note_data.note_type, connected_notes.size() > 0, note_data.hold)

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

