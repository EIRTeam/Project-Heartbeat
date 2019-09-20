extends Control


var selected_option : Control
const VISIBILITY_THRESHOLD = 3 # How many items should be visible
func _ready():
	if get_child_count() > 0:
		selected_option = get_child(0)

func _process(delta):
	var menu_start := Vector2(0, rect_size.y / 2)
	
	var children = get_children()
	if selected_option:
		# Place select option:
		selected_option.rect_position = lerp(selected_option.rect_position, Vector2(menu_start.x, menu_start.y - selected_option.rect_size.y/2), 0.5)
		selected_option.rect_scale = Vector2(1.0, 1.0)
		selected_option.self_modulate = lerp(selected_option.self_modulate, Color(1.0, 1.0, 1.0, 1.0), 0.5)
		var prev_child_pos = selected_option.rect_position
		var prev_child_scale = selected_option.rect_scale.y
		arrange_options(selected_option.get_position_in_parent()-1, -1, -1, selected_option.rect_position, selected_option.rect_size.y)
		arrange_options(selected_option.get_position_in_parent()+1, get_child_count(), 1.0, selected_option.rect_position, selected_option.rect_size.y)

func _input(event):
	if selected_option:
		if event.is_action_pressed("ui_down"):
			var current_pos = selected_option.get_position_in_parent()
			if current_pos < get_child_count()-1:
				selected_option = get_child(current_pos + 1)
		if event.is_action_pressed("ui_up"):
			var current_pos = selected_option.get_position_in_parent()
			if current_pos > 0:
				selected_option = get_child(current_pos - 1)

func arrange_options(start, end, step, start_position, start_size):
	var children = get_children()
	var prev_child_scale = 1.0
	var prev_child_pos = start_position
	var prev_child_size = start_size
	for i in range(start, end, step):
		print("child", i)

		var label = children[i]
		
		if (abs(selected_option.get_position_in_parent() - label.get_position_in_parent()) > VISIBILITY_THRESHOLD):
			label.self_modulate = lerp(label.self_modulate, Color(1.0, 1.0, 1.0, 0.0), 0.1)
		else:
			label.self_modulate = lerp(label.self_modulate, Color(1.0, 1.0, 1.0, 1.0), 0.1)
		
		var target_scale = prev_child_scale * 0.85
		label.rect_scale = lerp(label.rect_scale, Vector2(target_scale, target_scale), 0.5)
		print(label.rect_scale)
		var pos_diff = Vector2(0, 0)
		if end > start:
			# Under the selected one
			pos_diff.y += prev_child_size * prev_child_scale
		else:
			# Over the selected one
			pos_diff.y += label.rect_size.y * label.rect_scale.y
		label.rect_position = lerp(label.rect_position, prev_child_pos + sign(end-start) * pos_diff, 0.5)
		
		prev_child_pos = label.rect_position
		prev_child_scale = label.rect_scale.y
		prev_child_size = label.rect_size.y
