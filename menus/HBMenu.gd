extends Control

class_name HBMenu

signal changed_to_menu(menu_name, force_hard_transition, args)
signal transition_finished()
signal menu_entered
signal menu_exited

@onready var tween = Threen.new()

@export var transitions_enabled: bool = true

const TRANSITION_TYPE = Threen.TRANS_LINEAR

func _ready():
	add_child(tween)

	if transitions_enabled:
		tween.connect("tween_all_completed", Callable(self, "emit_signal").bind("transition_finished"))
func change_to_menu(menu_name: String, force_hard_transition=false, args = {}):
	emit_signal("changed_to_menu", menu_name, force_hard_transition, args)

func _on_menu_enter(force_hard_transition=false, args = {}):
	var starting_color = Color.WHITE
	starting_color.a = 0.0
	var target_color = Color.WHITE
	target_color.a = 1.0
	
	var starting_scale = Vector2(0.90, 0.90)
	var target_scale = Vector2.ONE
	
	show()
	pivot_offset = size / 2.0
	
	if transitions_enabled and not force_hard_transition:
		tween.interpolate_property(self, "modulate", starting_color, target_color, 0.15, Threen.TRANS_LINEAR, Threen.EASE_IN_OUT)
		tween.interpolate_property(self, "scale", starting_scale, target_scale, 0.25, Threen.TRANS_BACK, Threen.EASE_OUT)
		
		tween.start()
	else:
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
	
	if transitions_enabled and not force_hard_transition:
		tween.interpolate_property(self, "modulate", starting_color, target_color, 0.15, Threen.TRANS_LINEAR, Threen.EASE_IN_OUT)
		tween.interpolate_property(self, "scale", starting_scale, target_scale, 0.25, Threen.TRANS_BACK, Threen.EASE_IN)
		tween.start()
	else:
		hide()
		emit_signal("transition_finished")
	emit_signal("menu_exited")
