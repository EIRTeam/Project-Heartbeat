extends Control

const SCALE = 30.0 # Seconds per 500 pixels
	
var playhead_position := 20
	
onready var timeline = get_node("VBoxContainer/EditorTimelineContainer/EditorTimeline")
	
signal playhead_position_changed
	
const EDITOR_LAYER_SCENE = preload("res://editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://editor/timeline_items/EditorTimelineItemSingleNote.tscn")

var selected: EditorTimelineItem

func _ready():
	timeline.editor = self
	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
	var test_item = EDITOR_TIMELINE_ITEM_SCENE.instance()
	test_item.start = 1
	test_item.duration = 2
	timeline.get_layers()[0].add_item(test_item)
	seek(0)
	
func scale_msec(msec: int) -> float:
	return ((msec/1000.0)/SCALE)*500.0

# pixels to msec
func scale_pixels(pixels: float) -> float:
	return (pixels * SCALE / 500) * 1000.0

func select_item(item: EditorTimelineItem):
	if selected:
		selected.deselect()
	selected = item
	$VBoxContainer/HBoxContainer/EditorInspector.inspect(item)

func add_item(layer_n: int, item: EditorTimelineItem):
	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	layer.add_item(item)

func seek(value: int):
	playhead_position = max(value, 0.0)
	emit_signal("playhead_position_changed")
