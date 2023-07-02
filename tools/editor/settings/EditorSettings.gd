extends Control

class_name HBEditorSettings

@onready var tree: Tree = get_node("Tree")
@onready var color_picker_texture = load("res://tools/icons/ColorPick.svg")

var editor: HBEditor: set = set_editor
var settings
var settings_base

func _ready():
	tree.connect("item_edited", Callable(self, "_on_tree_item_edited").bind(), CONNECT_DEFERRED)
	tree.connect("custom_popup_edited", Callable(self, "_on_custom_popup_edited"))
	tree.connect("button_clicked", Callable(self, "_on_button_pressed"))

func set_editor(val):
	editor = val
	populate()

func populate():
	if not editor:
		return
	
	tree.clear()
	var root: TreeItem = tree.create_item()
	
	for section in settings:
		var section_item: TreeItem = tree.create_item(root)
		section_item.set_text(0, section)
		
		for option in settings[section]:
			if "options" in option and "condition" in option.options:
				var expr = Expression.new()
				var error = expr.parse(option.options.condition)
				if error != OK:
					print("ERROR: Condition check failed. " + expr.get_error_text())
					continue
				
				if not expr.execute([], settings_base):
					continue
			
			var item = create_item(option, section_item)
			
			if "options" in option and "set_var" in option.options and option.options.set_var:
				set(option.var + "_item", item)

func create_item(option, parent):
	match option.type:
		"Bool":
			var item := tree.create_item(parent)
			item.set_text(0, option.name)
			item.set_meta("property_name", option.var)
			item.set_meta("type", option.type)
			
			if "options" in option:
				if "update_affects_conditions" in option.options:
					item.set_meta("update_affects_conditions", option.options.update_affects_conditions)
			
			item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			item.set_checked(1, settings_base[option.var])
			item.set_editable(1, true)
			item.set_text(1, "Enabled")
			
			return item
		"Int":
			var item := tree.create_item(parent)
			item.set_text(0, option.name)
			item.set_meta("property_name", option.var)
			item.set_meta("type", option.type)
			
			var minimum = 0
			var maximum = 250
			var suffix = ""
			if "options" in option:
				if "min" in option.options:
					minimum = option.options.min
				if "max" in option.options:
					maximum = option.options.max
				if "suffix" in option.options:
					suffix = option.options.suffix
			
			item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			item.set_range_config(1, minimum, maximum, 1)
			item.set_range(1, settings_base[option.var])
			item.set_editable(1, true)
			item.set_suffix(1, suffix)
			
			return item
		"Float":
			var item := tree.create_item(parent)
			item.set_text(0, option.name)
			item.set_meta("property_name", option.var)
			item.set_meta("type", option.type)
			
			var minimum = 0.0
			var maximum = 999.0
			var step = 0.1
			var suffix = ""
			if "options" in option:
				if "min" in option.options:
					minimum = option.options.min
				if "max" in option.options:
					maximum = option.options.max
				if "step" in option.options:
					step = option.options.step
				if "suffix" in option.options:
					suffix = option.options.suffix
			
			item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			item.set_range_config(1, minimum, maximum, step)
			item.set_range(1, settings_base[option.var])
			item.set_editable(1, true)
			item.set_suffix(1, suffix)
			
			return item
		"Vector2":
			var item_x := tree.create_item(parent)
			item_x.set_text(0, option.x_name)
			item_x.set_meta("property_name", option.var)
			item_x.set_meta("type", option.type)
			
			var item_y := tree.create_item(parent)
			item_y.set_text(0, option.y_name)
			item_y.set_meta("property_name", option.var)
			item_y.set_meta("type", option.type)
			
			item_x.set_meta("item_x", item_x)
			item_x.set_meta("item_y", item_y)
			item_y.set_meta("item_x", item_x)
			item_y.set_meta("item_y", item_y)
			
			var minimum = 0.0
			var maximum = 999.0
			var step = 0.1
			var suffix_x = ""
			var suffix_y = ""
			var parser = ""
			if "options" in option:
				if "min" in option.options:
					minimum = option.options.min
				if "max" in option.options:
					maximum = option.options.max
				if "step" in option.options:
					step = option.options.step
				if "suffix" in option.options:
					suffix_x = option.options.suffix
					suffix_y = option.options.suffix
				if "suffix_x" in option.options:
					suffix_x = option.options.suffix_x
				if "suffix_y" in option.options:
					suffix_y = option.options.suffix_y
				if "parser" in option.options:
					parser = option.options.parser
			
			item_x.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			item_x.set_range_config(1, minimum, maximum, step)
			item_x.set_suffix(1, suffix_x)
			item_x.set_editable(1, true)
			
			item_y.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			item_y.set_range_config(1, minimum, maximum, step)
			item_y.set_suffix(1, suffix_y)
			item_y.set_editable(1, true)
			
			if parser:
				var value = settings_base[option.var]
				value = call(parser, value, "update")
				item_x.set_meta("parser", parser)
				item_y.set_meta("parser", parser)
				item_x.set_range(1, value.x)
				item_y.set_range(1, value.y)
			else:
				item_x.set_range(1, settings_base[option.var].x)
				item_y.set_range(1, settings_base[option.var].y)
			
			return item_x
		"List":
			var item := tree.create_item(parent)
			item.set_text(0, option.name)
			item.set_meta("property_name", option.var)
			item.set_meta("type", option.type)
			item.set_meta("data_callback", option.data_callback)
			
			var data = call(option.data_callback)
			var value = settings_base[option.var]
			
			var popup_menu := PopupMenu.new()
			for item_name in data:
				popup_menu.add_item(item_name)
				popup_menu.set_item_disabled(popup_menu.get_item_count()-1, !data[item_name])
			popup_menu.connect("index_pressed", Callable(self, "_on_list_item_selected").bind(item))
			tree.add_child(popup_menu)
			item.set_meta("popup_menu", popup_menu)
			
			if "options" in option:
				if "parser" in option.options:
					item.set_meta("parser", option.options.parser)
					value = call(option.options.parser, value, "update")
				if "update_affects_conditions" in option.options:
					item.set_meta("update_affects_conditions", option.options.update_affects_conditions)
			
			item.set_cell_mode(1, TreeItem.CELL_MODE_CUSTOM)
			item.set_text(1, data.keys()[value])
			item.set_meta("value", value)
			item.set_editable(1, true)
			
			return item
		"Color":
			var item := tree.create_item(parent)
			item.set_text(0, option.name)
			item.set_meta("property_name", option.var)
			item.set_meta("type", option.type)
			item.set_meta("presets", option.presets)
			
			var color_picker := ColorPicker.new()
			color_picker.color = settings_base[option.var]
			color_picker.connect("color_changed", Callable(self, "_on_color_changed").bind(item))
			item.set_meta("color_picker", color_picker)
			
			for preset in option.presets:
				color_picker.add_preset(preset)
			for preset in UserSettings.user_settings.color_presets:
				color_picker.add_preset(Color(preset))
			
			color_picker.connect("preset_added", Callable(self, "_on_colorpicker_preset_added").bind(item))
			color_picker.connect("preset_removed", Callable(self, "_on_colorpicker_preset_removed").bind(item))
			
			var popup := Window.new()
			popup.title = option.name
			popup.add_child(color_picker)
			add_child(popup)
			item.set_meta("popup", popup)
			
			item.set_text(1, "#" + settings_base[option.var].to_html(false))
			item.add_button(1, color_picker_texture)
			
			return item

func update(ignore = []):
	var root := tree.get_root()
	
	for item in root.get_children():
		if item in ignore or not item.has_meta("property_name"):
			continue
		
		var property_name := item.get_meta("property_name") as String
		var type := item.get_meta("type") as String
		var value = settings_base.get(property_name)
		
		if item.has_meta("parser"):
			value = call(item.get_meta("parser"), value, "update")
		
		match type:
			"Bool":
				item.set_checked(1, value)
			"Int", "Float":
				item.set_range(1, value)
			"Vector2":
				var item_x = item.get_meta("item_x")
				var item_y = item.get_meta("item_y")
				item_x.set_range(1, value.x)
				item_y.set_range(1, value.y)
			"List":
				var popup_menu = item.get_meta("popup_menu") as PopupMenu
				popup_menu.clear()
				
				var data = call(item.get_meta("data_callback"))
				for name in data:
					popup_menu.add_item(name)
					popup_menu.set_item_disabled(popup_menu.get_item_count()-1, !data[name])
				
				item.set_meta("value", value)
				item.set_text(1, data.keys()[value])
			"Color":
				item.set_text(1, "#" + value.to_html(false))
				var color_picker = item.get_meta("color_picker")
				color_picker.color = value
		
func _hide():
	var item = tree.get_selected()
	
	if item:
		var type = item.get_meta("type", null)
		
		if type == "List":
			var popup_menu = item.get_meta("popup_menu") as PopupMenu
			popup_menu.hide()


func _on_tree_item_edited():
	var edited := tree.get_edited()
	var property_name := edited.get_meta("property_name") as String
	var type := edited.get_meta("type") as String
	var update_affects_conditions = edited.get_meta("update_affects_conditions", false)
	
	var current_value = settings_base.get(property_name)
	var new_value = settings_base.get(property_name)
	match type:
		"Bool":
			new_value = edited.is_checked(1)
		"Int", "Float":
			new_value = edited.get_range(1)
		"Vector2":
			var item_x = edited.get_meta("item_x")
			var item_y = edited.get_meta("item_y")
			
			new_value = {"x": item_x.get_range(1), "y": item_y.get_range(1)}
		"List":
			new_value = edited.get_meta("value")
		_:
			custom_input_parser(edited)
			return
	
	if edited.get_meta("parser", ""):
		new_value = call(edited.get_meta("parser"), new_value, "edited")
	
	if current_value != new_value:
		update_setting(property_name, new_value)
		
		if update_affects_conditions:
			populate()


func _on_custom_popup_edited(_arrow_pressed: bool):
	var edited := tree.get_edited()
	var type := edited.get_meta("type") as String
	match type:
		"List":
			var popup_menu = edited.get_meta("popup_menu") as PopupMenu
			popup_menu.popup(tree.get_custom_popup_rect())

func _on_list_item_selected(idx: int, edited: TreeItem):
	var data = call(edited.get_meta("data_callback"))
	edited.set_meta("value", idx)
	edited.set_text(1, data.keys()[idx])
	_on_tree_item_edited()


func _on_button_pressed(item: TreeItem, column_id: int, id: int, _mouse_button: int):
	var type := item.get_meta("type") as String
	match type:
		"Color":
			var color_picker_popup = item.get_meta("popup")
			color_picker_popup.popup_centered()


func _on_color_changed(new_color: Color, item: TreeItem):
	var property_name := item.get_meta("property_name") as String
	var old_color := settings_base[property_name] as Color
	
	if old_color != new_color:
		update_setting(property_name, new_color)
		item.set_text(1, "#" + new_color.to_html(false))

func _on_colorpicker_preset_added(color: Color, item: TreeItem):
	var default_presets = item.get_meta("presets")
	if not color.to_html() in default_presets:
		UserSettings.user_settings.color_presets.append(color.to_html())
		UserSettings.save_user_settings()
func _on_colorpicker_preset_removed(color: Color, item: TreeItem):
	var default_presets = item.get_meta("presets")
	if not color.to_html() in default_presets:
		UserSettings.user_settings.color_presets.erase(color.to_html())
		UserSettings.save_user_settings()


func update_setting(property_name: String, new_value):
	pass

func custom_input_parser(item: TreeItem):
	pass
