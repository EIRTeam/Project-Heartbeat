extends PanelContainer

class_name HBInspectorMK2

@onready var vbox_container := get_node("ScrollContainer/VBoxContainer")

var current_object: Object
var resource_storage := HBInspectorResourceStorage.new()
@onready var name_label := Label.new()

signal value_changed(object)

class TestObj:
	extends Control
	@export var test1: float = 1.0
	@export var test2: int = 1
	func get_hb_inspector_whitelist() -> Array:
		return [
			"offset_left", "offset_right", "offset_top", "offset_bottom",
			"anchor_left", "anchor_right", "anchor_top", "anchor_bottom"
		]

var property_inspectors = {}

func inspect(to_inspect: Object):
	for ins in property_inspectors.values():
		ins.queue_free()
	property_inspectors.clear()
	name_label.hide()
	if to_inspect:
		if "name" in to_inspect:
			name_label.text = to_inspect.name
			name_label.show()
	else:
		return
	current_object = to_inspect

	
	var prop_whitelist := []
	var has_prop_whitelist := false
	
	if to_inspect.has_method("get_hb_inspector_whitelist"):
		prop_whitelist = to_inspect.get_hb_inspector_whitelist()
		has_prop_whitelist = true
	
	for property in to_inspect.get_property_list():
		if not has_prop_whitelist or property.name in prop_whitelist:
			var sc: HBInspectorPropertyEditor = null
			match property.type:
				TYPE_INT:
					if property.get("hint", PROPERTY_HINT_NONE) == PROPERTY_HINT_ENUM:
						sc = HBInspectorPropertyEditorEnum.new()
					else:
						sc = HBInspectorPropertyEditorReal.new()
				TYPE_FLOAT:
					sc = HBInspectorPropertyEditorReal.new()
				TYPE_COLOR:
					sc = HBInspectorPropertyEditorColor.new()
				TYPE_BOOL:
					sc = HBInspectorPropertyEditorBool.new()
				TYPE_OBJECT:
					if property.get("hint_string", "") == "hb_subres":
						sc = load("res://tools/new_inspector/HBInspectorPropertyEditorSubresource.gd").new()
						sc.resource_storage = resource_storage
					elif property.get("hint", PROPERTY_HINT_NONE) == PROPERTY_HINT_RESOURCE_TYPE:
						var hint_str := property.get("hint_string", "") as String
						match hint_str: 
							"Texture2D":
								sc = HBInspectorPropertyEditTexture.new()
								sc.resource_storage = resource_storage
					else:
						match property.get("class_name", ""):
							"FontFile":
								sc = HBInspectorPropertyEditFont.new()
								sc.resource_storage = resource_storage
			if sc:
				vbox_container.add_child(sc)
				if property.name in property_inspectors:
					property_inspectors[property.name].queue_free()
				property_inspectors[property.name] = sc
				sc.set_property_data(property)
				sc.set_value(current_object.get(property.name))
				sc.connect("value_changed", Callable(self, "_on_user_value_changed").bind(property.name))

func _on_user_value_changed(value, property_name: String):
	current_object.set(property_name, value)
	emit_signal("value_changed", current_object)

func property_changed_notified():
	for property_name in property_inspectors:
		var sc = property_inspectors[property_name] as HBInspectorPropertyEditor
		sc.set_value(current_object.get(property_name))

func clear_current():
	name_label.text = ""
	current_object = null
	for ins in property_inspectors.values():
		ins.queue_free()
	property_inspectors.clear()

func _ready():
	vbox_container.add_child(name_label)
