tool
extends HBMenu

func _ready():
	$ToolsList/SongMetaEditorButton.connect("pressed", self, "_on_SongMetaEditorButton_pressed")
	$ToolsList/OpenSongsDirectoryButton.connect("pressed", self, "_on_OpenSongsDirectoryButton_pressed")
	$ToolsList/OpenLogsDirectoryButton.connect("pressed", self, "_on_OpenLogsDirectoryButton_pressed")
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	$ToolsList.grab_focus()

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		change_to_menu("main_menu")

func _on_SongMetaEditorButton_pressed():
	get_tree().change_scene_to(preload("res://tools/editor/Editor.tscn"))

func _on_OpenSongsDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path(HBUtils.join_path(UserSettings.user_settings.content_path, "songs")))


func _on_OpenLogsDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://logs"))
