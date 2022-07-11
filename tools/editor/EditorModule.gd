extends Control

class_name HBEditorModule

signal show_transform(transformation)
signal hide_transform()
signal apply_transform(transformation)

var editor: HBEditor setget set_editor
var undo_redo: UndoRedo

var shortcuts = []

export(String, "left_panel", "right_panel") var module_location
var parent: TabContainer
var tab_idx: int

export(String) var module_name

export(int) var priority

export(String) var button_group_name = "buttons"

var transforms: Array

func _ready():
	get_tree().call_group(button_group_name, "set_module", self)
	update_shortcuts()

func set_editor(_editor: HBEditor):
	editor = _editor
	undo_redo = _editor.undo_redo
	editor.connect("modules_update_settings", self, "song_editor_settings_changed")
	
	# Add module to GUI
	parent = editor.get_node(editor.ui_module_locations[module_location]) as TabContainer
	parent.add_child(self)
	tab_idx = parent.get_tab_count() - 1
	parent.set_tab_title(tab_idx, module_name)
	
	connect("show_transform", editor, "_show_transform_on_current_notes")
	connect("hide_transform", editor.game_preview.transform_preview, "hide")
	connect("apply_transform", editor, "_apply_transform_on_current_notes")
	
	for transform in transforms:
		transform.set_editor(editor)

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

func add_shortcut(action: String, function_name: String, vararg: Array = [], echo: bool = false):
	var shortcut = {"action": action, "function": function_name, "args": vararg, "echo": echo}
	
	shortcuts.append(shortcut)

func update_shortcuts():
	for button in get_tree().get_nodes_in_group(button_group_name):
		if button.action:
			var action_list = InputMap.get_action_list(button.action)
			var event = action_list[0] if action_list else InputEventKey.new()
			var ev_text = get_event_text(event)
			
			button.update_shortcut(ev_text)

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

func timing_information_changed():
	editor._on_timing_information_changed()

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

func show_transform(id: int):
	emit_signal("show_transform", transforms[id])

func apply_transform(id: int):
	emit_signal("apply_transform", transforms[id])

# Having a catchall arg is stupid but we need it for drag_ended pokeKMS
func hide_transform(catchall = null):
	emit_signal("hide_transform")
