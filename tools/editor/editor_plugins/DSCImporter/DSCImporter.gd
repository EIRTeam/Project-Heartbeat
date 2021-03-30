extends HBEditorPlugin

var offset_spinbox
var options_button: OptionButton

const DSC_LOADER = preload("res://autoloads/song_loader/song_loaders/DSCConverter.gd")

enum DSC_OPTIONS {
	FT,
	F,
	F2
}

func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var ppd_file_select_dialog = FileDialog.new()
	ppd_file_select_dialog.mode = FileDialog.MODE_OPEN_FILE
	ppd_file_select_dialog.access = FileDialog.ACCESS_FILESYSTEM
	ppd_file_select_dialog.current_dir = ProjectSettings.globalize_path("user://songs")
	ppd_file_select_dialog.filters = ["*.dsc ; DSC chart"]
	ppd_file_select_dialog.connect("file_selected", self, "_on_file_selected")
	vbox_container.add_child(ppd_file_select_dialog)
	
	var  hbox_container = HBoxContainer.new()
	var offset_label = Label.new()
	offset_label.text = tr("Import offset (in milliseconds)")
	offset_spinbox = SpinBox.new()
	offset_spinbox.step = 1
	offset_spinbox.max_value = 10000
	offset_spinbox.min_value = -10000
	
	options_button = OptionButton.new()
	options_button.add_item("Future Tone/M39s")
	options_button.add_item("F/DT2")
	options_button.add_item("F2nd")
	
	vbox_container.add_child(options_button)
	
	hbox_container.add_child(offset_label)
	hbox_container.add_child(offset_spinbox)
	
	vbox_container.add_child(hbox_container)
	
	var import_button = Button.new()
	import_button.text = "Import DSC chart"
	import_button.clip_text = true
	import_button.connect("pressed", ppd_file_select_dialog, "popup_centered_ratio", [0.75])
	
	vbox_container.add_child(import_button)
	
	add_tool_to_tools_tab(vbox_container, "DSC Importer")
func _on_file_selected(file_path: String):
	var chart: HBChart
	var game = "FT"
	match options_button.get_selected_id():
		DSC_OPTIONS.FT:
			game = "FT"
		DSC_OPTIONS.F:
			game = "f"
		DSC_OPTIONS.F2:
			game = "F2"
	var opcode_map = DSCOpcodeMap.new("res://autoloads/song_loader/song_loaders/dsc_opcode_db.json", game)
	chart = DSC_LOADER.convert_dsc_to_chart(file_path, opcode_map)
	if chart:
		get_editor().from_chart(chart, true)
