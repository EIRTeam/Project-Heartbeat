extends HBUniversalListItem

class_name HBSongListItemBase

export(NodePath) var node_to_scale_path
onready var node_to_scale = get_node(node_to_scale_path)

const HOVERED_SCALE = Vector2(1.0, 1.0)
const NON_HOVERED_SCALE = Vector2(0.85, 0.85)

onready var scale_tween = Tween.new()

var hover_style = preload("res://styles/SongListItemHover.tres")
var normal_style = preload("res://styles/SongListItemNormal.tres")

# warning-ignore:unused_signal
# emitted by song list, TODO: fix this?
signal pressed

func get_scale():
	if is_hovered():
		return HOVERED_SCALE
	return NON_HOVERED_SCALE

func _on_resize():
	update_scale(get_scale(), true)

func _ready():
	connect("resized", self, "_on_resize")
	add_child(scale_tween)
	call_deferred("_on_resize")

func update_scale(to: Vector2, no_animation=false):
	node_to_scale.rect_pivot_offset = node_to_scale.rect_size / 2.0
	node_to_scale.rect_pivot_offset.x = 0
	if scale_tween.is_inside_tree():
		if no_animation:
			scale_tween.remove_all()
			node_to_scale.rect_scale = get_scale()
		else:
			scale_tween.remove_all()
			scale_tween.interpolate_property(node_to_scale, "rect_scale", node_to_scale.rect_scale, to, 0.25, Tween.TRANS_BACK, Tween.EASE_OUT)
			scale_tween.start()
func hover(no_animation=false):
	node_to_scale.add_stylebox_override("normal", hover_style)
	update_scale(get_scale(), no_animation)
func stop_hover(no_animation=false):
	node_to_scale.add_stylebox_override("normal", normal_style)
	update_scale(get_scale(), no_animation)

func is_hovered():
	return node_to_scale.get_stylebox("normal") == hover_style
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

