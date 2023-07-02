extends HBEditorModule

const EDITOR_SCRIPTS_PATH = "user://editor_scripts/"
const SCRIPT_META_FIELDS = ["name", "description", "usage"]

@onready var file_manager_tree: Tree = get_node("%FileTree")
@onready var script_runner_tree: Tree = get_node("%ScriptRunnerTree")
@onready var script_editor: HBEditorTextEdit = get_node("%ScriptEditor")
@onready var error_label: Label = get_node("%ErrorLabel")
@onready var script_editor_dialog: Window = get_node("%ScriptEditorDialog")
@onready var save_confirmation_dialog: ConfirmationDialog = get_node("%SaveDialog")
@onready var delete_confirmation_dialog: ConfirmationDialog = get_node("%DeleteDialog")
@onready var reload_dialog: ConfirmationDialog = get_node("%ReloadDialog")
@onready var file_name_line_edit: LineEdit = get_node("%FileNameLineEdit")
@onready var focus_trap_line_edit: LineEdit = get_node("%FocusTrapLineEdit")

@onready var load_icon = preload("res://tools/icons/icon_load.svg")
@onready var copy_icon = preload("res://tools/icons/icon_action_copy.svg")
@onready var delete_icon = preload("res://tools/icons/icon_remove.svg")
@onready var run_icon = preload("res://graphics/icons/console-line.svg")

var watcher: DirectoryWatcher

var script_template: String

var scripts: Dictionary= {}
var current_script_name: String = ""

var modified: bool = false
var last_modified_time: int

var _block_actions: bool = false

var requested_action: String

func _ready():
	super._ready()
	# Create and load defaults
	if not DirAccess.dir_exists_absolute(EDITOR_SCRIPTS_PATH):
		DirAccess.make_dir_absolute(EDITOR_SCRIPTS_PATH)
	script_editor_dialog.close_requested.connect(_close_script_editor)
	var file := FileAccess.open("res://tools/editor/editor_modules/ScriptsModule/ScriptRunnerScriptTemplate.gd", FileAccess.READ)
	script_template = file.get_as_text()
	script_editor.text = script_template
	
	# Set up trees
	file_manager_tree.set_column_expand(0, true)
	file_manager_tree.set_column_expand(1, true)
	file_manager_tree.set_column_expand(2, true)
	file_manager_tree.set_column_expand(3, true)
	file_manager_tree.set_column_custom_minimum_width(0, 9)
	file_manager_tree.set_column_custom_minimum_width(1, 1)
	file_manager_tree.set_column_custom_minimum_width(2, 1)
	file_manager_tree.set_column_custom_minimum_width(3, 1)
	
	script_runner_tree.set_column_expand(0, true)
	script_runner_tree.set_column_expand(1, true)
	script_runner_tree.set_column_custom_minimum_width(0, 9)
	script_runner_tree.set_column_custom_minimum_width(1, 1)
	
	populate_file_lists()
	
	# Set up file watcher
	watcher = DirectoryWatcher.new()
	watcher.add_scan_directory(EDITOR_SCRIPTS_PATH)
	watcher.scan_delay = 3.0
	
	watcher.connect("files_created", Callable(self, "_on_files_created"))
	watcher.connect("files_deleted", Callable(self, "_on_files_deleted"))
	watcher.connect("files_modified", Callable(self, "_on_files_modified"))
	
	add_child(watcher)
	
	# Change text for the confirmation dialog
	save_confirmation_dialog.get_ok_button().set_text("Yes")
	save_confirmation_dialog.get_cancel_button().set_text("Go back")
	
	# Change text for the delete dialog
	delete_confirmation_dialog.get_ok_button().set_text("Yes")
	
	# Change text for the reload dialog
	reload_dialog.get_ok_button().set_text("Reload")
	reload_dialog.get_cancel_button().set_text("Keep editing")

func _on_files_created(files: Array):
	populate_file_lists()
	
	if _block_actions:
		block_actions()

func _on_files_deleted(files: Array):
	if ProjectSettings.globalize_path(HBUtils.join_path(EDITOR_SCRIPTS_PATH, current_script_name)) in files:
		# Current file was deleted
		_set_modified(true)
	
	if focus_trap_line_edit.visible:
		if ProjectSettings.globalize_path(HBUtils.join_path(EDITOR_SCRIPTS_PATH, old_file_name)) in files:
			# The file we were duplicating/moving was deleted
			_on_name_rejected()
	
	populate_file_lists()
	
	if _block_actions:
		block_actions()

func _on_files_modified(files: Array):
	var current_path := ProjectSettings.globalize_path(HBUtils.join_path(EDITOR_SCRIPTS_PATH, current_script_name))
	
	for path in files:
		if not path.ends_with(".gd"):
			continue
		
		if current_path == path:
			var file := FileAccess.open(path, FileAccess.READ)
			
			if FileAccess.get_open_error() == OK:
				var time = file.get_modified_time(path)
				
				if time > last_modified_time:
					if $CanvasLayer.visible:
						reload_dialog.popup_centered()
					else:
						_set_modified(true, false)
		
		var script_name = path.get_file()
		
		var meta = parse_meta(script_name)
		scripts[script_name].meta = meta
		
		var item = scripts[script_name].runner_item
		set_item_meta(item, script_name, meta)

func parse_meta(script_name: String) -> Dictionary:
	var meta := {}
	var file := FileAccess.open(HBUtils.join_path(EDITOR_SCRIPTS_PATH, script_name), FileAccess.READ)
	if FileAccess.get_open_error() == OK:
		var script_contents := file.get_as_text()
		
		# Meta syntax looks like:
		#meta:<meta_name>:<value>
		for line in script_contents.split("\n"):
			for meta_field in SCRIPT_META_FIELDS:
				if line.begins_with("#meta:" + meta_field + ":"):
					meta[meta_field] = line.trim_prefix("#meta:" + meta_field + ":")
					break
			
			if meta.size() == SCRIPT_META_FIELDS.size():
				# Return early so its more efficient
				break
	
	return meta

func create_script_item(script_name: String, id: int = -1) -> TreeItem:
	var item := file_manager_tree.create_item(file_manager_tree.get_root(), id)
	item.set_text(0, script_name)
	
	item.add_button(1, load_icon, -1, false, "Open this script")
	item.add_button(2, copy_icon, -1, false, "Duplicate this script")
	item.add_button(3, delete_icon, -1, false, "Delete this script")
	
	return item

func set_item_meta(item: TreeItem, script_name: String, meta: Dictionary):
	if meta.has("name"):
		item.set_text(0, meta["name"])
	else:
		item.set_text(0, script_name)
	
	var tooltip = script_name
	if meta.has("description"):
		tooltip += "\n"
		tooltip += HBUtils.wrap_text(meta["description"])
	if meta.has("usage"):
		tooltip += "\n"
		tooltip += HBUtils.wrap_text("Usage: " + meta["usage"])
	
	item.set_tooltip_text(0, tooltip)

func create_script_runner_item(script_name: String, meta: Dictionary):
	var item := script_runner_tree.create_item(script_runner_tree.get_root())
	item.set_meta("script_name", script_name)
	
	set_item_meta(item, script_name, meta)
	
	item.add_button(1, run_icon, -1, false, "Execute this script")
	
	return item

func populate_file_lists():
	file_manager_tree.clear()
	file_manager_tree.create_item()
	
	script_runner_tree.clear()
	script_runner_tree.create_item()
	
	# Get script list and meta tags
	scripts.clear()
	var dir = DirAccess.open(EDITOR_SCRIPTS_PATH)
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var dir_name = dir.get_next()
		
		while dir_name != "":
			if not dir.current_is_dir() and dir_name.ends_with(".gd"):
				var meta = parse_meta(dir_name)
				scripts[dir_name] = {"meta": meta, "runner_item": null}
			
			dir_name = dir.get_next()
	
	var keys = scripts.keys()
	keys.sort()
	for script in keys:
		var item = create_script_item(script)
		
		var runner_item = create_script_runner_item(script, scripts[script].meta)
		scripts[script].runner_item = runner_item
		
		if focus_trap_line_edit.visible and old_file_name == script:
			# Reposition popup
			focus_trap_line_edit.visible = false
			popup_focus_trap(item, action)
	
	if focus_trap_line_edit.visible and action == "save":
		# Put popup at the end of the tree
		var script_name = current_script_name if current_script_name else "new_script.gd"
		var new_item = create_script_item(script_name)
		
		focus_trap_line_edit.visible = false
		popup_focus_trap(new_item, "save")

func popup_focus_trap(item: TreeItem, p_action: String):
	if focus_trap_line_edit.visible:
		return
	
	action = p_action
	var area_rect := file_manager_tree.get_item_area_rect(item, 0)
	
	focus_trap_line_edit.text = item.get_text(0)
	
	focus_trap_line_edit.position = area_rect.position + Vector2(12, 4)
	focus_trap_line_edit.size = area_rect.size - Vector2(7, 0)
	focus_trap_line_edit.visible = true
	focus_trap_line_edit.grab_focus()
	
	block_actions()

func _on_file_manager_cell_selected():
	if file_manager_tree.get_selected_column() != 0:
		return
	
	# Move file / Change name
	var item := file_manager_tree.get_selected()
	
	old_file_name = item.get_text(0)
	popup_focus_trap(item, "move")

func _on_file_manager_button_pressed(item: TreeItem, column: int, id: int):
	if not item:
		return
	
	var file_name = item.get_text(0)
	
	if column == 1:
		# Open file
		if file_name == current_script_name:
			return
		
		_open_file_name = file_name
		if modified:
			# Request confirmation
			requested_action = "open_file"
			save_confirmation_dialog.popup_centered()
		else:
			open_file()
	
	if column == 2:
		# Duplicate file
		var new_item = create_script_item(file_name, scripts.keys().find(file_name) + 1)
		
		old_file_name = file_name
		popup_focus_trap(new_item, "duplicate")
	
	if column == 3:
		# Delete file
		_delete_file_name = file_name
		delete_confirmation_dialog.popup_centered()

func _on_script_runner_button_pressed(item: TreeItem, column: int, id: int):
	var file_name = item.get_meta("script_name")
	
	if column == 1:
		# Execute script
		run_script(HBUtils.join_path(EDITOR_SCRIPTS_PATH, file_name))

var _open_file_name: String = ""
func open_file():
	var file := FileAccess.open(HBUtils.join_path(EDITOR_SCRIPTS_PATH, _open_file_name), FileAccess.READ)
	
	if FileAccess.get_open_error() == OK:
		script_editor.text = file.get_as_text()
		current_script_name = _open_file_name
		
		_set_modified(false)

func reload_file():
	_open_file_name = current_script_name
	open_file()

func save_file(save_as: bool = false):
	if _block_actions:
		return
	
	if FileAccess.file_exists(HBUtils.join_path(EDITOR_SCRIPTS_PATH, current_script_name)) and not save_as:
		var file := FileAccess.open(HBUtils.join_path(EDITOR_SCRIPTS_PATH, current_script_name), FileAccess.WRITE)
		if FileAccess.get_open_error() == OK:
			# File exists
			file.store_string(script_editor.get_text())
			_set_modified(false)
			
			return
	
	# Its a new file
	var script_name = current_script_name if current_script_name else "new_script.gd"
	var new_item = create_script_item(script_name)
	
	old_file_name = ""
	popup_focus_trap(new_item, "save")

var _delete_file_name: String = ""
func delete_file():
	_delete(_delete_file_name)

func new_file():
	if modified:
		# Request confirmation
		requested_action = "force_new_file"
		save_confirmation_dialog.popup_centered()
	else:
		current_script_name = ""
		_set_modified(false, false)
		
		script_editor.text = script_template

func force_new_file():
	modified = false
	new_file()

func open_scripts_dir():
	OS.shell_open(ProjectSettings.globalize_path(EDITOR_SCRIPTS_PATH))

func check_valid_file_name(file_name: String):
	if FileAccess.file_exists(HBUtils.join_path(EDITOR_SCRIPTS_PATH, file_name)):
		return "File already exists"
	
	if not file_name.ends_with(".gd"):
		return "Scripts must end with .gd"
	
	if "/" in file_name:
		return "Scripts cant live outside the editor_scripts dir"

var old_file_name: String = ""
var action: String = ""
func _on_name_accepted():
	error_label.text = ""
	
	var new_file_name := focus_trap_line_edit.get_text()
	if action == "move" and old_file_name == new_file_name:
		# Nothing changed
		focus_trap_line_edit.visible = false
		focus_trap_line_edit.release_focus()
		
		unblock_actions()
		populate_file_lists()
		
		return
	
	var error = check_valid_file_name(new_file_name)
	if error:
		# Display the error without unblocking
		error_label.text = "Error: " + error
		
		return
	
	# Get the contents from the apropiate file
	var contents = ""
	if action == "save":
		contents = script_editor.get_text()
	elif action == "move" or action == "duplicate":
		var file := FileAccess.open(HBUtils.join_path(EDITOR_SCRIPTS_PATH, old_file_name), FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			contents = file.get_as_text()
	
	# Save the contents
	var file := FileAccess.open(HBUtils.join_path(EDITOR_SCRIPTS_PATH, new_file_name), FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		file.store_string(contents)
	
	if action == "move":
		# Remove previous file
		_delete(old_file_name)
		
		if old_file_name == current_script_name:
			# We moved the current file
			current_script_name = new_file_name
			_set_modified(modified)
	elif action == "save":
		# We saved a new file
		current_script_name = new_file_name
		_set_modified(false)
	
	# Operation was successfull, release all safeguards
	focus_trap_line_edit.visible = false
	focus_trap_line_edit.release_focus()
	
	unblock_actions()

func _on_name_rejected():
	# Operation was cancelled, release all safeguards
	focus_trap_line_edit.visible = false
	focus_trap_line_edit.release_focus()
	
	unblock_actions()
	populate_file_lists()

func update_shortcuts():
	get_node("%ScriptManagerButton").update_shortcuts()

func _popup_script_editor():
	$CanvasLayer.visible = true
	script_editor_dialog.popup_centered_ratio(0.9)
	
	obscure_ui()
	
	watcher.scan_delay = 0.25

func _close_script_editor():
	if modified:
		# Request confirmation
		requested_action = "force_close"
		script_editor_dialog.popup()
		save_confirmation_dialog.popup_centered()
	else:
		$CanvasLayer.visible = false
		reveal_ui()
		
		watcher.scan_delay = 3.0

func force_close():
	_set_modified(false, false)
	_close_script_editor()
	script_editor_dialog.hide()

func _text_changed():
	_set_modified(true, false)

func _set_modified(p_modified: bool, record_modification: bool = true):
	modified = p_modified
	
	# Update modified status line
	var file_name = current_script_name if current_script_name else "New File"
	file_name += " (Modified)" if modified else ""
	file_name_line_edit.set_text(file_name)
	
	var path := HBUtils.join_path(EDITOR_SCRIPTS_PATH, current_script_name)
	if record_modification and current_script_name != "" and FileAccess.file_exists(path):
		last_modified_time = FileAccess.get_modified_time(path)

func block_actions():
	_block_actions = true
	
	# Block copy, open, move and delete
	var root := file_manager_tree.get_root()
	root.call_recursive("set_selectable", 0, false)
	root.call_recursive("set_button_disabled", 1, 0, true)
	root.call_recursive("set_button_disabled", 2, 0, true)
	root.call_recursive("set_button_disabled", 3, 0, true)
	
	# Block focus
	for control in get_tree().get_nodes_in_group("prevent_focus"):
		control.focus_mode = Control.FOCUS_NONE
	
	# Block the save, save as, delete and close buttons
	get_node("%SaveButton").disabled = true
	get_node("%SaveAsButton").disabled = true
	get_node("%NewFileButton").disabled = true
	
func unblock_actions():
	# We dont need to unblock copy and open since we are refreshing the list anyways
	# But we do need to unblock focus
	for control in get_tree().get_nodes_in_group("prevent_focus"):
		control.focus_mode = Control.FOCUS_ALL
	
	# And all the buttons
	get_node("%SaveButton").disabled = false
	get_node("%SaveAsButton").disabled = false
	get_node("%NewFileButton").disabled = false
	
	_block_actions = false

func _do_requested_action():
	call(requested_action)

func _delete(file_name: String):
	# Lets make sure we dont delete the whole folder, just in case I fuck something up really badly
	if not file_name:
		return
	
	# Lets also make sure we dont delete anything outside the folder
	if "../" in file_name:
		return
	
	OS.move_to_trash(ProjectSettings.globalize_path(HBUtils.join_path(EDITOR_SCRIPTS_PATH, file_name)))

func _keep_editing():
	_set_modified(true, false)

func run_script(script_path: String):
	var file := FileAccess.open(script_path, FileAccess.READ)
	var err := FileAccess.get_open_error()

	if err == OK:
		var script = GDScript.new()
		script.source_code = file.get_as_text()
		
		var reload_err = script.reload()
		if reload_err == OK:
			var inst = script.new() as ScriptRunnerScript
			inst._editor = editor
			inst.init_script()
			
			var result = inst.run_script()
			if result == OK:
				_process_changed_values(inst, scripts[script_path.get_file()].meta)
			else:
				print("Script returned %d, aborting..." % [result])
		else:
			prints("Error instancing script,", reload_err)
	else:
		prints("Error loading script", err)

func _process_changed_values(inst: ScriptRunnerScript, meta: Dictionary):
	if inst._timing_point_changed_properties or inst.new_timing_points:
		var action_name = "Run Script"
		if meta.has("name"):
			action_name = meta["name"] + " (Script)"
		
		undo_redo.create_action(action_name)
		
		# Some transforms might change the note type and thus the layer
		var type_to_layer_name_map = {}
		for type_name in HBNoteData.NOTE_TYPE:
			type_to_layer_name_map[HBNoteData.NOTE_TYPE[type_name]] = type_name
		
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT] = "SLIDE_LEFT"
		type_to_layer_name_map[HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT] = "SLIDE_RIGHT"
		
		for clone in inst._timing_point_changed_properties:
			var changed_property_list = inst._timing_point_changed_properties[clone]
			var target_item = inst._clone_to_original_timing_point_map[clone]
			
			for property_name in changed_property_list:
				if property_name in target_item.data:
					undo_redo.add_do_property(target_item.data, property_name, changed_property_list[property_name])
					undo_redo.add_undo_property(target_item.data, property_name, target_item.data.get(property_name))
					
					undo_redo.add_undo_method(target_item._layer.place_child.bind(target_item))
					undo_redo.add_do_method(target_item._layer.place_child.bind(target_item))
					
					if property_name == "note_type":
						# When note type is changed we also change the layer
						var new_note_type = changed_property_list.note_type
						if type_to_layer_name_map[new_note_type] != target_item._layer.layer_name and \
						   type_to_layer_name_map[new_note_type] + "2" != target_item._layer.layer_name:
							var source_layer = target_item._layer
							var target_layer_name = type_to_layer_name_map[new_note_type]
							
							if source_layer.layer_name.ends_with("2"):
								target_layer_name += "2"
							
							var target_layer := find_layer_by_name(target_layer_name)
							
							undo_redo.add_do_method(editor.remove_item_from_layer.bind(source_layer, target_item))
							undo_redo.add_do_method(editor.add_item_to_layer.bind(target_layer, target_item))
							
							undo_redo.add_undo_method(editor.remove_item_from_layer.bind(target_layer, target_item))
							undo_redo.add_undo_method(editor.add_item_to_layer.bind(source_layer, target_item))
					if property_name == "position":
						undo_redo.add_do_property(target_item.data, "pos_modified", true)
						undo_redo.add_undo_property(target_item.data, "pos_modified", target_item.data.pos_modified)
		
		for timing_point in inst.new_timing_points:
			var layer_name
			if "note_type" in timing_point:
				layer_name = type_to_layer_name_map[timing_point.note_type]
			else:
				layer_name = "Events"
			
			var layer = find_layer_by_name(layer_name)
			
			create_timing_point(layer, timing_point.get_timeline_item())
		
		undo_redo.add_do_method(self.timing_points_changed)
		undo_redo.add_undo_method(self.timing_points_changed)
		undo_redo.add_do_method(self.sync_inspector_values)
		undo_redo.add_undo_method(self.sync_inspector_values)
		undo_redo.commit_action()

func user_settings_changed():
	script_editor.update_font_size()
