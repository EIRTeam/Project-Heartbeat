extends Control

signal back

@onready var scroll_container = get_node("VBoxContainer/Panel/ScrollContainer")
@onready var item_container = get_node("VBoxContainer/Panel/ScrollContainer/VBoxContainer")
@onready var rebuilding_note_atlas_container = get_node("CenterContainer")
@onready var categories_container := get_node("VBoxContainer/CategoriesContainer")
var selected_resource_pack_scene

var CATEGORY_NAMES = {
	HBResourcePack.RESOURCE_PACK_TYPE.NOTE_PACK: tr("Note Packs"),
	HBResourcePack.RESOURCE_PACK_TYPE.SKIN: tr("Skins")
}

var filter_category: int = HBResourcePack.RESOURCE_PACK_TYPE.NOTE_PACK

func _ready():
	populate_categories()
	
	rebuilding_note_atlas_container.hide()
	selected_resource_pack_scene = null

	
	connect("focus_entered", Callable(scroll_container, "grab_focus").bind(), CONNECT_DEFERRED)
	connect("focus_entered", Callable(scroll_container, "select_item").bind(0), CONNECT_DEFERRED)
	
func populate_categories():
	for category in CATEGORY_NAMES:
		var button := HBHovereableButton.new()
		button.text = CATEGORY_NAMES[category]
		categories_container.add_child(button)
		if category == HBResourcePack.RESOURCE_PACK_TYPE.NOTE_PACK:
			categories_container.select_button(0)
		button.connect("hovered", Callable(self, "_on_category_changed").bind(category))
func show_section():
	populate()
	
func _on_category_changed(new_cat: int):
	filter_category = new_cat
	populate()
func populate():
	for item in item_container.get_children():
		item.queue_free()
		item_container.remove_child(item)
	for pack_id in ResourcePackLoader.resource_packs:
		var resource_pack := ResourcePackLoader.resource_packs[pack_id] as HBResourcePack
		if resource_pack.pack_type != filter_category:
			continue
		var pack_scene = preload("res://menus/options_menu/ResourcePackItem.tscn").instantiate()
		item_container.add_child(pack_scene)
		pack_scene.set_pack(resource_pack)
		match resource_pack.pack_type:
			HBResourcePack.RESOURCE_PACK_TYPE.NOTE_PACK:
				var is_current = UserSettings.user_settings.resource_pack == pack_id
				pack_scene.set_checked(is_current)
				if is_current:
					selected_resource_pack_scene = pack_scene
				
			HBResourcePack.RESOURCE_PACK_TYPE.SKIN:
				var is_current = ResourcePackLoader.current_skin._path == resource_pack._path
				# Ugly but it works...
				pack_scene.set_checked(is_current)
				if is_current:
					selected_resource_pack_scene = pack_scene

		pack_scene.connect("pressed", Callable(self, "_on_resource_pack_pressed").bind(resource_pack, pack_scene))
	
func _input(event):
	if scroll_container.has_focus():
		if event.is_action("gui_left") or event.is_action("gui_right"):
			categories_container._gui_input(event)
			return
		if event.is_action_pressed("gui_cancel"):
			get_viewport().set_input_as_handled()
			HBGame.fire_and_forget_sound(HBGame.menu_back_sfx, HBGame.sfx_group)
			emit_signal("back")
func _on_resource_pack_pressed(resource_pack: HBResourcePack, scene: Control):
	if rebuilding_note_atlas_container.visible:
		return
	if selected_resource_pack_scene == scene:
		return
	scene.set_checked(true)
	if selected_resource_pack_scene and not selected_resource_pack_scene == scene:
		selected_resource_pack_scene.set_checked(false)
	selected_resource_pack_scene = scene

	match resource_pack.pack_type:
		HBResourcePack.RESOURCE_PACK_TYPE.NOTE_PACK:
			if resource_pack._id != UserSettings.user_settings.resource_pack:
				UserSettings.user_settings.resource_pack = resource_pack._id

				UserSettings.save_user_settings()
				rebuilding_note_atlas_container.show()
				await get_tree().process_frame
				await get_tree().process_frame
				ResourcePackLoader.rebuild_final_atlases()
				rebuilding_note_atlas_container.hide()
		HBResourcePack.RESOURCE_PACK_TYPE.SKIN:
			if resource_pack._path == ResourcePackLoader.fallback_skin._path:
				ResourcePackLoader.current_skin = ResourcePackLoader.fallback_skin
				UserSettings.user_settings.ui_skin = ""
			else:
				ResourcePackLoader.current_skin = resource_pack.get_skin()
				UserSettings.user_settings.ui_skin = resource_pack._id
			UserSettings.save_user_settings()
