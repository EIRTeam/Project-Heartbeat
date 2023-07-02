extends HBInspectorPropertyEditor

class_name HBInspectorPropertyEditFont

@onready var font_selector_option_button := OptionButton.new()

var resource_storage: HBInspectorResourceStorage: set = set_resource_storage

var current_font: HBUIFont

var current_font_name := ""

@onready var size_spinbox := SpinBox.new()

@onready var fallback_hint_selector := OptionButton.new()

@onready var outline_size_spinbox := SpinBox.new()

@onready var outline_color_picker := ColorPickerButton.new()

@onready var extra_character_spacing_spinbox := SpinBox.new()
@onready var extra_spacing_top_spinbox := SpinBox.new()
@onready var extra_spacing_bottom_spinbox := SpinBox.new()

func update_font_list():
	var fonts := resource_storage.get_fonts()
	font_selector_option_button.set_block_signals(true)
	font_selector_option_button.clear()
	font_selector_option_button.add_item("None")
	font_selector_option_button.set_item_metadata(0, "")
	for font_name in fonts:
		font_selector_option_button.add_item(font_name)
		font_selector_option_button.set_item_metadata(font_selector_option_button.get_item_count()-1, font_name)
	font_selector_option_button.set_block_signals(false)

func set_resource_storage(val):
	resource_storage = val
	if is_inside_tree():
		update_font_list()
		
func make_label_container(label_n: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := Label.new()
	l.text = label_n
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	vbox_container.add_child(h)
	return h
		
func _init_inspector():
	super._init_inspector()
	resource_storage.connect("fonts_changed", Callable(self, "_on_resource_storage_fonts_changed"))
	resource_storage.connect("font_removed", Callable(self, "_on_resource_storage_fonts_removed"))
	await self.ready
	update_font_list()
	vbox_container.add_child(font_selector_option_button)
	
	var h := make_label_container("Size")
	h.add_child(size_spinbox)
	size_spinbox.connect("value_changed", Callable(self, "_on_size_value_changed"))
	
	font_selector_option_button.connect("item_selected", Callable(self, "_on_item_selected"))

	h = make_label_container("Fallback")

	h.add_child(fallback_hint_selector)

	fallback_hint_selector.add_item("Normal", HBUIFont.FALLBACK_HINT.NORMAL)
	fallback_hint_selector.add_item("Bold", HBUIFont.FALLBACK_HINT.BOLD)
	fallback_hint_selector.add_item("Black", HBUIFont.FALLBACK_HINT.BLACK)
	
	fallback_hint_selector.connect("item_selected", Callable(self, "_on_fallback_hint_item_selected"))

	h = make_label_container("Outline Size")

	h.add_child(outline_size_spinbox)
	
	outline_size_spinbox.connect("value_changed", Callable(self, "_on_outline_size_changed"))

	h = make_label_container("Outline Color")
	h.add_child(outline_color_picker)
	
	outline_color_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outline_color_picker.connect("color_changed", Callable(self, "_on_outline_color_changed"))
	
	var spacing_label := Label.new()
	spacing_label.text = "Extra spacing"
	vbox_container.add_child(spacing_label)
	
	h = make_label_container("Top")
	h.add_child(extra_spacing_top_spinbox)

	h = make_label_container("Bottom")
	h.add_child(extra_spacing_bottom_spinbox)

	h = make_label_container("Char")
	h.add_child(extra_character_spacing_spinbox)
	
	extra_spacing_top_spinbox.connect("value_changed", Callable(self, "_on_extra_spacing_top_value_changed"))
	extra_character_spacing_spinbox.connect("value_changed", Callable(self, "_on_extra_spacing_char_value_changed"))
	extra_spacing_bottom_spinbox.connect("value_changed", Callable(self, "_on_extra_spacing_bottom_value_changed"))

	size_spinbox.set_block_signals(true)
	size_spinbox.min_value = 1
	size_spinbox.max_value = 255
	size_spinbox.set_block_signals(false)
func _on_extra_spacing_top_value_changed(val: int):
	current_font.spacing_top = val
	emit_signal("value_changed", current_font)

func _on_extra_spacing_bottom_value_changed(val: int):
	current_font.spacing_bottom = val
	emit_signal("value_changed", current_font)

func _on_extra_spacing_char_value_changed(val: int):
	current_font.extra_spacing_char = val
	emit_signal("value_changed", current_font)

func set_property_data(data: Dictionary):
	super.set_property_data(data)
	
func _on_resource_storage_fonts_changed():
	update_font_list()
	_update_controls()

func _on_resource_storage_font_removed(font_name: String):
	if font_name == current_font_name:
		update_font_list()
		font_selector_option_button.select(0)
		current_font_name = ""

func _update_controls():
	font_selector_option_button.set_block_signals(true)
	for i in range(font_selector_option_button.get_item_count()):
		var meta := font_selector_option_button.get_item_metadata(i) as String
		if current_font_name == meta:
			font_selector_option_button.select(i)
			break
	font_selector_option_button.set_block_signals(false)
	
	size_spinbox.set_block_signals(true)
	size_spinbox.value = current_font.size
	size_spinbox.set_block_signals(false)
	
	fallback_hint_selector.set_block_signals(true)
	fallback_hint_selector.select(current_font.fallback_hint)
	fallback_hint_selector.set_block_signals(false)
	
	outline_size_spinbox.set_block_signals(true)
	outline_size_spinbox.value = current_font.outline_size
	outline_size_spinbox.set_block_signals(false)

	outline_color_picker.set_block_signals(true)
	outline_color_picker.color = current_font.outline_color
	outline_color_picker.set_block_signals(false)
	
	extra_spacing_bottom_spinbox.set_block_signals(true)
	extra_spacing_bottom_spinbox.value = current_font.spacing_bottom
	extra_spacing_bottom_spinbox.set_block_signals(false)
	
	extra_spacing_top_spinbox.set_block_signals(true)
	extra_spacing_top_spinbox.value = current_font.spacing_top
	extra_spacing_top_spinbox.set_block_signals(false)
	
	extra_character_spacing_spinbox.set_block_signals(true)
	extra_character_spacing_spinbox.value = current_font.extra_spacing_char
	extra_character_spacing_spinbox.set_block_signals(false)
	
func _on_item_selected(val: int):
	current_font_name = font_selector_option_button.get_item_metadata(val)
	if current_font_name:
		current_font.font_data = resource_storage.get_font(current_font_name)
	else:
		current_font.font_data = null
	emit_signal("value_changed", current_font)

func _on_fallback_hint_item_selected(fallback: int):
	current_font.fallback_hint = fallback
	emit_signal("value_changed", current_font)

func _on_size_value_changed(new_size: int):
	current_font.size = new_size
	emit_signal("value_changed", current_font)

func _on_outline_size_changed(new_size: int):
	current_font.outline_size = new_size
	emit_signal("value_changed", current_font)

func _on_outline_color_changed(color: Color):
	current_font.outline_color = color
	emit_signal("value_changed", current_font)

func set_value(val):
	super.set_value(val)
	current_font = val
	current_font_name = resource_storage.get_font_name(val.font_data)
	if is_inside_tree():
		_update_controls()

func can_collapse() -> bool:
	return true
