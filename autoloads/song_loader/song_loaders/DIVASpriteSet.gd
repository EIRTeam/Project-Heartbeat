class_name DIVASpriteSet

# Godot renderer is crashy in multi threaded mode
const ENABLE_TEXTURE_ALLOCATION := true

var buffer: StreamPeerBuffer

var has_error := false
var error_message := ""

var textures: Array[DIVATextureData] = []
var sprites: Array[DIVASprite] = []

enum DIVA_FORMATS {
	Unknown = -1,
	A8 = 0,
	RGB8 = 1,
	RGBA8 = 2,
	RGB5 = 3,
	RGB5A1 = 4,
	RGBA4 = 5,
	DXT1 = 6,
	DXT1a = 7,
	DXT3 = 8,
	DXT5 = 9,
	ATI1 = 10,
	ATI2 = 11,
	L8 = 12,
	L8A8 = 13
}

const DIVA_ATI2_FORMAT = 11

class DIVATextureData:
	var name := ""
	var texture: ImageTexture
	var texture_data: Image
	var texture_ycbcr_2: ImageTexture
	var texture_data_ycbcr_2: Image
	var format := 0


class DIVASprite:
	extends AtlasTexture
	var diva_texture: DIVATextureData
	var name := ""
	var texture_index := 0
	func get_fallback_material() -> ShaderMaterial:
		return null
	func notify_visible():
		pass

## DIVA Sprite for modern RenderingDevice renderers
class DIVASpriteRD:
	extends DIVASprite
	var diva_ui_texture: HBDIVAUITexture
	
	func allocate_diva_ui_texture():
		var is_ycbcr := diva_texture.texture_data_ycbcr_2 != null
		var flags := DIVATextureProcessor.Flags.FLAG_FLIP_Y | DIVATextureProcessor.Flags.FLAG_GENERATE_MIPMAPS
		if is_ycbcr:
			flags |= DIVATextureProcessor.Flags.FLAG_YCBCR_TO_RGB
			diva_ui_texture = HBDIVAUITexture.new([diva_texture.texture_data, diva_texture.texture_data_ycbcr_2], flags)
		else:
			diva_ui_texture = HBDIVAUITexture.new([diva_texture.texture_data], flags)
			
		atlas = diva_ui_texture
	func notify_visible():
		if not diva_ui_texture:
			allocate_diva_ui_texture()
		diva_ui_texture.notify_visible()

## DIVA Sprite for the compatibility (opengl) renderer
class DIVASpriteCompatibility:
	extends DIVASprite
	var ui_texture: HBDIVAUITexture
	var cbcr_atlas: ImageTexture
	
	func is_ycbcr() -> bool:
		return diva_texture.texture_data_ycbcr_2 != null
		
	func allocate_texture():
		if not atlas:
			atlas = ImageTexture.create_from_image(diva_texture.texture_data)
		
	func allocate_ycbcr_textures():
		if not cbcr_atlas:
			cbcr_atlas = ImageTexture.create_from_image(diva_texture.texture_data_ycbcr_2)
	
	func notify_visible():
		allocate_texture()
		if is_ycbcr():
			allocate_ycbcr_textures()
	
	## Used when renderingdevice is not available
	func get_fallback_material() -> ShaderMaterial:
		var shader_mat := ShaderMaterial.new()
		if is_ycbcr():
			shader_mat.shader = load("res://menus/diva_ycbcr.gdshader")
			shader_mat.set_shader_parameter("texture_ya", self)
			shader_mat.set_shader_parameter("texture_cbcr", cbcr_atlas)
		else:
			# Vertical flip in a shader
			shader_mat.shader = load("res://menus/diva_sprite.gdshader")
		return shader_mat
func propagate_error(error_msg: String):
	has_error = true
	error_message = error_msg
	push_error(error_message)
	
func read(_spb: StreamPeerBuffer):
	buffer = _spb
	var _signature := buffer.get_32()
	var textures_offset := buffer.get_u32()
	var _texture_count := buffer.get_32()
	var sprite_count := buffer.get_u32()
	var sprites_offset := buffer.get_32()
	var texture_names_offset := buffer.get_32()
	var sprite_names_offset := buffer.get_32()
	var _sprite_modes_offset := buffer.get_32()
	
	# Read textures
	buffer.seek(textures_offset)
	read_texture_set()
	buffer.seek(sprites_offset)
	read_sprites(sprite_count)
	buffer.seek(texture_names_offset)
	read_texture_names()
	buffer.seek(sprite_names_offset)
	read_sprite_names()
	
func read_texture_set():
	var original_endianness := buffer.big_endian
	var texture_set_start := buffer.get_position()
	var texture_set_signature := buffer.get_32()
	if texture_set_signature != 0x03505854:
		buffer.big_endian = !buffer.big_endian
		buffer.seek(buffer.get_position()-4)
		texture_set_signature = buffer.get_32()
		if texture_set_signature != 0x03505854:
			propagate_error("Invalid signature")
			return
	var texture_count := buffer.get_32()
	var _texture_count_rub := buffer.get_32()
	
	for _texture in range(texture_count):
		var texture_data := DIVATextureData.new()
		read_texture_from_offset(texture_data, texture_set_start + buffer.get_32())
		textures.append(texture_data)
	
	buffer.big_endian = original_endianness
	
func read_texture_from_offset(texture_data: DIVATextureData, texture_offset: int) -> bool:
	var original_offset := buffer.get_position()
	buffer.seek(texture_offset)
	var texture_start := buffer.get_position()
	var texture_signature := buffer.get_32()
	if texture_signature != 0x04505854 && texture_signature != 0x05505854:
		propagate_error("Invalid TXP file")
		buffer.seek(original_offset)
		return false
	
	var _subtexture_count := buffer.get_32()
	var info := buffer.get_32()
	
	var mipmap_count := info & 0xFF
	var array_size := (info >> 8) & 0xFF
	for _array in range(array_size):
		for _subtexture in range(mipmap_count):
			if _subtexture > 0 and not texture_data.format == DIVA_ATI2_FORMAT:
				# We skip any mipmap over 0 since we don't use them...
				# unless it's a ycbcr texture, in which case we need two
				continue
			var subtexture_offset := buffer.get_32()
			if not read_texture_data_from_offset(texture_data, texture_start+subtexture_offset):
				buffer.seek(original_offset)
				return false
	buffer.seek(original_offset)
	return true
	
func diva_to_godot_format(diva_format: int) -> int:
	var godot_format := Image.FORMAT_L8
	match diva_format:
		DIVA_FORMATS.A8:
			# Should be A8 but since we don't use these...
			godot_format = Image.FORMAT_L8
		DIVA_FORMATS.RGB8:
			godot_format = Image.FORMAT_RGB8
		DIVA_FORMATS.RGBA8:
			godot_format = Image.FORMAT_RGBA8
		DIVA_FORMATS.RGB5:
			# Unsupported MonkaS, should be RGB5
			godot_format = -1
		DIVA_FORMATS.RGB5A1:
			godot_format = -1
		DIVA_FORMATS.RGBA4:
			godot_format = Image.FORMAT_RGBA4444
		DIVA_FORMATS.DXT1:
			godot_format = Image.FORMAT_DXT1
		DIVA_FORMATS.DXT1a:
			godot_format = Image.FORMAT_DXT1
		DIVA_FORMATS.DXT3:
			godot_format = Image.FORMAT_DXT3
		DIVA_FORMATS.DXT5:
			godot_format = Image.FORMAT_DXT5
		DIVA_FORMATS.ATI1:
			# Unsupported too, should be BC4, who uses these!?!?!
			godot_format = -1
		DIVA_FORMATS.ATI2:
			# ATI2
			# Do note ati2 here doesn't *actually* mean ATI2, but rather two
			# textures combined as YA + CBCR
			godot_format = Image.FORMAT_RGTC_RG
		DIVA_FORMATS.L8:
			godot_format = Image.FORMAT_L8
		DIVA_FORMATS.L8A8:
			godot_format = Image.FORMAT_LA8
	return godot_format
	
# MML calls this a subtexture
func read_texture_data_from_offset(texture_data, texture_data_offset: int) -> bool:
	var original_offset := buffer.get_position()
	
	buffer.seek(texture_data_offset)
	
	var _signature := buffer.get_32()
	
	var width := buffer.get_32()
	var height := buffer.get_32()
	var format := buffer.get_32()
	var godot_format := diva_to_godot_format(format)
	
	if texture_data.texture and format != DIVA_ATI2_FORMAT:
		# We already have a texture, this must mean we are dealing with a lower
		# quality mipmap we can't even use
		buffer.seek(original_offset)
		print("FAILED TO READ")
		return false
	
	if godot_format == -1:
		print("FAILED TO FIND SUITABLE GODOT FORMAT")
		buffer.seek(original_offset)
		return false
	
	# Skip ID
	buffer.seek(buffer.get_position()+4)
	
	var data_size := buffer.get_32()
	var image := Image.create_from_data(width, height, false, godot_format, buffer.get_data(data_size)[1])
	
	if texture_data.texture_data and format == DIVA_ATI2_FORMAT:
		texture_data.texture_data_ycbcr_2 = image
	else:
		texture_data.texture_data = image
	
	texture_data.format = format
	
	buffer.seek(original_offset)
	
	return true
			
func read_texture_names():
	for texture in textures:
		var texture_name_offset := buffer.get_32()
		var current_offset := buffer.get_position()
		
		buffer.seek(texture_name_offset)
		
		var texture_name := read_string()
		
		texture.name = texture_name
		
		buffer.seek(current_offset)
		
func read_sprite_names():
	for sprite in sprites:
		var sprite_name_offset := buffer.get_32()
		var current_offset := buffer.get_position()
		
		buffer.seek(sprite_name_offset)
		
		var sprite_name := read_string()
		
		sprite.name = sprite_name
		buffer.seek(current_offset)
			
func read_sprites(sprite_count: int):
	var current_offset := buffer.get_position()
	for _i in range(sprite_count):
		var sprite: DIVASprite
		
		if RenderingServer.get_rendering_device():
			sprite = DIVASpriteRD.new()
		else:
			sprite = DIVASpriteCompatibility.new()
		
		var texture_index := buffer.get_u32()
		buffer.seek(buffer.get_position()+4) # ???
		var _rectangle_begin := Vector2(buffer.get_float(), buffer.get_float())
		var _rectangle_end := Vector2(buffer.get_float(), buffer.get_float())
		var x := buffer.get_float()
		var y := buffer.get_float()
		var width := buffer.get_float()
		var height := buffer.get_float()
		var texture := textures[texture_index] as DIVATextureData
		
		var region_rect := Rect2(x, y, width, height)
		sprite.region = region_rect
		sprite.diva_texture = texture

		sprites.append(sprite)
	buffer.seek(current_offset)

func read_string() -> String:
	var curr_offset := buffer.get_position()
	
	var out_str := ""
	
	var str_size := 0
	
	while buffer.get_available_bytes() != 0:
		var byte := buffer.get_8()
		str_size += 1
		if byte == 0x00:
			break
	
	buffer.seek(curr_offset)
	
	out_str = buffer.get_utf8_string(str_size)
	
	return out_str
