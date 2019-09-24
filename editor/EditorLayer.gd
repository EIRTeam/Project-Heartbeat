extends Control

var editor

var layer_name : String = "New Layer"

onready var preview = get_node("EditorTimelinePreview")

func _ready():
	preview.hide()
func place_child(child: EditorTimelineItem):
	var x_pos = clamp(editor.scale_seconds(child.start), 0, 1000000.0)
	child.rect_position = Vector2(x_pos, 0)
	child.rect_size = Vector2(editor.scale_seconds(child.duration), child.rect_size.y)
	
func place_preview(start: float, duration: float):
	var x_pos = clamp(editor.scale_seconds(start), 0, 1000000.0)
	preview.rect_position = Vector2(x_pos, 0)
	preview.rect_size = Vector2(editor.scale_seconds(duration), preview.rect_size.y)
	
func add_item(item: EditorTimelineItem):
	add_child(item)
	item._layer = self
	item.editor = editor
	place_child(item)
	item.connect("item_bounds_changed", self, "place_child", [item])

func can_drop_data(position, data):
	if data is EditorTimelineItem:
		if not data in get_children():
			preview.show()
			place_preview(editor.scale_pixels(position.x + data._drag_x_offset), data.duration)
			return true
	else:
		return false



func drop_data(position, data: EditorTimelineItem):
	data._layer.remove_child(data)
	data.disconnect("item_bounds_changed", data._layer, "place_child")
	data.start = editor.scale_pixels(position.x + data._drag_x_offset)
	add_item(data)


func _on_EditorLayer_mouse_exited():
	preview.hide()
