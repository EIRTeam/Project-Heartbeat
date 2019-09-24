extends Control

var editor

onready var layers = get_node("VBoxContainer/ScrollContainer/HBoxContainer/LayerControl")
onready var layer_names = get_node("VBoxContainer/ScrollContainer/HBoxContainer/LayerNames")

const LAYER_NAME_SCENE = preload("res://editor/EditorLayerName.tscn")

func _ready():
	update()
	
func _draw():
	_draw_playhead()
	
func _draw_playhead():
	var playhead_pos = Vector2(editor.scale_seconds(30), 0.0)
	draw_line(playhead_pos, playhead_pos+Vector2(0.0, rect_size.y), Color(1.0, 0.0, 0.0), 1.0)

func add_layer(layer):
	layer.editor = editor
	layers.add_child(layer)
	var lns = LAYER_NAME_SCENE.instance()
	lns.layer_name = layer.layer_name
	layer_names.add_child(lns)

func get_layers():
	return layers.get_children()
