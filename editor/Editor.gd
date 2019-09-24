extends Control

const SCALE = 30.0 # Seconds per 500 pixels
	
onready var timeline = get_node("Editor/EditorTimeline")
	
const EDITOR_LAYER_SCENE = preload("res://editor/EditorLayer.tscn")
const EDITOR_TIMELINE_ITEM_SCENE = preload("res://editor/EditorTimelineItem.tscn")
func _ready():
	timeline.editor = self
	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
	timeline.add_layer(EDITOR_LAYER_SCENE.instance())
	var test_item = EDITOR_TIMELINE_ITEM_SCENE.instance()
	test_item.start = 1
	test_item.duration = 2
	timeline.get_layers()[0].add_item(test_item)
	
func scale_seconds(seconds: float) -> float:
	return (seconds/SCALE)*500.0

# pixels to seconds
func scale_pixels(pixels: float) -> float:
	return pixels * SCALE / 500

func add_item(layer_n: int, item: EditorTimelineItem):
	var layers = timeline.get_layers()
	var layer = layers[layer_n]
	layer.add_item(item)
