extends MeshInstance
export(NodePath) var viewport_path
func _ready():
	get_viewport().connect("size_changed", self, "_on_resized")
	_on_resized()
func _on_resized():
	var viewport = get_node(viewport_path) as Viewport
	var base_width = ProjectSettings.get("display/window/size/width")
	var base_height = ProjectSettings.get("display/window/size/height")
	var base_ratio = float(base_width) / float(base_height)
	
	var current_aspect_ratio = get_viewport().size.x / get_viewport().size.y
	var new_scale = current_aspect_ratio / base_ratio
	scale = Vector3(new_scale, 1.0, 1.0)
	
	viewport.size = get_viewport().size
