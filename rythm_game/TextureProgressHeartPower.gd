extends TextureProgress

var decreasing setget set_decreasing

func _ready():
	connect("value_changed", self, "_on_changed")
func _on_changed(new_val: float):
	var mat = material as ShaderMaterial
	mat.set_shader_param("progress", value / max_value)

func set_decreasing(val):
	decreasing = val
	var mat = material as ShaderMaterial
	mat.set_shader_param("decreasing", decreasing)
