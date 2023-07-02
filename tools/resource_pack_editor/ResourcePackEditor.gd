extends Control

@onready var tree: Tree = get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/Tree")
@onready var open_resource_pack_dialog := get_node("OpenResourcePackDialog")
@onready var open_graphic_file_dialog := get_node("FileDialog")

const SUBGRAPHIC_TYPES := ["note", "target", "multi_note", "multi_note_target"]
const SUBGRAPHIC_TYPES_NORMAL_NOTES := ["sustain_note", "sustain_target", "double_target", "double_note"]


@onready var top_level_tab_container := get_node("VBoxContainer/TabContainer")
@onready var atlas_preview_texture_rect := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Atlas Preview/VBoxContainer/AtlasPreviewTextureRect")
@onready var atlas_preview_label := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Atlas Preview/VBoxContainer/AtlasPreviewLabel")
@onready var remove_graphic_confirmation_dialog := get_node("RemoveGraphicConfirmationDialog")
@onready var metatlas_tab_container := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer")

@onready var error_dialog := get_node("ErrorDialog")
@onready var resize_confirmation_dialog := get_node("ResizeConfirmationDialog")

@onready var color_picker_popup := get_node("ColorPickerPopup")
@onready var color_picker_popup_color_picker := get_node("ColorPickerPopup/ColorPicker")

# Meta data
@onready var icon_pack_title_line_edit := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Metadata/ScrollContainer/VBoxContainer/TitleLineEdit")
@onready var icon_pack_creator_line_edit := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Metadata/ScrollContainer/VBoxContainer/PackCreatorLineEdit")

@onready var pack_icon_texture_rect := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Metadata/ScrollContainer/VBoxContainer/HBoxContainer/PackIconTextureRect")
@onready var no_pack_icon_image_label := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Metadata/ScrollContainer/VBoxContainer/HBoxContainer/PackIconTextureRect/NoPreviewImageLabel")

@onready var description_text_label := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Metadata/ScrollContainer/VBoxContainer/DescriptionTextLabel")
@onready var description_text_edit := get_node("VBoxContainer/TabContainer/Textures/MarginContainer/VBoxContainer/HSplitContainer/TabContainer/Metadata/ScrollContainer/VBoxContainer/DescriptionTextLabel/DescriptionTextEdit")

@onready var skin_editor := get_node("VBoxContainer/TabContainer/Skin")
@onready var texture_editor := get_node("VBoxContainer/TabContainer/Textures")

enum ITEM_BUTTONS {
	BROWSE,
	REMOVE,
	PICK_COLOR,
	RESET_PROPERTY
}

enum ITEM_TYPES {
	RANGE,
	COLOR_PICKER
}

var root_item: TreeItem

var current_pack: HBResourcePack

var _default_pack = HBResourcePack.new()

var _currently_opening_resource := ""
var _currently_opened_image: Image
var _currently_editing_property: String

var resource_items = {}
var property_items = {}
var resource_images_per_atlas = {
	"__no_atlas": []
}

var first_time_save_atlases = []

func _ready():
	top_level_tab_container.set_tab_title(0, "Resource Pack")
	#get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND, Vector2(1280, 720))
	tree.connect("button_pressed", Callable(self, "_on_button_pressed"))
	tree.connect("item_edited", Callable(self, "_on_item_edited"))
	open_resource_pack_dialog.popup_centered()
	
	# It's mandatory to open a pack on startup, if not the user gets sent back to the menu
	open_resource_pack_dialog.get_cancel_button().connect("pressed", Callable(self, "_exit"))
	open_resource_pack_dialog.close_requested.connect(_exit)
	open_resource_pack_dialog.connect("pack_opened", Callable(self, "_on_OpenResourcePackDialog_pack_opened"))
	tree.set_column_expand(0, true)
	tree.set_column_expand(1, false)
	tree.set_column_custom_minimum_width(1, 150)
	
	$FileDialog.set_current_dir(UserSettings.user_settings.last_graphics_dir)
	$FileDialogPackIcon.set_current_dir(UserSettings.user_settings.last_graphics_dir)
	
func _exit():
	get_tree().change_scene_to_packed(load("res://menus/MainMenu3D.tscn"))

func get_resources_dir_for_atlas(atlas_name: String) -> String:
	if atlas_name == "__no_atlas":
		return HBUtils.join_path(current_pack._path, "graphics")
	else:
		return HBUtils.join_path(current_pack._path, "editor_resources")

func add_graphic_item(parent: TreeItem, text: String, resource_name: String, atlas_name="__no_atlas", require_square=true, recommended_size = Vector2(128, 128)):
	var resources_dir := get_resources_dir_for_atlas(atlas_name)
	
	var item := tree.create_item(parent)
	resource_name = resource_name.to_lower()
	item.set_text(0, text + " (%dx%d)" % [recommended_size.x, recommended_size.y])
	item.set_meta("resource_name", resource_name)
	item.set_meta("require_square", require_square)
	item.set_meta("recommended_size", recommended_size)
	item.set_meta("resize_to_recommended", true)
	item.set_meta("atlas_name", atlas_name)
	var resource_path = HBUtils.join_path(resources_dir, resource_name)
	if FileAccess.file_exists(resource_path):
		if not resource_name in current_pack.notes_atlas_data:
			first_time_save_atlases.append(atlas_name)
		var img = Image.new()
		img.load(resource_path)
		resource_images_per_atlas[atlas_name][resource_name] = img
		var icon = ImageTexture.create_from_image(img)
		item.set_icon(0, icon)
		
	item.add_button(1, preload("res://tools/icons/icon_folder.svg"), ITEM_BUTTONS.BROWSE, false, "Browse graphic")
	var have_resource = resource_name in resource_images_per_atlas[atlas_name]
	item.add_button(1, preload("res://tools/icons/icon_close.svg"), ITEM_BUTTONS.REMOVE, !have_resource, "Remove graphic usage from pack")
	resource_items[resource_name] = item
	
func add_range_item(parent: TreeItem, text: String, property_name: String, minimum: float, maximum: float, step: float):
	var item := tree.create_item(parent)
	item.set_suffix(0, text)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	item.set_meta("property_name", property_name)
	item.set_meta("item_type", ITEM_TYPES.RANGE)
	item.set_tooltip_text(0, "Override this property")
	item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
	tree.set_block_signals(true)
	item.set_range_config(1, minimum, maximum, step)
	item.set_range(1, current_pack.get(property_name))
	item.set_checked(0, property_name in current_pack.property_overrides)
	tree.set_block_signals(false)
	item.set_editable(1, true)
	var is_property_default_value = current_pack.get(property_name) == _default_pack.get(property_name)
	item.add_button(1, preload("res://tools/icons/icon_close.svg"), ITEM_BUTTONS.RESET_PROPERTY, is_property_default_value, "Reset to default value")
	item.set_meta("reset_button_i", item.get_button_count(1)-1)
	property_items[property_name] = item
	
func add_color_item(parent: TreeItem, text: String, property_name: String):
	var item := tree.create_item(parent)
	item.set_suffix(0, text)
	item.set_editable(0, true)
	item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
	
	tree.set_block_signals(true)
	item.set_checked(0, property_name in current_pack.property_overrides)
	tree.set_block_signals(false)
	
	item.set_tooltip_text(0, "Override this property")
	item.set_meta("property_name", property_name)
	item.set_meta("item_type", ITEM_TYPES.COLOR_PICKER)
	item.add_button(1, preload("res://tools/icons/ColorPick.svg"), ITEM_BUTTONS.PICK_COLOR, false, "Pick color")
	item.set_custom_bg_color(1, current_pack.get(property_name))
	var is_property_default_value = current_pack.get(property_name) == _default_pack.get(property_name)
	item.add_button(1, preload("res://tools/icons/icon_close.svg"), ITEM_BUTTONS.RESET_PROPERTY, is_property_default_value, "Reset to default value")
	item.set_meta("reset_button_i", item.get_button_count(1)-1)
	property_items[property_name] = item
	
func populate_items():
	tree.clear()
	root_item = tree.create_item()
	root_item.set_text(0, "Resource Pack")
	var note_category_item := tree.create_item(root_item)
	note_category_item.set_text(0, "Note Graphics")
	for note_name in HBBaseNote.NOTE_TYPE:
		var capitalized_note_name = note_name.capitalize()
		var note := HBBaseNote.NOTE_TYPE[note_name] as int
		var note_item := tree.create_item(note_category_item)
		note_item.set_text(0, capitalized_note_name)
		note_item.collapsed = true
		
		add_color_item(note_item, "Trail Color", "%s_trail_color" % [note_name.to_lower()])
		add_range_item(note_item, "Trail Margin", "%s_trail_margin" % [note_name.to_lower()], 0.0, 0.1, 0.01)
		add_graphic_item(note_item, "Note", "%s_note.png" % [note_name], "notes")
		add_graphic_item(note_item, "Target", "%s_target.png" % [note_name], "notes")
		
		if note in [HBNoteData.NOTE_TYPE.UP, HBNoteData.NOTE_TYPE.DOWN, HBNoteData.NOTE_TYPE.LEFT,
				HBNoteData.NOTE_TYPE.RIGHT, HBNoteData.NOTE_TYPE.HEART]:
			add_graphic_item(note_item, "Multi Note", "%s_multi_note.png" % [note_name], "notes")
			add_graphic_item(note_item, "Multi Note Target", "%s_multi_note_target.png" % [note_name], "notes")
			add_graphic_item(note_item, "Double Note", "%s_double_note.png" % [note_name], "notes")
			add_graphic_item(note_item, "Double Note Target", "%s_double_note_target.png" % [note_name], "notes")
			add_graphic_item(note_item, "Sustain Note", "%s_sustain_note.png" % [note_name], "notes")
			add_graphic_item(note_item, "Sustain Target", "%s_sustain_note_target.png" % [note_name], "notes")
		
		if note in [HBNoteData.NOTE_TYPE.SLIDE_LEFT, HBNoteData.NOTE_TYPE.SLIDE_RIGHT]:
			add_graphic_item(note_item, "Multi Note", "%s_multi_note.png" % [note_name], "notes")
			add_graphic_item(note_item, "Multi Note Target", "%s_multi_note_target.png" % [note_name], "notes")
		if note in [HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_LEFT, HBNoteData.NOTE_TYPE.SLIDE_CHAIN_PIECE_RIGHT]:
			add_graphic_item(note_item, "Target Blue", "%s_target_blue.png" % [note_name], "notes")
	var misc_item := tree.create_item(note_category_item)
	misc_item.set_text(0, "Other Note Graphics")
	misc_item.collapsed = true
	add_graphic_item(misc_item, "Timing Arm", "timing_arm.png", "notes")
	add_graphic_item(misc_item, "Multi Laser", "multi_laser.png", "__no_atlas", false, Vector2(256, 64))
	add_graphic_item(misc_item, "Hold Text", "hold_text.png", "notes")
	add_graphic_item(misc_item, "Hold Text Multi", "hold_text_multi.png", "notes")
	add_graphic_item(misc_item, "Note Trail", "note_trail.png", "__no_atlas", false, Vector2(256, 64))
	if OS.has_feature("editor"):
		add_graphic_item(misc_item, "Note Hit Bubble", "bubble.png", "effects", true, Vector2(496, 496))
		add_graphic_item(misc_item, "Note Hit Flare", "flare.png", "effects", true, Vector2(800, 800))
		add_graphic_item(misc_item, "Note Hit Loop", "loop.png", "effects", true, Vector2(310, 310))
	add_graphic_item(misc_item, "Sustain Trail", "sustain_trail.png", "__no_atlas", true, Vector2(128, 128))
func _on_button_pressed(item: TreeItem, _column: int, id: int):
	if item.has_meta("resource_name"):
		_currently_opening_resource = item.get_meta("resource_name")
	if item.has_meta("property_name"):
		_currently_editing_property = item.get_meta("property_name")
	match id:
		ITEM_BUTTONS.BROWSE:
			open_graphic_file_dialog.popup_centered()
		ITEM_BUTTONS.REMOVE:
			remove_graphic_confirmation_dialog.popup_centered()
		ITEM_BUTTONS.PICK_COLOR:
			color_picker_popup_color_picker.set_block_signals(true)
			color_picker_popup_color_picker.color = current_pack.get(_currently_editing_property) as Color
			color_picker_popup_color_picker.set_block_signals(false)
			color_picker_popup.global_position = get_global_mouse_position()
			color_picker_popup.popup()
		ITEM_BUTTONS.RESET_PROPERTY:
			var default_val = _default_pack.get(_currently_editing_property)
			current_pack.set(_currently_editing_property, default_val)
			item.set_button_disabled(1, item.get_meta("reset_button_i"), true)
			match item.get_meta("item_type"):
				ITEM_TYPES.RANGE:
					item.set_range(1, default_val)
				ITEM_TYPES.COLOR_PICKER:
					item.set_custom_bg_color(1, default_val)
			tree.set_block_signals(true)
			item.set_checked(0, false)
			if _currently_editing_property in current_pack.property_overrides:
				current_pack.property_overrides.erase(_currently_editing_property)
			tree.set_block_signals(false)

func _on_OpenResourcePackDialog_pack_opened(pack: HBResourcePack):
	first_time_save_atlases = []
	current_pack = pack
	skin_editor.resource_pack = pack
	resource_images_per_atlas = {
		"__no_atlas": {}
	}
	
	tree.visible = !pack.is_skin()
	metatlas_tab_container.set_tab_hidden(1, pack.is_skin())
	
	top_level_tab_container.set_tab_hidden(1, !pack.is_skin())
	
	var atlases = ResourcePackLoader.ATLASES
	
	if not OS.has_feature("editor"):
		atlases.erase("effects")
	
	for atlas_name in atlases:
		resource_images_per_atlas[atlas_name] = {}
	populate_items()
	for atlas_name in atlases:
		_generate_atlas(atlas_name, atlas_name in first_time_save_atlases)
	
	icon_pack_title_line_edit.text = pack.pack_name
	icon_pack_creator_line_edit.text = pack.pack_author_name
	
	# Disconnects these so we won't be kicked to the menu if close the modal
	if open_resource_pack_dialog.get_cancel_button().is_connected("pressed", Callable(self, "_exit")):
		open_resource_pack_dialog.get_cancel_button().disconnect("pressed", Callable(self, "_exit"))
		open_resource_pack_dialog.close_requested.connect(self._exit)
	pack_icon_texture_rect.texture = null
	no_pack_icon_image_label.show()
	var pack_icon := current_pack.get_pack_icon()
	if pack_icon:
		var pack_icon_tex := ImageTexture.create_from_image(pack_icon)
		no_pack_icon_image_label.hide()
		pack_icon_texture_rect.texture = pack_icon_tex
	description_text_edit.text = current_pack.pack_description
	description_text_edit.show()

func _generate_atlas(atlas_name: String, save=true):
	if atlas_name == "__no_atlas":
		return
	var time_start = Time.get_ticks_usec()
	var out = HBUtils.pack_images_turbo16(resource_images_per_atlas[atlas_name], 1)
	current_pack.set(atlas_name + "_atlas_data", out.atlas_data)
	var texture := out.texture as Texture2D
	atlas_preview_texture_rect.set_atlas(out)
	atlas_preview_label.text = "Atlas size: %s" % [str(texture.get_size())]
	if save:
		current_pack.save_pack()
		var atlas_path := current_pack.get_atlas_path(atlas_name)
		if not DirAccess.dir_exists_absolute(atlas_path.get_base_dir()):
			DirAccess.make_dir_recursive_absolute(atlas_path.get_base_dir())
		if texture.get_size().length() > 0:
			var err: Error = texture.get_image().save_png(atlas_path)
			if err != OK:
				show_error("Error saving atlas, error code %d" % [err])
	var time_end = Time.get_ticks_usec()
	print("_generate_atlas took %d microseconds" % [(time_end - time_start)])

func set_resource_image(atlas_name: String, resource_name: String, image: Image):
	var resources_dir := get_resources_dir_for_atlas(atlas_name)
	var resource_item := resource_items[resource_name] as TreeItem
	resource_images_per_atlas[atlas_name][resource_name] = image
	resource_item.set_button_disabled(1, ITEM_BUTTONS.REMOVE, false)
	image.save_png(HBUtils.join_path(resources_dir, resource_name))
	var tex = ImageTexture.create_from_image(image)
	resource_item.set_icon(0, tex)
	_generate_atlas(atlas_name)

func _on_FileDialog_file_selected(path):
	var resource_item := resource_items[_currently_opening_resource] as TreeItem
	var resources_dir = get_resources_dir_for_atlas(resource_item.get_meta("atlas_name" as String))
	if not DirAccess.dir_exists_absolute(resources_dir):
		DirAccess.make_dir_recursive_absolute(resources_dir)
	var img := Image.new()
	var img_err = img.load(path)
	if img_err == OK:
		_currently_opened_image = img
		if resource_item.get_meta("require_square"):
			if img.get_size().x != img.get_size().y:
				var recommended_size := resource_item.get_meta("recommended_size") as Vector2i
				var err = "Error loading image, it must be square, preferably %d by %d pixels" % \
					[recommended_size.x, recommended_size.y]
				show_error(err)
				return
		if resource_item.get_meta("resize_to_recommended"):
			var image_size := img.get_size()
			var recommended_size := resource_item.get_meta("recommended_size") as Vector2i
			if image_size != recommended_size:
				var d_vals = {
					"image_x": image_size.x,
					"image_y": image_size.y,
					"rec_x": recommended_size.x,
					"rec_y": recommended_size.y
				}
				var d_t = """The image you provided is of dimensions {image_x} by {image_y} pixels
							However, a {rec_x} by {rec_y} pixels image is required
							Do you want to resize your image to that size now?""".format(d_vals)
				resize_confirmation_dialog.dialog_text = d_t
				resize_confirmation_dialog.popup_centered()
				return
		set_resource_image(resource_item.get_meta("atlas_name"), _currently_opening_resource, img)
	else:
		show_error("Error loading image, error code %d" % [img_err])
	
	UserSettings.user_settings.last_graphics_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	$FileDialogPackIcon.set_current_dir(UserSettings.user_settings.last_graphics_dir)


func _user_regenerate_atlas(from_disk = false):
	if from_disk:
		populate_items()
	_generate_atlas("notes")

func _on_RemoveGraphicConfirmationDialog_confirmed():
	var resource_item := resource_items[_currently_opening_resource] as TreeItem
	var atlas_name = resource_item.get_meta("atlas_name") as String
	var resources_dir := get_resources_dir_for_atlas(atlas_name)
	var resource_path := HBUtils.join_path(resources_dir, _currently_opening_resource)
	if FileAccess.file_exists(resource_path):
		DirAccess.remove_absolute(resource_path)
		if _currently_opening_resource in resource_images_per_atlas[atlas_name]:
			resource_images_per_atlas[atlas_name].erase(_currently_opening_resource)
		var item := resource_items[_currently_opening_resource] as TreeItem
		item.set_icon(0, null)
		item.set_button_disabled(1, ITEM_BUTTONS.REMOVE, true)
		_generate_atlas(atlas_name)


func _on_SaveButton_pressed():
	current_pack.pack_name = icon_pack_title_line_edit.text
	current_pack.pack_author_name = icon_pack_creator_line_edit.text
	current_pack.pack_description = description_text_edit.text
	current_pack.save_pack()
	if current_pack.is_skin():
		skin_editor.save_skin()
	else:
		_generate_atlas("notes")
		if OS.has_feature("editor"):
			_generate_atlas("effects")

func show_error(error: String):
	error_dialog.dialog_text = error
	error_dialog.popup_centered()
func _on_item_edited():
	var selected := tree.get_selected()
	if selected:
		var property_name = selected.get_meta("property_name") as String
		match selected.get_cell_mode(1):
			TreeItem.CELL_MODE_RANGE:
				current_pack.set(property_name, selected.get_range(1))
				var is_property_default_value = current_pack.get(property_name) == _default_pack.get(property_name)
				prints(current_pack.get(property_name), _default_pack.get(property_name))
				var item := property_items[property_name] as TreeItem
				item.set_button_disabled(1, item.get_meta("reset_button_i"), is_property_default_value)
				if not property_name in current_pack.property_overrides:
					current_pack.property_overrides.append(property_name)
				item.set_checked(0, true)
		match selected.get_cell_mode(0):
			TreeItem.CELL_MODE_CHECK:
				if selected.is_checked(0):
					if not property_name in current_pack.property_overrides:
						current_pack.property_overrides.append(property_name)
				elif property_name in current_pack.property_overrides:
					current_pack.property_overrides.erase(property_name)

func _on_ResizeConfirmationDialog_confirmed():
	var resource_item := resource_items[_currently_opening_resource] as TreeItem
	var recommended_size := resource_item.get_meta("recommended_size") as Vector2
	_currently_opened_image.resize(recommended_size.x, recommended_size.y)
	set_resource_image(resource_item.get_meta("atlas_name"), _currently_opening_resource, _currently_opened_image)


func _on_ColorPicker_color_changed(color: Color):
	current_pack.set(_currently_editing_property, color)
	var item = property_items[_currently_editing_property] as TreeItem
	var is_property_default_value = current_pack.get(_currently_editing_property) == _default_pack.get(_currently_editing_property)
	item.set_button_disabled(1, item.get_meta("reset_button_i"), is_property_default_value)
	item.set_custom_bg_color(1, color)
	tree.set_block_signals(true)
	if not _currently_editing_property in current_pack.property_overrides:
		current_pack.property_overrides.append(_currently_editing_property)
	item.set_checked(0, true)
	tree.set_block_signals(false)

func show_error_code(text: String, error_code: int):
	if error_code != OK:
		show_error("%s: %s" % [text, HBError.ERR2STR[error_code]])
	return error_code

func _on_ConfirmationDialog_confirmed():
	_exit()

func _replace_preview_image(path: String):
	var img := Image.new()
	var err := img.load(path)
	if show_error_code("Error loading image", err) == OK:
		if img.get_size().x  > 512 and img.get_size().y > 512:
			show_error("Maximum image size is 512x512")
		else:
			var err_img := img.save_png(current_pack.get_pack_icon_path())
			if show_error_code("Error saving resource pack image", err_img) == OK:
				var texture := ImageTexture.create_from_image(img)
				pack_icon_texture_rect.texture = texture
				no_pack_icon_image_label.hide()
	
	UserSettings.user_settings.last_graphics_dir = path.get_base_dir()
	UserSettings.save_user_settings()
	$FileDialog.set_current_dir(UserSettings.user_settings.last_graphics_dir)


func _on_PreviewBBCodeCheckbox_toggled(button_pressed):
	if button_pressed:
		description_text_label.text = description_text_edit.text
		description_text_label.bbcode_enabled = true
	description_text_edit.visible = !button_pressed



func _on_HelpButton_pressed():
	OS.shell_open("https://steamcommunity.com/sharedfiles/filedetails/?id=2800271334")
