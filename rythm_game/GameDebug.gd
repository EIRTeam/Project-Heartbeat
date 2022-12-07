extends WindowDialog

class_name HBGameDebug

onready var group_tree: Tree = get_node("%GroupTree")
onready var debug_label: Label = get_node("%DebugLabel")

var tracked_groups := []

func _ready():
	var root := group_tree.create_item()
	group_tree.hide_root = true

func track_group(group: HBNoteGroup):
	var item := group_tree.create_item()
	item.set_text(0, "Group - %d - %d - %d" % [group.get_start_time_msec(), group.get_hit_time_msec(), group.get_end_time_msec()])
	
	for an in group.note_datas:
		var note: HBBaseNote = an
		var note_item := group_tree.create_item(item)
		note_item.set_text(0, note.get_serialized_type())
	
	group.set_meta("debug_item", item)
	tracked_groups.append(group)

func _input(event: InputEvent):
	if event is InputEventKey:
		if event.scancode == KEY_F10 and event.is_pressed() and not event.is_echo():
			if not visible:
				popup_centered()
			else:
				visible = false

func untrack_group(group: HBNoteGroup):
	var item: TreeItem = group.get_meta("debug_item")
	if item:
		item.free()
		tracked_groups.erase(group)
