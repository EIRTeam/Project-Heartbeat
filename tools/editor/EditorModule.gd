extends Control

class_name HBEditorModule

signal shown_transform(transformation)
signal hidden_transform()
signal applied_transform(transformation)

var editor: HBEditor: set = set_editor
var undo_redo: UndoRedo

var shortcuts = []

@export var module_location: String # (String, "left_panel", "right_panel")
var parent: TabContainer
var tab_idx: int

@export var module_name: String

@export var priority: int

@export var button_group_name: String = "buttons"

@export var blocks_switch_to_inspector: bool = false

var transforms: Array
var _current_transform

func _ready():
	get_tree().call_group(button_group_name, "set_module", self)
	update_shortcuts()

func set_editor(_editor: HBEditor):
	editor = _editor
	undo_redo = _editor.undo_redo
	editor.connect("modules_update_settings", Callable(self, "song_editor_settings_changed"))
	editor.connect("modules_update_user_settings", Callable(self, "user_settings_changed"))
	
	# Add module to GUI
	if module_location:
		parent = editor.get_node(editor.ui_module_locations[module_location]) as TabContainer
		parent.add_child(self)
		tab_idx = parent.get_tab_count() - 1
		parent.set_tab_title(tab_idx, module_name)
	else:
		editor.add_child(self)
	
	connect("shown_transform", Callable(editor, "_show_transform_on_current_notes"))
	connect("hidden_transform", Callable(editor.game_preview.transform_preview, "_hide"))
	connect("applied_transform", Callable(editor, "_apply_transform_on_current_notes"))
	
	for transform in transforms:
		transform.set_editor(editor)

func song_editor_settings_changed(settings: HBPerSongEditorSettings):
	pass

func user_settings_changed():
	pass

func update_selected():
	pass

func _input(event: InputEvent):
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	
	if shortcuts_blocked():
		return
	
	if event is InputEventKey or event is InputEventMouseButton:
		for shortcut in shortcuts:
			if shortcut.control and shortcut.control.disabled:
				continue
			
			if event.is_action_pressed(shortcut.action, shortcut.echo, true):
				var function = Callable(self, shortcut.function)
				function.callv(shortcut.args)
				
				get_viewport().set_input_as_handled()
				break

func add_shortcut(action: String, function_name: String, vararg: Array = [], echo: bool = false, control = null):
	var shortcut = {"action": action, "function": function_name, "args": vararg, "echo": echo, "control": control}
	
	shortcuts.append(shortcut)

func update_shortcuts():
	for button in get_tree().get_nodes_in_group(button_group_name):
		if button.action:
			var action_list = InputMap.action_get_events(button.action)
			var event = action_list[0] if action_list else InputEventKey.new()
			var ev_text = get_event_text(event)
			
			button.update_shortcut(ev_text)

func get_event_text(event: InputEvent) -> String:
	return HBUtils.get_event_text(event)

func create_timing_point(layer: EditorLayer, item: EditorTimelineItem, force: bool = false):
	editor.user_create_timing_point(layer, item, force)

func add_item_to_layer(layer: EditorLayer, item: EditorTimelineItem):
	editor.add_item_to_layer(layer, item)

func remove_item_from_layer(layer: EditorLayer, item: EditorTimelineItem):
	editor.remove_item_from_layer(layer, item)

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

func force_game_process():
	editor.force_game_process()

func get_layers() -> Array:
	return editor.timeline.get_layers()

func find_layer_by_name(layer_name: String) -> EditorLayer:
	return editor.timeline.find_layer_by_name(layer_name)

func get_playhead_position() -> int:
	return editor.playhead_position

func get_selected() -> Array:
	return editor.selected

func get_timing_map() -> Array:
	return editor.get_timing_map()

func get_normalized_timing_map() -> Array:
	return editor.get_normalized_timing_map()

func get_signature_map() -> Array:
	return editor.get_signature_map()

func get_metronome_map() -> Array:
	return editor.get_metronome_map()

func get_timing_info_at_time(time: int) -> HBTimingChange:
	for timing_change in editor.get_timing_changes():
		if timing_change.data.time <= time:
			return timing_change.data
	
	return null

func get_time_as_eight(time: int) -> float:
	return editor.get_time_as_eight(time)

func get_speed_changes() -> Array:
	return editor.get_speed_changes()

func bsearch_upper(array: Array, value: int) -> int:
	return HBUtils.bsearch_upper(array, value)

func bsearch_closest(array: Array, value: int) -> int:
	return HBUtils.bsearch_closest(array, value)

func bsearch_linear(array: Array, value: int) -> float:
	return HBUtils.bsearch_linear(array, value)

func get_song_settings():
	return editor.song_editor_settings

func show_transform(id: int):
	emit_signal("shown_transform", transforms[id])
	_current_transform = id

func apply_transform(id: int):
	emit_signal("applied_transform", transforms[id])
	
	if _current_transform:
		show_transform(_current_transform)

# Having a catchall arg is stupid but we need it for drag_ended pokeKMS
func hide_transform(catchall = null):
	emit_signal("hidden_transform")
	_current_transform = null

func select_item(item: EditorTimelineItem, inclusive: bool = false):
	editor.select_item(item, inclusive)

func deselect_item(item: EditorTimelineItem):
	editor.deselect_item(item)

func select_all():
	editor.select_all()

func deselect_all():
	editor.deselect_all()

func shortcuts_blocked() -> bool:
	return editor.shortcuts_blocked()

func obscure_ui(extended: bool = true):
	editor.obscure_ui(extended)

func reveal_ui(extended: bool = true):
	editor.reveal_ui(extended)

func get_contextual_menu() -> HBEditorContextualMenuControl:
	return editor.contextual_menu

func get_time_being_hovered() -> int:
	return editor.timeline.get_time_being_hovered()

func get_items_at_time(time: int) -> Array:
	return editor.get_items_at_time(time)

func get_notes_at_time(time: int) -> Array:
	return editor.get_notes_at_time(time)

func get_timing_points() -> Array:
	return editor.get_timing_points()

func get_timeline_items() -> Array:
	return editor.get_timeline_items()

func sort_groups():
	editor.sort_groups()

func sort_items():
	editor.sort_current_items()

func snap_time_to_timeline(time: int):
	return editor.snap_time_to_timeline(time)
