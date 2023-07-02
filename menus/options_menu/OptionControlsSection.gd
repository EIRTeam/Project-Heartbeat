extends Control

signal back

@onready var scroll_container = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/ScrollContainer")
const ACTION_SCENE = preload("res://menus/options_menu/OptionControlsSectionAction.tscn")
const EVENT_SCENE = preload("res://menus/options_menu/OptionControlsSectionEvent.tscn")
const RESET_SCENE = preload("res://menus/options_menu/OptionControlsSectionReset.tscn")
@onready var bind_popup = get_node("Popup")
@onready var reset_confirmation_window = get_node("ResetConfirmationWindow")
@onready var category_container = get_node("VBoxContainer/Panel2/MarginContainer/VBoxContainer/CategoryContainer")
var action_being_bound = ""
@onready var action_bind_debounce := Timer.new()

func _unhandled_input(event):
	if visible:
		if action_being_bound and action_bind_debounce.is_stopped():
			if not event.is_pressed() or event.is_echo():
				return
			# we can only bind inputs from the selected controller device
			if (event is InputEventJoypadButton or event is InputEventJoypadMotion) \
					and event.device != UserSettings.controller_device_idx:
				return
			if event is InputEventJoypadMotion and action_being_bound in UserSettings.DISABLE_ANALOG_FOR_ACTION:
				return
			if InputMap.action_has_event(action_being_bound, event):
				action_being_bound = ""
				bind_popup.hide()
				scroll_container.grab_focus()
				return
			if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
				get_viewport().set_input_as_handled()
				if event.is_pressed() and not event.is_echo():
					add_event_user(action_being_bound, event)
					bind_popup.hide()
					action_being_bound = ""
					scroll_container.grab_focus()
		elif event.is_action_pressed("gui_cancel"):
			if get_viewport().gui_get_focus_owner() == scroll_container:
				get_viewport().set_input_as_handled()
				HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
				emit_signal("back")
				if scroll_container.get_selected_item():
					scroll_container.get_selected_item().stop_hover()
				populate()
				show_category(UserSettings.ACTION_CATEGORIES.keys()[0], true)
		elif (event.is_action_pressed("gui_left") or event.is_action_pressed("gui_right")) and scroll_container.has_focus():
			get_viewport().set_input_as_handled()
			category_container._gui_input(event)
		else:
			var si = scroll_container.get_selected_item()
			if si:
				si._gui_input(event)

func _ready():
	populate()
	show_category(UserSettings.ACTION_CATEGORIES.keys()[0], true)
	connect("focus_entered", Callable(self, "_on_focus_entered"))
	focus_mode = Control.FOCUS_ALL
	reset_confirmation_window.connect("accept", Callable(self, "_on_reset_bindings_confirmed"))
	reset_confirmation_window.connect("cancel", Callable(self, "grab_focus"))
	add_child(action_bind_debounce)
	action_bind_debounce.one_shot = true
	action_bind_debounce.wait_time = 0.15
func populate():
	for child in category_container.get_children():
		category_container.remove_child(child)
		child.queue_free()
		
	for category in UserSettings.ACTION_CATEGORIES:
		var button = HBHovereableButton.new()
		button.text = category
		category_container.add_child(button)
		button.connect("hovered", Callable(self, "show_category").bind(category))
		
var current_category = ""
		
func show_category(category: String, prevent_selection=false):
	var children = scroll_container.item_container.get_children()
	for child in children:
		scroll_container.item_container.remove_child(child)
		child.queue_free()
		
	var reset_scene = RESET_SCENE.instantiate()
	reset_scene.connect("pressed", Callable(self, "_on_reset_bindings"))
	scroll_container.item_container.add_child(reset_scene)
	var input_map = UserSettings.get_input_map()
	current_category = category
	for action_name in UserSettings.ACTION_CATEGORIES[category]:
		var action_scene = ACTION_SCENE.instantiate()
		action_scene.action = UserSettings.action_names[action_name]
		action_scene.action_name = action_name
		scroll_container.item_container.add_child(action_scene)
		action_scene.connect("pressed", Callable(self, "_on_action_add_press").bind(action_name))
		for event in input_map[action_name]:
			if event is InputEventKey and action_name in UserSettings.HIDE_KB_REMAPS_ACTIONS:
				continue
			var event_scene = EVENT_SCENE.instantiate()
			scroll_container.item_container.add_child(event_scene)
			event_scene.action = action_name
			event_scene.event = event
			event_scene.connect("pressed", Callable(self, "_on_event_delete").bind(event_scene, action_name, event))
	if not prevent_selection:
		scroll_container.select_item(0)
func _on_action_add_press(action_name):
	# To prevent double presses from being picked up
	action_bind_debounce.start()
	bind_popup.popup_centered()
	action_being_bound = action_name
	grab_focus()
	
func _on_event_delete(control, action, event):
	if InputMap.action_has_event(action, event):
		InputMap.action_erase_event(action, event)
		var position = control.get_index() -1
		scroll_container.select_item(position)
		control.queue_free()
		UserSettings.save_user_settings()
func _on_focus_entered():
	if not action_being_bound:
		category_container.selected_button = null
		category_container.selected_button_i = null
		category_container.select_button(0, false)
		scroll_container.grab_focus()

func add_event_user(action_name, event):
	var action_control = scroll_container.get_selected_item()
	var action_control_i = action_control.get_index()
	var child_count = scroll_container.item_container.get_child_count()
	var event_scene = EVENT_SCENE.instantiate()

	event_scene.event = event
	event_scene.connect("pressed", Callable(self, "_on_event_delete").bind(event_scene, action_name, event))
	scroll_container.item_container.add_child(event_scene)
	if action_control_i < child_count-2: # -2 because we just added the event scene
		for control_i in range(action_control_i+1, child_count):
			var control = scroll_container.item_container.get_child(control_i)
			if control is HBOptionControlsSectionAction:
				scroll_container.item_container.move_child(event_scene, control_i)
				break
	InputMap.action_add_event(action_name, event)
	UserSettings.save_user_settings()
func _on_reset_bindings():
	reset_confirmation_window.popup_centered()

func _on_reset_bindings_confirmed():
	UserSettings.reset_to_default_input_map()
	populate()
	show_category(current_category)
	scroll_container.select_item(0)
	grab_focus()
	UserSettings.save_user_settings()
