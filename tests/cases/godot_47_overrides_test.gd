extends "res://tests/test_case.gd"


func test_font_set_hook_preserves_default_property_handling() -> void:
	var font := HBUIFont.new()
	expect_false(font._set("unhandled_property", null))
	expect_false(font._set("font_data", null))


func test_label_set_hook_preserves_default_property_handling() -> void:
	var label := HBUIDynamicLabel.new()
	expect_false(label._set("unhandled_property", null))
	expect_false(label._set("text", "test"))
	label.free()


func test_editor_layer_rejects_non_items() -> void:
	var layer := EditorLayer.new()
	expect_false(layer._can_drop_data(Vector2.ZERO, {}))
	layer.free()
