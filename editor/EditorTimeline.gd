extends Control

var editor

onready var layers = get_node("VBoxContainer/ScrollContainer/HBoxContainer/LayerControl")
onready var layer_names = get_node("VBoxContainer/ScrollContainer/HBoxContainer/LayerNames")

const LAYER_NAME_SCENE = preload("res://editor/EditorLayerName.tscn")

func _ready():
	update()
	connect("resized", self, "_on_viewport_size_changed")
	
func _on_viewport_size_changed():
	# HACK: On linux we wait one frame because the size transformation doesn't
	# get applied on time, user should not notice this
	yield(get_tree(), "idle_frame")
	update()
	
func _draw():
	_draw_playhead()
	
func _draw_playhead():
	var playhead_pos = Vector2(layers.rect_position.x + editor.scale_msec(editor.playhead_position), 0.0)
	draw_line(playhead_pos, playhead_pos+Vector2(0.0, rect_size.y), Color(1.0, 0.0, 0.0), 1.0)

func add_layer(layer):
	layer.editor = editor
	layers.add_child(layer)
	var lns = LAYER_NAME_SCENE.instance()
	lns.layer_name = layer.layer_name
	layer_names.add_child(lns)

func get_layers():
	return layers.get_children()


func _on_PlayheadArea_mouse_x_input(value):
	editor.seek(editor.scale_pixels(int(value)))

func _on_playhead_position_changed():
	update()
	$VBoxContainer/HBoxContainer/PlayheadPosText/Label.text = HBUtils.format_time(editor.playhead_position)
