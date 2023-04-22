extends MultiSpinBox

class_name HBEditorMultiSpinBox

const INTERPOLATE_ID = 8

func _ready():
	connect("error_changed", self, "_on_error")
	get_line_edit().connect("focus_entered", self, "_on_focus_entered")
	
	var menu := get_line_edit().get_menu()
	menu.connect("id_pressed", self, "_on_menu_id_pressed")
	
	menu.add_separator()
	menu.add_item("Interpolate property", INTERPOLATE_ID, get_shortcut(KEY_F, ["ctrl"]))

func _input(event):
	if event is InputEventMouseButton and not get_global_rect().has_point(get_global_mouse_position()):
		if event.button_index == BUTTON_LEFT and event.pressed:
			if get_line_edit().has_focus():
				reset_expression()

func _on_error(error_text):
	hint_tooltip = error_text

func _on_focus_entered():
	get_line_edit().select_all()

func get_shortcut(keycode: int, modifier: Array = []) -> int:
	var i := InputEventKey.new()
	
	i.control = modifier.has("ctrl")
	i.shift = modifier.has("shift")
	i.alt = modifier.has("alt")
	i.scancode = keycode
	
	return i.get_scancode_with_modifiers()

func _on_menu_id_pressed(id: int):
	var property = property_name if not inner_property_name else "%s.%s" % [property_name, inner_property_name]
	
	if id == INTERPOLATE_ID:
		var t = ""
		if property_name == "time":
			t = "i * (1 / float(notes.size() - 1))"
		else:
			t = "float(note.time - notes[0].time) / float(notes[notes.size() - 1].time - notes[0].time)"
		
		execute("lerp(notes[0].%s, notes[notes.size() - 1].%s, %s)" % [property, property, t])
		
		# HACK: Clear the array warning, since this is not an user-provided expression
		set_block_signals(true)
		execute("note.%s" % property)
		set_block_signals(false)
