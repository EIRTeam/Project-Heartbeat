class_name DIVATextureProcessor

static var pipeline_ycbcr: RID
static var shader_ycbcr: RID
static var sampler: RID

var textures: Array[Image]
var in_texture_rids_rs: Array[RID]
var in_texture_rids_rd: Array[RID]
var out_texture: RID
var ycbcr_uniform_set: RID

var out_texture_2d := Texture2DRD.new()
var mipmap_generator: HBMipmapGenerator

enum Flags {
	FLAG_YCBCR_TO_RGB = 1,
	FLAG_FLIP_Y = 2,
	FLAG_GENERATE_MIPMAPS = 4
}

var flags: int

signal completed

# Static destructor called by HBGame
static func _destruct():
	var rd := RenderingServer.get_rendering_device()
	if pipeline_ycbcr.is_valid():
		rd.free_rid(pipeline_ycbcr)
	if sampler.is_valid():
		rd.free_rid(sampler)
	if shader_ycbcr.is_valid():
		rd.free_rid(shader_ycbcr)

static func _static_init_rd() -> void:
	var rd := RenderingServer.get_rendering_device()
	const SHADER: RDShaderFile = preload("res://scripts/diva_yuv_to_rgb_conversion.glsl")
	shader_ycbcr = rd.shader_create_from_spirv(SHADER.get_spirv())
	pipeline_ycbcr = rd.compute_pipeline_create(shader_ycbcr)

func _validate_texture_sizes(luma: Image, chroma: Image) -> bool:
	return luma.get_size().x == chroma.get_size().x * 2 and luma.get_size().y == chroma.get_size().y * 2

func _validate_texture_format(img: Image) -> bool:
	return img.get_format() == Image.FORMAT_RGTC_RG

func _init(_textures: Array[Image], _flags := 0) -> void:
	flags = _flags
	if flags & Flags.FLAG_YCBCR_TO_RGB:
		assert(_textures.size() == 2)
		assert(_validate_texture_sizes(_textures[0], _textures[1]), "Chrominance texture must be half the size of the luma/alpha one")
		assert(_validate_texture_format(_textures[0]), "DIVA textures must be FORMAT_RGTC_RG")
		assert(_validate_texture_format(_textures[1]), "DIVA textures must be FORMAT_RGTC_RG")
	else:
		assert(_textures.size() == 1)
	textures = _textures
	RenderingServer.call_on_render_thread(_conversion_impl)

func get_texture_2d_rd() -> Texture2DRD:
	return out_texture_2d

func _ycbcr_to_rgb(rd: RenderingDevice, output_uniform: RDUniform, output_texture_format: RDTextureFormat, flip_y: bool):
	var uniform_yalpha := RDUniform.new()
	uniform_yalpha.binding = 0
	uniform_yalpha.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform_yalpha.add_id(sampler)
	uniform_yalpha.add_id(in_texture_rids_rd[0])
	
	var uniform_cbcr := RDUniform.new()
	uniform_cbcr.binding = 1
	uniform_cbcr.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform_cbcr.add_id(sampler)
	uniform_cbcr.add_id(in_texture_rids_rd[1])
	
	ycbcr_uniform_set = rd.uniform_set_create([uniform_yalpha, uniform_cbcr, output_uniform], shader_ycbcr, 0)
	
	var push_constant := PackedFloat32Array([output_texture_format.width, output_texture_format.height, 1.0 if flip_y else 0.0, 0.0])
	var push_constant_bytes := push_constant.to_byte_array()
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline_ycbcr)
	rd.compute_list_bind_uniform_set(compute_list, ycbcr_uniform_set, 0)
	rd.compute_list_set_push_constant(compute_list, push_constant_bytes, push_constant_bytes.size())
	rd.compute_list_dispatch(compute_list, ceil(output_texture_format.width / 8.0), ceil(output_texture_format.height / 8.0), 1)
	rd.compute_list_end()
	
func _conversion_impl():
	var rd := RenderingServer.get_rendering_device()
	rd.draw_command_begin_label("DIVA image processing", Color.DEEP_PINK)
	in_texture_rids_rs.resize(textures.size())
	in_texture_rids_rd.resize(textures.size())
	for i in range(textures.size()):
		var texture_data := textures[i]
		var texture_rid_rs := RenderingServer.texture_2d_create(texture_data)
		var texture_rid_rd := RenderingServer.texture_get_rd_texture(texture_rid_rs)
		in_texture_rids_rs[i] = texture_rid_rs
		in_texture_rids_rd[i] = texture_rid_rd
	
	# Create out texture
	var out_texture_format := RDTextureFormat.new()
	out_texture_format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	out_texture_format.width = textures[0].get_width()
	out_texture_format.height = textures[0].get_height()
	out_texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_TO_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	if flags & Flags.FLAG_GENERATE_MIPMAPS:
		out_texture_format.mipmaps = floor(log(max(out_texture_format.width, out_texture_format.height)) / log(2)) + 1
	out_texture = rd.texture_create(out_texture_format, RDTextureView.new())
	sampler = rd.sampler_create(RDSamplerState.new())
	
	var uniform_out := RDUniform.new()
	uniform_out.binding = 2
	uniform_out.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform_out.add_id(out_texture)
	
	if flags & Flags.FLAG_YCBCR_TO_RGB:
		_ycbcr_to_rgb(rd, uniform_out, out_texture_format, flags & Flags.FLAG_FLIP_Y)
		# Mipmap generation from an already flipped image
		if flags & Flags.FLAG_GENERATE_MIPMAPS:
			mipmap_generator = HBMipmapGenerator.new(out_texture_format, out_texture, out_texture)
			mipmap_generator.generate()
	else:
		# Mipmap generation from scratch
		if flags & Flags.FLAG_GENERATE_MIPMAPS:
			mipmap_generator = HBMipmapGenerator.new(out_texture_format, in_texture_rids_rd[0], out_texture, flags & Flags.FLAG_FLIP_Y)
			mipmap_generator.generate()
	out_texture_2d.texture_rd_rid = out_texture
	completed.emit.call_deferred()
	rd.draw_command_end_label()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			var rd := RenderingServer.get_rendering_device()
			if ycbcr_uniform_set.is_valid():
				rd.free_rid(ycbcr_uniform_set)
			if sampler.is_valid():
				rd.free_rid(sampler)
			for tex_rid in in_texture_rids_rs:
				RenderingServer.free_rid(tex_rid)
