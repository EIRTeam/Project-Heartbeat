extends HBEditorPlugin

const DISCLAIMER_TEXT = """Before you import a PPD chart, please keep in mind:
- Placing a PPD chart in the songs folder will make it work seamlessly with the game.
- Importing in the editor should only be used for porting charts to PH.
- While it will mostly work with old-style charts, this is with FT style charts in mind.

Are you entirely sure that you want to do this?"""

var offset_spinbox

func _init(_editor).(_editor):
	var vbox_container = VBoxContainer.new()
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var ppd_file_select_dialog = FileDialog.new()
	ppd_file_select_dialog.mode = FileDialog.MODE_OPEN_FILE
	ppd_file_select_dialog.access = FileDialog.ACCESS_FILESYSTEM
	ppd_file_select_dialog.current_dir = ProjectSettings.globalize_path("user://songs")
	ppd_file_select_dialog.filters = ["*.ppd ; PPD chart"]
	ppd_file_select_dialog.connect("file_selected", self, "_on_file_selected")
	vbox_container.add_child(ppd_file_select_dialog)
	
	var ppd_disclaimer_dialog = ConfirmationDialog.new()
	ppd_disclaimer_dialog.dialog_text = DISCLAIMER_TEXT
	ppd_disclaimer_dialog.connect("confirmed", ppd_file_select_dialog, "popup_centered_ratio", [0.75])
	vbox_container.add_child(ppd_disclaimer_dialog)
	
	var  hbox_container = HBoxContainer.new()
	var offset_label = Label.new()
	offset_label.text = tr("Import offset (in milliseconds)")
	offset_spinbox = HBEditorSpinBox.new()
	offset_spinbox.step = 1
	offset_spinbox.max_value = 10000
	offset_spinbox.min_value = -10000
	
	hbox_container.add_child(offset_label)
	hbox_container.add_child(offset_spinbox)
	
	vbox_container.add_child(hbox_container)
	
	var import_button = Button.new()
	import_button.text = "Import chart from PPD"
	import_button.clip_text = true
	import_button.connect("pressed", ppd_disclaimer_dialog, "popup_centered")
	
	vbox_container.add_child(import_button)
	
	add_tool_to_tools_tab(vbox_container, "PPD Importer")
func _on_file_selected(file_path: String):
	var charter = PPDLoader.PPD2HBChart(file_path, _editor.get_bpm(), offset_spinbox.value)
	get_editor().from_chart(charter, true)
