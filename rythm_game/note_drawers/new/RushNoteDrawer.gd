extends HBNewNoteDrawer

class_name HBRushNoteDrawer

var pressed := false

var hits_done := 0

@onready var score_bonus_container: Node2D = %ScoreBonus
@onready var score_bonus_label: Label = %ScoreBonusLabel
@onready var rush_note_graphic: NoteGraphics = %RushNoteGraphic
@onready var rush_particle_drawer: RushParticleDrawer = %RushParticleDrawer
@onready var rush_text_container: Node2D = %RushText
@onready var rush_text_sprite: Sprite2D = %RushTextSprite
@onready var rush_timing_arm: Sprite2D = %RushNoteTimingArm

const EndParticles := preload("res://graphics/effects/RushNoteEndParticles.tscn")

func set_note_data(val):
	super.set_note_data(val)

func set_is_multi_note(val):
	super.set_is_multi_note(val)
	rush_note_graphic.set_note_type(note_data.note_type, false, false, true)
	rush_particle_drawer.set_note_data(note_data as HBRushNote)
	rush_text_sprite.texture = HBBaseNote.get_note_graphic(note_data.note_type, "rush_text")

func note_init():
	hits_done = 0
	pressed = false
	
	remove_child(score_bonus_container)
	remove_child(rush_text_container)
	remove_child(rush_particle_drawer)
	bind_node_to_layer(rush_particle_drawer, &"HitParticles", NodePath("NoteTarget"))
	bind_node_to_layer(score_bonus_container, &"RushText", NodePath("NoteTarget"))
	bind_node_to_layer(rush_text_container, &"RushText", NodePath("NoteTarget"))
	score_bonus_label.position = -(score_bonus_label.size * 0.5)
	score_bonus_label.position -= Vector2(0, 64)
	rush_timing_arm.texture = ResourcePackLoader.get_graphic("rush_note_timing_arm.png")
	
	score_bonus_container.hide()
	rush_note_graphic.hide()
	super.note_init()
func handles_input(event: InputEventHB):
	var action := HBGame.NOTE_TYPE_TO_ACTIONS_MAP[note_data.note_type][0] as String
	var is_input_in_range: bool = abs(event.game_time - note_data.time * 1000) < game.judge.get_target_window_usec()
	var action_pressed: bool = event.is_action_pressed(action)
	if not pressed:
		return action_pressed and is_input_in_range
	else:
		return action_pressed

func process_input(event: InputEventHB):
	if pressed:
		_on_rush_press()
	else:
		_on_pressed(event)
		
func _on_rush_press():
	hits_done += 1
	note_target_graphics.scale = Vector2.ONE * UserSettings.user_settings.note_size * get_base_target_scale()
	game.add_rush_bonus_score(30)
	score_bonus_label.text = "+%d" % [hits_done * 30]
	score_bonus_container.show()
	show_note_hit_effect(note_data.position, get_base_target_scale())
	fire_and_forget_user_sfx("note_hit")
	rush_particle_drawer.emit()
	var max_hit_count := (note_data as HBRushNote).calculate_capped_hit_count()
	if hits_done >= max_hit_count:
		play_end_particles()
		finished.emit()
func _on_pressed(event = null, judge := true):
	if sine_drawer:
		sine_drawer.hide()
	note_graphics.hide()
	note_target_graphics.hide()
	rush_note_graphic.show()
	rush_note_graphic.scale = UserSettings.user_settings.note_size * Vector2.ONE * get_base_target_scale() * 0.5
	rush_note_graphic.position = note_data.position
	rush_timing_arm.hide()
	hits_done = 0
	pressed = true
	
	if not is_autoplay_enabled():
		fire_and_forget_user_sfx("note_hit")
	var time := game.time_usec
	if event:
		time = event.game_time
	var judgement := game.judge.judge_note_usec(time, note_data.time * 1000) as int
	if judge:
		emit_signal("judged", judgement, false, note_data.time, event)
	if not is_multi_note:
		game.add_score(HBNoteData.NOTE_SCORES[judgement])
		if judgement < HBJudge.JUDGE_RATINGS.FINE:
			emit_signal("finished")
		if judgement >= HBJudge.JUDGE_RATINGS.FINE:
			show_note_hit_effect(note_data.position)

func update_arm_position(time_usec: int):
	var note_time_usec := note_data.time * 1000
	var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.time)) * 1000
	if pressed:
		note_target_graphics.arm2_position = 0.0
	else:
		note_target_graphics.arm2_position = 1.0 - ((note_time_usec - time_usec) / float(time_out))
	var time_out_distance = time_out - (note_time_usec - time_usec) - (note_data.get_duration() * 1000)
	note_target_graphics.arm_position = clamp(time_out_distance / float(time_out), 0.0, 1.0)

func is_in_editor_mode():
	return game.game_mode == 1

func play_end_particles():
	var end_particles: HBRushNoteEndParticles = EndParticles.instantiate()
	game.game_ui.get_drawing_layer_node(&"HitParticles").add_child(end_particles)
	end_particles.position = note_data.position
	end_particles.play()

func process_note(time_usec: int):
	super.process_note(time_usec)
	
	var t_msec := time_usec / 1000
	var note_time_usec := note_data.time * 1000
	var note_end_time_usec := note_data.end_time * 1000 as int
	
	if is_autoplay_enabled():
		if not scheduled_autoplay_sound:
			var target_time: int = note_data.time if not pressed else note_data.end_time
			if is_in_autoplay_schedule_range(t_msec, target_time):
				var note_sfx := "note_hit" if not pressed else "sustain_note_release"
				schedule_autoplay_sound(note_sfx, t_msec, target_time)
		if time_usec > note_time_usec and not pressed:
			_on_pressed()
			if scheduled_autoplay_sound:
				get_tree().root.remove_child(scheduled_autoplay_sound)
				game.track_sound(scheduled_autoplay_sound)
				scheduled_autoplay_sound = null
			return
		elif time_usec > note_end_time_usec and pressed:
			finished.emit()
			return
			
	if is_in_editor_mode():
		if time_usec > note_time_usec:
			pressed = true
			note_graphics.hide()
		else:
			pressed = false
			note_graphics.show()
	# Handle note going out of range
	if pressed:
		if time_usec > note_end_time_usec:
			emit_signal("finished")
	else:
		if time_usec > note_time_usec + game.judge.get_target_window_usec():
			# Judge note independently once, that way it will count as 2 worsts
			emit_signal("judged", HBJudge.JUDGE_RATINGS.WORST, false, note_data.time, null)
			emit_signal("finished")

func get_base_target_scale() -> float:
	var rush_scale: float = 1.0 + min((hits_done / 33.0), 1.0)
	return rush_scale

func update_graphic_positions_and_scale(time_usec: int):
	super.update_graphic_positions_and_scale(time_usec)
	update_arm_position(time_usec)
	if pressed:
		rush_note_graphic.scale = UserSettings.user_settings.note_size * Vector2.ONE * get_base_target_scale() * 0.5
		rush_note_graphic.position = note_data.position
	if pressed:
		var time_out := note_data.get_time_out(game.get_note_speed_at_time(note_data.time)) * 1000
		var note_time_usec := note_data.time * 1000
		var time_out_distance = time_out - (note_time_usec - time_usec) - (note_data.get_duration() * 1000)
		var timing_arm_rot_amount := clamp(time_out_distance / float(time_out), 0.0, 1.0)
		if timing_arm_rot_amount > 0.0:
			rush_timing_arm.rotation = timing_arm_rot_amount * TAU
			rush_timing_arm.show()

func _on_rollback():
	if pressed:
		emit_signal("finished")

func _on_multi_note_judged(judgement: int):
	if judgement < HBJudge.JUDGE_RATINGS.FINE:
		emit_signal("finished")

func _on_wrong(_judgement: int):
	emit_signal("finished")
