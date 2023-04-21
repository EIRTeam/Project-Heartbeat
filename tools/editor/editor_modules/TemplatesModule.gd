extends HBEditorModule

const EDITOR_TEMPLATES_PATH := "user://editor_templates"
const DOWN_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_down.svg")
const RIGHT_ICON = preload("res://tools/icons/icon_GUI_tree_arrow_right.svg")

onready var templates_container: VBoxContainer = get_node("%TemplatesVBoxContainer")
onready var create_template_button: HBEditorButton = get_node("%CreateTemplateButton")
onready var template_name_confirmation_dialog: ConfirmationDialog = get_node("%TemplateNameConfirmationDialog")
onready var template_name_line_edit: HBEditorLineEdit = get_node("%TemplateNameLineEdit")
onready var save_all_checkbox: CheckBox = get_node("%SaveAllCheckBox")
onready var autohide_checkbox: CheckBox = get_node("%AutoHideCheckBox")
onready var category_option_button: OptionButton = get_node("%CategoryOptionButton")

onready var default_templates = preload("res://tools/editor/editor_modules/TemplatesModule/DefaultTemplates.gd").new()

var templates := []
var templates_file_tree := {}
var buttons := []
var category_list := []

func _ready():
	load_templates()

static func template_from_note_array(notes: Array, save_all_properties: bool) -> HBEditorTemplate:
	var template := HBEditorTemplate.new()
	
	var _properties := [
		"position",
		"entry_angle",
		"oscillation_amplitude",
		"oscillation_frequency",
		"auto_time_out",
		"time_out",
		"distance",
	]
	var properties := []
	
	var default := HBBaseNote.new()
	for item in notes:
		var note = item.data
		
		if not note is HBBaseNote:
			continue
		
		for property in _properties:
			var condition = note.get(property) != default.get(property)
			
			if property == "position":
				condition = note.pos_modified
			
			if (condition or save_all_properties) and not property in properties:
				properties.append(property)
		
		var note_ser = note.serialize()
		var note_copy = HBSerializable.deserialize(note_ser) as HBBaseNote
		
		template.set_type_template(note_copy)
	
	template.saved_properties = properties
	
	return template

func load_templates():
	var dir := Directory.new()
	
	if not dir.dir_exists(EDITOR_TEMPLATES_PATH):
		var officials_path := HBUtils.join_path(EDITOR_TEMPLATES_PATH, "official_templates")
		var result = dir.make_dir_recursive(officials_path)
		
		if result != OK:
			Log.log(self, "Error creating templates directory: " + str(result), Log.LogLevel.ERROR)
			return
		
		for template in default_templates.default_templates:
			template.save(officials_path)
		
		UserSettings.user_settings.editor_templates_visibility = {"__all": true, "__uncategorized": false, "user://editor_templates/official_templates": false}
	
	templates.clear()
	templates_file_tree.clear()
	
	templates_file_tree = traverse_dir(EDITOR_TEMPLATES_PATH, true)
	
	update_templates()

func traverse_dir(path: String, root: bool = false) -> Dictionary:
	var dir := Directory.new()
	var tree := {}
	
	var result := dir.open(path)
	if result != OK:
		Log.log(self, "Error opening templates directory: " + str(result), Log.LogLevel.ERROR)
		return {}
	
	result = dir.list_dir_begin(true)
	if result != OK:
		Log.log(self, "Error listing templates directory: " + str(result), Log.LogLevel.ERROR)
		return {}
	
	var next = dir.get_next()
	while next:
		var full_path := HBUtils.join_path(path, next)
		
		if next.ends_with(".json"):
			var file := File.new()
			
			result = file.open(full_path, File.READ)
			if result != OK:
				Log.log(self, "Error opening template file (" + full_path + "): " + str(result), Log.LogLevel.ERROR)
				next = dir.get_next()
				
				continue
			
			var json_result = JSON.parse(file.get_as_text()).result
			
			if json_result == null:
				Log.log(self, "Error deserializing template file " + full_path, Log.LogLevel.ERROR)
				next = dir.get_next()
				
				continue
			
			var template = HBEditorTemplate.deserialize(json_result)
			template.filename = next
			
			templates.append(template)
			
			if root:
				if not tree.has("uncategorized"):
					tree["uncategorized"] = {}
					tree["uncategorized"].__full_path = "__uncategorized"
				
				tree["uncategorized"][next] = template
			else:
				tree[next] = template
		
		if dir.current_is_dir():
			tree[next] = traverse_dir(full_path)
			tree[next].__full_path = full_path
			
			if not full_path in UserSettings.user_settings.editor_templates_visibility:
				UserSettings.user_settings.editor_templates_visibility[full_path] = false
				UserSettings.save_user_settings()
		
		next = dir.get_next()
	
	return tree

func create_dropdown(parent: VBoxContainer, name: String, full_path: String) -> VBoxContainer:
	var open = false
	if full_path in UserSettings.user_settings.editor_templates_visibility:
		open = UserSettings.user_settings.editor_templates_visibility[full_path]
	
	var hbox_container := HBoxContainer.new()
	hbox_container.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var dropdown_button := Button.new()
	dropdown_button.flat = true
	dropdown_button.icon = DOWN_ICON if open else RIGHT_ICON
	dropdown_button.set_meta("full_path", full_path)
	
	var label := Label.new()
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.text = name.replace("_", " ").replace("-", " ").capitalize()
	
	hbox_container.add_child(dropdown_button)
	hbox_container.add_child(label)
	
	var margin_container := MarginContainer.new()
	margin_container.size_flags_horizontal = SIZE_EXPAND_FILL
	margin_container.add_constant_override("margin_left", 16)
	
	var vbox_container := VBoxContainer.new()
	vbox_container.size_flags_horizontal = SIZE_EXPAND_FILL
	vbox_container.visible = open
	
	margin_container.add_child(vbox_container)
	
	parent.add_child(hbox_container)
	parent.add_child(margin_container)
	
	dropdown_button.connect("pressed", self, "_toggle_dropdown", [dropdown_button, vbox_container])
	
	return vbox_container

func _toggle_dropdown(dropdown_button: Button, vbox_container: VBoxContainer):
	var new_open = not vbox_container.visible
	
	dropdown_button.icon = DOWN_ICON if new_open else RIGHT_ICON
	vbox_container.visible = new_open
	
	var full_path = dropdown_button.get_meta("full_path")
	UserSettings.user_settings.editor_templates_visibility[full_path] = new_open
	UserSettings.save_user_settings()

func create_button(template: HBEditorTemplate) -> Button:
	var button := Button.new()
	button.text = template.name
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var transform = template.get_transform()
	transform.set_editor(editor)
	transforms.append(transform)
	
	var transform_idx = transforms.size() - 1
	button.connect("mouse_entered", self, "show_transform", [transform_idx])
	button.connect("mouse_exited", self, "hide_transform")
	button.connect("pressed", self, "apply_transform", [transform_idx])
	
	button.set_meta("template", template)
	
	buttons.append(button)
	
	return button

func build_template_tree(file_tree: Dictionary, parent: VBoxContainer):
	var subfolders := []
	var inner_templates := []
	
	for filename in file_tree:
		var value = file_tree[filename]
		
		if value is HBEditorTemplate:
			inner_templates.append(value)
		elif value is Dictionary:
			subfolders.append({"name": filename, "files": value, "full_path": value.__full_path})
	
	subfolders.sort_custom(self, "_sort_subfolders_by_name")
	for subfolder in subfolders:
		var dropdown = create_dropdown(parent, subfolder.name, subfolder.full_path)
		
		if subfolder.full_path != "__uncategorized":
			var full_path_name = subfolder.full_path.trim_prefix("user://") \
										  .replace("_", " ").replace("-", " ") \
										  .replace("/", " > ") \
										  .capitalize()
			category_option_button.add_item(full_path_name, category_list.size())
			
			category_list.append(subfolder.full_path)
		
		build_template_tree(subfolder.files, dropdown)
	
	inner_templates.sort_custom(self, "_sort_templates_by_name")
	for template in inner_templates:
		var button := create_button(template)
		parent.add_child(button)

func update_templates():
	for child in templates_container.get_children():
		child.queue_free()
	
	transforms.clear()
	buttons.clear()
	category_option_button.clear()
	category_list.clear()
	
	templates.sort_custom(self, "_sort_templates_by_name")
	
	var all_folder := create_dropdown(templates_container, "all", "__all")
	for template in templates:
		var button := create_button(template)
		all_folder.add_child(button)
	
	category_list.append(EDITOR_TEMPLATES_PATH)
	category_option_button.add_item("Uncategorized", 0)
	category_option_button.select(0)
	
	build_template_tree(templates_file_tree, templates_container)
	
	update_visibility()

func update_visibility():
	var types_at_times := {}
	for item in get_selected():
		if not item.data is HBBaseNote:
			continue
		
		var time = item.data.time
		if not time in types_at_times:
			types_at_times[time] = []
		
		types_at_times[time].append(item.data.note_type)
	
	var common_types := []
	for type in HBBaseNote.NOTE_TYPE.values():
		var found_in_all := true
		
		for types in types_at_times.values():
			if not type in types:
				found_in_all = false
				
				break
		
		if found_in_all:
			common_types.append(type)
	
	for button in buttons:
		var template = button.get_meta("template")
		
		button.visible = true
		if template.autohide and not template.are_types_valid(common_types):
			button.visible = false

func update_selected():
	update_visibility()
	
	if not get_selected():
		create_template_button.set_disabled(true)
		return
	
	var t = get_selected()[0].data.time
	for item in get_selected():
		if t != item.data.time:
			create_template_button.set_disabled(true)
			return
	
	create_template_button.set_disabled(false)

func create_template():
	var selected := get_selected()
	var template := template_from_note_array(selected, save_all_checkbox.pressed)
	template.name = template_name_line_edit.text if template_name_line_edit.text else "New Template"
	template.autohide = autohide_checkbox.pressed
	
	var path = category_list[category_option_button.get_selected_id()]
	
	var result = template.save(path)
	if result == ERR_ALREADY_EXISTS:
		template_name_confirmation_dialog.dialog_text = "That name is already in use!"
		
		return
	elif result == ERR_FILE_BAD_PATH:
		template_name_confirmation_dialog.dialog_text = "The name has to contain an ASCII character."
		
		return
	elif result != OK:
		Log.log(self, "Could not save template: " + str(result), Log.LogLevel.ERROR)
		
		return
	
	template_name_confirmation_dialog.hide()
	
	load_templates()

func _template_name_accepted():
	if not template_name_line_edit.text:
		return
	
	template_name_confirmation_dialog.hide()
	create_template()

func _template_name_changed(new_text):
	template_name_confirmation_dialog.dialog_text = "Please input a name for the template:"

func _on_create_template_pressed():
	template_name_confirmation_dialog.popup_centered()
	template_name_line_edit.clear()
	template_name_line_edit.call_deferred("grab_focus")

func _on_manage_templates_pressed():
	OS.shell_open(ProjectSettings.globalize_path(EDITOR_TEMPLATES_PATH))

static func _sort_templates_by_name(a: HBEditorTemplate, b: HBEditorTemplate) -> bool:
	return a.name < b.name

static func _sort_subfolders_by_name(a: Dictionary, b: Dictionary) -> bool:
	return a.name < b.name
