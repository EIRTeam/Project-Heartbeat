extends MarginContainer

signal layer_visibility_changed(visibility, layer)

onready var layer_container = get_node("VBoxContainer2")
const EditorLayerManagerLayer = preload("res://tools/editor/EditorLayerManagerLayer.tscn")

func clear_layers():
	for child in layer_container.get_children():
		child.queue_free()

func add_layer(layer_name: String, layer_visibility: bool):
	var layer = EditorLayerManagerLayer.instance()
	layer_container.add_child(layer)
	layer.layer_name = layer_name
	layer.layer_visible = layer_visibility
	layer.connect("layer_visibility_changed", self, "_on_layer_visibility_changed", [layer_name])
	
	
func _on_layer_visibility_changed(visibility: bool, layer_name: String):
	emit_signal("layer_visibility_changed", visibility, layer_name)
