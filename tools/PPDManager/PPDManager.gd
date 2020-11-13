extends Control

onready var tools_panel = get_node("CenterContainer/ToolsPopup")
onready var error_dialog = get_node("ErrorDialog")
onready var ppd_manager_panel = get_node("PPDManagerPopup")
onready var ppd_downloader_panel = get_node("PPDDownloader")
func _ready():
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	tools_panel.popup_centered()
	tools_panel.get_close_button().connect("pressed", self, "_on_exit")
	ppd_manager_panel.connect("error", self, "show_error")
	ppd_downloader_panel.connect("error", self, "show_error")
	
func show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()

func _on_exit():
	get_tree().change_scene_to(load("res://menus/MainMenu3D.tscn"))
