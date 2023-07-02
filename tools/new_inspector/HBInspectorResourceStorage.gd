class_name HBInspectorResourceStorage

signal textures_changed
signal texture_removed(texture_name)

signal fonts_changed
signal font_removed(font_name)

var textures := {}
var fonts := {}

func add_texture(name: String, texture: Texture2D):
	textures[name] = texture
	texture.set_meta("texture_name", name)
	emit_signal("textures_changed")

func get_texture(name: String):
	return textures.get(name, null)

func get_font(name: String):
	return fonts.get(name, null)

func add_font(name: String, font: FontFile):
	fonts[name] = font
	font.set_meta("font_name", name)
	emit_signal("fonts_changed")
	
func remove_font(name: String):
	if fonts.erase(name):
		emit_signal("font_removed", name)

func remove_texture(texture_name: String):
	if textures.erase(texture_name):
		emit_signal("texture_removed", texture_name)

func get_textures() -> Dictionary:
	return textures

func get_fonts() -> Dictionary:
	return fonts

func get_texture_name(texture: Texture2D) -> String:
	if not texture:
		return ""
	assert(texture.has_meta("texture_name"))
	return texture.get_meta("texture_name")

func get_font_name(font: FontFile):
	if not font:
		return ""
	assert(font.has_meta("font_name"))
	return font.get_meta("font_name")

func has_texture(texture_name: String) -> bool:
	return textures.has(texture_name)

func has_theme_font(font_name: String) -> bool:
	return fonts.has(font_name)
