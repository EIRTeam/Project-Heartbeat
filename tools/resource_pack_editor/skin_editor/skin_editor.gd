extends Panel

@onready var aspect_ratio_button: OptionButton = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/HBoxContainer/MenuButton")
@onready var aspect_ratio_container: AspectRatioContainer = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/AspectRatioContainer")
@onready var viewport: SubViewport = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/AspectRatioContainer/TextureRect/SubViewport")
@onready var edit_root: Control = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/AspectRatioContainer/TextureRect/SubViewport/Control")
@onready var edit_layer: Control = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/AspectRatioContainer/TextureRect/SubViewport/Control/EditLayer")
@onready var outliner: HBSkinEditorOutliner = get_node("HSplitContainer/HBoxContainer/Control/TabContainer2/Outline/ScrollContainer/Outline")
@onready var component_widget_margin: HBSkinEditorWidget = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/AspectRatioContainer/TextureRect/SubViewport/Control/SkinEditorWidgetMargin")
@onready var component_widget_anchor: HBSkinEditorWidget = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/AspectRatioContainer/TextureRect/SubViewport/Control/SkinEditorWidgetAnchor")
@onready var inspector: HBInspectorMK2 = get_node("HSplitContainer/Panel2/HBoxContainer/TabContainer/Inspector")
@onready var skin_resource_editor: HBSkinResourceEditor = get_node("HSplitContainer/HBoxContainer/Control/TabContainer/Resources/HBSkinResourceEditor")
@onready var screen_option_button: OptionButton = get_node("HSplitContainer/Panel2/HBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/ScreenButton")
@onready var error_popup := AcceptDialog.new()

var layers := {}

const ASPECT_RATIOS = [
	16/9.0,
	4/3.0,
	16/10.0
]

var resource_pack: HBResourcePack: set = set_resource_pack

const SCREEN_GAMEPLAY = 0

var skin: HBUISkin = HBUISkin.new()

func clear_components():
	for layer in edit_layer.get_children():
		layer.queue_free()

func set_resource_pack(val):
	resource_pack = val
	skin_resource_editor.resource_pack = resource_pack
	if resource_pack.is_skin():
		inspector.clear_current()
		component_widget_anchor.clear_current()
		component_widget_margin.clear_current()
		skin_resource_editor.clear()
		
		skin = resource_pack.get_skin()
		var cache := skin.resources.get_cache() as HBSkinResourcesCache
		skin_resource_editor.from_skin_resource_cache(cache)
		
		inspector.resource_storage = skin_resource_editor.resource_storage
		inspector.resource_storage.connect("texture_removed", Callable(self, "_on_resource_storage_texture_removed"))
		inspector.resource_storage.connect("font_removed", Callable(self, "_on_resource_storage_font_removed"))
		
		var layered_components := skin.get_components(get_current_screen(), cache)
		_on_screen_selected()
		for layer_name in layered_components:
			if layer_name in layers:
				for component in layered_components[layer_name]:
					layers[layer_name].add_child(component, true)
					outliner.add_component(component, layer_name)
	
func show_error(error: String):
	error_popup.dialog_text = error
	error_popup.popup_centered_clamped()
	
func get_current_screen() -> String:
	var out := ""
	
	match screen_option_button.get_selected_id():
		SCREEN_GAMEPLAY:
			out = "gameplay"
	return out
	
func get_screen_layers(screen: int):
	var sreen_layers := []
	match screen:
		SCREEN_GAMEPLAY:
			sreen_layers = ["UnderNotes", "OverNotes"]
	return sreen_layers
func _ready():
	add_child(error_popup)
	screen_option_button.add_item("Gameplay", SCREEN_GAMEPLAY)
	aspect_ratio_button.connect("item_selected", Callable(self, "_on_aspect_ratio_item_selected"))
	outliner.connect("component_selected", Callable(self, "_on_component_selected"))
	component_widget_anchor.connect("changed", Callable(inspector, "property_changed_notified"))
	component_widget_margin.connect("changed", Callable(inspector, "property_changed_notified"))

	error_popup.exclusive = true
	outliner.connect("item_removed", Callable(self, "_on_item_removed"))
	outliner.connect("moved_component_to_layer", Callable(self, "_on_outliner_moved_component_to_layer"))
	component_widget_anchor.mode = HBSkinEditorWidget.WIDGET_MODE.ANCHOR
	component_widget_anchor.hide()
	component_widget_margin.hide()
	component_widget_margin.connect("changed", Callable(component_widget_anchor, "_copy_anchor_from_target_node"))
	skin_resource_editor.connect("resource_deleted", Callable(self, "save_skin"))
	skin_resource_editor.connect("resource_added", Callable(self, "save_skin"))

func _on_screen_selected():
	outliner.clear_layers()
	clear_components()
	for layer in layers.values():
		layer.queue_free()
	layers.clear()
	for layer in get_screen_layers(screen_option_button.selected):
		outliner.add_layer(layer)
		var layer_control := Control.new()
		layer_control.name = layer
		layer_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		edit_layer.add_child(layer_control)
		layers[layer] = layer_control
	
func _on_outliner_moved_component_to_layer(old_layer: String, new_layer: String, component: HBUIComponent):
	layers[old_layer].remove_child(component)
	layers[new_layer].add_child(component)
	outliner.add_component(component, new_layer)
func _on_resource_storage_texture_removed(texture_name: String):
	for layer_name in layers:
		for component in layers[layer_name].get_children():
			if component is HBUIComponent:
				for cname in component.get_hb_inspector_whitelist():
					if typeof(component.get(cname)) == TYPE_OBJECT:
						var texture := component.get(cname) as Texture2D
						if texture:
							if inspector.resource_storage.get_texture_name(texture) == texture_name:
								component.set(cname, null)
	save_skin()

func _on_resource_storage_font_removed(font_name: String):
	for layer_name in layers:
		for component in layers[layer_name].get_children():
			if component is HBUIComponent:
				for cname in component.get_hb_inspector_whitelist():
					if typeof(component.get(cname)) == TYPE_OBJECT:
						var font := component.get(cname) as HBUIFont
						if font:
							if inspector.resource_storage.get_font_name(font.font_data) == font_name:
								font.font_data = null
								component.set(cname, font)

func _on_aspect_ratio_item_selected(index: int):
	aspect_ratio_container.ratio = ASPECT_RATIOS[index]
	viewport.size = Vector2((ASPECT_RATIOS[index] * 1080) * 1.1, 1080 * 1.1)
	var real_size := Vector2((ASPECT_RATIOS[index] * 1080), 1080)
	edit_root.offset_left = -real_size.x * 0.5
	edit_root.offset_right = real_size.x * 0.5
	edit_root.offset_top = -real_size.y * 0.5
	edit_root.offset_bottom = real_size.y * 0.5
	component_widget_anchor._copy_anchor_from_target_node()
	component_widget_margin._copy_margin_from_target_node()

func _on_component_selected(component: HBUIComponent):
	component_widget_margin.target_node = component
	component_widget_anchor.target_node = component
	component_widget_anchor.show()
	component_widget_margin.show()
	inspector.inspect(component)

func _on_HBSkinEditorComponentPicker_component_picked(component):
	if not outliner.get_selected_layer():
		show_error("You must select a layer before adding components")
		return
	var cmp := component.new() as HBUIComponent
	cmp.size = Vector2(128, 128)
	cmp.position = Vector2(1920, 1080) * 0.5
	cmp.name = cmp.get_component_name().capitalize().replace(" ", "")
	layers[outliner.get_selected_layer()].add_child(cmp, true)
	outliner.add_component(cmp, outliner.get_selected_layer())

func skin_to_dict() -> Dictionary:
	assert(resource_pack)
	var screen_name := get_current_screen()
	var scr := HBUISkinScreen.new()
	for layer_name in layers:
		scr.layered_components[layer_name] = []
		for component in layers[layer_name].get_children():
			if component is HBUIComponent:
				scr.layered_components[layer_name].push_back(component._to_dict(inspector.resource_storage))
	skin.screens[screen_name] = scr
	skin.resources = skin_resource_editor.to_skin_resources()
	return skin.serialize()
	
func save_skin():
	var skin_dict := skin_to_dict()
	var js := JSON.stringify(skin_dict, "  ")
	var f := FileAccess.open(resource_pack.get_skin_config_path(), FileAccess.WRITE)
	f.store_string(js)
	f.close()
	resource_pack.save_pack()
	ResourcePackLoader.reload_skin()

func _on_item_removed(item: HBUIComponent):
	if item == inspector.current_object:
		inspector.clear_current()
		component_widget_anchor.clear_current()
		component_widget_margin.clear_current()
	item.queue_free()
