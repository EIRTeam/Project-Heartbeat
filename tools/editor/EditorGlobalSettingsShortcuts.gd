extends Panel


onready var combination_label: Label = get_node("WindowDialog/VBoxContainer/Label2")
onready var bind_window: ConfirmationDialog = get_node("WindowDialog")
onready var reset_to_default_button: Button = get_node("WindowDialog/VBoxContainer/ResetToDefaultButton")
onready var reset_confirmation_dialog: ConfirmationDialog = get_node("ResetConfirmationDialog")

onready var tree: Tree = get_node("VBoxContainer/Tree")

var temp_event: InputEvent
var current_item: TreeItem

const EDITOR_EVENTS = [
	"editor_quick_lyric",
	"editor_quick_phrase_start",
	"editor_quick_phrase_end",
	"editor_select_all",
	"editor_playtest",
	"editor_arrange_l",
	"editor_arrange_r",
	"editor_arrange_u",
	"editor_arrange_d",
	"editor_arrange_ul",
	"editor_arrange_ur",
	"editor_arrange_dl",
	"editor_arrange_dr",
	"editor_arrange_center",
	"editor_flip_v",
	"editor_flip_h",
	"editor_flip_angle",
	"editor_flip_oscillation",
	"editor_make_circle_c",
	"editor_make_circle_cc",
	"editor_circle_size_bigger",
	"editor_circle_size_smaller",
	"editor_circle_inside",
]

var tree_items = {}

func _ready():
	set_process_input(false)
	var root_item = tree.create_item()
	for event_name in EDITOR_EVENTS:
		var item := tree.create_item(root_item)
		var event: InputEventKey = InputMap.get_action_list(event_name)[0]
		item.set_meta("event", event)
		item.set_meta("action_name", event_name)
		set_item_text(item, event_name, event)
		tree_items[event_name] = item
	tree.connect("item_activated", self, "_on_item_double_clicked")
	bind_window.connect("confirmed", self, "_on_bind_window_confirmed")
	bind_window.get_cancel().connect("pressed", self, "set_process_input", [false])
	reset_to_default_button.connect("pressed", self, "_on_reset_to_default_button_pressed")
	reset_confirmation_dialog.connect("confirmed", self, "reset_all_to_default")
	
func _on_reset_to_default_button_pressed():
	var ev = UserSettings.base_input_map[current_item.get_meta("action_name")][0]
	set_temp_event(ev)
	
func _on_bind_window_confirmed():
	set_process_input(false)
	if temp_event:
		var item = tree.get_selected() as TreeItem
		var action_name: String = item.get_meta("action_name")
		var event: InputEvent = item.get_meta("event")
		InputMap.action_erase_event(action_name, event)
		item.set_meta("event", temp_event)
		set_item_text(item, action_name, temp_event)
		InputMap.action_add_event(action_name, temp_event)
		UserSettings.save_user_settings()
		
func set_item_text(item: TreeItem, action: String, event: InputEvent):
	var ev_text = event.as_text()
	if ev_text.begins_with("Kp "):
		ev_text = ev_text.replace("Kp ", "Keypad ")
	if action in UserSettings.action_names:
		item.set_text(0, UserSettings.action_names[action])
	elif action.begins_with("editor_"):
		var base = action.substr(7).capitalize().to_lower()
		base[0] = (base[0] as String).to_upper()
		item.set_text(0, base)
	item.set_text(1, ev_text)
	
func _on_item_double_clicked():
	if tree.get_selected_column() == 1:
		current_item = tree.get_selected()
		bind_window.popup_centered()
		set_process_input(true)
		temp_event = null
		combination_label.text = ""
		
func set_temp_event(event: InputEventKey):
	temp_event = event
	combination_label.text = event.as_text()

func _input(event):
	if event is InputEventKey:
		if event.is_pressed():
			get_tree().set_input_as_handled()
			set_temp_event(event)

func reset_all_to_default():
	for action_name in EDITOR_EVENTS:
		var item: TreeItem = tree_items[action_name]
		InputMap.action_erase_event(action_name, item.get_meta("event"))
		InputMap.action_add_event(action_name, UserSettings.base_input_map[action_name][0])
		set_item_text(item, action_name, UserSettings.base_input_map[action_name][0])
		
