extends Control

class_name HBResourcePackAtlasPreview

var texture_size_physical: Vector2
var atlas: Dictionary
const CHECKERBOARD_PATTERN = preload("res://tools/icon_pack_creator/Checkerboard_pattern.svg")

func set_atlas(_atlas: Dictionary):
	atlas = _atlas
#	texture = atlas.texture

	queue_redraw()
func _draw():
	if atlas:
		var tex_size := atlas.texture.get_size() as Vector2
		if tex_size.length() > 0:
			var ratio = tex_size.x / tex_size.y
			var new_size_x = size.y * ratio
			var new_size = Vector2()
			if new_size_x <= size.x:
				new_size = Vector2(new_size_x, size.y)
			else:
				new_size = Vector2(size.x, size.x / ratio)
			texture_size_physical = new_size
		
			var col = Color.BLUE
			col.a = 0.25
			var col2 = Color.BLUE
			var r = Rect2(Vector2.ZERO, texture_size_physical)
			draw_texture_rect(CHECKERBOARD_PATTERN, r, true)
			var tex_r = texture_size_physical / tex_size
			for _atlas in atlas.atlas_textures.values():
				if _atlas is AtlasTexture:
					var at = _atlas as AtlasTexture
					var region = at.region as Rect2
					region.position *= tex_r
					region.size *= tex_r
					draw_rect(region, col2, false, 1)
					draw_rect(region, col)
			draw_texture_rect(atlas.texture, r, false)
