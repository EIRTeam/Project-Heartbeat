extends HBUniversalListItem

class_name HBSongListItemBase

@export var node_to_scale_path: NodePath
@onready var node_to_scale = get_node(node_to_scale_path)

const HOVERED_SCALE = Vector2(1.0, 1.0)
const NON_HOVERED_SCALE = Vector2(0.85, 0.85)

@onready var scale_tween = Threen.new()

var hover_style = preload("res://styles/SongListItemHover.tres")
var normal_style = preload("res://styles/SongListItemNormal.tres")

# warning-ignore:unused_signal
# emitted by song list, TODO: fix this?
signal pressed

func get_target_scale():
	if is_hovered():
		return HOVERED_SCALE
	return NON_HOVERED_SCALE

func _on_resize():
	update_scale(get_target_scale(), true)

func _ready():
	connect("resized", Callable(self, "_on_resize"))
	add_child(scale_tween)
	call_deferred("_on_resize")

func update_scale(to: Vector2, no_animation=false):
	node_to_scale.pivot_offset = node_to_scale.size / 2.0
	node_to_scale.pivot_offset.x = 0
	if scale_tween.is_inside_tree():
		if no_animation:
			scale_tween.remove_all()
			node_to_scale.scale = get_target_scale()
		else:
			scale_tween.remove_all()
			scale_tween.interpolate_property(node_to_scale, "scale", node_to_scale.scale, to, 0.25, Threen.TRANS_BACK, Threen.EASE_OUT)
			scale_tween.start()
func hover(no_animation=false):
	node_to_scale.add_theme_stylebox_override("normal", hover_style)
	update_scale(get_target_scale(), no_animation)
func stop_hover(no_animation=false):
	node_to_scale.add_theme_stylebox_override("normal", normal_style)
	update_scale(get_target_scale(), no_animation)

func is_hovered():
	return node_to_scale.get_theme_stylebox("normal") == hover_style
#	var new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
#	var scene = new_scene.instance()
#	get_tree().current_scene.queue_free()
#	get_tree().root.add_child(scene)
#	get_tree().current_scene = scene
#	scene.set_song(song)

