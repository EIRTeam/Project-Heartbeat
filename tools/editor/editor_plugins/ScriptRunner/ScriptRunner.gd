extends HBEditorPlugin

var script_name_line_edit: LineEdit
var script_add_dialog: ConfirmationDialog
var script_item_list: ItemList
var script_template = ""

const EDITOR_SCRIPTS_PATH = "user://editor_scripts"

func _init(_editor).(_editor):
	script_name_line_edit = LineEdit.new()
	script_add_dialog = ConfirmationDialog.new()
	script_item_list = ItemList.new()
	
	var dir = Directory.new()
	if not dir.dir_exists(EDITOR_SCRIPTS_PATH):
		dir.make_dir(EDITOR_SCRIPTS_PATH)

	var file = File.new()
	file.open("res://tools/editor/editor_plugins/ScriptRunner/ScriptRunnerScriptTemplate.txt", File.READ)
	script_template = file.get_as_text()

	var vbox_container = VBoxContainer.new()

	var warning_label = Label.new()
	warning_label.autowrap = true
	warning_label.text = """WARNING! This is an advanced feature, errors in custom scripts
	may break the game's scripting engine and corrupt data, please be sure to make backups of
	your charts before running scripts on them! You can find errors in the console.
	
	WARNING2!! Scripts are not sandboxed, don't run scripts you don't trust."""
	
	vbox_container.add_child(warning_label)
	
	var doc_link_button = LinkButton.new()
	doc_link_button.text = "Documentation"
	doc_link_button.connect("pressed", OS, "shell_open", ["https://steamcommunity.com/sharedfiles/filedetails/?id=2398390074"])
	vbox_container.add_child(doc_link_button)
	script_add_dialog.window_title = "What should the new script be called?"
	script_add_dialog.popup_exclusive = true
	script_name_line_edit.placeholder_text = "Script name (MyScript or MyScript.gd)"
	script_add_dialog.add_child(script_name_line_edit)
	script_add_dialog.connect("confirmed", self, "_on_add_confirmed")

	vbox_container.add_child(script_add_dialog)

	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hbox_container = HBoxContainer.new()
	hbox_container.alignment = BoxContainer.ALIGN_END
	vbox_container.add_child(hbox_container)
	
	var refresh_button = Button.new()
	refresh_button.hint_tooltip = "Refresh scripts"
	refresh_button.connect("pressed", self, "refresh_script_list")
	refresh_button.icon = preload("res://graphics/icons/refresh.svg")

	var folder_button = Button.new()
	folder_button.hint_tooltip = "Open scripts directory"
	folder_button.icon = preload("res://tools/icons/icon_folder.svg")
	folder_button.connect("pressed", OS, "shell_open", [ProjectSettings.globalize_path(EDITOR_SCRIPTS_PATH)])

	

	var add_button = Button.new()
	add_button.hint_tooltip = "Add new script"
	add_button.icon = preload("res://tools/icons/icon_add.svg")
	add_button.connect("pressed", self, "_on_add_button_pressed")

	hbox_container.add_child(refresh_button)
	hbox_container.add_child(folder_button)
	hbox_container.add_child(add_button)

	script_item_list = ItemList.new()
	vbox_container.add_child(script_item_list)
	script_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	script_item_list.rect_min_size = Vector2(0, 300)

	var run_button = Button.new()
	run_button.text = "Run script"
	run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	run_button.connect("pressed", self, "_on_run_script_button_pressed")

	vbox_container.add_child(run_button)

	add_tool_to_tools_tab(vbox_container, "Script Runner")
	refresh_script_list()
func _on_add_button_pressed():
	script_add_dialog.popup_centered()

func refresh_script_list():
	script_item_list.clear()
	var dir = Directory.new()
	var scripts = []
	if dir.open(EDITOR_SCRIPTS_PATH) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()

		while dir_name != "":
			if not dir.current_is_dir() and dir_name.ends_with(".gd"):
				scripts.append(dir_name)
			dir_name = dir.get_next()
	scripts.sort()
	for script in scripts:
		script_item_list.add_item(script)

func _on_add_confirmed():
	var script_name := script_name_line_edit.text.strip_edges() as String
	if not script_name.ends_with(".gd"):
		script_name += ".gd"
	var script_path = HBUtils.join_path(EDITOR_SCRIPTS_PATH, script_name)
	var file = File.new()
	if not file.file_exists(script_path):
		var err = file.open(script_path, File.WRITE)
		if err == OK:
			file.store_string(script_template)
		else:
			prints("Error writing script to disk", script_path)
	script_add_dialog.hide()
	refresh_script_list()

func _on_run_script_button_pressed():
	var selected = script_item_list.get_selected_items()[0]
	var script_name = script_item_list.get_item_text(selected)
	var script_path = HBUtils.join_path(EDITOR_SCRIPTS_PATH, script_name)
	run_script(script_path)

func _process_changed_values(inst: ScriptRunnerScript):
	if inst._timing_point_changed_properties.size() > 0:
		_editor.undo_redo.create_action("Run Script")

		# Some transforms might change the note type and thus the layer
		var type_to_layer_name_map = {}
		for type_name in HBNoteData.NOTE_TYPE:
			type_to_layer_name_map[HBNoteData.NOTE_TYPE[type_name]] = type_name
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_LEFT_HOLD_PIECE] = "SLIDE_LEFT"
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_RIGHT_HOLD_PIECE] = "SLIDE_RIGHT"

		for clone in inst._timing_point_changed_properties:
			var changed_property_list = inst._timing_point_changed_properties[clone]
			var target_item = inst._clone_to_original_timing_point_map[clone]

			for property_name in changed_property_list:
				if property_name in target_item.data:
					_editor.undo_redo.add_do_property(target_item.data, property_name, changed_property_list[property_name])
					_editor.undo_redo.add_undo_property(target_item.data, property_name, target_item.data.get(property_name))
					_editor.undo_redo.add_undo_method(target_item._layer, "place_child", target_item)
					_editor.undo_redo.add_do_method(target_item._layer, "place_child", target_item)
					if property_name == "note_type":
						# When note type is changed we also change the layer
						var new_note_type = changed_property_list.note_type
						if type_to_layer_name_map[new_note_type] != target_item._layer.layer_name and \
								type_to_layer_name_map[new_note_type] + "2" != target_item._layer.layer_name:
							var source_layer = target_item._layer
							var target_layer_name = type_to_layer_name_map[new_note_type]
							if source_layer.layer_name.ends_with("2"):
								target_layer_name += "2"
							var target_layer = _editor.timeline.find_layer_by_name(target_layer_name)
							_editor.undo_redo.add_do_method(_editor, "remove_item_from_layer", source_layer, target_item)
							_editor.undo_redo.add_do_method(_editor, "add_item_to_layer", target_layer, target_item)
							_editor.undo_redo.add_undo_method(_editor, "remove_item_from_layer", target_layer, target_item)
							_editor.undo_redo.add_undo_method(_editor, "add_item_to_layer", source_layer, target_item)

		_editor.undo_redo.add_do_method(_editor, "_on_timing_points_changed")
		_editor.undo_redo.add_undo_method(_editor, "_on_timing_points_changed")
		_editor.undo_redo.commit_action()
func run_script(script_path: String):
	if script_item_list.is_anything_selected():

		var file = File.new()
		var err = file.open(script_path, File.READ)
		if err == OK:
			var script = GDScript.new()
			script.source_code = file.get_as_text()
			var reload_err = script.reload()
			if reload_err == OK:
				var inst = script.new() as ScriptRunnerScript
				inst._editor = _editor
				inst.init_script()
				var result = inst.run_script()
				if result == OK:
					_process_changed_values(inst)
				else:
					print("Script returned %d, aborting..." % [result])
			else:
				prints("Error instancing script,", reload_err)
		else:
			prints("Error loading script", err)
		
