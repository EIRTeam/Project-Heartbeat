extends VBoxContainer

class_name HBSkinResourceEditor

@onready var open_texture_file_dialog := FileDialog.new()
@onready var open_font_file_dialog := FileDialog.new()
@onready var font_name_text_input = preload("res://menus/HBTextInput.tscn").instantiate()
@onready var texture_name_text_input := preload("res://menus/HBTextInput.tscn").instantiate()
@onready var tree := Tree.new()
@onready var delete_resource_confirmation_dialog := ConfirmationDialog.new()

const RESOURCE_TYPE_TEXTURE = 0
const RESOURCE_TYPE_FONT = 1
const RESOURCE_BUTTON_DELETE = 0
const RESOURCE_BUTTON_EDIT = 1

var resource_pack: HBResourcePack

var resource_storage: HBInspectorResourceStorage

var currently_creating_font_name := ""
var currently_creating_texture_name := ""

enum TEXTURE_IMPORT_MODE {
	NORMAL,
	ANIMATED
}

var texture_import_mode: int = TEXTURE_IMPORT_MODE.NORMAL

var button_pressed_item: TreeItem

var error_confirmation_dialog := ConfirmationDialog.new()

signal resource_deleted
signal resource_added

@onready var animated_texture_editor_window := Window.new()
@onready var animated_texture_editor: AnimatedTextureEditor = preload("res://tools/resource_pack_editor/skin_editor/AnimatedTextureEditor.tscn").instantiate()

func set_texture_import_mode(val):
	texture_import_mode = val
	match texture_import_mode:
		TEXTURE_IMPORT_MODE.NORMAL:
			open_texture_file_dialog.dialog_text = "Select a file to import"
			open_texture_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		TEXTURE_IMPORT_MODE.ANIMATED:
			open_texture_file_dialog.dialog_text = "Select files to import"
			open_texture_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES

func _ready():
	add_child(animated_texture_editor_window)
	animated_texture_editor_window.hide()
	animated_texture_editor_window.add_child(animated_texture_editor)
	animated_texture_editor_window.exclusive = true
	
	error_confirmation_dialog.title = "Error importing!"
	error_confirmation_dialog.exclusive = true
	add_child(error_confirmation_dialog)
	
	add_child(delete_resource_confirmation_dialog)
	delete_resource_confirmation_dialog.exclusive = true
	delete_resource_confirmation_dialog.dialog_text = "Are you sure you want to delete this resource?\nThis cannot be undone"
	delete_resource_confirmation_dialog.connect("confirmed", Callable(self, "_on_delete_resource_confirmed"))
	
	add_child(open_texture_file_dialog)
	add_child(open_font_file_dialog)
	open_texture_file_dialog.filters = ["*.png ; Portable network graphics"]
	open_font_file_dialog.filters = ["*.otf ; OpenType Font"]
	open_font_file_dialog.filters = ["*.otf ; OpenType Font", "*.ttf ; TrueType Font"]
	open_font_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_texture_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_texture_file_dialog.connect("file_selected", Callable(self, "user_add_texture_from_path"))
	open_texture_file_dialog.connect("files_selected", Callable(self, "user_add_animated_texture_from_paths"))
	open_font_file_dialog.connect("file_selected", Callable(self, "user_add_font_from_path"))
	open_font_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_texture_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	var _root := tree.create_item()
	tree.hide_root = true
	tree.columns = 2
	add_child(font_name_text_input)
	add_child(texture_name_text_input)
	font_name_text_input.text = "Enter your font's internal name"
	texture_name_text_input.text = "Enter your texture's internal name"
	font_name_text_input.connect("entered", Callable(self, "_on_font_name_text_entered"))
	texture_name_text_input.connect("entered", Callable(self, "_on_texture_name_text_entered"))
	
	var hbox_contanier := HBoxContainer.new()
	var add_texture_button := Button.new()
	add_texture_button.text = "Add texture"
	var add_animated_texture_button := Button.new()
	add_animated_texture_button.text = "Add animated texture"
	add_animated_texture_button.connect("pressed", Callable(self, "set_texture_import_mode").bind(TEXTURE_IMPORT_MODE.ANIMATED))
	add_animated_texture_button.connect("pressed", Callable(texture_name_text_input, "popup_centered"))
	var add_font_button := Button.new()
	add_font_button.text = "Add font"
	add_texture_button.connect("pressed", Callable(self, "set_texture_import_mode").bind(TEXTURE_IMPORT_MODE.NORMAL))
	add_texture_button.connect("pressed", Callable(texture_name_text_input, "popup_centered"))
	add_font_button.connect("pressed", Callable(font_name_text_input, "popup_centered"))

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	add_child(hbox_contanier)
	
	add_texture_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_font_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	hbox_contanier.add_child(add_texture_button)
	hbox_contanier.add_child(add_font_button)
	add_child(add_animated_texture_button)

	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL

	add_child(tree)
	
	tree.connect("button_pressed", Callable(self, "_on_item_button_pressed"))

func _on_font_name_text_entered(font_name: String):
	font_name_text_input.hide()
	if resource_storage.has_theme_font(font_name):
		show_error("A font with that name already exists!")
		return
	currently_creating_font_name = font_name
	open_font_file_dialog.popup_centered_ratio()

func _on_texture_name_text_entered(texture_name: String):
	texture_name_text_input.hide()
	if resource_storage.has_texture(texture_name):
		show_error("A texture with that name already exists!")
		return
	currently_creating_texture_name = texture_name
	open_texture_file_dialog.popup_centered_ratio()

func show_error(err: String):
	error_confirmation_dialog.dialog_text = err
	error_confirmation_dialog.popup_centered()

func clear():
	tree.clear()
	tree.create_item()
func user_add_texture_from_path(path: String):
	if texture_import_mode == TEXTURE_IMPORT_MODE.ANIMATED:
		return
	assert(resource_pack)
	if FileAccess.file_exists(path):
		var skin_resources_path := resource_pack.get_skin_resources_path()
		if not DirAccess.dir_exists_absolute(skin_resources_path):
			DirAccess.make_dir_recursive_absolute(skin_resources_path)
		var f := FileAccess.open(path, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var array := f.get_buffer(4)
			if array == PackedByteArray([0x89, 0x50, 0x4E, 0x47]):
				f.close()
				var new_path := skin_resources_path.path_join(HBUtils.get_valid_filename(currently_creating_texture_name) + ".png")
				if FileAccess.file_exists(new_path):
					show_error("File with name %s already exists in skin" % new_path.get_file())
				else:
					DirAccess.copy_absolute(path, new_path)
					add_texture_from_path(currently_creating_texture_name, new_path)
			else:
				show_error("Not a valid PNG file")
		else:
			show_error("Error opening file %s" % path)
	emit_signal("resource_added")
func user_add_animated_texture_from_paths(paths: Array):
	for i in range(paths.size()):
		var path := paths[i] as String
		if FileAccess.file_exists(path):
			var skin_resources_path := resource_pack.get_skin_resources_path()
			if not DirAccess.dir_exists_absolute(skin_resources_path):
				DirAccess.make_dir_recursive_absolute(skin_resources_path)
			var f := FileAccess.open(path, FileAccess.READ)
			if FileAccess.get_open_error() == OK:
				var array := f.get_buffer(4)
				if array == PackedByteArray([0x89, 0x50, 0x4E, 0x47]):
					f.close()
					var frame_str := "_%0*d" % [str(paths.size()).length(), i]
					var new_path := skin_resources_path.path_join(HBUtils.get_valid_filename(currently_creating_texture_name) + frame_str + ".png")
					if FileAccess.file_exists(new_path):
						show_error("File with name %s already exists in skin" % new_path.get_file())
						return
				else:
					show_error("Not a valid PNG file")
					return
			else:
				show_error("Error opening file %s" % path)
				return
	# If we got here it means it's all OK, so let us copy shit over now!
	for i in range(paths.size()):
		var path := paths[i] as String
		if FileAccess.file_exists(path):
			var skin_resources_path := resource_pack.get_skin_resources_path()
			var frame_str := "_%0*d" % [str(paths.size()).length(), i]
			var new_path := skin_resources_path.path_join(HBUtils.get_valid_filename(currently_creating_texture_name) + frame_str + ".png")
			DirAccess.copy_absolute(path, new_path)
	add_animated_texture_from_paths(currently_creating_texture_name, paths)
	emit_signal("resource_added")

func user_add_font_from_path(path: String):
	assert(resource_pack)
	if FileAccess.file_exists(path):
		var skin_resources_path := resource_pack.get_skin_resources_path()
		if not DirAccess.dir_exists_absolute(skin_resources_path):
			DirAccess.make_dir_recursive_absolute(skin_resources_path)
		var f := FileAccess.open(path, FileAccess.READ)
		if FileAccess.get_open_error() == OK:
			var array := f.get_buffer(4)
			var extension := ".otf"
			var is_otf = array == PackedByteArray([0x4F, 0x54, 0x54, 0x4F])
			var is_ttf = array == PackedByteArray([0x00, 0x01, 0x00, 0x00])
			if is_otf or is_ttf:
				f.close()
				if is_ttf:
					extension = ".ttf"
				var new_path := skin_resources_path.path_join(HBUtils.get_valid_filename(currently_creating_font_name) + extension)
				if FileAccess.file_exists(new_path):
					show_error("File with name %s already exists in skin" % new_path.get_file())
				else:
					DirAccess.copy_absolute(path, new_path)
					add_font_from_path(currently_creating_font_name, new_path)
			else:
				show_error("Not a valid OTF/TTF file")
		else:
			show_error("Error opening file %s" % path)
	emit_signal("resource_added")

func add_texture(texture_name: String, path: String, texture: Texture2D):
	resource_storage.add_texture(texture_name, texture)
	
	var item := tree.create_item()
	item.set_text(0, texture_name)
	item.set_text(1, "Texture2D")
	item.set_meta("texture_name", texture_name)
	item.set_meta("is_animated_texture", false)
	item.set_meta("texture_path", path)
	item.set_meta("type", RESOURCE_TYPE_TEXTURE)
	item.add_button(1, preload("res://tools/icons/icon_remove.svg"), RESOURCE_BUTTON_DELETE)
			
func add_animated_texture(texture_name: String, texture: AnimatedTexture):
	resource_storage.add_texture(texture_name, texture)
	
	var item := tree.create_item()
	item.set_text(0, texture_name)
	item.set_text(1, "Animated Texture2D")
	item.set_meta("is_animated_texture", true)
	item.set_meta("animated_texture", texture)
	item.set_meta("texture_name", texture_name)
	item.set_meta("type", RESOURCE_TYPE_TEXTURE)
	item.add_button(1, preload("res://tools/icons/pencil.svg"), RESOURCE_BUTTON_EDIT)
	item.add_button(1, preload("res://tools/icons/icon_remove.svg"), RESOURCE_BUTTON_DELETE)
	
func _on_item_button_pressed(item: TreeItem, _column: int, id: int):
	button_pressed_item = item
	match id:
		RESOURCE_BUTTON_DELETE:
			delete_resource_confirmation_dialog.popup_centered()
		RESOURCE_BUTTON_EDIT:
			match item.get_meta("type"):
				RESOURCE_TYPE_TEXTURE:
					# Must be an animated texture
					animated_texture_editor.edit(item.get_meta("animated_texture"))
					animated_texture_editor_window.popup_centered_ratio()
func delete_resource(item: TreeItem):
	var resource_type := item.get_meta("type") as int
	match resource_type:
		RESOURCE_TYPE_FONT:
			var font := resource_storage.get_font(item.get_meta("font_name")) as Font
			DirAccess.remove_absolute(font.font_path)
			resource_storage.remove_font(item.get_meta("font_name"))
		RESOURCE_TYPE_TEXTURE:
			if item.get_meta("is_animated_texture"):
				var animated_texture := item.get_meta("animated_texture") as AnimatedTexture
				for frame in range(animated_texture.frames):
					DirAccess.remove_absolute(animated_texture.get_frame_texture(frame).get_meta("animated_texture_path"))
			else:
				DirAccess.remove_absolute(item.get_meta("texture_path") as String)
			resource_storage.remove_texture(item.get_meta("texture_name"))
	item.free()
	emit_signal("resource_deleted")
func _on_delete_resource_confirmed():
	delete_resource(button_pressed_item)
			
func add_font(font_name: String, path: String, font: Font):
	resource_storage.add_font(font_name, font)
	var item := tree.create_item()
	item.set_text(0, font_name)
	item.set_text(1, "Font")
	item.set_meta("font_name", font_name)
	item.set_meta("font_path", path)
	item.set_meta("type", RESOURCE_TYPE_FONT)
	item.add_button(1, preload("res://tools/icons/icon_remove.svg"), RESOURCE_BUTTON_DELETE)
func add_texture_from_path(texture_name: String, path: String):
	assert(resource_pack)
	var img := Image.new()
	if not img.load(path) == OK:
		show_error("Error loading texture %s from %s" % [texture_name, path])
		return
	var imgtex := ImageTexture.create_from_image(img) #,HBGame.platform_settings.texture_mode
	
	add_texture(texture_name, path, imgtex)
	
func add_animated_texture_from_paths(texture_name: String, paths: Array):
	assert(resource_pack)
	var animated_tex := AnimatedTexture.new()
	animated_tex.frames = paths.size()
	animated_tex.fps = 24
	for i in range(paths.size()):
		var path := paths[i] as String
		var img := Image.new()
		if not img.load(path) == OK:
			show_error("Error loading texture %s from %s" % [texture_name, path])
			return
		var imgtex := ImageTexture.create_from_image(img) #,HBGame.platform_settings.texture_mode
		imgtex.set_meta("animated_texture_path", resource_pack._path.path_join("skin_resources").path_join(texture_name + "_%0*d" % [str(paths.size()).length(), i] + ".png"))
		animated_tex.set_frame_texture(i, imgtex)
	add_animated_texture(texture_name, animated_tex)
	
func add_font_from_path(font_name: String, path: String):
	assert(resource_pack)
	var fnt := FontFile.new()
	fnt.load_dynamic_font(path)
	add_font(font_name, path, fnt)

	
func to_skin_resources() -> HBSkinResources:
	var resources := HBSkinResources.new()
	for item in tree.get_root().get_children():
		assert(item.has_meta("type"))
		match item.get_meta("type"):
			RESOURCE_TYPE_TEXTURE:
				var texture_name := item.get_meta("texture_name") as String
				var is_animated := item.get_meta("is_animated_texture") as bool
				if is_animated:
					var animated_texture := item.get_meta("animated_texture") as AnimatedTexture
					var frames := []
					resources.textures[texture_name] = {
						"frames": frames
					}
					for i in range(animated_texture.frames):
						frames.push_back({
							"duration": animated_texture.get_frame_duration(i),
							"texture_path": animated_texture.get_frame_texture(i).get_meta("animated_texture_path").get_file()
						})
				else:
					var texture_path := item.get_meta("texture_path") as String
					resources.textures[texture_name] = texture_path.get_file()
			RESOURCE_TYPE_FONT:
				var font_name := item.get_meta("font_name") as String
				var font_path := item.get_meta("font_path") as String
				resources.fonts[font_name] = font_path.get_file()
	return resources

func from_skin_resource_cache(cache: HBSkinResourcesCache):
	resource_storage = HBInspectorResourceStorage.new()
	for texture_name in cache.skin_resources.textures:
		if cache.skin_resources.is_animated_texture(texture_name):
			add_animated_texture(texture_name, cache.get_texture(texture_name))
		else:
			add_texture(texture_name, cache.skin_resources.get_texture_path(texture_name), cache.get_texture(texture_name))
	for font_name in cache.skin_resources.fonts:
		add_font(font_name, cache.skin_resources.get_font_path(font_name), cache.get_font(font_name))
		
