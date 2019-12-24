tool
extends Control

class_name HBListContainer

signal selected_option_changed
signal navigate_to_menu(menu)
signal navigated

var selected_option : Control
export(int) var VISIBILITY_THRESHOLD = 3 # How many items should be visible
var lerp_weight = 8.0
export(int) var margin
export (float) var scale_factor = 0.75
export (bool) var disable_repositioning = false
const MOVE_SOUND = preload("res://sounds/sfx/274199__littlerobotsoundfactory__ui-electric-08.wav")
const ACCEPT_SOUND = preload("res://sounds/sfx/MENU A_Select.wav")
var move_sound_player = AudioStreamPlayer.new()
export(bool) var fixed_scale_factor = false

func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")
	move_sound_player.stream = MOVE_SOUND
	move_sound_player.pause_mode = PAUSE_MODE_PROCESS
	get_tree().root.call_deferred("add_child", move_sound_player)
	focus_mode = FOCUS_ALL
	get_viewport().connect("size_changed", self, "hard_arrange_all")
	if get_child_count() > 0:
		selected_option = get_child(0)
		emit_signal("selected_option_changed")
		hard_arrange_all()
	for child in get_children():
		if child is BaseButton:
			child.connect("pressed", self, "_on_button_pressed", [child])
	hard_arrange_all()

func _on_button_pressed(option: BaseButton):
	if has_focus():
		if option != selected_option:
			selected_option = option
			emit_signal("selected_option_changed")
		else:
			if option is HBMenuChangeButton:
				if option.next_menu:
					emit_signal("navigate_to_menu", option.next_menu)
					emit_signal("navigated")
			else:
				option.emit_signal("pressed")

#			option.connect("pressed", self, "_on_button_pressed", [option], CONNECT_ONESHOT)
				
func _on_focus_entered():
	print("FOCUS")
	if selected_option:
		selected_option.hover()
			
func _on_focus_exited():
	if selected_option:
		selected_option.stop_hover()
			
func _process(delta):
	

	
	var menu_start := Vector2(0, rect_size.y / 2)
	
	if not selected_option:
		if get_child_count() > 0:
			selected_option = get_children()[0]
			if has_focus():
				emit_signal("selected_option_changed")
			
	if selected_option:
		if disable_repositioning:
			selected_option.rect_position = Vector2(menu_start.x, menu_start.y - selected_option.rect_size.y/2)
			selected_option.rect_scale = Vector2(1.0, 1.0)
			selected_option.modulate.a = 1.0
			arrange_options(1, get_child_count(), 1.0, get_child(0).rect_position, selected_option.rect_size.y, true)
		else:
			# Place select option:
			var starting_position = lerp(selected_option.rect_position, Vector2(menu_start.x, menu_start.y - selected_option.rect_size.y/2), lerp_weight * delta)
			selected_option.rect_position = starting_position
			selected_option.rect_scale = lerp(selected_option.rect_scale, Vector2(1.0, 1.0), lerp_weight * delta)
			#selected_option.rect_scale = Vector2(1.0, 1.0)
			selected_option.self_modulate = lerp(selected_option.self_modulate, Color(1.0, 1.0, 1.0, 1.0), lerp_weight * delta)
			var prev_child_pos = selected_option.rect_position
			var prev_child_scale = selected_option.rect_scale.y
			arrange_options(selected_option.get_position_in_parent()-1, -1, -1, selected_option.rect_position, selected_option.rect_size.y)
			arrange_options(selected_option.get_position_in_parent()+1, get_child_count(), 1.0, selected_option.rect_position, selected_option.rect_size.y, false, selected_option.rect_scale.y)

func _gui_input(event):
	if selected_option:
		if event.is_action_pressed("ui_down"):
			var current_pos = selected_option.get_position_in_parent()
			if current_pos < get_child_count()-1:
				get_tree().set_input_as_handled()
				selected_option.stop_hover()
				selected_option = get_child(current_pos + 1)
				selected_option.hover()
				emit_signal("selected_option_changed")
				move_sound_player.play()
				print("DOWN")
		if event.is_action_pressed("ui_up"):
			var current_pos = selected_option.get_position_in_parent()
			if current_pos > 0:
				get_tree().set_input_as_handled()
				selected_option.stop_hover()
				selected_option = get_child(current_pos - 1)
				selected_option.hover()
				emit_signal("selected_option_changed")
				move_sound_player.play()
		if event.is_action_pressed("ui_accept"):
			if selected_option is BaseButton:
				get_tree().set_input_as_handled()
				selected_option.emit_signal("pressed")
				emit_signal("selected_option_changed")
		if event.is_action_pressed("ui_right"):
			if focus_neighbour_right:
				get_tree().set_input_as_handled()
				var right_neighbour = get_node(focus_neighbour_right) as Control
				right_neighbour.grab_focus()
func hard_arrange_all():
	var menu_start := Vector2(0, rect_size.y / 2)
	selected_option.rect_position = Vector2(menu_start.x, menu_start.y - selected_option.rect_size.y/2)
	selected_option.rect_scale = Vector2(1.0, 1.0)
	selected_option.modulate.a = 1.0
	arrange_options(selected_option.get_position_in_parent()-1, -1, -1, selected_option.rect_position, selected_option.rect_size.y, true)
	arrange_options(selected_option.get_position_in_parent()+1, get_child_count(), 1.0, selected_option.rect_position, selected_option.rect_size.y, true)

func arrange_options(start, end, step, start_position, start_size, hard = false, start_scale=1.0):
	var lw = lerp_weight * get_process_delta_time()
	var children = get_children()
	var prev_child_scale = start_scale
	var prev_child_pos = start_position
	var prev_child_size = start_size
	var target_poss_average_diff = 0.0
	for i in range(start, end, step):
		var label = children[i]
		
		# Opacity interpolation
		var target_op = 0.0
		if (abs(selected_option.get_position_in_parent() - label.get_position_in_parent()) > VISIBILITY_THRESHOLD):
			label.modulate.a = lerp(label.modulate.a, 0.0, lw)
		else:
			label.modulate.a = lerp(label.modulate.a, 1.0, lw)
			target_op = 1.0
		
		# Scale interpolation
		
		var target_scale = prev_child_scale * scale_factor
		if fixed_scale_factor:
			target_scale = scale_factor
		label.rect_scale = lerp(label.rect_scale, Vector2(target_scale, target_scale), lw)
		
		# Calculate the difference between where our label is and wher eit should be
		
		var pos_diff = Vector2(0, 0)
		if end > start:
			# Under the selected one, important to care about thep revious child's size
			pos_diff.y += (prev_child_size + margin) * prev_child_scale
		else:
			# Over the selected one, only care about our own size
			pos_diff.y += (label.rect_size.y + margin) * label.rect_scale.y
			
		#label.rect_position = lerp(label.rect_position, prev_child_pos + sign(end-start) * pos_diff, lw)
		label.rect_position = prev_child_pos + sign(end-start) * pos_diff # Looks much better if we don't interpolate position...
		if hard:
			label.modulate.a = target_op
			label.rect_scale = Vector2(target_scale, target_scale)
		prev_child_pos = label.rect_position
		prev_child_scale = label.rect_scale.y
		prev_child_size = label.rect_size.y
