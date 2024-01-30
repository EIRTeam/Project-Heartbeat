@uid("uid://lgbt87xiaj46") # Generated automatically, do not modify.
@tool
extends Container
@onready var song_title = get_node("SongTitle")
var song: HBSong: set = set_song
var difficulty : set = set_difficulty

const SCROLL_DURATION := 3.0

var scroll_amount := 0.0
var tween: Tween

var MATERIAL: ShaderMaterial = load("res://menus/scrolling_container_material.tres")

const FADE_SIZE = 100

func set_song(value):
	song_title.song = value
func set_difficulty(value):
	song_title.difficulty = value
		
func _update_scroll(delta: float):
	if not tween or not tween.is_running():
		var final_value := 0.0 if scroll_amount == 1.0 else 1.0
		tween = create_tween()
		tween.tween_property(self, "scroll_amount", final_value, SCROLL_DURATION).set_delay(1.0)
	
	var center_y := size.y * 0.5
	var last_child_x_max := 0.0
	
	var total_children_width := 0.0
	for child: Control in get_children():
		if child.visible:
			total_children_width += child.size.x
	
	var remainder := max(total_children_width - size.x, 0.0) as int
	var offset := remainder * scroll_amount
	for child: Control in get_children():
		if not child.visible:
			continue
		child.size = child.get_minimum_size()
		child.position.y = center_y - child.get_minimum_size().y * 0.5
		child.position.x = last_child_x_max - offset
		last_child_x_max += child.size.x
	# HACK: We pass the fade data through MODULATE since godot 4 doesn't support
	# instance uniforms for 2d yet...
	var fade_amount_l := (FADE_SIZE / size.x) * min((offset/FADE_SIZE), 1.0) as float
	var fade_amount_r := (FADE_SIZE / size.x) * min(-(offset-remainder)/FADE_SIZE, 1.0) as float
	self_modulate.r = fade_amount_l
	self_modulate.g = fade_amount_r
func _process(delta: float):
	_update_scroll(delta)

func _on_sort_children():
	var total_children_width := 0.0
	for child: Control in get_children():
		if child.visible:
			total_children_width += child.size.x
	if total_children_width > size.x:
		if not material:
			material = MATERIAL
			queue_redraw()
		set_process(true)
	else:
		if material:
			material = null
			queue_redraw()
		set_process(false)
	_update_scroll(0.0)
func _ready():
	set_process(false)
	sort_children.connect(_on_sort_children)
	material = null
func _draw():
	if material:
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
