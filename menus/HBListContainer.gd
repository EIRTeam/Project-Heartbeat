tool
extends Control

class_name HBListContainer

signal selected_option_changed
signal navigate_to_menu(menu)
signal navigated

var selected_option : Control
var VISIBILITY_THRESHOLD_TOP = 3 # How many items should be visible
var VISIBILITY_THRESHOLD_BOTTOM = 3 # How many items should be visible
var lerp_weight = 8.0
export(int) var margin
export (float) var scale_factor = 0.75
var menu_start_percentage = 0.5
export(int)var items_visible_top = 2 # How many items should be visible on top
export (bool) var disable_repositioning = false
export(bool) var instant_scale_change = false
var f = true
const MOVE_SOUND = preload("res://sounds/sfx/274199__littlerobotsoundfactory__ui-electric-08.wav")
const ACCEPT_SOUND = preload("res://sounds/sfx/MENU A_Select.wav")
var move_sound_player = AudioStreamPlayer.new()
export(bool) var fixed_scale_factor = false
var prevent_hard_arrange = false

const MOVE_DEBOUNCE_T = 0.1
const INITIAL_MOVE_DEBOUNCE_T = 0.3
var move_debounce = MOVE_DEBOUNCE_T
var initial_move_debounce = INITIAL_MOVE_DEBOUNCE_T

func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")
	move_sound_player.stream = MOVE_SOUND
	move_sound_player.pause_mode = PAUSE_MODE_PROCESS
	get_tree().root.call_deferred("add_child", move_sound_player)
	focus_mode = FOCUS_ALL
	connect("resized", self, "hard_arrange_all")
	connect("resized", self, "calculate_visibility_threshholds")
	connect("resized", self, "resize_children")
	if get_child_count() > 0:
		selected_option = get_child(0)
		emit_signal("selected_option_changed")
		hard_arrange_all()
		calculate_visibility_threshholds()
	for child in get_children():
		for _signal in child.get_signal_list():
			print(_signal.name)
			if _signal.name == "pressed":
				child.connect("pressed", self, "_on_button_pressed", [child])
				break
func resize_children():
	for child in get_children():
		child.rect_size.x = rect_size.x
func _on_button_pressed(option: BaseButton):
	if has_focus():
		if option != selected_option:
			selected_option = option
			emit_signal("selected_option_changed")
		else:
			if option is HBMenuChangeButton:
				if option.next_menu:
					option.stop_hover()
					emit_signal("navigate_to_menu", option.next_menu)
					emit_signal("navigated")
#				option.emit_signal("pressed")

#			option.connect("pressed", self, "_on_button_pressed", [option], CONNECT_ONESHOT)
				
func _on_focus_entered():
	if selected_option:
		selected_option.hover()
			
func _on_focus_exited():
	if selected_option:
		selected_option.stop_hover()
			
func _process(delta):
	move_debounce += delta
	initial_move_debounce += delta
	var can_press = move_debounce >= MOVE_DEBOUNCE_T and initial_move_debounce >= INITIAL_MOVE_DEBOUNCE_T and has_focus()
	if (Input.is_action_just_pressed("gui_down") or Input.is_action_just_pressed("gui_up")) and can_press:
		move_debounce = MOVE_DEBOUNCE_T
		initial_move_debounce = 0.0
		can_press = true
	if get_child_count() == 0:
		can_press = false
	if Input.is_action_pressed("gui_down") and can_press:
		move_debounce = 0.0
		var current_pos = selected_option.get_position_in_parent()
		if current_pos < get_child_count()-1:
			select_option(current_pos+1)
			move_sound_player.play()
	if Input.is_action_pressed("gui_up") and can_press:
		move_debounce = 0.0
		var current_pos = selected_option.get_position_in_parent()
		if current_pos > 0:
			select_option(current_pos-1)
			move_sound_player.play()
	var menu_start := Vector2(0, rect_size.y * menu_start_percentage)
	if not selected_option:
		if get_child_count() > 0:
			selected_option = get_children()[0]
			if has_focus():
				emit_signal("selected_option_changed")
			
	if selected_option:
		if disable_repositioning:
			arrange_options(0, get_child_count(), 1.0, menu_start * 0.75, get_child(0).rect_size.y, true)
		else:
			# Place select option:
			var starting_position = lerp(selected_option.rect_position, Vector2(menu_start.x, menu_start.y - selected_option.rect_size.y/2), lerp_weight * delta)
			selected_option.rect_position = starting_position
			if instant_scale_change:
				selected_option.rect_scale = Vector2(1.0, 1.0)
			else:
				selected_option.rect_scale = lerp(selected_option.rect_scale, Vector2(1.0, 1.0), lerp_weight * delta)
			#selected_option.rect_scale = Vector2(1.0, 1.0)
			selected_option.self_modulate = lerp(selected_option.self_modulate, Color(1.0, 1.0, 1.0, 1.0), lerp_weight * delta)
			var prev_child_pos = selected_option.rect_position
			var prev_child_scale = selected_option.rect_scale.y
			arrange_options(selected_option.get_position_in_parent()-1, -1, -1, selected_option.rect_position, selected_option.rect_size.y)
			arrange_options(selected_option.get_position_in_parent()+1, get_child_count(), 1.0, selected_option.rect_position, selected_option.rect_size.y, false, selected_option.rect_scale.y)

func select_option(option_i: int):
	get_tree().set_input_as_handled()
	if selected_option:
		selected_option.stop_hover()
	selected_option = get_child(option_i)
	selected_option.hover()
	emit_signal("selected_option_changed")

func _gui_input(event):
	if selected_option:
		if event.is_action_released("gui_up") or event.is_action_released("gui_down"):
			move_debounce = MOVE_DEBOUNCE_T
			initial_move_debounce = INITIAL_MOVE_DEBOUNCE_T
		if event.is_action_pressed("gui_accept"):
			get_tree().set_input_as_handled()
			selected_option.emit_signal("pressed")
			emit_signal("selected_option_changed")
		if event.is_action_pressed("gui_right"):
			if focus_neighbour_right:
				get_tree().set_input_as_handled()
				var right_neighbour = get_node(focus_neighbour_right) as Control
				right_neighbour.grab_focus()
		if event is InputEventMouseButton and event.is_pressed() and not event.is_echo():
			if event.button_index == BUTTON_WHEEL_UP:
				move_debounce = 0.0
				var current_pos = selected_option.get_position_in_parent()
				if current_pos > 0:
					select_option(current_pos-1)
					move_sound_player.play()
			if event.button_index == BUTTON_WHEEL_DOWN:
				move_debounce = 0.0
				var current_pos = selected_option.get_position_in_parent()
				if current_pos < get_child_count()-1:
					select_option(current_pos+1)
					move_sound_player.play()
#	if Input.is_action_pressed("gui_down") and can_press:
#		move_debounce = 0.0
#		var current_pos = selected_option.get_position_in_parent()
#		if current_pos < get_child_count()-1:
#			select_option(current_pos+1)
#			move_sound_player.play()
#	if Input.is_action_pressed("gui_up") and can_press:
#		move_debounce = 0.0
#		var current_pos = selected_option.get_position_in_parent()
#		if current_pos > 0:
#			select_option(current_pos-1)
#			move_sound_player.play()
func hard_arrange_all():
#	yield(get_tree(), "idle_frame")
#	yield(get_tree(), "idle_frame")
	print("HARD")
	if selected_option:
		if not prevent_hard_arrange:
			var menu_start := Vector2(0, rect_size.y * menu_start_percentage)
			
			if disable_repositioning:
				arrange_options(0, get_child_count(), 1.0, get_child(0).rect_position, get_child(0).rect_size.y, true)
			else:
				selected_option.rect_position = Vector2(menu_start.x, menu_start.y - selected_option.rect_size.y/2)
				selected_option.rect_scale = Vector2(1.0, 1.0)
				selected_option.target_opacity = 1.0
				selected_option.modulate.a = 1.0
				arrange_options(selected_option.get_position_in_parent()-1, -1, -1, selected_option.rect_position, selected_option.rect_size.y, true)
				arrange_options(selected_option.get_position_in_parent()+1, get_child_count(), 1.0, selected_option.rect_position, selected_option.rect_size.y, true)

func is_child_visible(child_i):
	var child = get_child(child_i)
	if child_i < selected_option.get_position_in_parent():
		return abs(selected_option.get_position_in_parent() - child.get_position_in_parent()) > VISIBILITY_THRESHOLD_TOP
	else:
		return abs(child.get_position_in_parent() - selected_option.get_position_in_parent()) > VISIBILITY_THRESHOLD_BOTTOM
	return true

func _draw():
	pass
#	var rect_first = Rect2(Vector2.ZERO, Vector2(rect_size.x, rect_size.y * menu_start_percentage))
#	var color_first = Color.green
#	color_first.a = 0.25
#
#	var rect_second = Rect2(Vector2(0, rect_size.y * menu_start_percentage), Vector2(rect_size.x, rect_size.y * (1.0- menu_start_percentage)))
#	var color_second = Color.blue
#	color_second.a = 0.25
#	draw_rect(rect_first, color_first, true, 1.0, true)
#	draw_rect(rect_second, color_second, true, 1.0, true)

func calculate_visibility_threshholds():
	if get_child_count() > 0:
		var child_size_y = get_child(0).rect_size.y
		menu_start_percentage = (((child_size_y*scale_factor)+margin) * (items_visible_top)  + child_size_y / 2.0) / rect_size.y
		var total_space = rect_size.y - child_size_y - margin
		var first = true
	#	for child in get_children():
	#		if child != selected_option:
	#			if not first:
	#				total_space -= margin
	#			else:
	#				first = false
		var child_size = (child_size_y  * scale_factor) +  margin
		var visible_item_count = floor(total_space / child_size) - 1
		VISIBILITY_THRESHOLD_TOP = items_visible_top
		VISIBILITY_THRESHOLD_BOTTOM = visible_item_count - items_visible_top + 1
		update()

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
		if is_child_visible(label.get_position_in_parent()):
			label.target_opacity = target_op
		else:
			target_op = 1.0
			label.target_opacity = target_op
		
		# Scale interpolation
		
		var target_scale = prev_child_scale * scale_factor
		if not label == selected_option:
			if fixed_scale_factor:
				target_scale = scale_factor
		else:
			target_scale = 1.0
		if instant_scale_change:
			label.rect_scale = Vector2(target_scale, target_scale)
		else:
			label.rect_scale = lerp(label.rect_scale, Vector2(target_scale, target_scale), lw)
		
		# Calculate the difference between where our label is and wher eit should be
		
		var pos_diff = Vector2(0, 0)
		if end > start:
			# Under the selected one, important to care about thep revious child's size
			pos_diff.y += (prev_child_size + margin) * prev_child_scale
		else:
			# Over the selected one, only care about our own size
			pos_diff.y += (label.rect_size.y + margin) * label.rect_scale.y
			
#		label.rect_position = lerp(label.rect_position, prev_child_pos + sign(end-start) * pos_diff, lw)
		label.rect_position = prev_child_pos + sign(end-start) * pos_diff # Looks much better if we don't interpolate position...
		if hard:
			label.target_opacity = target_op
			label.modulate.a = target_op
			label.rect_scale = Vector2(target_scale, target_scale)
		prev_child_pos = label.rect_position
		prev_child_scale = label.rect_scale.y
		prev_child_size = label.rect_size.y
