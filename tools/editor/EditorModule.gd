extends Control

class_name HBEditorModule

var editor: HBEditor setget set_editor
var undo_redo: UndoRedo

var shortcuts = []

export var module_location: String
var parent: TabContainer
var tab_idx: int

export var module_name: String

func set_editor(_editor: HBEditor):
	editor = _editor
	undo_redo = _editor.undo_redo
	editor.connect("modules_update_settings", self, "song_editor_settings_changed")
	
	# Add module to GUI
	parent = editor.get_node(editor.ui_module_locations[module_location]) as TabContainer
	parent.add_child(self)
	tab_idx = parent.get_tab_count() - 1
	parent.set_tab_title(tab_idx, module_name)

func song_editor_settings_changed(settings: HBPerSongEditorSettings):
	pass

func _input(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton:
		for shortcut in shortcuts:
			if event.is_action_pressed(shortcut.action, shortcut.echo, true):
				var function = FuncRef.new()
				function.set_function(shortcut.function)
				function.set_instance(self)
				function.call_funcv(shortcut.args)
				break

func add_shortcut(action: String, function_name: String, control: Control = null, vararg: Array = [], echo: bool = false):
	var shortcut = {"action": action, "function": function_name, "control": control, "args": vararg, "echo": echo}
	if control:
		shortcut.default_hint = control.hint_tooltip
	
	shortcuts.append(shortcut)

func update_shortcuts():
	for shortcut in shortcuts:
		if shortcut.control:
			var action_list = InputMap.get_action_list(shortcut.action)
			var event = action_list[0] if action_list else InputEventKey.new()
			var ev_text = get_event_text(event)
			
			shortcut.control.hint_tooltip = shortcut.default_hint
			shortcut.control.hint_tooltip += "\nShortcut: " + ev_text

func get_event_text(event: InputEvent):
	var text = ""
	
	if event is InputEventKey:
		text = event.as_text()
		if "Kp " in text:
			text = text.replace("Kp ", "Keypad ")
	elif event is InputEventMouseButton:
		text = "Mouse %d" % event.button_index
	
	return text

func create_timing_point(layer, item: EditorTimelineItem):
	editor.user_create_timing_point(layer, item)

func change_selected_property_single_item(item, property_name: String, new_value):
	editor._change_selected_property_single_item(item, property_name, new_value)

func commit_selected_property_change(property_name: String, create_action: bool = true):
	editor._commit_selected_property_change(property_name, create_action)

func timing_points_changed():
	editor._on_timing_points_changed()

func timing_points_params_changed():
	editor._on_timing_points_params_changed()

func sync_inspector_values():
	editor.inspector.sync_visible_values_with_data()

func get_layers():
	return editor.timeline.get_layers()

func get_playhead_position():
	return editor.playhead_position

func get_selected():
	return editor.selected

func get_timing_interval(note_resolution=null):
	return editor.get_timing_interval(note_resolution)

func get_bpm():
	return editor.get_bpm()

func get_song_settings():
	return editor.song_editor_settings
