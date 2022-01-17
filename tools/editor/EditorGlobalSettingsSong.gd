extends Control

onready var tree: Tree = get_node("Tree")

var editor: HBEditor setget set_editor
var per_song_settings = {
	"Timeline": [
		{"name": "BPM", "var": "bpm", "type": "Float", "options": {"min": 1}},
		{"name": tr("Offset"), "var": "offset", "type": "Float", "options": {"suffix": "s", "step": 0.001, "max": 100}},
		{"name": tr("Note resolution"), "var": "note_resolution", "type": "Int", "options": {"min": 1, "max": 32}},
		{"name": tr("Beats per bar"), "var": "beats_per_bar", "type": "Int", "options": {"min": 1, "max": 4}},
		{"name": tr("Snap to timeline"), "var": "timeline_snap", "type": "Bool"},
		{"name": tr("Show waveform"), "var": "waveform", "type": "Bool"},
		{"name": tr("Show hold duration"), "var": "hold_calculator", "type": "Bool"},
	],
	"Media": [
		{"name": tr("Show video"), "var": "show_video", "type": "Bool"},
		{"name": tr("Show background"), "var": "show_bg", "type": "Bool"},
		{"name": tr("Selected variant"), "var": "selected_variant", "type": "List", "data_callback": "_get_variants", "options": {"parser": "_variants_parser", "update_affects_media": true}},
	],
	"Grid": [
		{"name": tr("Snap to grid"), "var": "grid_snap", "type": "Bool"},
		{"name": tr("Show grid"), "var": "show_grid", "type": "Bool"},
		{"x_name": tr("Grid rows"), "y_name": tr("Grid columns"), "var": "grid_resolution", "type": "Vector2", "options": {"suffix_x": "rows", "suffix_y": "columns", "min": 1, "max": 100, "step": 0.05, "update_affects_settings": true}},
		{"x_name": tr("Grid row spacing"), "y_name": tr("Grid column spacing"), "var": "grid_resolution", "type": "Vector2", "options": {"parser": "_grid_column_spacing_parser", "suffix": "px", "min": 1, "step": 1, "update_affects_settings": true}},
	],
	"Placements": [
		{"name": tr("Place notes on a line"), "var": "autoplace", "type": "Bool"},
		{"name": tr("Angle notes automatically"), "var": "autoangle", "type": "Bool"},
		{"name": tr("Automatically set multi params"), "var": "auto_multi", "type": "Bool"},
		{"name": tr("Space slide pieces correctly"), "var": "autoslide", "type": "Bool"},
		{"name": tr("Separation per 8th"), "var": "separation", "type": "Int", "options": {"suffix": "px"}},
		{"name": tr("Diagonal angle"), "var": "diagonal_angle", "type": "Int", "options": {"suffix": "º", "max": 90}},
		{"name": tr("Arranger snaps"), "var": "arranger_snaps", "type": "Int", "options": {"min": 1, "max": 92}},
		{"name": tr("Angle snaps"), "var": "angle_snaps", "type": "Int", "options": {"min": 1, "max": 92}},
	],
	"Transforms": [
		{"name": tr("Use center for transforms"), "var": "transforms_use_center", "type": "Bool"},
		{"name": tr("Angle circle inwards"), "var": "circle_from_inside", "type": "Bool"},
		{"name": tr("Circle size"), "var": "circle_size", "type": "Int", "options": {"suffix": "8ths", "min": 1, "max": 64, }},
		{"name": tr("Circle separation per 8th"), "var": "circle_separation", "type": "Int", "options": {"suffix": "px"}},
	]
}


func _ready():
	tree.connect("item_edited", self, "_on_tree_item_edited")
	tree.connect("custom_popup_edited", self, "_on_custom_popup_edited")
	populate()

func set_editor(val):
	editor = val
	editor.connect("song_editor_settings_changed", self, "update")
	populate()

func populate():
	if not editor:
		return
	
	tree.clear()
	var root: TreeItem = tree.create_item()
	
	for section in per_song_settings:
		var section_item: TreeItem = tree.create_item(root)
		section_item.set_text(0, section)
		
		for option in per_song_settings[section]:
			match option.type:
				"Bool":
					var item := tree.create_item(section_item)
					item.set_text(0, option.name)
					item.set_meta("property_name", option.var)
					item.set_meta("type", option.type)
					
					item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
					item.set_checked(1, editor.song_editor_settings[option.var])
					item.set_editable(1, true)
					item.set_text(1, "Enabled")
				"Int":
					var item := tree.create_item(section_item)
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
					item.set_range(1, editor.song_editor_settings[option.var])
					item.set_editable(1, true)
					item.set_suffix(1, suffix)
				"Float":
					var item := tree.create_item(section_item)
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
					item.set_range(1, editor.song_editor_settings[option.var])
					item.set_editable(1, true)
					item.set_suffix(1, suffix)
				"Vector2":
					var item_x := tree.create_item(section_item)
					item_x.set_text(0, option.x_name)
					item_x.set_meta("property_name", option.var)
					item_x.set_meta("type", option.type)
					
					var item_y := tree.create_item(section_item)
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
						if "update_affects_settings" in option.options:
							item_x.set_meta("update_affects_settings", option.options.update_affects_settings)
							item_y.set_meta("update_affects_settings", option.options.update_affects_settings)
					
					item_x.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
					item_x.set_range_config(1, minimum, maximum, step)
					item_x.set_suffix(1, suffix_x)
					item_x.set_editable(1, true)
					
					item_y.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
					item_y.set_range_config(1, minimum, maximum, step)
					item_y.set_suffix(1, suffix_y)
					item_y.set_editable(1, true)
					
					if parser:
						var value = editor.song_editor_settings[option.var]
						value = call(parser, value, "update")
						item_x.set_meta("parser", parser)
						item_y.set_meta("parser", parser)
						item_x.set_range(1, value.x)
						item_y.set_range(1, value.y)
					else:
						item_x.set_range(1, editor.song_editor_settings[option.var].x)
						item_y.set_range(1, editor.song_editor_settings[option.var].y)
				"List":
					var item := tree.create_item(section_item)
					item.set_text(0, option.name)
					item.set_meta("property_name", option.var)
					item.set_meta("type", option.type)
					item.set_meta("data_callback", option.data_callback)
					
					var data = call(option.data_callback)
					var value = editor.song_editor_settings[option.var]
					
					var popup_menu := PopupMenu.new()
					for name in data:
						popup_menu.add_item(name)
					popup_menu.connect("index_pressed", self, "_on_list_item_selected", [item])
					editor.add_child(popup_menu)
					item.set_meta("popup_menu", popup_menu)
					
					if "options" in option:
						if "update_affects_media" in option.options:
							item.set_meta("update_affects_media", option.options.update_affects_media)
						if "parser" in option.options:
							item.set_meta("parser", option.options.parser)
							value = call(option.options.parser, value, "update")
					
					item.set_cell_mode(1, TreeItem.CELL_MODE_CUSTOM)
					item.set_text(1, data[value])
					item.set_meta("value", value)
					item.set_editable(1, true)

func update(ignore = []):
	var root := tree.get_root()
	
	var item := root.get_children() as TreeItem
	while item:
		if item in ignore or not item.has_meta("property_name"):
			item = item.get_next_visible()
			continue
		
		var property_name := item.get_meta("property_name") as String
		var type := item.get_meta("type") as String
		var value = editor.song_editor_settings[property_name]
		
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
				
				item.set_meta("value", value)
				item.set_text(1, data[value])
		
		item = item.get_next_visible()


func _on_tree_item_edited():
	var edited := tree.get_edited()
	var property_name := edited.get_meta("property_name") as String
	var type := edited.get_meta("type") as String
	var update_affects_settings = edited.get_meta("update_affects_settings")
	var update_affects_media = edited.get_meta("update_affects_media")
	var ignore_list = []
	
	var current_value = editor.song_editor_settings.get(property_name)
	var new_value = editor.song_editor_settings.get(property_name)
	match type:
		"Bool":
			new_value = edited.is_checked(1)
			ignore_list = [edited]
		"Int", "Float":
			new_value = edited.get_range(1)
			ignore_list = [edited]
		"Vector2":
			var item_x = edited.get_meta("item_x")
			var item_y = edited.get_meta("item_y")
			ignore_list = [item_x, item_y]
			
			new_value = {"x": item_x.get_range(1), "y": item_y.get_range(1)}
		"List":
			new_value = edited.get_meta("value")
	
	if edited.get_meta("parser"):
		new_value = call(edited.get_meta("parser"), new_value, "edited")
	
	if current_value != new_value:
		editor.disconnect("song_editor_settings_changed", self, "update")
		editor.song_editor_settings.set(property_name, new_value)
		editor.load_settings(editor.song_editor_settings, true)
		editor.connect("song_editor_settings_changed", self, "update")
		if update_affects_settings:
			update(ignore_list)
		if update_affects_media:
			editor.update_media()

func _on_custom_popup_edited(_arrow_pressed: bool):
	var edited := tree.get_edited()
	var property_name := edited.get_meta("property_name") as String
	var type := edited.get_meta("type") as String
	match type:
		"List":
			var popup_menu = edited.get_meta("popup_menu") as PopupMenu
			popup_menu.popup(tree.get_custom_popup_rect())

func _on_list_item_selected(idx: int, edited: TreeItem):
	var data = call(edited.get_meta("data_callback"))
	edited.set_meta("value", idx)
	edited.set_text(1, data[idx])
	_on_tree_item_edited()


func _grid_column_spacing_parser(value, _mode):
	var new_value = {"x": 1080.0 / value.x, "y": 1920.0 / value.y}
	return new_value

func _get_variants():
	var variants = ["Default"]
	if editor.current_song:
		for variant in editor.current_song.song_variants:
			if YoutubeDL.get_cache_status(variant.variant_url, !variant.audio_only, true) == YoutubeDL.CACHE_STATUS.OK:
				variants.append(variant.variant_name)
	
	return variants

func _variants_parser(value, mode):
	if mode == "update":
		return value + 1
	else:
		return value - 1
