extends BoxContainer

var selected_button
var selected_button_i
enum ORIENTATION {
	HORIZONTAL,
	VERTICAL
}
export(bool) var stop_hover_on_focus_exit = true
export(ORIENTATION) var orientation = ORIENTATION.HORIZONTAL
signal hover(hovered_button)
signal back
signal bottom
func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")
func select_button(i: int):
	var child = get_child(i)
	if selected_button:
		selected_button.stop_hover()
	child.hover()
	emit_signal("hover", child)
	selected_button = child
	selected_button_i = i

func _on_focus_entered():
	if get_child_count() > 0:
		if selected_button:
			select_button(selected_button_i)
		else:
			select_button(0)

func _gui_input(event):
	var next_action = "gui_right"
	var prev_action = "gui_left"
	var down_action = "gui_down"
	var up_action = "up_action"
	if orientation == ORIENTATION.VERTICAL:
		next_action = "gui_down"
		prev_action = "gui_up"

	if event.is_action_pressed(down_action):
		if orientation == ORIENTATION.VERTICAL:
			if selected_button_i == get_child_count()-1:
				get_tree().set_input_as_handled()
				emit_signal("bottom")
		else:
			get_tree().set_input_as_handled()
			emit_signal("bottom")

	if event.is_action_pressed(prev_action):
		if selected_button:
			if selected_button_i == 0:
				if focus_neighbour_left:
					get_tree().set_input_as_handled()
					var neighbor_left = get_node(focus_neighbour_left) as Control
					neighbor_left.grab_focus()
			else:
				get_tree().set_input_as_handled()
				select_button(selected_button_i-1)

	elif event.is_action_pressed(next_action):
		if selected_button:
			if selected_button_i == get_child_count()-1:
				if focus_neighbour_right:
					get_tree().set_input_as_handled()
					var neighbour_right = get_node(focus_neighbour_right) as Control
					neighbour_right.grab_focus()
			else:
				get_tree().set_input_as_handled()
				select_button(selected_button_i+1)
	elif event.is_action_pressed("gui_accept"):
		if selected_button:
			get_tree().set_input_as_handled()
			selected_button.emit_signal("pressed")
func _on_focus_exited():
	if selected_button:
		if stop_hover_on_focus_exit:
			selected_button.stop_hover()
