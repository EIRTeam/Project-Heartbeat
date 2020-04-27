extends ScrollContainer

class_name HBScrollList

export(bool) var maintain_selected_child = false
export(bool) var page_skip_enabled = false
onready var vbox_container = get_node("VBoxContainer")

const INTERP_SPEED = 5
var scroll_target = 0.0
# Vertical scroll is separate because we need it to be a float
var current_scroll = 0.0
var selected_child
signal selected_child_changed
const BOTTOM_MARGIN = 50
const TOP_MARGIN = 50

signal out_from_top
signal out_from_bottom
signal option_hovered(option)
func _ready():
	connect("focus_entered", self, "_on_focus_entered")
	connect("focus_exited", self, "_on_focus_lost")
	_set_opacities(true)
	connect("resized", self, "_on_resized")

func _on_resized():
	yield(get_tree(), "idle_frame")
	if selected_child:
		select_child(selected_child, true)
func is_child_off_the_bottom(child):
	if child.rect_position.y + child.rect_size.y > scroll_target + rect_size.y:
		return true
	return false
	
func clear_children():
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
	selected_child = null
	
func is_child_off_the_top(child):
	if child.rect_position.y < scroll_target:
		return true
	return false
	
func deselect_child():
	if selected_child:
		selected_child.stop_hover()
	
func _on_focus_lost():
	deselect_child()
	
func select_child(child, hard = false):
	if not get_v_scrollbar().visible:
		scroll_target = 0
		current_scroll = scroll_target
	elif is_child_off_the_bottom(child):
		scroll_target = child.rect_position.y + child.rect_size.y - rect_size.y
		if hard:
			current_scroll = scroll_target
			scroll_vertical = scroll_target
	elif is_child_off_the_top(child):
		scroll_target = child.rect_position.y
		if hard:
			current_scroll = scroll_target
			scroll_vertical = scroll_target
	if selected_child:
		selected_child.stop_hover()
	selected_child = child
	selected_child.hover()
	_set_opacities(hard)
func _set_opacities(hard=false):
	for child in vbox_container.get_children():
		if child is BaseButton:
			if is_child_off_the_bottom(child) or is_child_off_the_top(child):
				child.target_opacity = 0
				if hard:
					child.modulate.a = 0
			else:
				child.target_opacity = 1.0
				if hard:
					child.modulate.a = 1.0

func _gui_input(event):
	if selected_child:
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
			var child_i = vbox_container.get_children().find(selected_child)
			if child_i == 0 and event.is_action_pressed("gui_up") and not event.is_echo():
				get_tree().set_input_as_handled()
				emit_signal("out_from_top")
			if child_i == vbox_container.get_child_count()-1 and event.is_action_pressed("gui_down") and not event.is_echo():
				get_tree().set_input_as_handled()
				emit_signal("out_from_bottom")
			if event.is_action_pressed("gui_down") and not event.is_echo() and child_i < vbox_container.get_child_count()-1:
				get_tree().set_input_as_handled()
				select_child(vbox_container.get_child(child_i+1))
				emit_signal("option_hovered", selected_child)
				$AudioStreamPlayer.play()
			if event.is_action_pressed("gui_up") and not event.is_echo() and child_i > 0:
				get_tree().set_input_as_handled()
				select_child(vbox_container.get_child(child_i-1))
				emit_signal("option_hovered", selected_child)
				$AudioStreamPlayer.play()
			if page_skip_enabled:
				if event.is_action_pressed("gui_left"):
					select_child(vbox_container.get_child(clamp(child_i-5, 0, vbox_container.get_child_count()-1)))
				if event.is_action_pressed("gui_right"):
					select_child(vbox_container.get_child(clamp(child_i+5, 0, vbox_container.get_child_count()-1)))
			if event.is_action_pressed("gui_accept"):
				get_tree().set_input_as_handled()
				selected_child.emit_signal("pressed")
		if not get_tree().is_input_handled():
			selected_child._gui_input(event)
				
func _process(delta):
	current_scroll = lerp(current_scroll, scroll_target, delta * INTERP_SPEED )
	scroll_vertical = current_scroll

func _on_focus_entered():
	if maintain_selected_child and selected_child:
		select_child(selected_child)
	else:
		scroll_vertical = 0
		scroll_target = 0
		current_scroll = 0
		for child in vbox_container.get_children():
			if child.has_method("hover"):
				
				select_child(child)
				_set_opacities(true)
				break
