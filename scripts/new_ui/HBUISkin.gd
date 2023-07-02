extends HBSerializable

class_name HBUISkin

# Map of screen to components
var screens := {}

var resources := HBSkinResources.new()

var rating_label_top_margin := 160

# not serialized
var _path: String: set = set_path

func set_path(val):
	_path = val
	resources._path = val

func _init():
	serializable_fields += [
		"screens", "resources", "rating_label_top_margin"
	]

func get_serialized_type():
	return "Skin"

func is_empty() -> bool:
	return screens.is_empty()

func get_components(screen: String, cache) -> Dictionary:
	var layered_components := {}
	if screen in screens:
		for layer_name in screens[screen].layered_components:
			if screens[screen].layered_components[layer_name] is Array:
				layered_components[layer_name] = []
				for component_dict in screens[screen].layered_components[layer_name]:
					if "component_type" in component_dict:
						var component_class: GDScript = HBGame.ui_components.get(component_dict.component_type, null)
						if component_class:
							var component: HBUIComponent = component_class.new()
							component._from_dict(component_dict, cache)
							layered_components[layer_name].push_back(component)
	return layered_components

func has_screen(screen_name: String) -> bool:
	return screens.has(screen_name) and screens[screen_name].layered_components.size() > 0
