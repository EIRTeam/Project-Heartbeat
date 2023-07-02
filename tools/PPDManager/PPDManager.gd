extends Control

@onready var tools_panel: Popup = get_node("CenterContainer/ToolsPopup")
@onready var error_dialog = get_node("ErrorDialog")
@onready var ppd_manager_panel = get_node("PPDManagerPopup")
@onready var ppd_downloader_panel = get_node("PPDDownloader")
@onready var ppd_importer_panel = get_node("PPDImporter")
func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	
	tools_panel.popup_centered()
	tools_panel.connect("popup_hide", Callable(tools_panel, "popup_centered"))
	tools_panel.close_requested.connect(self._on_exit)
	ppd_manager_panel.connect("error", Callable(self, "show_error"))
	ppd_downloader_panel.connect("error", Callable(self, "show_error"))
	ppd_importer_panel.connect("error", Callable(self, "show_error"))
	
	if not HBGame.has_mp4_support:
		$CenterContainer/ToolsPopup/MarginContainer/VBoxContainer/PPDImporter.hide()
	
func show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()

func _on_exit():
	get_tree().change_scene_to_packed(load("res://menus/MainMenu3D.tscn"))
