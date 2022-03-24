extends BoxContainer

class_name HBSimpleMenu

var selected_button
var selected_button_i
enum ORIENTATION {
	HORIZONTAL,
	VERTICAL
}
export(bool) var stop_hover_on_focus_exit = true
export(ORIENTATION) var orientation = ORIENTATION.HORIZONTAL
signal hover(hovered_button)
signal bottom
signal out_from_top
var plays_sfx = true
var ignore_down = false # Ignore down action

var prev_action = "gui_left"
var next_action = "gui_right"

export var enable_wrap_around := false

func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_exited")
func select_button(i: int, fire_event=true):
	var child = get_child(i)
	if selected_button:
		selected_button.stop_hover()
	child.hover()
	if fire_event:
		emit_signal("hover", child)
	selected_button = child
	selected_button_i = i

func _on_focus_entered():
	if get_child_count() > 0:
		if selected_button and selected_button.visible:
			select_button(selected_button_i)
		else:
			for child_i in range(get_child_count()):
				var child = get_child(child_i)
				if child.visible and child is BaseButton:
					select_button(child_i)
					break

func _gui_input(event):
	var left_action = "gui_up"
	var right_action = "gui_down"
	if orientation == ORIENTATION.VERTICAL:
		next_action = "gui_down"
		prev_action = "gui_up"
		left_action = "gui_left"
		right_action = "gui_right"
		

	if orientation == ORIENTATION.VERTICAL:
		if selected_button_i == get_child_count() - 1:
			if event.is_action_pressed("gui_down"):
				get_tree().set_input_as_handled()
				emit_signal("bottom")
	if orientation == ORIENTATION.HORIZONTAL:
		if event.is_action_pressed("gui_up"):
			get_tree().set_input_as_handled()
			if focus_neighbour_top:
				var neighbor_up = get_node(focus_neighbour_top) as Control
				neighbor_up.grab_focus()
				ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")

	if event.is_action_pressed(prev_action):
		if selected_button:
			if selected_button_i == 0 and not enable_wrap_around:
				get_tree().set_input_as_handled()
				if orientation == ORIENTATION.HORIZONTAL:
					if focus_neighbour_left:
						var neighbor_left = get_node(focus_neighbour_left) as Control
						neighbor_left.grab_focus()
						ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")
				else:
					if focus_neighbour_top:
						var neighbor_up = get_node(focus_neighbour_top) as Control
						neighbor_up.grab_focus()
						ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")
				emit_signal("out_from_top")
			else:
				get_tree().set_input_as_handled()
				var i = wrapi(selected_button_i-1, 0, get_child_count())
				while i >= 0:
					if get_child(i).visible and get_child(i) is BaseButton:
						select_button(i)
						ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")
						break
					i -= 1

	elif event.is_action_pressed(next_action):
		if selected_button:
			if selected_button_i == get_child_count()-1 and not enable_wrap_around:
				get_tree().set_input_as_handled()
				if orientation == ORIENTATION.HORIZONTAL:
					if focus_neighbour_right:
						var neighbor_right = get_node(focus_neighbour_right) as Control
						neighbor_right.grab_focus()
						ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")
				else:
					if focus_neighbour_bottom:
						var neighbor_bottom = get_node(focus_neighbour_bottom) as Control
						neighbor_bottom.grab_focus()
						ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")
			else:
				get_tree().set_input_as_handled()
				var i = wrapi(selected_button_i+1, 0, get_child_count())
				while i <= get_child_count()-1:
					if get_child(i).visible and get_child(i) is BaseButton:
						select_button(i)
						ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")
						break
					i += 1
	elif event.is_action_pressed("gui_accept"):
		if selected_button:
			get_tree().set_input_as_handled()
			var sfx_type = HBGame.MENU_FORWARD_SFX
			if selected_button.has_meta("sfx"):
				sfx_type = selected_button.get_meta("sfx")
			if not sfx_type.empty():
				ShinobuGodot.fire_and_forget_sound(sfx_type, "sfx")
			selected_button.emit_signal("pressed")
	elif event.is_action_pressed("gui_down")  and not ignore_down:
		get_tree().set_input_as_handled()
		emit_signal("bottom")
	elif event.is_action_pressed(right_action):
		if orientation == ORIENTATION.VERTICAL:
			if focus_neighbour_right:
				var neighbor_right = get_node(focus_neighbour_right) as Control
				neighbor_right.grab_focus()
		else:
			if focus_neighbour_top:
				var neighbor_up = get_node(focus_neighbour_top) as Control
				neighbor_up.grab_focus()
	elif event.is_action_pressed(left_action):
		if orientation == ORIENTATION.VERTICAL:
			if focus_neighbour_left:
				var neighbor_left = get_node(focus_neighbour_left) as Control
				neighbor_left.grab_focus()
		else:
			if focus_neighbour_bottom:
				var neighbor_bottom = get_node(focus_neighbour_bottom) as Control
				neighbor_bottom.grab_focus()
func _on_focus_exited():
	if selected_button:
		if stop_hover_on_focus_exit:
			selected_button.stop_hover()

func _on_button_pressed(button: BaseButton):
	select_button(button.get_position_in_parent())

func add_child(new_n, legible_u_name = false):
	.add_child(new_n, legible_u_name)
	if new_n is BaseButton:
		new_n.focus_mode = Control.FOCUS_NONE
		new_n.connect("pressed", self, "_on_button_pressed", [new_n])
	
