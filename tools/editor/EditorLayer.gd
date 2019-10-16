extends Control

var editor

var layer_name : String = "New Layer"

onready var preview = get_node("EditorTimelinePreview")

func _ready():
	preview.hide()
	
func place_child(child: EditorTimelineItem):
	var x_pos = max(editor.scale_msec(child.data.time), 0.0)
	child.rect_position = Vector2(x_pos, 0)
	child.rect_size = child.get_editor_size()
	
func place_all_children():
	for child in get_children():
		if child != preview:
			place_child(child)
	
func place_preview(start: float, duration: float):
	var x_pos = max(editor.scale_msec(start), 0)
	preview.rect_position = Vector2(x_pos, 0)
	preview.rect_size = Vector2(editor.scale_msec(duration), preview.rect_size.y)
	
	
func add_item(item: EditorTimelineItem):
	item._layer = self
	item.editor = editor
	place_child(item)
	item.connect("item_changed", self, "place_child", [item])
	add_child(item)

func can_drop_data(position, data):
	if data is EditorTimelineItem:
		if not data in get_children():
			preview.show()
			place_preview(editor.scale_pixels(position.x + data._drag_x_offset), editor.scale_pixels(data.get_size().x))
			return true
	else:
		return false

func get_timing_points():
	var points = []
	for child in get_children():
		if not child == preview:
			points.append(child.data)
	return points

func get_editor_items():
	var points = []
	for child in get_children():
		if not child == preview:
			points.append(child)
	return points

func drop_data(position, data: EditorTimelineItem):
	data._layer.remove_child(data)
	data.disconnect("item_changed", data._layer, "place_child")
	data.data.time = int(editor.scale_pixels(position.x + data._drag_x_offset))
	add_item(data)


func _on_EditorLayer_mouse_exited():
	preview.hide()

