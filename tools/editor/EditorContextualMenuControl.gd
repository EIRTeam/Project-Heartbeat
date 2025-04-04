extends PopupMenu

class_name HBEditorContextualMenuControl

const LOG_NAME = "EditorContextualMenuControl"

signal item_pressed(item_name)

var name_id_map = {}

func _ready():
	connect("index_pressed", Callable(self, "_on_index_pressed"))

func _input(event):
	if not visible:
		return
	
	if event.is_action_pressed("editor_contextual_menu", false, true):
		hide()

func add_contextual_item(label: String, item_name: String):
	if not item_name in name_id_map.values():
		var id = get_item_count()
		
		add_item(label, id)
		name_id_map[id] = item_name
	else:
		Log.log(self, "Adding an existing contextual item")
		
func set_contextual_item_disabled(item_name: String, disabled: bool):
	var item_idx = HBUtils.find_key(name_id_map, item_name)
	set_item_disabled(item_idx, disabled)

func get_contextual_item_disabled(item_name: String):
	var item_idx = HBUtils.find_key(name_id_map, item_name)
	
	if item_idx != null:
		return is_item_disabled(item_idx)
	
	return false

func set_contextual_item_icon(item_name: String, icon: Texture2D):
	var item_idx = HBUtils.find_key(name_id_map, item_name)
	set_item_icon(item_idx, icon)

func set_contextual_item_accelerator(item_name: String, accelerator: int):
	var item_idx = HBUtils.find_key(name_id_map, item_name)
	set_item_accelerator(item_idx, accelerator)

func _on_index_pressed(index: int):
	emit_signal("item_pressed", name_id_map[index])
