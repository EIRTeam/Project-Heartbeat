extends Control

signal change_to_menu(menu_name, force_hard_transition, args)
signal transition_finished()
signal menu_entered
signal menu_exited
class_name HBMenu

onready var tween = Tween.new()

export(bool) var transitions_enabled = true

const TRANSITION_TYPE = Tween.TRANS_LINEAR

func _ready():
	add_child(tween)

	if transitions_enabled:
		tween.connect("tween_all_completed", self, "emit_signal", ["transition_finished"])
func change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	emit_signal("change_to_menu", menu_name, force_hard_transition, args)

func _on_menu_enter(force_hard_transition=false, args = {}):
	var starting_color = Color.white
	starting_color.a = 0.0
	var target_color = Color.white
	target_color.a = 1.0
	
	var starting_scale = Vector2(0.90, 0.90)
	var target_scale = Vector2.ONE
	
	show()
	rect_pivot_offset = rect_size / 2.0
	
	if transitions_enabled and not force_hard_transition:
		tween.interpolate_property(self, "modulate", starting_color, target_color, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rect_scale", starting_scale, target_scale, 0.25, Tween.TRANS_BACK, Tween.EASE_OUT)
		
		tween.start()
	else:
		hide()
		emit_signal("transition_finished")
	emit_signal("menu_entered")
func _on_menu_exit(force_hard_transition = false):
	var starting_color = Color.white
	starting_color.a = 1.0
	var target_color = Color.white
	target_color.a = 0.0
	var target_scale = Vector2(1.1, 1.1)
	var starting_scale = Vector2.ONE
	
	rect_pivot_offset = rect_size / 2.0
	
	if transitions_enabled and not force_hard_transition:
		tween.interpolate_property(self, "modulate", starting_color, target_color, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.interpolate_property(self, "rect_scale", starting_scale, target_scale, 0.25, Tween.TRANS_BACK, Tween.EASE_IN)
		tween.start()
	else:
		hide()
		emit_signal("transition_finished")
	emit_signal("menu_exited")
