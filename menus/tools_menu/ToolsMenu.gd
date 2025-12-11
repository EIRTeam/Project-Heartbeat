@tool
extends HBMenu

func _ready():
	super._ready()
	$ToolsList/SongMetaEditorButton.pressed.connect(_on_SongMetaEditorButton_pressed)
	$ToolsList/OpenSongsDirectoryButton.pressed.connect(_on_OpenSongsDirectoryButton_pressed)
	$ToolsList/OpenLogsDirectoryButton.pressed.connect(_on_OpenLogsDirectoryButton_pressed)
	$ToolsList/OpenUserDirectoryButton.pressed.connect(_on_OpenUserDirectoryButton_pressed)
	$ToolsList/PPDManagerButton.pressed.connect(_on_PPDDownloaderButton_pressed)
	$ToolsList/ResourcePackEditorButton.pressed.connect(_on_ResourcePackEditorButton_pressed)
	$ToolsList/LatencyCalculatorButton.pressed.connect(_on_LatencyCalculatorButton_pressed)
	$ToolsList/OOBDebugButton.pressed.connect(change_to_menu.bind("oob"))
	$ToolsList/ExporterButton.pressed.connect(_on_exporter_button_pressed)
func _on_menu_enter(force_hard_transition=false, args = {}):
	super._on_menu_enter(force_hard_transition, args)
	$ToolsList.grab_focus()

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
		change_to_menu("main_menu")

func _on_SongMetaEditorButton_pressed():
	var new_scene = load("res://tools/editor/Editor.tscn")
	var scene = new_scene.instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene

func _on_OpenSongsDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path(HBUtils.join_path(HBGame.content_dir, "songs")))


func _on_OpenLogsDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://logs"))

func _on_OpenUserDirectoryButton_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))

func _on_PPDDownloaderButton_pressed():
	get_tree().change_scene_to_packed(load("res://tools/PPDManager/PPDManager.tscn"))

func _on_ResourcePackEditorButton_pressed():
	get_tree().change_scene_to_packed(load("res://tools/resource_pack_editor/ResourcePackEditor.tscn"))

func _on_dja_debug_button_pressed():
	get_tree().change_scene_to_packed(load("res://tools/InputManagerTester.tscn"))

func _on_exporter_button_pressed():
	get_tree().change_scene_to_packed(load("res://tools/pack_exporter/PackExporter.tscn"))

func _on_LatencyCalculatorButton_pressed():
	change_to_menu("latency_tester")
