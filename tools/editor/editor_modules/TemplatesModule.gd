extends HBEditorModule

const EDITOR_TEMPLATES_PATH := "user://editor_templates"

onready var templates_container: VBoxContainer = get_node("%TemplatesVBoxContainer")
onready var create_template_button: HBEditorButton = get_node("%CreateTemplateButton")
onready var template_name_confirmation_dialog: ConfirmationDialog = get_node("%TemplateNameConfirmationDialog")
onready var template_name_line_edit: HBEditorLineEdit = get_node("%TemplateNameLineEdit")
onready var save_all_checkbox: CheckBox = get_node("%SaveAllCheckBox")
onready var template_deletion_confirmation_dialog: ConfirmationDialog = get_node("%TemplateDeletionConfirmationDialog")
onready var template_deletion_tree: Tree = get_node("%TemplateDeletionTree")
onready var really_delete_confirmation_dialog: ConfirmationDialog = get_node("%ReallyReallyDeleteConfirmationDialog")

onready var default_templates = preload("res://tools/editor/editor_modules/TemplatesModule/DefaultTemplates.gd").new()

var templates := []

func _ready():
	template_deletion_confirmation_dialog.get_ok().set_text("Delete")
	really_delete_confirmation_dialog.get_ok().set_text("Delete")
	
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
		var result = dir.make_dir(EDITOR_TEMPLATES_PATH)
		
		if result != OK:
			Log.log(self, "Error creating templates directory: " + result, Log.LogLevel.ERROR)
			return
		
		for template in default_templates.default_templates:
			template.save()
	
	templates.clear()
	
	var result := dir.open(EDITOR_TEMPLATES_PATH)
	if result != OK:
		Log.log(self, "Error opening templates directory: " + str(result), Log.LogLevel.ERROR)
		return
	
	result = dir.list_dir_begin(true)
	if result != OK:
		Log.log(self, "Error listing templates directory: " + str(result), Log.LogLevel.ERROR)
		return
	
	var next = dir.get_next()
	while next:
		if next.ends_with(".json"):
			var file := File.new()
			
			result = file.open(HBUtils.join_path(EDITOR_TEMPLATES_PATH, next), File.READ)
			if result != OK:
				Log.log(self, "Error opening template file (" + HBUtils.join_path(EDITOR_TEMPLATES_PATH, next) + "): " + str(result), Log.LogLevel.ERROR)
				next = dir.get_next()
				
				continue
			
			var json_result = JSON.parse(file.get_as_text()).result
			
			if json_result == null:
				return
			
			var template = HBEditorTemplate.deserialize(json_result)
			template.filename = next
			templates.append(template)
		
		next = dir.get_next()
	
	update_templates()

func update_templates():
	for child in templates_container.get_children():
		child.queue_free()
	
	transforms.clear()
	template_deletion_tree.clear()
	
	var root = template_deletion_tree.create_item()
	
	templates.sort_custom(self, "_sort_templates_by_name")
	for template in templates:
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
		
		templates_container.add_child(button)
		
		var item = template_deletion_tree.create_item(root)
		
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_text(0, template.name)
		
		item.set_meta("filename", template.filename)

func update_selected():
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
	
	var result = template.save()
	if result == ERR_ALREADY_EXISTS:
		template_name_confirmation_dialog.dialog_text = "That name is already in use!"
		
		return
	elif result != OK:
		Log.log(self, "Could not save template: " + str(result), Log.LogLevel.ERROR)
		return
	
	template_name_confirmation_dialog.hide()
	
	templates.append(template)
	update_templates()

func delete_templates():
	var root := template_deletion_tree.get_root()
	var next := root.get_children()
	
	var dir := Directory.new()
	while next:
		if next.is_checked(0):
			# Delete this template
			var path = HBUtils.join_path(EDITOR_TEMPLATES_PATH, next.get_meta("filename"))
			
			var result = dir.remove(path)
			if result != OK:
				Log.log(self, "Could not remove template \"" + next.get_text(0) + "\": " + str(result), Log.LogLevel.ERROR)
		 
		next = next.get_next()
	
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

func _on_delete_templates_pressed():
	template_deletion_confirmation_dialog.popup_centered()

static func _sort_templates_by_name(a: HBEditorTemplate, b: HBEditorTemplate) -> bool:
	return a.name < b.name
