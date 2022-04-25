extends Panel

class_name HBSkinEditorCorner

var anchor_graphic_rotation := 0.0 setget set_anchor_graphic_rotation
var anchor_graphic_visible := false setget set_anchor_graphic_visible

onready var anchor_graphic = get_node("TextureRect")

func set_anchor_graphic_rotation(val):
	anchor_graphic_rotation = val
	if is_inside_tree():
		anchor_graphic.rect_rotation = val
		
func set_anchor_graphic_visible(val):
	anchor_graphic_visible = val
	if is_inside_tree():
		anchor_graphic.visible = val
	if anchor_graphic_visible:
		self_modulate.a = 0.0
	else:
		self_modulate.a = 1.0
		
func _ready():
	set_anchor_graphic_rotation(anchor_graphic_rotation)
	set_anchor_graphic_visible(anchor_graphic_visible)

func get_anchor_graphic_global_rect() -> Rect2:
	var rect := anchor_graphic.get_rect() as Rect2
	rect.position -= anchor_graphic.rect_position
	return anchor_graphic.get_global_transform().xform(rect)
