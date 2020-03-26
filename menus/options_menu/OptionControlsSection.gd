extends Control

signal back

onready var scroll_container = get_node("VBoxContainer/Panel2/MarginContainer/ScrollContainer")
const ACTION_SCENE = preload("res://menus/options_menu/OptionControlsSectionAction.tscn")
const EVENT_SCENE = preload("res://menus/options_menu/OptionControlsSectionEvent.tscn")
const RESET_SCENE = preload("res://menus/options_menu/OptionControlsSectionReset.tscn")
onready var bind_popup = get_node("Popup")
onready var reset_confirmation_window = get_node("ResetConfirmationWindow")
var action_being_bound = ""

func _unhandled_input(event):
	if visible:
		if action_being_bound:
			if event is InputEventJoypadMotion and not action_being_bound in UserSettings.ANALOG_ACTIONS:
				return
			if InputMap.action_has_event(action_being_bound, event):
				return
			if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
				get_tree().set_input_as_handled()
				if event.is_pressed() and not event.is_echo():
					if not event.is_action_pressed("gui_cancel"):
						# We find the action control and add the new event
						add_event_user(action_being_bound, event)
					bind_popup.hide()
					action_being_bound = ""
					scroll_container.grab_focus()
		elif event.is_action_pressed("gui_cancel"):
			if get_focus_owner() == scroll_container:
				get_tree().set_input_as_handled()
				emit_signal("back")
				if scroll_container.selected_child:
					scroll_container.selected_child.stop_hover()
		else:
			if scroll_container.selected_child:
				scroll_container.selected_child._gui_input(event)

func _ready():
	populate()
	connect("focus_entered", self, "_on_focus_entered")
	focus_mode = Control.FOCUS_ALL
	reset_confirmation_window.connect("accept", self, "_on_reset_bindings_confirmed")
	reset_confirmation_window.connect("cancel", self, "grab_focus")
func populate():
	scroll_container.selected_child = null
	var children = scroll_container.vbox_container.get_children()
	for child in children:
		scroll_container.vbox_container.remove_child(child)
		child.queue_free()
		
	var reset_scene = RESET_SCENE.instance()
	reset_scene.connect("pressed", self, "_on_reset_bindings")
	scroll_container.vbox_container.add_child(reset_scene)
	var input_map = UserSettings.get_input_map()
	for action_name in input_map:
		var action_scene = ACTION_SCENE.instance()
		action_scene.action = UserSettings.action_names[action_name]
		scroll_container.vbox_container.add_child(action_scene)
		action_scene.connect("pressed", self, "_on_action_add_press", [action_name])
		for event in input_map[action_name]:
			if event is InputEventKey and action_name in UserSettings.HIDE_KB_REMAPS_ACTIONS:
				continue
			var event_scene = EVENT_SCENE.instance()
			scroll_container.vbox_container.add_child(event_scene)
			event_scene.event = event
			event_scene.connect("pressed", self, "_on_event_delete", [event_scene, action_name, event])
func _on_action_add_press(action_name):
	
	bind_popup.popup_centered()
	action_being_bound = action_name
	grab_focus()
	
func _on_event_delete(control, action, event):
	if InputMap.action_has_event(action, event):
		InputMap.action_erase_event(action, event)
		var position = control.get_position_in_parent() -1
		scroll_container.select_child(scroll_container.vbox_container.get_child(position))
		control.queue_free()
func _on_focus_entered():
	if not action_being_bound:
		scroll_container.grab_focus()

func add_event_user(action_name, event):
	var action_control = scroll_container.selected_child
	var action_control_i = action_control.get_position_in_parent()
	var child_count = scroll_container.vbox_container.get_child_count()
	var event_scene = EVENT_SCENE.instance()

	event_scene.event = event
	event_scene.connect("pressed", self, "_on_event_delete", [event_scene, action_name, event])
	scroll_container.vbox_container.add_child(event_scene)
	if action_control_i < child_count-2: # -2 because we just added the event scene
		for control_i in range(action_control_i+1, child_count):
			var control = scroll_container.vbox_container.get_child(control_i)
			if control is HBOptionControlsSectionAction:
				scroll_container.vbox_container.move_child(event_scene, control_i)
				break
	InputMap.action_add_event(action_name, event)

func _on_reset_bindings():
	reset_confirmation_window.popup_centered()

func _on_reset_bindings_confirmed():
	UserSettings.reset_to_default_input_map()
	populate()
	scroll_container.select_child(scroll_container.vbox_container.get_child(0))
	grab_focus()
