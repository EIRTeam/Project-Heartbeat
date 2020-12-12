extends Node

class_name HBEditorPlugin

var _editor: HBEditor

const EDITOR_PLUGIN_TOOL_SCENE = preload("res://tools/editor/EditorPluginTool.tscn")

func _init(editor):
	_editor = editor

func add_button_to_tools_tab(button: BaseButton):
	_editor.add_button_to_tools_tab(button)
func add_tool_to_tools_tab(tool_control: Control, tool_name: String):
	var tool_scene = EDITOR_PLUGIN_TOOL_SCENE.instance()
	tool_scene.set_tool(tool_control, tool_name)
	_editor.add_tool_to_tools_tab(tool_scene)
func add_child_to_editor(child: Node):
	_editor.add_child(child)

func get_editor() -> HBEditor:
	return _editor

func show_error(error: String):
	_editor.show_error(error)

func get_selected_items():
	return _editor.selected

func get_contextual_menu() -> HBEditorContextualMenuControl:
	return _editor.contextual_menu
