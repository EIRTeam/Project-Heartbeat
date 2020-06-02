extends MeshInstance

const LOG_NAME = "GLES2ViewportRTHack"

# Fixes an issue that causes GLES2 Menus to be completely black

func _ready():
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		Log.log(self, "Applying GLES2 ViewportTexture hack")
		var material = get_surface_material(0) as SpatialMaterial
		material.flags_albedo_tex_force_srgb = false
		var texture = material.albedo_texture as ViewportTexture
		texture.flags = ViewportTexture.FLAG_FILTER
		VisualServer.viewport_set_hdr(get_viewport().get_viewport_rid(), false)
