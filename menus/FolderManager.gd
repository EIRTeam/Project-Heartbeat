extends Panel

@onready var scroll_list_container = get_node("MarginContainer/VBoxContainer/HBScrollList/VBoxContainer")
@onready var scroll_list = get_node("MarginContainer/VBoxContainer/HBScrollList")
@onready var delete_confirmation_window = get_node("DeleteConfirmationWindow")
@onready var folder_option_window = get_node("Panel")
@onready var folder_options = get_node("Panel/MarginContainer/VBoxContainer")
@onready var text_input_window_create = get_node("TextInputCreate")
@onready var text_input_window_rename = get_node("TextInputRename")
const FolderButton = preload("res://menus/FolderManagerFolderButton.tscn")

enum MODE {
	MANAGE,
	SELECT
}

var mode: int = MODE.MANAGE

signal closed
signal folder_selected(folder)

var no_root_buttons = []

func _ready():
	text_input_window_create.text_input_description = tr("Enter the new folder name")
	text_input_window_rename.text_input_description = tr("Enter the new folder name")
	
	delete_confirmation_window.connect("accept", Callable(self, "delete_selected_folder"))
	delete_confirmation_window.connect("cancel", Callable(scroll_list, "grab_focus"))
	
	text_input_window_create.connect("entered", Callable(self, "create_folder"))
	text_input_window_rename.connect("entered", Callable(self, "rename_folder"))
	text_input_window_create.connect("cancel", Callable(scroll_list, "grab_focus"))
	text_input_window_rename.connect("cancel", Callable(scroll_list, "grab_focus"))
	
	var folder_options_buttons = []
	
	var add_subfolder_button = HBHovereableButton.new()
	add_subfolder_button.text = "Add subfolder"
	add_subfolder_button.connect("pressed", Callable(text_input_window_create, "popup_centered"))
	folder_options_buttons.append(add_subfolder_button)
	
	var rename_folder_button = HBHovereableButton.new()
	rename_folder_button.text = "Rename folder"
	rename_folder_button.connect("pressed", Callable(self, "_on_rename_folder_pressed"))
	folder_options_buttons.append(rename_folder_button)
	no_root_buttons.append(rename_folder_button)
	
	var delete_folder_button = HBHovereableButton.new()
	delete_folder_button.text = "Delete folder"
	delete_folder_button.connect("pressed", Callable(delete_confirmation_window, "popup_centered"))
	folder_options_buttons.append(delete_folder_button)
	no_root_buttons.append(delete_folder_button)
	
	for button in folder_options_buttons:
		folder_options.add_child(button)
		button.connect("pressed", Callable(folder_option_window, "hide"))
	
func _on_rename_folder_pressed():
	var folder = scroll_list.get_selected_item().folder as HBFolder
	text_input_window_rename.line_edit.text = folder.folder_name
	
	text_input_window_rename.line_edit.caret_column = text_input_window_rename.line_edit.text.length()
	text_input_window_rename.popup_centered()
	
func get_folder_name(folder, depth):
	var subf_name = folder.folder_name + " - %d Subfolder(s)" % [folder.subfolders.size()]

	var c_name = ""
	for _i in range(depth):
		c_name += "-"
	return c_name + " " + subf_name
func add_folder_item(folder: HBFolder, depth = 0):
	var folder_button = FolderButton.instantiate()
	folder_button.folder = folder
	folder_button.depth = depth+1
	folder_button.text = get_folder_name(folder, depth+1)
	folder_button.connect("pressed", Callable(self, "_on_folder_selected").bind(folder_button))
	if scroll_list.get_selected_item():
		scroll_list.get_selected_item().add_sibling(folder_button)
	else:
		scroll_list_container.add_child(folder_button)
		
func create_folder(f_name: String):
	var selected_child = scroll_list.get_selected_item()
	var depth = selected_child.depth
	var selected_folder = selected_child.folder as HBFolder
	var folder = HBFolder.new()
	folder.folder_name = f_name
	selected_folder.subfolders.append(folder)
	hide_folders(selected_child)
	show_folders_for(selected_child.folder, depth)
	text_input_window_create.hide()
	scroll_list.grab_focus()
	UserSettings.save_user_settings()
	text_input_window_create.line_edit.text = ""
func rename_folder(f_name: String):
	var selected_child = scroll_list.get_selected_item()
	var folder = selected_child.folder as HBFolder
	folder.folder_name = f_name
	selected_child.text = get_folder_name(folder, selected_child.depth)
	text_input_window_rename.hide()
	scroll_list.grab_focus()
	UserSettings.save_user_settings()
func show_folders_for(folder: HBFolder, depth = 0):
	for subfolder in folder.subfolders:
		add_folder_item(subfolder, depth)
func show_manager(mode_val: int):
	mode = mode_val
	for child in scroll_list_container.get_children():
		scroll_list_container.remove_child(child)
		child.queue_free()
	add_folder_item(UserSettings.user_settings.root_folder, -1)
	show_folders_for(UserSettings.user_settings.root_folder, 0)
	scroll_list.grab_focus()
	show()
func _on_folder_selected(folder_button):
	if mode == MODE.SELECT:
		var folder = scroll_list.get_selected_item().folder as HBFolder
		if folder != UserSettings.user_settings.root_folder:
			emit_signal("folder_selected", folder)
			hide()
		return
	
	if folder_button.folder == UserSettings.user_settings.root_folder:
		for button in no_root_buttons:
			button.hide()
	else:
		for button in no_root_buttons:
			button.show()
	
	folder_options.select_button(0)
	folder_option_window.show()
	folder_options.grab_focus()
	
func delete_selected_folder():
	delete_confirmation_window.hide()
	var parent = UserSettings.user_settings.root_folder as HBFolder
	var parent_item = null
	var current_folder_item = scroll_list.get_selected_item()
	
	hide_folders(current_folder_item)
	var pos = scroll_list.get_selected_item().get_index()
	if scroll_list.get_selected_item().depth > 0:
		for i in range(pos, -1, -1):
			var child = scroll_list_container.get_child(i)
			if child.depth < scroll_list.get_selected_item().depth:
				parent = child.folder
				parent_item = child
				break
	parent.subfolders.erase(scroll_list.get_selected_item().folder)
	
	var new_selection = max(pos-1, 0)
	
	if pos == 0:
		new_selection = 1
	
	if parent_item:
		parent_item.text = get_folder_name(parent, parent_item.depth)
	
	scroll_list.grab_focus()
	
	scroll_list.select_item(new_selection)
	
	scroll_list_container.remove_child(current_folder_item)
	
	UserSettings.save_user_settings()
	
func hide_folders(folder_item):
	var pos = folder_item.get_index()
	var final_pos = pos
	for i in range(pos+1, scroll_list_container.get_child_count()):
		var child = scroll_list_container.get_child(i)
		if child.depth <= folder_item.depth:
			break
		final_pos = i
	for i in range(final_pos, -1, -1):
		var child = scroll_list_container.get_child(i)
		if child == folder_item:
			break
		if child.depth > folder_item.depth:
			scroll_list_container.remove_child(child)
		else:
			break
	
func _unhandled_input(event):
	if scroll_list.has_focus():
		if event.is_action_pressed("gui_left"):
			get_viewport().set_input_as_handled()
			hide_folders(scroll_list.get_selected_item())
		if event.is_action_pressed("gui_right"):
			get_viewport().set_input_as_handled()
			var selected_folder = scroll_list.get_selected_item().folder as HBFolder
			var pos_in_parent = scroll_list.get_selected_item().get_index()
			if pos_in_parent < scroll_list_container.get_child_count() - 1:
				if scroll_list_container.get_child(pos_in_parent+1).depth > scroll_list.get_selected_item().depth:
					return
			show_folders_for(selected_folder, scroll_list.get_selected_item().depth)
		if event.is_action_pressed("gui_cancel"):
			get_viewport().set_input_as_handled()
			emit_signal("closed")
			hide()
	if folder_options.has_focus():
		if event.is_action_pressed("gui_cancel") and folder_option_window.visible:
			get_viewport().set_input_as_handled()
			scroll_list.grab_focus()
			folder_option_window.hide()
