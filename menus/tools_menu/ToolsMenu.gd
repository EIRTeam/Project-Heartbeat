tool
extends HBMenu

func _ready():
	$ToolsList/SongMetaEditorButton.connect("pressed", self, "_on_SongMetaEditorButton_pressed")
	$ToolsList/OpenSongsDirectoryButton.connect("pressed", self, "_on_OpenSongsDirectoryButton_pressed")
	$ToolsList/OpenLogsDirectoryButton.connect("pressed", self, "_on_OpenLogsDirectoryButton_pressed")
	$ToolsList/OpenUserDirectoryButton.connect("pressed", self, "_on_OpenUserDirectoryButton_pressed")
	$ToolsList/PPDManagerButton.connect("pressed", self, "_on_PPDDownloaderButton_pressed")
	$ToolsList/ResourcePackEditorButton.connect("pressed", self, "_on_ResourcePackEditorButton_pressed")
	$ToolsList/SwitchExporterButton.connect("pressed", self, "_on_SwitchExporterButton_pressed")
	$ToolsList/LatencyCalculatorButton.connect("pressed", self, "_on_LatencyCalculatorButton_pressed")
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	$ToolsList.grab_focus()

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		change_to_menu("main_menu")

func _on_SongMetaEditorButton_pressed():
	var new_scene = load("res://tools/editor/Editor.tscn")
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene

func _on_OpenSongsDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path(HBUtils.join_path(UserSettings.user_settings.content_path, "songs")))


func _on_OpenLogsDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://logs"))

func _on_OpenUserDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func _on_PPDDownloaderButton_pressed():
	get_tree().change_scene_to(load("res://tools/PPDManager/PPDManager.tscn"))

func _on_ResourcePackEditorButton_pressed():
	get_tree().change_scene_to(load("res://tools/resource_pack_editor/ResourcePackEditor.tscn"))

func _on_SwitchExporterButton_pressed():
	get_tree().change_scene_to(load("res://tools/SwitchExporter/SwitchExporter.tscn"))

func _on_LatencyCalculatorButton_pressed():
	change_to_menu("latency_tester")
