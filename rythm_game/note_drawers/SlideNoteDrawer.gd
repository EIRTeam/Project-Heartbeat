extends "res://rythm_game/note_drawers/SingleNoteDrawer.gd"

class_name SlideNoteDrawer

var slide_chain
var slide_chain_drawers = {}
const BLUE_SLIDE_PIECES_PER_SECOND = 93.75
var hit_first = false
var current_sfx_player: AudioStreamPlayer
var is_audio_looping = false

const SLIDE_HIT_SFX_NAME = "slide_hit"

func set_note_data(data):
	.set_note_data(data)

func handles_hit_sfx_playback():
	return (note_data.time - (game.time * 1000.0)) <= game.judge.get_target_window_msec()
	
func get_hit_sfx():
	return SLIDE_HIT_SFX_NAME

func _ready():
	if note_data in game.slide_hold_chains:
		slide_chain = game.slide_hold_chains[note_data]
		slide_chain_drawers = {}

		for slide_piece in slide_chain.pieces:
			var note_drawer = slide_piece.get_drawer().instance()
			note_drawer.note_data = slide_piece
			note_drawer.game = game
			slide_chain_drawers[slide_piece] = note_drawer
			note_drawer._note_init()
			bind_node_to_layer(note_drawer, "SlideChainPieces")
			#add_child(note_drawer)
			note_drawer.hide()

func _on_note_judged(judgement, prevent_free = false):
	if not prevent_free:
		._on_note_judged(judgement, false)
		return
	if slide_chain:
		if judgement >= HBJudge.JUDGE_RATINGS.FINE:
			hit_first = true
			for renderer in multi_note_line_renderers:
				renderer.hide()
			connected_notes = [note_data]
			show_note_hit_effect()
			note_graphic.hide()
			target_graphic.hide()
			sine_drawer.hide()
			set_process_unhandled_input(false)
			if not game.editing and not game.previewing:
				if UserSettings.user_settings.enable_vibration:
					Input.start_joy_vibration(UserSettings.controller_device_idx, 1.0, 1.0)
				
			if not game.editing or game.previewing:
				if not current_sfx_player:
					current_sfx_player = game.sfx_pool.play_sfx("slide_chain_start", true)
					current_sfx_player.connect("finished", self, "_on_start_sound_finished")
			._on_note_judged(judgement, true)
		else:
			._on_note_judged(judgement, false)
	else:
		._on_note_judged(judgement, false)
func _on_note_type_changed():
	._on_note_type_changed()

var last_time = 0

func is_slide_direction_pressed():
	if game.editing and not game.previewing:
		return true
	var direction_pressed = false
	for action in note_data.get_input_actions():
		if game.game_input_manager.is_action_held(action):
			direction_pressed = true
			break
	return direction_pressed

func _on_start_sound_finished():
	is_audio_looping = true
	current_sfx_player = game.sfx_pool.play_looping_sfx("slide_chain_loop")

func _on_game_time_changed(time: float):
	if game.editing or game.previewing:
		if last_time * 1000.0 > note_data.time:
			if time * 1000.0 < note_data.time:
				reset_note_state()
		last_time = time
		if time * 1000.0 < note_data.time:
			kill_loop_sfx_player()
	if game.editing and not game.previewing:
		._on_game_time_changed(time)
	if not is_queued_for_deletion():
		if not hit_first and (not game.editing or game.previewing):
			._on_game_time_changed(time)
		if game.editing:
			if time * 1000.0 > note_data.time and note_graphic.visible:
				note_graphic.hide()
				target_graphic.hide()
				sine_drawer.hide()
				show_note_hit_effect()
			if time * 1000.0 < note_data.time and not note_graphic.visible:
				note_graphic.show()
				sine_drawer.show()
				target_graphic.show()
				note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
		if visible:
			update_graphic_positions_and_scale(time)
		if slide_chain:
			var blue_notes = max(0, float(time - (note_data.time / 1000.0)) * BLUE_SLIDE_PIECES_PER_SECOND)

			var direction_pressed = is_slide_direction_pressed()

			var chain_failed = false

			for i in range(slide_chain_drawers.size()):
				
				var piece = slide_chain_drawers.keys()[i] as HBNoteData
				var piece_drawer = slide_chain_drawers[piece]

				if i < blue_notes:
					if direction_pressed:
						piece_drawer.make_blue()
				elif game.editing:
					piece_drawer.undo_blue()


				# Chain piece appear
				var piece_appear_time = piece.time - piece.get_time_out(game.get_bpm_at_time(piece.time))
				if time * 1000.0 > piece_appear_time:
					if time * 1000.0 < piece.time:
						if not piece_drawer.visible:
							piece_drawer.show()
							piece_drawer.play_appear_animation()
				else:
					piece_drawer.hide()
				if piece_drawer.visible and (hit_first or game.editing):
					if time * 1000.0 >= piece.time:
						var current_score = (i + 1) * game.SLIDE_HOLD_PIECE_SCORE
						if not piece_drawer.blue and not direction_pressed and not game.previewing:
							chain_failed = true
							game.add_slide_chain_score(current_score)
							break
						piece_drawer.show_note_hit_effect()
						game.show_slide_hold_score(piece.position, current_score, i >= slide_chain.pieces.size() - 1)
						piece_drawer.hide()
						if i >= slide_chain.pieces.size() - 1:
							kill_note()
							game.add_slide_chain_score(current_score)
							game.sfx_pool.play_sfx("slide_chain_ok")
				if piece_drawer.visible:
					piece_drawer.update_graphic_positions_and_scale(time)
			if chain_failed:
				kill_note()
				game.sfx_pool.play_sfx("slide_chain_fail")
		else:
			._on_game_time_changed(time)
func kill_note():
	emit_signal("note_removed")
	kill_loop_sfx_player()

func is_sliding():
	return hit_first

func kill_loop_sfx_player():
	if current_sfx_player:
		if is_audio_looping:
			game.sfx_pool.stop_looping_sfx(current_sfx_player)
		else:
			if is_instance_valid(current_sfx_player):
				game.sfx_pool.stop_sfx(current_sfx_player)
		is_audio_looping = false
		current_sfx_player = null

func reset_note_state():
	hit_first = false
	for slide_drawer in slide_chain_drawers.values():
		slide_drawer.undo_blue()
		slide_drawer.hide()
	note_graphic.show()
	note_graphic.scale = Vector2(game.get_note_scale(), game.get_note_scale())
	target_graphic.show()
	kill_loop_sfx_player()
	for renderer in multi_note_line_renderers:
		renderer.show()


func is_slide_chain_active():
	return not note_graphic.visible

func _notification(what):
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		kill_loop_sfx_player()
		Input.stop_joy_vibration(UserSettings.controller_device_idx)
