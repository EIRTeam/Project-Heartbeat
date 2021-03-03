extends Control

var texture_size_physical: Vector2
var atlas: Dictionary
const CHECKERBOARD_PATTERN = preload("res://tools/icon_pack_creator/Checkerboard_pattern.svg")
"""
		var video_size = video_texture.get_size()
		var video_ar = video_size.x / video_size.y
		var new_size_x = rect_size.y * video_ar
		if new_size_x <= rect_size.x:
			# side black bars (or none)
			video_player.rect_size = Vector2(new_size_x, rect_size.y)
		else:
			# bottom and top black bars
			video_player.rect_size = Vector2(rect_size.x, rect_size.x / video_ar)
		# Center that shit
		video_player.rect_position.x = (rect_size.x - video_player.rect_size.x) / 2.0
		video_player.rect_position.y = (rect_size.y - video_player.rect_size.y) / 2.0
"""

func set_atlas(_atlas: Dictionary):
	atlas = _atlas
#	texture = atlas.texture

	update()
func _draw():
	if atlas:
		var size := atlas.texture.get_size() as Vector2
		if size.length() > 0:
			var ratio = size.x / size.y
			var new_size_x = rect_size.y * ratio
			var new_size = Vector2()
			if new_size_x <= rect_size.x:
				new_size = Vector2(new_size_x, rect_size.y)
			else:
				new_size = Vector2(rect_size.x, rect_size.x / ratio)
			texture_size_physical = new_size
		
			var col = Color.blue
			col.a = 0.25
			var col2 = Color.blue
			var r = Rect2(Vector2.ZERO, texture_size_physical)
			draw_texture_rect(CHECKERBOARD_PATTERN, r, true)
			var tex_r = texture_size_physical / size
			for _atlas in atlas.atlas_textures.values():
				if _atlas is AtlasTexture:
					var at = _atlas as AtlasTexture
					var region = at.region as Rect2
					region.position *= tex_r
					region.size *= tex_r
					draw_rect(region, col2, false, 1)
					draw_rect(region, col)
			draw_texture_rect(atlas.texture, r, false)
