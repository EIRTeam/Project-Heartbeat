extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditTexture

@onready var option_button := OptionButton.new()

var resource_storage: HBInspectorResourceStorage: set = set_resource_storage

var current_texture_name := ""

func update_texture_list():
	var textures := resource_storage.get_textures()
	option_button.set_block_signals(true)
	option_button.clear()
	option_button.add_item("None")
	option_button.set_item_metadata(0, "")
	for texture_name in textures:
		option_button.add_item(texture_name)
		option_button.set_item_metadata(option_button.get_item_count()-1, texture_name)
	option_button.set_block_signals(false)

func set_resource_storage(val):
	resource_storage = val
	if is_inside_tree():
		update_texture_list()
func _init_inspector():
	super._init_inspector()
	resource_storage.connect("textures_changed", Callable(self, "_on_resource_storage_textures_changed"))
	resource_storage.connect("texture_removed", Callable(self, "_on_resource_storage_texture_removed"))
	await self.ready
	update_texture_list()
	vbox_container.add_child(option_button)
	option_button.connect("item_selected", Callable(self, "_on_item_selected"))

func set_property_data(data: Dictionary):
	super.set_property_data(data)
	
func _on_resource_storage_textures_changed():
	update_texture_list()
	_update_selected_texture()

func _on_resource_storage_texture_removed(texture_name: String):
	if texture_name == current_texture_name:
		update_texture_list()
		option_button.select(0)

func _update_selected_texture():
	option_button.set_block_signals(true)
	for i in range(option_button.get_item_count()):
		var meta := option_button.get_item_metadata(i) as String
		if current_texture_name == meta:
			option_button.select(i)
			break
	option_button.set_block_signals(false)

func _on_item_selected(val: int):
	current_texture_name = option_button.get_item_metadata(val)
	if current_texture_name:
		emit_signal("value_changed", resource_storage.get_texture(current_texture_name))
	else:
		emit_signal("value_changed", null)

func set_value(val):
	super.set_value(val)
	current_texture_name = resource_storage.get_texture_name(val)
	if is_inside_tree():
		_update_selected_texture()
