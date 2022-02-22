extends HBEditorPlugin

var offset_spinbox: HBEditorSpinBox
var options_button: OptionButton
var link_stars_checkbox: CheckBox

const EDIT_LOADER = preload("res://autoloads/song_loader/song_loaders/EditConverter.gd")

enum EDIT_OPTIONS {
	F2
}

func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var import_disclaimer = Label.new()
	import_disclaimer.text = "NOTE: The edit has to be decrypted first"
	
	var edit_file_select_dialog = FileDialog.new()
	edit_file_select_dialog.mode = FileDialog.MODE_OPEN_FILE
	edit_file_select_dialog.access = FileDialog.ACCESS_FILESYSTEM
	edit_file_select_dialog.current_dir = UserSettings.user_settings.last_edit_dir
	edit_file_select_dialog.filters = ["SECURE.BIN ; Edit data"]
	edit_file_select_dialog.connect("file_selected", self, "_on_file_selected")
	vbox_container.add_child(edit_file_select_dialog)
	
	options_button = OptionButton.new()
	options_button.add_item("F2nd")
	
	var hbox_container = HBoxContainer.new()
	var offset_label = Label.new()
	offset_label.text = tr("Import offset (in milliseconds)")
	offset_spinbox = HBEditorSpinBox.new()
	offset_spinbox.step = 1
	offset_spinbox.max_value = 10000
	offset_spinbox.min_value = -10000
	
	link_stars_checkbox = CheckBox.new()
	link_stars_checkbox.text = tr("Use custom params for link stars")
	link_stars_checkbox.pressed = true
	
	vbox_container.add_child(import_disclaimer)
	
	vbox_container.add_child(options_button)
	
	hbox_container.add_child(offset_label)
	hbox_container.add_child(offset_spinbox)
	vbox_container.add_child(hbox_container)
	
	vbox_container.add_child(link_stars_checkbox)
	
	var import_button = Button.new()
	import_button.text = "Import edit"
	import_button.clip_text = true
	import_button.connect("pressed", edit_file_select_dialog, "popup_centered_ratio", [0.75])
	
	vbox_container.add_child(import_button)
	
	add_tool_to_tools_tab(vbox_container, "Edit Importer")
func _on_file_selected(file_path: String):
	var game = "F2"
	match options_button.get_selected_id():
		EDIT_OPTIONS.F2:
			game = "F2"
	
	var chart = EDIT_LOADER.convert_edit_to_chart(file_path, offset_spinbox.value, link_stars_checkbox.pressed)
	if chart:
		get_editor().from_chart(chart, true)
	
	UserSettings.user_settings.last_edit_dir = file_path.get_base_dir()
	UserSettings.save_user_settings()
