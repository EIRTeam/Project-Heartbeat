extends Control

class_name HBEditorModule

var editor: HBEditor setget set_editor

var shortcuts = []

export var module_location: String
var parent: TabContainer
var tab_idx: int

export var module_name: String

func set_editor(_editor: HBEditor):
	editor = _editor
	
	# Add module to GUI
	parent = editor.get_node(editor.ui_module_locations[module_location]) as TabContainer
	parent.add_child(self)
	tab_idx = parent.get_tab_count() - 1
	parent.set_tab_title(tab_idx, module_name)

func _unhandled_input(event):
	for shortcut in shortcuts:
		if event.is_action_pressed(shortcut.action, shortcut.echo, true):
			var function = FuncRef.new()
			function.set_function(shortcut.function)
			function.set_instance(self)
			function.call_func()
			break

func add_shortcut(action: String, function, control: Control = null, echo: bool = false):
	var shortcut = {"action": action, "function": function, "control": control, "echo": echo}
	if control:
		shortcut.default_hint = control.hint_tooltip
	
	shortcuts.append(shortcut)

func update_shortcuts():
	for shortcut in shortcuts:
		if shortcut.control:
			var action_list = InputMap.get_action_list(shortcut.action)
			var event = action_list[0] if action_list else InputEventKey.new()
			var ev_text = event.as_text()
			if "Kp " in ev_text:
				ev_text = ev_text.replace("Kp ", "Keypad ")
			
			shortcut.control.hint_tooltip = shortcut.default_hint
			shortcut.control.hint_tooltip += "\nShortcut: " + ev_text

func create_timing_point(layer, item: EditorTimelineItem):
	editor.user_create_timing_point(layer, item)

func get_layers():
	return editor.timeline.get_layers()

func get_playhead_position():
	return editor.playhead_position
