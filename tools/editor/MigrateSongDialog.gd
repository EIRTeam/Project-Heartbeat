extends ConfirmationDialog

class_name HBMigrateSongDialog

@onready var status_dialog: AcceptDialog = get_node("%StatusDialog")
@onready var error_dialog: AcceptDialog = get_node("%ErrorDialog")
@onready var completed_dialog: AcceptDialog = get_node("%CompletedDialog")

var show_completed_dialog := true

var song: HBSong

func _ready() -> void:
	status_dialog.get_ok_button().hide()
	confirmed.connect(_run_migration)
	
func _show_status(status_text: String):
	status_dialog.dialog_text = status_text

func _show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()
	await error_dialog.visibility_changed
	hide()

func _run_migration():
	_show_status("Migrating song %s!" % [song.get_visible_title()])
	var task := HBMigrateSongTask.new(song)
	task.run_migration()
	var migration_result: HBMigrateSongTask.MigrationResult = await task.migration_finished
	if migration_result.error != HBMigrateSongTask.MigrationError.OK:
		_show_error(migration_result.error_message)
	if show_completed_dialog:
		completed_dialog.popup_centered()
