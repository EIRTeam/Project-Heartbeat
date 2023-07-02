extends Node2D

class_name HBNewNoteDrawer

var note_data: HBBaseNote: set = set_note_data
var appear_animation_enabled := true
var disable_autoplay := false # disables autoplay for some notes, used for slide chain pieces mainly

var scheduled_autoplay_sound: ShinobuSoundPlayer
var scheduled_autoplay_sound_time: int
# in MS, margin used to schedule sounds
const SCHEDULE_MARGIN := 100

func set_note_data(val):
	note_data = val
	note_data.connect("parameter_changed", Callable(self, "_on_note_parameter_changed_received"))

var parameters_changed_this_frame := []

func _on_note_parameter_changed_received(parameter_name: String):
	if parameters_changed_this_frame.is_empty():
		call_deferred("_on_note_parameter_changed")
	parameters_changed_this_frame.append(parameter_name)

func _on_note_parameter_changed():
	var regenerate_trail := false
	for parameter_name in parameters_changed_this_frame:
		if parameter_name in ["entry_angle", "oscillation_frequency", "oscillation_amplitude", "time_out", "distance", "position"]:
			regenerate_trail = true
		elif parameter_name == "hold":
			note_target_graphics.set_note_type(note_data, is_multi_note)
	if regenerate_trail:
		if sine_drawer:
			sine_drawer.generate_trail_points()
	parameters_changed_this_frame.clear()

var sine_drawer: SineDrawerCPU
var disable_trail_margin := false

@onready var appear_animation_tween := Threen.new()
@onready var note_target_graphics: NoteTarget = get_node("NoteTarget")
@onready var note_graphics: NoteGraphics = get_node("Note")

@onready var current_note_tween: Tween

var layer_bound_node_datas = []

signal add_node_to_layer(layer_name, node)
signal remove_node_from_layer(layer_name, node)
signal judged(judgement, independent, target_time, event)
signal finished

@onready var appear_particles_node = preload("res://menus/AppearParticles.tscn").instantiate()

var game

class LayerBoundNodeData:
	var node: Node2D
	var remote_transform = null
	var source_transform
	var layer_name: String
	var node_self_visibility = false # for storing the old visibility of the node
	
	func _on_node_self_visibility_changed():
		node_self_visibility = node.visible

var enable_trail := false: set = set_enable_trail

func set_enable_trail(val):
	if enable_trail != val:
		enable_trail = val
		if enable_trail and not sine_drawer:
			sine_drawer = SineDrawerCPU.new()
			sine_drawer.game = game
			sine_drawer.note_data = note_data
			bind_node_to_layer(sine_drawer, "Trails")
		elif sine_drawer:
			free_node_bind(sine_drawer)
			sine_drawer.queue_free()

var is_multi_note := false: set = set_is_multi_note

func set_is_multi_note(val):
	if is_inside_tree():
		note_graphics.set_note_type(note_data.note_type, val)
		note_target_graphics.set_note_type(note_data, val)
	is_multi_note = val
	set_enable_trail(!val)

func note_init():
	note_graphics.scale = Vector2.ONE * UserSettings.user_settings.note_size
	note_target_graphics.scale = Vector2.ONE * UserSettings.user_settings.note_size
	bind_node_to_layer(appear_particles_node, "AppearParticles", NodePath("NoteTarget"))
	if appear_animation_enabled:
		play_appear_animation()

func play_appear_animation():
	note_target_graphics.scale = Vector2.ONE
	if current_note_tween:
		current_note_tween.kill()
		current_note_tween = null
	current_note_tween = create_tween()
	current_note_tween.tween_property(note_target_graphics, "scale", Vector2.ONE * UserSettings.user_settings.note_size * 1.1, 0.17)
	current_note_tween.tween_property(note_target_graphics, "scale", Vector2.ONE * UserSettings.user_settings.note_size * 1.0, 0.17)
	appear_particles_node.show()
	appear_particles_node.get_node("AnimationPlayer").play("appear")

func add_bind_to_tree(data):
	emit_signal("add_node_to_layer", data.layer_name, data.node)
	if data.remote_transform:
		data.remote_transform.remote_path = data.node.get_path()
		var trg = get_node(data.source_transform)
		trg.add_child(data.remote_transform)

func remove_bind_from_tree(data: LayerBoundNodeData):
	emit_signal("remove_node_from_layer", data.layer_name, data.node)
	if data.remote_transform:
		var target_node = get_node(data.source_transform)
		target_node.remove_child(data.remote_transform)

func free_node_bind(node: Node):
	var layer_bind := node.get_meta("layer_bind") as LayerBoundNodeData
	free_bind(layer_bind)

func free_bind(data: LayerBoundNodeData):
	if data.remote_transform:
		data.remote_transform.queue_free()
	layer_bound_node_datas.erase(data)

func bind_node_to_layer(node: Node2D, layer_name: String, source_transform = null):
	var data := LayerBoundNodeData.new()
	data.node = node
	data.layer_name = layer_name
	
	if source_transform is NodePath:
		var remote_transform = RemoteTransform2D.new()
		data.remote_transform = remote_transform
		data.source_transform = source_transform
	data.node_self_visibility = node.visible
	node.connect("visibility_changed", Callable(data, "_on_node_self_visibility_changed"))
	node.set_meta("layer_bind", data)
	if is_inside_tree():
		add_bind_to_tree(data)
	
	layer_bound_node_datas.append(data)

func draw_trail(time_msec: int):
	if not sine_drawer:
		return
	if sine_drawer.is_inside_tree():
		var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.time))
		var time_out_distance = time_out - (note_data.time - time_msec)
		# Trail will be time_out / 2 behind
		# How much margin we leave for the trail from the note center, this prevents
		# the trail from leaking into notes with holes in the middle

		var t = clamp((time_out_distance / float(time_out)), 0.0, 1.25)
		var trail_margin = ResourcePackLoader.get_note_trail_margin(note_data.note_type)
		if disable_trail_margin:
			trail_margin = 0.0
		sine_drawer.time = t-trail_margin
		sine_drawer.trail_margin = trail_margin

func is_autoplay_enabled() -> bool:
	# Hardcoded GAME_MODE.AUTOPLAY because godot 3 doesn't support cyclic references
	return game.game_mode == 2 and not disable_autoplay

func update_graphic_positions_and_scale(time_msec: int):
	note_target_graphics.position = note_data.position
	var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.time))
	var time_out_distance = time_out - (note_data.time - time_msec)

	note_graphics.position = HBUtils.calculate_note_sine(time_out_distance/float(time_out), note_data.position, note_data.entry_angle, note_data.oscillation_frequency, note_data.oscillation_amplitude, note_data.distance)
	note_graphics.scale = Vector2.ONE * UserSettings.user_settings.note_size
	if time_msec > note_data.time:
		var disappereance_time = note_data.time + (game.judge.get_target_window_msec())
		var new_scale = (disappereance_time - time_msec) / float(game.judge.get_target_window_msec()) * game.get_note_scale()
		new_scale = max(new_scale, 0.0)
		note_graphics.scale = Vector2(new_scale, new_scale) * UserSettings.user_settings.note_size
	note_target_graphics.arm_position = 1.0 - ((note_data.time - time_msec) / float(time_out))
	draw_trail(time_msec)

func process_note(time_msec: int):
	update_graphic_positions_and_scale(time_msec)
	process_scheduled_autoplay_sound()

func process_scheduled_autoplay_sound():
	if (scheduled_autoplay_sound and not is_autoplay_enabled()) or (scheduled_autoplay_sound and scheduled_autoplay_sound.is_at_stream_end()):
		get_tree().root.remove_child(scheduled_autoplay_sound)
		scheduled_autoplay_sound.queue_free()
		scheduled_autoplay_sound = null

# Returns true if this note will be able to handle this input, false if its a wrong input
func handles_input(event: InputEventHB) -> bool:
	return false

# Returns true if this note will be able to handle this input, false if its a wrong input
func process_input(event: InputEventHB):
	pass

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if not is_inside_tree():
			for data in layer_bound_node_datas:
				if not data.node.is_queued_for_deletion():
					data.node.queue_free()
				if data.remote_transform:
					if not data.remote_transform.is_queued_for_deletion():
						data.remote_transform.queue_free()
	elif what == NOTIFICATION_POST_ENTER_TREE:
		for data in layer_bound_node_datas:
			add_bind_to_tree(data)
	elif what == NOTIFICATION_EXIT_TREE:
		for data in layer_bound_node_datas:
			remove_bind_from_tree(data)
		if scheduled_autoplay_sound:
			# Hand it over to the game
			get_tree().root.remove_child(scheduled_autoplay_sound)
			game.track_sound(scheduled_autoplay_sound)

func show_note_hit_effect(target_pos: Vector2):
	var effect_scene = preload("res://graphics/effects/NoteHitEffect.tscn")
	var effect = effect_scene.instantiate()
	effect.scale = Vector2.ONE * UserSettings.user_settings.note_size
	game.game_ui.get_drawing_layer_node("HitParticles").add_child(effect)
	effect.position = target_pos

func fire_and_forget_user_sfx(sfx_name: String):
	if not game.is_sound_debounced(sfx_name):
		game.debounce_sound(sfx_name)
		var user_sfx := HBGame.instantiate_user_sfx(sfx_name) as ShinobuSoundPlayer
		game.track_sound(user_sfx)
		user_sfx.start()

# called when the user unpauses the game with rollback
func _on_rollback():
	pass
	
# Called when the multi note this note is a part of is judged
func _on_multi_note_judged(judgement: int):
	pass

func _on_wrong(judgement: int):
	pass

# You can use this to schedule a sound to play at a time when the note is supposed to be hit, it will
# automatically be started/freed
func schedule_autoplay_sound(user_sfx_name: String, game_time_msec: int, target_time_msec: int):
	if not game.sfx_enabled:
		return
	
	if scheduled_autoplay_sound:
		get_tree().root.remove_child(scheduled_autoplay_sound)
		scheduled_autoplay_sound.queue_free()
		scheduled_autoplay_sound.stop()
		scheduled_autoplay_sound = null
	
	if not target_time_msec in game.autoplay_scheduled_sounds:
		game.autoplay_scheduled_sounds[target_time_msec] = []
	var sounds: Array = game.autoplay_scheduled_sounds[target_time_msec]
	if user_sfx_name in sounds:
		return
	else:
		sounds.append(user_sfx_name)
	scheduled_autoplay_sound = HBGame.instantiate_user_sfx(user_sfx_name)
	var time_to_hit := target_time_msec - game_time_msec
	# Now you may be wondering why we are doing this
	# its because sounds are scheduled using the global
	# audio timer, so if we are slowing down or speeding
	# up the audio it would be off-sync
	time_to_hit /= game.audio_playback.pitch_scale
	scheduled_autoplay_sound_time = Shinobu.get_dsp_time() + time_to_hit
	get_tree().root.add_child(scheduled_autoplay_sound)
	scheduled_autoplay_sound.schedule_start_time(scheduled_autoplay_sound_time)
	scheduled_autoplay_sound.start()

# returns true if we are close enough to start scheduling the hit sound
# check SCHEDULE_MARGIN
func is_in_autoplay_schedule_range(time_msec: int, target_time: int) -> bool:
	return target_time - time_msec <= (SCHEDULE_MARGIN * game.audio_playback.pitch_scale) and time_msec < target_time
