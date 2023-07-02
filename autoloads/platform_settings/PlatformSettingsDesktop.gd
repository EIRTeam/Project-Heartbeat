extends HBPlatformSettings

class_name HBPlatformSettingsDesktop

enum ANGLE_BACKEND {
	NO_ANGLE,
	VULKAN,
	D3D11
}

var angle_backend = ANGLE_BACKEND.NO_ANGLE

func _init():
	var args = OS.get_cmdline_args()
	if "angle" in RenderingServer.get_video_adapter_name().to_lower():
		angle_backend = ANGLE_BACKEND.VULKAN
		for i in range(args.size()):
			var arg = args[i]
			if arg == "--angle-backend":
				if args.size() > i+1:
					var backend := (args[i+1] as String).to_lower()
					match backend:
						"vulkan":
							angle_backend = ANGLE_BACKEND.VULKAN
						"d3d11":
							angle_backend = ANGLE_BACKEND.D3D11
	
