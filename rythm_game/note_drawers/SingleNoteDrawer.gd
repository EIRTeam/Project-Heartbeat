extends "res://rythm_game/note_drawers/NoteDrawer.gd"

onready var target_graphic = get_node("NoteTarget")
onready var note_graphic = get_node("Note")
onready var shadow
var disable_trail_margin = false
export(float) var target_scale_modifier = 1.0

var connected_note_judgements = {}
var connected_note_events = {}
var gradient = Gradient.new()
var grad_texture = GradientTexture.new()
var leading_grad_texture = GradientTexture.new()

var sine_drawer = SineDrawerCPU.new()
var blue = false
var slide_chain_master = false
var note_scale = 1.0

var appear_particles_node = preload("res://menus/AppearParticles.tscn").instance()

const NOTE_HIT_SFX = "note_hit"
const HEART_HIT_SFX = "heart_hit"

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

func undo_blue():
	blue = false
	target_graphic.set_note_type(note_data, connected_notes.size() > 0, false)
func play_appear_animation():
	$AnimationPlayer.play("note_appear")
	appear_particles_node.show()
	appear_particles_node.get_node("AnimationPlayer").play("appear")
	#$AppearParticles.hide()


func _note_init():
	bind_node_to_layer(appear_particles_node, "AppearParticles", NodePath("NoteTarget"))
	bind_node_to_layer(sine_drawer, "Trails")

func _notification(what):
	if what == NOTIFICATION_POST_ENTER_TREE:
		sine_drawer.note_data = note_data
		sine_drawer.time_out = get_time_out()
		sine_drawer.game = game
		
		for data in layer_bound_node_datas:
			add_bind_to_tree(data)
	elif what == NOTIFICATION_EXIT_TREE:
		for data in layer_bound_node_datas:
			var ui_node = game.game_ui.get_drawing_layer_node(data.layer_name)
			ui_node.remove_child(data.node)
	elif what == NOTIFICATION_PREDELETE:
		for data in layer_bound_node_datas:
			if is_instance_valid(data.node) and not data.node.is_queued_for_deletion():
				data.node.queue_free()
			if is_instance_valid(data.remote_transform) and not data.remote_transform.is_queued_for_deletion():
				data.remote_transform.queue_free()
		for node in [appear_particles_node, sine_drawer]:
			if is_instance_valid(node) and not node.is_queued_for_deletion():
				node.queue_free()

func _on_visibility_changed():
	for data in layer_bound_node_datas:
		data.node.set_block_signals(true)
		if not visible:
			data.node.visible = false
		else:
			data.node.visible = data.node_self_visibility
		data.node.set_block_signals(false)

func _ready():
	connect("visibility_changed", self, "_on_visibility_changed")
	_on_note_type_changed()
	play_appear_animation()
	#move_child(sine_drawer, 0)
	_on_game_size_changed()
	for data in layer_bound_node_datas:
		if data.remote_transform:
			var target_node = get_node(data.source_transform)
			data.remote_transform.use_global_coordinates = true
			target_node.add_child(data.remote_transform)
#	target_remote_transform.use_global_coordinates = true
#	$NoteTarget.add_child(target_remote_transform)
	appear_particles_node.get_node("AnimationPlayer").connect("animation_finished", self, "_on_appear_particles_node_animation_finished")
	
func _on_appear_particles_node_animation_finished(_animation_name: String):
	appear_particles_node.hide()
	
var cached_amplitude
var cached_starting_pos
func _on_game_size_changed():
	cached_amplitude = game.remap_coords(Vector2(1, 1)).x * note_data.oscillation_amplitude
	cached_starting_pos = game.remap_coords(get_initial_position())
	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * note_scale
	if game.time * 1000.0 < note_data.time:
		note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * note_scale
	sine_drawer._on_resized()
	target_graphic.position = game.remap_coords(note_data.position)
	if game.editing:
		sine_drawer.setup()

func update_arm_position(time: float):
	target_graphic.arm_position = 1.0 - ((note_data.time - time*1000) / get_time_out())
	
var last_graphic_update_time = 0

func update_graphic_positions_and_scale(time: float):
	if last_graphic_update_time > time:
		_on_game_size_changed()
	var time_out_distance = get_time_out() - (note_data.time - time*1000.0)

	note_graphic.position = game.remap_coords(HBUtils.calculate_note_sine(time_out_distance/get_time_out(), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance))
	
	if time * 1000.0 > note_data.time:
		var disappereance_time = note_data.time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time * 1000.0) / (game.judge.get_target_window_msec()) * game.get_note_scale()
		new_scale = max(new_scale, 0.0)
		note_graphic.scale = Vector2(new_scale, new_scale) * note_scale
#	target_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale()) * target_scale_modifier
	update_arm_position(time)
	draw_trail(time)
	.update_graphic_positions_and_scale(time)
	last_graphic_update_time = time
	
enum GRADIENT_OFFSETS {
	COLOR_EMPTY1,
	COLOR_EMPTY2,
	COLOR_EARLY,
	COLOR_LATE
}
func generate_trail_points():
	sine_drawer.generate_trail_points()
func draw_trail(time: float):
	if sine_drawer.is_inside_tree():
		var time_out_distance = get_time_out() - (note_data.time - time*1000.0)
		# Trail will be time_out / 2 behind
		var time_out = get_time_out()
		# How much margin we leave for the trail from the note center, this prevents
		# the trail from leaking into notes with holes in the middle

		var t = clamp((time_out_distance / time_out), 0.0, 1.25)
		var trail_margin = ResourcePackLoader.get_note_trail_margin(note_data.note_type)
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
			particles.scale *= game.get_note_scale()
			game.game_ui.get_drawing_layer_node("StarParticles").add_child(particles)
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

func handles_hit_sfx_playback():
	return (note_data.time - (game.time * 1000.0)) <= game.judge.get_target_window_msec() and \
			note_data.note_type == HBBaseNote.NOTE_TYPE.HEART

func get_hit_sfx():
	return HEART_HIT_SFX

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
		
		# HACK: Slides ignore ordinary notes, and vice-versa, unless it's a multi!
		if conn_notes.size() <= 1:
			if (note_data is HBNoteData and note_data.is_slide_note()) or note_data.note_type == HBBaseNote.NOTE_TYPE.HEART:
				if not event.is_action("slide_left") and not event.is_action("slide_right") \
						and not event.is_action("heart_note"):
					return
			else:
				if event.is_action("slide_left") or event.is_action("slide_right") \
						or event.is_action("heart_note"):
					return
		
		# get a list of actions that can happen amongst these connected notes, this
		# is used for wrong note detection
		var allowed_actions = []
		var have_slider = false
		var have_heart = false
		var input_manager = game.game_input_manager as HeartbeatInputManager
		var triggered_actions_count = input_manager.current_actions.size()
		# Hearts sliders and normal notes ignore eachother
		for note in conn_notes:
			if note.note_type in HBGame.NOTE_TYPE_TO_ACTIONS_MAP:
				for action in note.get_input_actions():
					allowed_actions.append(action)
			if note is HBNoteData and note.is_slide_note():
				have_slider = true
			if note.note_type == HBNoteData.NOTE_TYPE.HEART:
				have_heart = true
				
		if not have_slider:
			if "slide_left" in input_manager.current_actions:
				triggered_actions_count -= 1
			if "slide_right" in input_manager.current_actions:
				triggered_actions_count -= 1
		if not have_heart:
			if "heart_note" in input_manager.current_actions:
				triggered_actions_count -= 1
		if event is InputEventHB and event.is_pressed():
			if event.action == "heart" and not have_heart \
					or (not have_slider and event.action in ["slide_left", "slide_right"]):
				return
		for note in conn_notes:
			if event.is_pressed():
				if note in game.get_closest_notes():
					# Non-wrong note checks
					game.get_note_drawer(note).handle_input(event, game.time)
					var input_judgement = game.get_note_drawer(note).judge_note_input(event, game.time) as JudgeInputResult
					# This ensures macro can't be bound to many buttons and still be used to hit multi notes
					var event_had_too_many_actions = false
					if triggered_actions_count > conn_notes.size():
						event_had_too_many_actions = true
					if (note is HBNoteData and note.is_slide_note()) or \
						note.note_type == HBBaseNote.NOTE_TYPE.HEART:
							event_had_too_many_actions = false
					if not input_judgement.has_rating or event_had_too_many_actions:
						# Check for wrongs
						var found_input = false
						for action in allowed_actions:
							if event.is_action_pressed(action):
								found_input = true
								break
								
						var heart_bypass_hack = false
							
						# HACK: We ignore slide up and down to prevent the user
						# from getting a wrong on slides when using the heart action
						if not note.note_type == HBBaseNote.NOTE_TYPE.HEART:
							if (event.is_action_pressed("heart_note")):
								heart_bypass_hack = true
								
						# Same but the other way around for hearts
						if note.note_type == HBBaseNote.NOTE_TYPE.HEART:
							event_had_too_many_actions = false
							if (event.is_action_pressed("slide_left") or event.is_action_pressed("slide_right")):
								heart_bypass_hack = true
								
						# If the action was not amongs the allowed action of the connected
						# notes and our note is amongst the closest notes it means we got
						# a wrong
						if (not found_input and not heart_bypass_hack) or event_had_too_many_actions:
							# janky way of emulating the correct input and figuring out
							# what the rating would be, if we would get a rating it means
							# we got a wrong note
							
							var a = InputEventHB.new()
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
							connected_note_events[note] = event
							get_tree().set_input_as_handled()
							break
						elif not note.is_slide_note():
							continue
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
			emit_signal("notes_judged", conn_notes, result_judgement, wrong, connected_note_events)
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
					if "slide_chain" in drawer and result_judgement >= HBJudge.JUDGE_RATINGS.FINE:
						drawer.hit_first = true
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
		if note_data.can_be_judged() and note_master:
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
				for note in conn_notes:
					var drawer = game.get_note_drawer(note)
					if drawer:
						if not drawer.is_queued_for_deletion():
							drawer.emit_signal("note_removed")
							drawer.queue_free()
		update_graphic_positions_and_scale(time)
				
func get_note_graphic():
	return note_graphic

