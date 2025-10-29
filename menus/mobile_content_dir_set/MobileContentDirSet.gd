extends HBMenu

class_name HBMobileContentDirSetMenu

@onready var pick_directory_button: Button = %PickDirectoryButton
@onready var button_container: HBSimpleMenu = %ButtonContainer
@onready var restart_confirmation_window: HBConfirmationWindow = %RestartConfirmationWindow
@onready var permissions_confirmation_window: HBConfirmationWindow = %PermissionsConfirmationWindow

func _on_directory_picked(status: bool, selected_paths: PackedStringArray, selected_filter_index: int):
	if not status or selected_paths.is_empty():
		return
	
	UserSettings.user_settings.content_path = selected_paths[0]
	UserSettings.save_user_settings()
	
	
	restart_confirmation_window.popup_centered()
	
func _on_menu_enter(force_hard_transition=false, args = {}):
	pick_directory_button.pressed.connect(func():
		if "android.permission.MANAGE_EXTERNAL_STORAGE" in OS.get_granted_permissions():
			DisplayServer.file_dialog_show("Pick a content directory!!", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_DIR, [], _on_directory_picked)
		else:
			permissions_confirmation_window.popup_centered()
	)
	
	permissions_confirmation_window.accept.connect(func():
		if OS.request_permission("android.permission.MANAGE_EXTERNAL_STORAGE"):
			DisplayServer.file_dialog_show("Pick a content directory!!", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_DIR, [], _on_directory_picked)
	)
	
	button_container.grab_focus()

func _on_request_permissions_result(permission: String, granted: bool):
	if permission == "android.permission.MANAGE_EXTERNAL_STORAGE":
		if granted:
			DisplayServer.file_dialog_show("Pick a content directory!!", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_DIR, [], _on_directory_picked)
		else:
			button_container.grab_focus()

func _ready() -> void:
	restart_confirmation_window.accept.connect(get_tree().quit)
	get_tree().on_request_permissions_result.connect(_on_request_permissions_result)
