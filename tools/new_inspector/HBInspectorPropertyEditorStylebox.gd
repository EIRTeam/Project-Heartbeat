extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditorStylebox

"""
			stylebox.border_width_top = dict.get("border_width_top", 0)
			stylebox.border_width_bottom = dict.get("border_width_bottom", 0)
			stylebox.border_width_right = dict.get("border_width_right", 0)
			stylebox.border_width_left = dict.get("border_width_left", 0)
			stylebox.bg_color = Color(dict.get("bg_color", "#999999"))
			stylebox.border_color = Color(dict.get("border_color", "#cccccc"))
			stylebox.corner_detail = dict.get("corner_detail", 8)
			stylebox.anti_aliasing = dict.get("anti_aliasing", true)
			stylebox.corner_radius_bottom_left = dict.get("corner_radius_bottom_left", 0)
			stylebox.corner_radius_bottom_right = dict.get("corner_radius_bottom_right", 0)
			stylebox.corner_radius_top_left = dict.get("corner_radius_top_left", 0)
			stylebox.corner_radius_top_right = dict.get("corner_radius_top_right", 0)
			stylebox.shadow_color = Color(dict.get("shadow_color", "#cc000000"))
			stylebox.shadow_size = dict.get("shadow_size", 0)
"""

var property_controls := {}

var control_container := VBoxContainer.new()

var current_stylebox: StyleBox

func _init_inspector():
	super._init_inspector()
	await self.ready
	vbox_container.add_child(control_container)

func set_property_data(data: Dictionary):
	super.set_property_data(data)

func _on_color_changed(col: Color):
	value = col
	emit_signal("value_changed", col)

func _create_float_editor(property_name: String, step := 0.01):
	var sp := HBInspectorPropertyEditorReal.new()
	var hb := HBoxContainer.new()
	var l := Label.new()
	l.text = property_name.capitalize()
	hb.add_child(l)
	hb.add_child(sp)
	sp.step = step
	sp.value = current_stylebox.get(property_name)
	sp.connect("value_changed", Callable(self, "_on_float_property_changed").bind(property_name))
	control_container.add_child(hb)
	property_controls[property_name] = sp
	
func _create_bool_editor(property_name: String):
	var cb := HBInspectorPropertyEditorBool.new()
	var hb := HBoxContainer.new()
	var l := Label.new()
	l.text = property_name.capitalize()
	hb.add_child(l)
	hb.add_child(cb)
	cb.set_value(current_stylebox.get(property_name))
	cb.connect("toggled", Callable(self, "value_changed").bind(property_name))
	control_container.add_child(hb)
	property_controls[property_name] = cb

func _create_color_editor(property_name: String):
	var cb := ColorPickerButton.new()
	var hb := HBoxContainer.new()
	var l := Label.new()
	l.text = property_name.capitalize()
	hb.add_child(l)
	hb.add_child(cb)
	cb.color = current_stylebox.get(property_name)
	cb.connect("color_changed", Callable(self, "_on_color_property_changed").bind(property_name))
	control_container.add_child(hb)
	property_controls[property_name] = cb
	
func _on_float_property_changed(val: float, property_name: String):
	current_stylebox.set(property_name, val)
	emit_signal("value_changed", current_stylebox)
	
func _on_bool_property_changed(val: bool, property_name: String):
	current_stylebox.set(property_name, val)
	emit_signal("value_changed", current_stylebox)
	
func _on_color_property_changed(color: Color, property_name: String):
	current_stylebox.set(property_name, color)
	emit_signal("value_changed", current_stylebox)
	
	
func _create_editors_flat():
	for control in property_controls.values():
		control.queue_free()
	property_controls.clear()
	
	_create_float_editor("border_width_top", 1)
	_create_float_editor("border_width_bottom", 1)
	_create_float_editor("border_width_right", 1)
	_create_float_editor("border_width_left", 1)
	_create_color_editor("bg_color")
	_create_color_editor("border_color")
	_create_float_editor("corner_detail", 1)
	_create_bool_editor("anti_aliasing")
	_create_float_editor("corner_radius_bottom_left", 1)
	_create_float_editor("corner_radius_bottom_right", 1)
	_create_float_editor("corner_radius_top_left", 1)
	_create_float_editor("corner_radius_top_right", 1)
	_create_color_editor("shadow_color")
	_create_float_editor("shadow_size", 1)

func set_value(val):
	super.set_value(val)
	if is_inside_tree():
		if val is StyleBoxFlat:
			_create_editors_flat()
