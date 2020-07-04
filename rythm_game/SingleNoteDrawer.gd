extends "res://rythm_game/note_drawers/NoteDrawer.gd"

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
onready var shadow
var disable_trail_margin = false
export(float) var target_scale_modifier = 1.0

var connected_note_judgements = {}

var gradient = Gradient.new()
var grad_texture = GradientTexture.new()
var leading_grad_texture = GradientTexture.new()

var sine_drawer = SineDrawerCPU.new()
var blue = false
var slide_chain_master = false
func set_connected_notes(val):
	.set_connected_notes(val)
	if connected_notes.size() > 1:
		_on_note_type_changed()
		sine_drawer.hide()
	else:
		sine_drawer.show()

func make_blue():
	blue = true
	target_graphic.set_note_type(note_data, connected_notes.size() > 0, true)

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
	target_graphic.position = game.remap_coords(note_data.position)
	
func update_arm_position(time: float):
	target_graphic.arm_position = 1.0 - ((note_data.time - time*1000) / get_time_out())
	
func update_graphic_positions_and_scale(time: float):
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
	# Movement along wave
	var oscillation_amplitude = cached_amplitude
	var starting_pos = cached_starting_pos

	note_graphic.position = game.remap_coords(HBUtils.calculate_note_sine(time_out_distance/get_time_out(), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance))
	
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		new_scale = max(new_scale, 0.0)
		note_graphic.scale = Vector2(new_scale, new_scale)
#	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	update_arm_position(time)
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

	var t = clamp((time_out_distance / time_out), 0.0, 1.25)
	var trail_margin = IconPackLoader.get_trail_margin(HBUtils.find_key(HBNoteData.NOTE_TYPE, note_data.note_type))
	if disable_trail_margin:
		trail_margin = 0.0
	sine_drawer.time = t-trail_margin
	sine_drawer.trail_margin = trail_margin
func _on_note_type_changed():
	$Note.set_note_type(note_data.note_type, connected_notes.size() > 0)
	target_graphic.set_note_type(note_data, connected_notes.size() > 0)

func _on_note_judged(judgement, prevent_freeing = false):
	if note_data is HBNoteData and note_data.is_slide_note():
		if judgement >= game.judge.JUDGE_RATINGS.FINE:
			
			var particles = preload("res://graphics/effects/SlideParticles.tscn").instance()
			
			if note_data.note_type == HBNoteData.NOTE_TYPE.SLIDE_LEFT:
				particles.scale = Vector2(-1.0, 1.0)
			game.game_ui.get_notes_node().add_child(particles)
			particles.position = game.remap_coords(note_data.position)
	else:
		if judgement >= game.judge.JUDGE_RATINGS.FINE:
			show_note_hit_effect()
	if not prevent_freeing:
		queue_free()
		emit_signal("note_removed")
		
		if game.is_connected("time_changed", self, "_on_game_time_changed"):
			game.disconnect("time_changed", self, "_on_game_time_changed")
		set_process_unhandled_input(false)

func _unhandled_input(event):
	# HACK: Because godot is dumb, it seems to treat built in node methods differently
	# and calls them on parent classes too
	_handle_unhandled_input(event)
	
func judge_note_input(event: InputEvent, time: float) -> JudgeInputResult:
	var result = .judge_note_input(event, time)
	if note_data is HBNoteData and note_data.is_slide_note():
		if result.has_rating and slide_chain_master:
			result.resulting_rating = HBJudge.JUDGE_RATINGS.COOL
		if result.has_rating and result.resulting_rating < HBJudge.JUDGE_RATINGS.FINE:
			result.resulting_rating = HBJudge.JUDGE_RATINGS.FINE
	return result
	
func _handle_unhandled_input(event):
	# Master notes handle all the input
	if not event is InputEventAction:
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
			if note.note_type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
				for action in note.get_input_actions():
					allowed_actions.append(action)
		for note in conn_notes:
			if event.is_pressed():
				if note in game.get_closest_notes():
					# Non-wrong note checks
					game.get_note_drawer(note).handle_input(event, game.time)
					var input_judgement = game.get_note_drawer(note).judge_note_input(event, game.time) as JudgeInputResult
					if not input_judgement.has_rating:
						# Check for wrongs
						var found_input = false
						var found_input_action = ""
						for action in allowed_actions:
							if event.is_action_pressed(action):
								found_input = true
								break
								
						var heart_bypass_hack = false
							
						print("ACT: ", found_input_action)
							
						# HACK: We ignore slide up and down to prevent the user
						# from getting a wrong on slides accidentally, unless they have a heart note
						if not note.note_type == HBBaseNote.NOTE_TYPE.HEART:
							if (event.is_action_pressed("tap_down") or event.is_action_pressed("tap_up")):
								heart_bypass_hack = true
								
						# If the action was not amongs the allowed action of the connected
						# notes and our note is amongst the closest notes it means we got
						# a wrong
						if not found_input and not heart_bypass_hack:
							# janky way of emulating the correct input and figuring out
							# what the rating would be, if we would get a rating it means
							# we got a wrong note
							
							
							var a = InputEventAction.new()
							a.action = note.get_input_actions()[0]
							a.pressed = true
							var wrong_input_judgement = game.get_note_drawer(note).judge_note_input(a, game.time)
							if wrong_input_judgement.has_rating:
								wrong_rating = wrong_input_judgement.resulting_rating
								wrong = true
								get_tree().set_input_as_handled()
								break
					
					else:
						if not note in connected_note_judgements:
							connected_note_judgements[note] = input_judgement.resulting_rating
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

			
			# Make multinotes count
			if not wrong:
				game.add_score(HBNoteData.NOTE_SCORES[result_judgement])
			emit_signal("notes_judged", conn_notes, result_judgement, wrong)
			for note in conn_notes:
				var drawer = game.get_note_drawer(note)
				
				# Some notes shouldn't be automatically killed
				if wrong:
					drawer._on_note_judged(HBJudge.JUDGE_RATINGS.WORST)
				elif drawer.note_data.is_auto_freed():
					drawer._on_note_judged(result_judgement)
				else:
					# The note is now on it's own
					if not game.is_connected("time_changed", drawer, "_on_game_time_changed"):
						game.connect("time_changed", drawer, "_on_game_time_changed")
					drawer._on_note_judged(result_judgement, true)
#		if not event is InputEventJoypadMotion:
#			var actions = []
#			var input_judgement = judge_note_input(event, game.time)
#			if input_judgement != -1:
#				_on_note_judged(input_judgement)

func _on_game_time_changed(time: float):
	if not is_queued_for_deletion():
		._on_game_time_changed(time)
		var conn_notes = connected_notes
		if conn_notes.size() == 0:
			conn_notes = [note_data]
		var time_out = get_time_out()
		if note_data.can_be_judged():
			if note_data is HBNoteData and note_data.is_slide_note() and slide_chain_master and note_master:
				for action in note_data.get_input_actions():
					if (game.game_input_manager.is_action_held(action)) and game.game_input_manager.get_action_press_count(action) >= conn_notes.size():
						if time >= note_data.time / 1000.0:
							emit_signal("notes_judged", conn_notes, game.judge.JUDGE_RATINGS.COOL, false)
							for note in conn_notes:
								var drawer = game.get_note_drawer(note)
								if drawer.note_data.is_auto_freed():
									drawer._on_note_judged(game.judge.JUDGE_RATINGS.COOL)
									game.add_score(HBNoteData.NOTE_SCORES[game.judge.JUDGE_RATINGS.COOL])
								else:
									# The note is now on it's own
									if not game.is_connected("time_changed", drawer, "_on_game_time_changed"):
										game.connect("time_changed", drawer, "_on_game_time_changed")
									drawer._on_note_judged(game.judge.JUDGE_RATINGS.COOL, true)
									game.add_score(HBNoteData.NOTE_SCORES[game.judge.JUDGE_RATINGS.COOL])
							break
			if time >= (note_data.time + game.judge.get_target_window_msec()) / 1000.0:
				emit_signal("notes_judged", conn_notes, game.judge.JUDGE_RATINGS.WORST, false)
				emit_signal("note_removed")
				queue_free()
		update_graphic_positions_and_scale(time)
				
func get_note_graphic():
	return note_graphic

