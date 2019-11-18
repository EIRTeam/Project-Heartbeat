extends HBoxContainer

var selected_button
var selected_button_i
func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")
	focus_mode = Control.FOCUS_ALL
func select_button(i: int):
	var child = get_child(i)
	if selected_button:
		selected_button.stop_hover()
	if child is HBHorizontalButton:
		child.hover()
		selected_button = child
		selected_button_i = i

func _on_focus_entered():
	if get_child_count() > 0:
		select_button(0)
		
func _unhandled_input(event):
	if event.is_action_pressed("ui_left"):
		if selected_button:
			if selected_button_i == 0:
				if focus_neighbour_left:
					var neighbor_left = get_node(focus_neighbour_left) as Control
					neighbor_left.grab_focus()
			else:
				select_button(selected_button_i-1)
	elif event.is_action_pressed("ui_right"):
		if selected_button:
			if selected_button_i == get_child_count()-1:
				if focus_neighbour_right:
					var neighbour_right = get_node(focus_neighbour_right) as Control
					neighbour_right.grab_focus()
			else:
				select_button(selected_button_i+1)
	elif event.is_action_pressed("ui_accept"):
		if selected_button:
			selected_button.emit_signal("pressed")
func _on_focus_exited():
	if selected_button:
		selected_button.stop_hover()
		selected_button = null
		selected_button_i = 0
