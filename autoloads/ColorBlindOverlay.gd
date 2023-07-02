extends CanvasLayer

func _ready():
	$Control.hide()

func update_overlay():
	if UserSettings.user_settings.color_remap == HBUserSettings.COLORBLIND_COLOR_REMAP.NONE:
		$Control.hide()
	else:
		$Control.show()
		var mat := $Control.material as ShaderMaterial
		mat.set_shader_parameter("mode", UserSettings.user_settings.color_remap)
