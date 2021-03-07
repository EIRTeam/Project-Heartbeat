extends Control

signal back

onready var scroll_container = get_node("VBoxContainer/Panel/ScrollContainer")
onready var item_container = get_node("VBoxContainer/Panel/ScrollContainer/VBoxContainer")
onready var rebuilding_note_atlas_container = get_node("CenterContainer")
var selected_resource_pack_scene
var note_override_resource_pack_scene
func _ready():
	rebuilding_note_atlas_container.hide()
	selected_resource_pack_scene = null
	note_override_resource_pack_scene = null

	
	connect("focus_entered", scroll_container, "grab_focus")
	
func show_section():
	populate()
	
func populate():
	for item in item_container.get_children():
		item.queue_free()
		item_container.remove_child(item)
	for pack_id in ResourcePackLoader.resource_packs:
		var resource_pack := ResourcePackLoader.resource_packs[pack_id] as HBResourcePack
		var pack_scene = preload("res://menus/options_menu/ResourcePackItem.tscn").instance()
		item_container.add_child(pack_scene)
		pack_scene.set_pack(resource_pack)
		if UserSettings.user_settings.resource_pack == pack_id:
			selected_resource_pack_scene = pack_scene
		pack_scene.set_checked(UserSettings.user_settings.resource_pack == pack_id)
		if UserSettings.user_settings.note_icon_override == pack_id:
			note_override_resource_pack_scene = pack_scene
		pack_scene.set_note_override(UserSettings.user_settings.note_icon_override == pack_id)

		pack_scene.connect("pressed", self, "_on_resource_pack_pressed", [resource_pack, pack_scene])
	
func _input(event):
	if scroll_container.has_focus():
		if event.is_action_pressed("gui_cancel"):
			get_tree().set_input_as_handled()
			emit_signal("back")
		if event.is_action_pressed("contextual_option"):
			get_tree().set_input_as_handled()
			var item = scroll_container.get_selected_item()
			if rebuilding_note_atlas_container.visible:
				return
			if item:
				if item == note_override_resource_pack_scene:
					UserSettings.user_settings.note_icon_override = "__resource_pack"
					item.set_note_override(false)
					note_override_resource_pack_scene = null
				else:
					if note_override_resource_pack_scene:
						note_override_resource_pack_scene.set_note_override(false)
					note_override_resource_pack_scene = item
					item.set_note_override(true)
					UserSettings.user_settings.note_icon_override = (item.resource_pack as HBResourcePack)._id
				rebuilding_note_atlas_container.show()
				yield(get_tree(), "idle_frame")
				yield(get_tree(), "idle_frame")
				ResourcePackLoader.rebuild_final_atlases()
				rebuilding_note_atlas_container.hide()
				
func _on_resource_pack_pressed(resource_pack: HBResourcePack, scene: Control):
	if rebuilding_note_atlas_container.visible:
		return
	if resource_pack._id != UserSettings.user_settings.resource_pack:
		UserSettings.user_settings.resource_pack = resource_pack._id
		scene.set_checked(true)
		if selected_resource_pack_scene:
			selected_resource_pack_scene.set_checked(false)
		UserSettings.save_user_settings()
		rebuilding_note_atlas_container.show()
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		ResourcePackLoader.rebuild_final_atlases()
		rebuilding_note_atlas_container.hide()
		selected_resource_pack_scene = scene
