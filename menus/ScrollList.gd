extends ScrollContainer

class_name HBScrollList

export(bool) var maintain_selected_child = false

onready var vbox_container = get_node("MarginContainer/VBoxContainer")
const INTERP_SPEED = 5
export(float) var visible_items = 3 # Items that will be visible after the selected one, if possible
var scroll_target = 0.0
# Vertical scroll is separate because we need it to be a float
var current_scroll = 0.0
var selected_child
signal selected_child_changed
const BOTTOM_MARGIN = 50
const TOP_MARGIN = 50

signal option_hovered(option)
func _ready():
	connect("focus_entered", self, "_on_focus_entered")


func select_child(child):
	if selected_child:
		selected_child.stop_hover()
	selected_child = child
	child.hover()

	var child_i = vbox_container.get_children().find(child)


	# Get the next N children (see visible items)

	var next_children = []
	var next_children_size = 0
	if child_i < vbox_container.get_child_count()-1:
		for i in range(child_i+1, clamp(vbox_container.get_child_count(), child_i, child_i+visible_items+1)):
			if vbox_container.get_child(i) is BaseButton:
				next_children.append(vbox_container.get_child(i))

	if next_children.size() > 0:
		var next_child = next_children[next_children.size()-1]

		next_children_size = (next_child.rect_position.y + next_child.rect_size.y) - (child.rect_position.y + child.rect_size.y)
	# Child is not visible (from bottom)
	if child.rect_position.y + child.rect_size.y + next_children_size - rect_size.y + TOP_MARGIN + BOTTOM_MARGIN - vbox_container.get_constant("separation") > scroll_vertical:
		scroll_target = child.rect_position.y - rect_size.y + child.rect_size.y + next_children_size + TOP_MARGIN + BOTTOM_MARGIN - vbox_container.get_constant("separation")

	# Get the previous n children (see visible items)

	var prev_children = []
	var prev_children_size = 0

	if vbox_container.get_child_count() > 1:
		for i in range(clamp(child_i-visible_items, 0, vbox_container.get_child_count()-1), child_i):
			if vbox_container.get_child(i) is BaseButton:
				prev_children.append(vbox_container.get_child(i))
				break
	if prev_children.size() > 0:
		var prev_child = prev_children[0]

		prev_children_size =  child.rect_position.y - prev_child.rect_position.y

	# Child is not visible (from top)
	if child.rect_position.y - prev_children_size - TOP_MARGIN < scroll_vertical:
		scroll_target = child.rect_position.y - prev_children_size - TOP_MARGIN

	_set_opacities()

func _set_opacities():
	for child in vbox_container.get_children():
		if child is BaseButton:
			if child.rect_position.y + TOP_MARGIN < scroll_target or child.rect_position.y + child.rect_size.y + BOTTOM_MARGIN - vbox_container.get_constant("separation") > scroll_target + rect_size.y:
				child.target_opacity = 0
			else:
				child.target_opacity = 1.0

func _gui_input(event):
	if selected_child:
		if event is InputEventKey or event is InputEventJoypadButton:
			var child_i = vbox_container.get_children().find(selected_child)
			if event.is_action_pressed("ui_down") and not event.is_echo() and child_i < vbox_container.get_child_count()-1:
				select_child(vbox_container.get_child(child_i+1))
				emit_signal("option_hovered", selected_child)
				$AudioStreamPlayer.play()
				get_tree().set_input_as_handled()
			if event.is_action_pressed("ui_up") and not event.is_echo() and child_i > 0:
				select_child(vbox_container.get_child(child_i-1))
				emit_signal("option_hovered", selected_child)
				$AudioStreamPlayer.play()
				get_tree().set_input_as_handled()
			if event.is_action_pressed("ui_accept"):
				get_tree().set_input_as_handled()
				selected_child.emit_signal("pressed")
				get_tree().set_input_as_handled()
func _process(delta):
	current_scroll = lerp(current_scroll, scroll_target, delta * INTERP_SPEED )
	scroll_vertical = current_scroll
	if get_v_scrollbar():
		get_v_scrollbar().rect_size.y = rect_size.y - BOTTOM_MARGIN - TOP_MARGIN + vbox_container.get_constant("separation")
		get_v_scrollbar().rect_position.y = TOP_MARGIN
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
				break

