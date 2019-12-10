tool
extends HBMenu

func _ready():
	$ToolsList/EditorButton.connect("pressed", self, "_on_EditorButton_pressed")
	$ToolsList/SongMetaEditorButton.connect("pressed", self, "_on_SongMetaEditorButton_pressed")
	$ToolsList/OpenSongsDirectoryButton.connect("pressed", self, "_on_OpenSongsDirectoryButton_pressed")
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	$ToolsList.grab_focus()


func _on_EditorButton_pressed():
	get_tree().change_scene_to(preload("res://tools/editor/Editor.tscn"))

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		change_to_menu("main_menu")

func _on_SongMetaEditorButton_pressed():
	get_tree().change_scene_to(preload("res://tools/song_meta_editor/SongMetaEditor.tscn"))

func _on_OpenSongsDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://songs"))
