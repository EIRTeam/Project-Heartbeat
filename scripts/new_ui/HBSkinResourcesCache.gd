class_name HBSkinResourcesCache

# No type because cyclic reference :(
var skin_resources: HBSkinResources

var texture_cache := {}
var font_cache := {}

func _init(_skin_resources):
	skin_resources = _skin_resources

func get_texture(texture_name: String) -> Texture:
	if not texture_name:
		return null
	var tex: Texture = texture_cache.get(texture_name)
	if not tex:
		if skin_resources.is_animated_texture(texture_name):
			var animated_texture := AnimatedTexture.new()
			animated_texture.fps = skin_resources.get_animated_texture_fps(texture_name)
			var frame_count := skin_resources.get_animated_texture_frame_count(texture_name)
			animated_texture.frames = frame_count
			print("FRAME COUNT!", frame_count)
			for i in range(frame_count):
				var texture_path := skin_resources.get_animated_texture_frame_path(texture_name, i)
				var image_texture := ImageTexture.new()
				var image := Image.new()
				image.load(texture_path)
				image_texture.create_from_image(image, HBGame.platform_settings.texture_mode)
				image_texture.set_meta("animated_texture_path", texture_path)
				animated_texture.set_frame_texture(i, image_texture)
				animated_texture.set_frame_delay(i, skin_resources.get_animated_texture_frame_delay(texture_name, i))
			animated_texture.set_meta("texture_name", texture_name)
			tex = animated_texture
		else:
			var image_texture := ImageTexture.new()
			var image := Image.new()
			image.load(skin_resources.get_texture_path(texture_name))
			image_texture.create_from_image(image, HBGame.platform_settings.texture_mode)
			texture_cache[texture_name] = image_texture
			image_texture.set_meta("texture_name", texture_name)
			tex = image_texture
	return tex

func get_font(font_name: String) -> DynamicFontData:
	var font: DynamicFontData = font_cache.get(font_name)
	if not font:
		var font_path := skin_resources.get_font_path(font_name)
		if not font_path:
			return null
		font = DynamicFontData.new()
		font.font_path = font_path
		font.set_meta("font_name", font_name)
		font_cache[font_name] = font
	return font
