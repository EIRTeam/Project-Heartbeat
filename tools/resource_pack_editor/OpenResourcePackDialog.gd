extends ConfirmationDialog

@onready var tree: Tree = get_node("VBoxContainer/VBoxContainer/Tree")
@onready var create_icon_pack_dialog_text_edit = get_node("CreateIconPackDialog/VBoxContainer/TextEdit")
@onready var icon_pack_creator_skin_specific_options := get_node("CreateIconPackDialog/VBoxContainer/SkinSpecificOptions")
@onready var copy_original_skin_checkbox := get_node("CreateIconPackDialog/VBoxContainer/SkinSpecificOptions/CopyOriginalSkinCheckbox")
@onready var pack_type_option_button := get_node("CreateIconPackDialog/VBoxContainer/HBoxContainer/PackTypeOptionButton")

@onready var workshop_upload_dialog = get_node("WorkshopUploadDialog")

@onready var workshop_upload_button = get_node("VBoxContainer/VBoxContainer2/UploadToWorkshopButton")
@onready var delete_resource_pack_button = get_node("VBoxContainer/VBoxContainer2/DeleteResourcePackButton")

signal pack_opened(pack)

func populate_list(allow_builtin=false):
	tree.hide_root = true
	tree.clear()
	var root = tree.create_item()
	for pack_id in ResourcePackLoader.resource_packs:
		var pack: HBResourcePack = ResourcePackLoader.resource_packs[pack_id] as HBResourcePack
		if pack._path.begins_with("user://editor_resource_packs") or (allow_builtin and pack._path.begins_with("res://")):
			var item: TreeItem = tree.create_item(root)
			item.set_text(0, pack.pack_name)
			item.set_meta("pack", pack)
	if allow_builtin:
		var item: TreeItem = tree.create_item(root)
		item.set_text(0, ResourcePackLoader.fallback_pack.pack_name)
		item.set_meta("pack", ResourcePackLoader.fallback_pack)

func _ready():
	connect("about_to_popup", Callable(self, "_on_about_to_show"))
	workshop_upload_button.disabled = true
	delete_resource_pack_button.disabled = true
func _on_about_to_show():
	populate_list()

func _on_CreateIconPackDialog_confirmed():
	var file_name := HBUtils.get_valid_filename(create_icon_pack_dialog_text_edit.text) as String
	if file_name.strip_edges() != "":
		var meta_path = HBUtils.join_path("user://editor_resource_packs", file_name)
		if not DirAccess.dir_exists_absolute(meta_path):
			DirAccess.make_dir_recursive_absolute(meta_path)
		var pack := HBResourcePack.new()
		pack.pack_name = create_icon_pack_dialog_text_edit.text
		pack._path = meta_path
		pack.pack_type = pack_type_option_button.selected
		pack._id = file_name
		if copy_original_skin_checkbox.pressed:
			HBUtils.copy_recursive(ResourcePackLoader.fallback_skin._path.path_join("skin_resources"), pack.get_skin_resources_path())
			ResourcePackLoader.fallback_skin.save_to_file(pack.get_skin_config_path())
		else:
			var skin := HBUISkin.new()
			skin.save_to_file(pack.get_skin_config_path())
		ResourcePackLoader.resource_packs[file_name] = pack
		pack.save_pack()
	populate_list()

func _on_OpenResourcePackDialog_confirmed():
	if tree.get_selected():
		emit_signal("pack_opened", tree.get_selected().get_meta("pack"))
		hide()

func _unhandled_input(event):
	if event.is_action_pressed("show_hidden"):
		populate_list(true)


func _on_UploadToWorkshopButton_pressed():
	workshop_upload_dialog.set_resource_pack(tree.get_selected().get_meta("pack"))
	workshop_upload_dialog.popup_centered()

func _on_Tree_item_selected():
	workshop_upload_button.disabled = false
	delete_resource_pack_button.disabled = false

func _on_Tree_nothing_selected():
	workshop_upload_button.disabled = true
	delete_resource_pack_button.disabled = true

func _on_PackTypeOptionButton_item_selected(index):
	icon_pack_creator_skin_specific_options.hide()
	if index == HBResourcePack.RESOURCE_PACK_TYPE.SKIN:
		icon_pack_creator_skin_specific_options.show()
