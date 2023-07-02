extends HBNewNoteDrawer
	
var SINGLE_NOTE_DRAWER_SCENE := load("res://rythm_game/note_drawers/new/SingleNoteDrawer.tscn")
	
var chain_piece_drawers := {}
	
# For when the user lets go while holding a slide chain without it being filled completely
var last_hold_time := -1
	
const BLUE_SLIDE_PIECES_PER_SECOND = 93.75
	
var current_slide_chain_sound: ShinobuSoundPlayer
	
var slide_effect_scene: PackedScene
	
var pressed := false: set = set_pressed
func set_pressed(val):
	pressed = val
	note_graphics.visible = !pressed
	if sine_drawer:
		sine_drawer.visible = !pressed
	note_target_graphics.visible = !pressed
	
func _init():
	slide_effect_scene = load("res://graphics/effects/SlideParticlesCPU.tscn")
	
func note_init():
	super.note_init()
	
func play_appear_animation():
	super.play_appear_animation()
	
func show_note_hit_effect(target_pos: Vector2):
	if note_data.is_slide_note():
		var effect = slide_effect_scene.instantiate()
		effect.scale = Vector2.ONE * UserSettings.user_settings.note_size
		game.game_ui.get_drawing_layer_node("StarParticles").add_child(effect)
		if note_data.note_type == HBBaseNote.NOTE_TYPE.SLIDE_LEFT:
			effect.scale.x = -1.0
		effect.position = target_pos
	
func create_note_drawer(piece: HBNoteData):
	var drawer := SINGLE_NOTE_DRAWER_SCENE.instantiate() as HBNewNoteDrawer
	drawer.game = game
	drawer.note_data = piece
	drawer.connect("add_node_to_layer", Callable(self, "_on_slide_piece_add_node_to_layer"))
	drawer.connect("remove_node_from_layer", Callable(self, "_on_slide_piece_remove_node_from_layer"))
	bind_node_to_layer(drawer, "SlideChainPieces")
	drawer.is_multi_note = false
	drawer.appear_animation_enabled = false
	drawer.note_init()
	drawer.disable_autoplay = true
	return drawer
	
func _on_slide_piece_add_node_to_layer(layer_name: String, node: Node):
	emit_signal("add_node_to_layer", layer_name, node)
	
func _on_slide_piece_remove_node_from_layer(layer_name: String, node: Node):
	emit_signal("remove_node_from_layer", layer_name, node)
	
func is_slide_chain() -> bool:
	return note_data in game.slide_hold_chains
	
func get_slide_chain_pieces() -> Array:
	return game.slide_hold_chains.get(note_data).pieces
	
func handles_input(event: InputEventHB) -> bool:
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	var is_input_in_range: bool = abs(game.time_msec - note_data.time) < game.judge.get_target_window_msec()
	if not is_slide_chain() and pressed and is_multi_note:
		return false
	return event.is_action_pressed(action) and is_input_in_range

func is_in_editor_mode():
	return game.game_mode == HBRhythmGame.GAME_MODE.EDITOR_SEEK

func process_input(event: InputEventHB):
	if not pressed:
		_on_pressed()

func _on_pressed():
	var judgement := game.judge.judge_note(game.time_msec, note_data.time) as int
	judgement = max(HBJudge.JUDGE_RATINGS.FINE, judgement) # Slide notes always give at least a fine
	if is_slide_chain():
		judgement = HBJudge.JUDGE_RATINGS.COOL # Slide chains can never be a fine
	
	if not is_in_editor_mode() and not is_autoplay_enabled() and not is_slide_chain():
		fire_and_forget_user_sfx("slide_hit")
	
	set_pressed(true)
	
	if not is_in_editor_mode():
		emit_signal("judged", judgement, false, note_data.time, null)
		show_note_hit_effect(note_data.position)
		
		if not is_multi_note:
			game.add_score(HBNoteData.NOTE_SCORES[judgement])
			if not is_slide_chain():
				emit_signal("finished")
			else:
				_on_slide_chain_started()
		else:
			note_graphics.hide()
			note_target_graphics.hide()

func _on_slide_chain_started():
	if not game.sfx_enabled:
		return
	
	var slide_chain_start_sfx := HBGame.instantiate_user_sfx("slide_chain_start")
	add_child(slide_chain_start_sfx)
	current_slide_chain_sound = slide_chain_start_sfx
	slide_chain_start_sfx.start()

func ensure_vibration():
	if game.game_mode != HBRhythmGame.GAME_MODE.NORMAL:
		end_vibration()
		return
	if UserSettings.user_settings.enable_vibration:
		if UserSettings.controller_device_idx in Input.get_connected_joypads():
			Input.start_joy_vibration(UserSettings.controller_device_idx, 1.0, 1.0)

func end_vibration():
	if UserSettings.user_settings.enable_vibration:
		if UserSettings.controller_device_idx in Input.get_connected_joypads():
			if Input.get_joy_vibration_strength(UserSettings.controller_device_idx).length() != 0:
				Input.stop_joy_vibration(UserSettings.controller_device_idx)

func is_slide_direction_pressed():
	if is_in_editor_mode() or is_autoplay_enabled():
		return true
	var direction_pressed = false
	for action in note_data.get_input_actions():
		if game.game_input_manager.is_action_held(action):
			direction_pressed = true
			break
	return direction_pressed

func process_note(time_msec: int):
	super.process_note(time_msec)
	
	if is_autoplay_enabled():
		if is_in_autoplay_schedule_range(time_msec, note_data.time) and \
				not scheduled_autoplay_sound and not is_slide_chain():
			schedule_autoplay_sound("slide_hit", time_msec, note_data.time)
	
	if is_in_editor_mode():
		if current_slide_chain_sound:
			current_slide_chain_sound.queue_free()
			current_slide_chain_sound = null
		set_pressed(false)
	
	if is_slide_direction_pressed():
		last_hold_time = time_msec
	elif not pressed:
		last_hold_time = -1
	
	if is_slide_chain():
		if not pressed:
			if is_slide_direction_pressed():
				if time_msec > note_data.time:
					_on_pressed()
		if pressed:
			if current_slide_chain_sound and current_slide_chain_sound.is_at_stream_end():
				current_slide_chain_sound.queue_free()
				current_slide_chain_sound = null
			if not current_slide_chain_sound and not is_in_editor_mode() and game.sfx_enabled:
				current_slide_chain_sound = HBGame.instantiate_user_sfx("slide_chain_loop")
				current_slide_chain_sound.looping_enabled = true
				current_slide_chain_sound.start()
				add_child(current_slide_chain_sound)
			ensure_vibration()
		
		var blue_notes = max(0, float(last_hold_time - (note_data.time)) * (BLUE_SLIDE_PIECES_PER_SECOND / 1000.0))
		var slide_chain_pieces := get_slide_chain_pieces()
		
		for i in range(slide_chain_pieces.size()):
			var piece := slide_chain_pieces[i] as HBNoteData
			var time_out := piece.get_time_out(game.get_note_speed_at_time(piece.time)) as int
			var should_be_visible: bool = (piece.time - time_out) < time_msec
			# Process pieces that are alive
			if should_be_visible:
				var should_create := piece.time > time_msec
				if not piece in chain_piece_drawers:
					if not should_create:
						continue
					chain_piece_drawers[piece] = create_note_drawer(piece)
				var drawer := chain_piece_drawers[piece] as HBNewNoteDrawer
				drawer.process_note(time_msec)
				
				if last_hold_time == -1:
					continue
				
				var is_blue: bool = blue_notes > i
				drawer.note_target_graphics.set_note_type(drawer.note_data, false, is_blue)
				
				if time_msec >= piece.time:
					var current_score = (i + 1) * game.SLIDE_HOLD_PIECE_SCORE
					# Fail the chain if its not being held
					if not is_slide_direction_pressed() and not is_blue:
						game.add_slide_chain_score(current_score)
						game.sfx_pool.play_sfx("slide_chain_fail")
						emit_signal("finished")
						return
					var is_last := i >= slide_chain_pieces.size() - 1
					if not is_in_editor_mode():
						game.show_slide_hold_score(piece.position, current_score, is_last)
						super.show_note_hit_effect(piece.position)
					free_node_bind(drawer)
					drawer.queue_free()
					chain_piece_drawers.erase(piece)
					
					# On last note play the bonus funnies
					if is_last:
						if game.sfx_enabled:
							game.sfx_pool.play_sfx("slide_chain_ok")
						
						game.add_slide_chain_score(current_score)
						emit_signal("finished")
						return
			# Remove pieces that shouldn't actually be around
			elif piece in chain_piece_drawers:
				free_node_bind(chain_piece_drawers[piece])
				chain_piece_drawers[piece].queue_free()
				chain_piece_drawers.erase(piece)
	elif is_autoplay_enabled():
		if time_msec >= note_data.time:
			_on_pressed()
	if not pressed:
		if time_msec > note_data.time + game.judge.get_target_window_msec() and not (is_slide_chain() and is_slide_direction_pressed()):
			emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.time, null)
			emit_signal("finished")

func _on_rollback():
	if pressed:
		emit_signal("finished")

func _on_multi_note_judged(judgement: int):
	if is_slide_chain():
		_on_slide_chain_started()
	else:
		emit_signal("finished")

func _notification(what: int):
	match what:
		NOTIFICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			end_vibration()
			end_vibration()
