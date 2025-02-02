class_name HBMipmapGenerator

var texture_format: RDTextureFormat
var in_texture: RID
var texture: RID
var shader: RID
var pipeline: RID
var sampler: RID
var uniform_sets: Array[RID]
var texture_views: Array[RID]
var flip_y := false

func _init(_texture_format: RDTextureFormat, _input_texture: RID, _out_texture: RID, _flip_y := false) -> void:
	texture_format = _texture_format
	texture = _out_texture
	in_texture = _input_texture
	flip_y = _flip_y

func generate():
	var rd := RenderingServer.get_rendering_device()
	sampler = rd.sampler_create(RDSamplerState.new())
	shader = rd.shader_create_from_spirv(preload("res://scripts/mipmap_generator_blit.glsl").get_spirv())
	pipeline = rd.compute_pipeline_create(shader)
	
	# Need a mip0 texture view to prevent overlapping slices, helps godot not bitch at us
	var mip0_texture_view := rd.texture_create_shared_from_slice(RDTextureView.new(), in_texture, 0, 0)
	texture_views.push_back(mip0_texture_view)
	
	var uniform_source := RDUniform.new()
	uniform_source.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform_source.binding = 0
	uniform_source.add_id(sampler)
	uniform_source.add_id(mip0_texture_view)
	var push_constant := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])

	var compute_list := rd.compute_list_begin()
	for i in range(1 if in_texture == texture else 0, texture_format.mipmaps):
		var dest_size := Vector2i(texture_format.width, texture_format.height) / pow(2, i)
		var texture_view := rd.texture_create_shared_from_slice(RDTextureView.new(), texture, 0, i)
		texture_views.push_back(texture_view)
		var mipmap_uniform := RDUniform.new()
		mipmap_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		mipmap_uniform.binding = 1
		mipmap_uniform.add_id(texture_view)
		
		var uniform_set := rd.uniform_set_create([uniform_source, mipmap_uniform], shader, 0)
		uniform_sets.push_back(uniform_set)
		
		push_constant[0] = dest_size.x
		push_constant[1] = dest_size.y
		push_constant[2] = 1.0 if flip_y else 0.0
		var push_constant_bytes := push_constant.to_byte_array()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_set_push_constant(compute_list, push_constant_bytes, push_constant_bytes.size())
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_dispatch(compute_list, ceil(dest_size.x / 8.0), ceil(dest_size.y / 8.0), 1)
	rd.compute_list_end()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			var rd := RenderingServer.get_rendering_device()
			for uniform_set in uniform_sets:
				rd.free_rid(uniform_set)
			for texture_view in texture_views:
				rd.free_rid(texture_view)
				
			if sampler.is_valid():
				rd.free_rid(sampler)
			if pipeline.is_valid():
				rd.free_rid(pipeline)
			if shader.is_valid():
				rd.free_rid(shader)
