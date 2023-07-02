extends ConfirmationDialog

class_name HBEditorSkinPicker

@onready var option_button: OptionButton = get_node("%SkinPickerOptionButton")

var visible_ids := []

var selected_value := 0: set = set_selected_value

signal skin_selected(skin_ugc_id)

func set_selected_value(val):
	selected_value = val
	if selected_value == 0:
		option_button.set_block_signals(true)
		option_button.select(0)
		option_button.set_block_signals(false)
	else:
		for item_i in range(option_button.get_item_count()):
			var item_id := option_button.get_item_id(item_i)
			if item_i == selected_value:
				option_button.set_block_signals(true)
				option_button.select(item_i)
				option_button.set_block_signals(false)

func populate_list():
	visible_ids.clear()
	option_button.clear()
	option_button.add_item("None", 0)
	visible_ids.append(0)
	for pack_name in ResourcePackLoader.resource_packs:
		var pack: HBResourcePack = ResourcePackLoader.resource_packs[pack_name]
		if pack.ugc_id != 0 and pack.is_skin():
			if not pack.ugc_id in visible_ids: 
				option_button.add_item(pack.pack_name, pack.ugc_id)
				visible_ids.append(pack.ugc_id)
				if pack.ugc_id == selected_value:
					option_button.set_block_signals(true)
					option_button.select(option_button.get_item_count()-1)
					option_button.set_block_signals(false)

func _ready():
	option_button.connect("item_selected", Callable(self, "_on_skin_selected"))
	populate_list()
	connect("confirmed", Callable(self, "_on_confirmed"))
	
func _on_confirmed():
	emit_signal("skin_selected", selected_value)
	
func _on_skin_selected(index: int):
	var item_id := visible_ids[index] as int
	selected_value = item_id

func _on_RefreshButton_pressed():
	populate_list()
