class_name HBEditorPlugin

var _editor: HBEditor

func _init(editor):
	_editor = editor

func add_button_to_tools_tab(button: BaseButton):
	_editor.add_button_to_tools_tab(button)

func add_child_to_editor(child: Node):
	_editor.add_child(child)

func get_editor() -> HBEditor:
	return _editor
