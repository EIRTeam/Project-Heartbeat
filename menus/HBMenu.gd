extends Control

class_name HBMenu

signal changed_to_menu(menu_name, force_hard_transition, args)
signal transition_finished()
signal menu_entered
signal menu_exited

var tween: Tween

@export var transitions_enabled: bool = true

const TRANSITION_TYPE = Threen.TRANS_LINEAR

func _ready():
	pass

func change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	emit_signal("changed_to_menu", menu_name, force_hard_transition, args)

func is_mid_transition() -> bool:
	return tween and tween.is_running()

func _on_menu_enter(force_hard_transition=false, args = {}):
	var starting_color = Color.WHITE
	starting_color.a = 0.0
	var target_color = Color.WHITE
	target_color.a = 1.0
	
	var starting_scale = Vector2(0.90, 0.90)
	var target_scale = Vector2.ONE
	
	show()
	
	pivot_offset = size / 2.0
	
	if tween and tween.is_running():
		tween.kill()
		tween = null
	
	if transitions_enabled and not force_hard_transition:
		tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.15) \
			.from(Color.TRANSPARENT) \
			.set_trans(Tween.TRANS_LINEAR) \
			.set_ease(Tween.EASE_IN_OUT)
		tween.parallel() \
			.tween_property(self, "scale", Vector2.ONE, 0.25) \
			.from(Vector2.ONE * 0.90) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_OUT)
		tween.tween_callback(transition_finished.emit)
	else:
		scale = Vector2.ONE
		modulate.a = 1.0
		hide()
		emit_signal("transition_finished")
	emit_signal("menu_entered")
func _on_menu_exit(force_hard_transition = false):
	var starting_color = Color.WHITE
	starting_color.a = 1.0
	var target_color = Color.WHITE
	target_color.a = 0.0
	var target_scale = Vector2(1.1, 1.1)
	var starting_scale = Vector2.ONE
	
	pivot_offset = size / 2.0
	if tween and tween.is_running():
		tween.kill()
		tween = null
	if transitions_enabled and not force_hard_transition:
		tween = create_tween()
		tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.15) \
			.from(Color.WHITE) \
			.set_trans(Tween.TRANS_LINEAR) \
			.set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(self, "scale", Vector2.ONE * 1.1, 0.25) \
			.from(Vector2.ONE) \
			.set_trans(Tween.TRANS_BACK) \
			.set_ease(Tween.EASE_IN)
		tween.tween_callback(transition_finished.emit)
	else:
		scale = Vector2.ONE
		modulate.a = 1.0
		hide()
		transition_finished.emit()
	emit_signal("menu_exited")
