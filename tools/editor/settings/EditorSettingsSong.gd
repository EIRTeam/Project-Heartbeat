extends HBEditorSettings

signal layer_visibility_changed(visibility, layer)

const HIDDEN_ICON = preload("res://tools/icons/icon_GUI_visibility_hidden.svg")
const VISIBLE_ICON = preload("res://tools/icons/icon_GUI_visibility_visible.svg")

var layers_item: TreeItem
var note_resolution_item: TreeItem

func _ready():
	super._ready()
	settings = {
		"Timeline": [
			{"name": tr("Note resolution"), "var": "note_resolution", "type": "Int", "options": {"min": 1, "max": 128, "set_var": true}},
			{"name": tr("Snap to timeline"), "var": "timeline_snap", "type": "Bool"},
		],
		"Media": [
			{"name": tr("Show video"), "var": "show_video", "type": "Bool"},
			{"name": tr("Show background"), "var": "show_bg", "type": "Bool"},
			{"name": tr("Selected variant"), "var": "selected_variant", "type": "List", "data_callback": "_get_variants", "options": {"parser": "_variants_parser"}},
		],
	}

func populate():
	super.populate()
	
	if not editor:
		return
	
	var root := tree.get_root()
	
	layers_item = tree.create_item(root)
	layers_item.set_text(0, tr("Layer visibility"))

func set_editor(val):
	editor = val
	
	load_settings(editor.song_editor_settings)
	editor.connect("song_editor_settings_changed", Callable(self, "update"))
	
	connect("layer_visibility_changed", Callable(editor.timeline, "change_layer_visibility"))
	connect("layer_visibility_changed", Callable(editor, "_on_layer_visibility_changed"))
	
	populate()

func load_settings(settings):
	settings_base = settings

func update_setting(property_name: String, new_value):
	editor.disconnect("song_editor_settings_changed", Callable(self, "update"))
	settings_base.set(property_name, new_value)
	editor.load_settings(settings_base, true)
	editor.connect("song_editor_settings_changed", Callable(self, "update"))
	
	if property_name == "selected_variant":
		editor.update_media()

func _grid_column_spacing_parser(value, _mode):
	var new_value = {"x": 1080.0 / value.x, "y": 1920.0 / value.y}
	return new_value

func _get_variants():
	var variants = {"Default": true}
	if editor.current_song:
		for variant in editor.current_song.song_variants:
			var display_name = variant.variant_name
			var audio_status = YoutubeDL.get_cache_status(variant.variant_url, false, true) == YoutubeDL.CACHE_STATUS.OK
			if not audio_status:
				display_name += " (audio not downloaded)"
			elif not variant.audio_only:
				if not YoutubeDL.get_cache_status(variant.variant_url, true, true) == YoutubeDL.CACHE_STATUS.OK:
					display_name += " (video not downloaded)"
			variants[display_name] = audio_status
	
	return variants

func _variants_parser(value, mode):
	if mode == "update":
		return value + 1
	else:
		return value - 1


func clear_layers():
	var item = layers_item.get_children()
	while item:
		var _item = item
		item = item.get_next()
		_item.free()

func add_layer(layer_name: String, layer_visibility: bool):
	var text := tr("Visible") if layer_visibility else tr("Hidden")
	var icon := VISIBLE_ICON if layer_visibility else HIDDEN_ICON
	
	var item := tree.create_item(layers_item)
	item.set_text(0, _get_nice_name(layer_name))
	item.set_meta("property_name", layer_name)
	item.set_meta("type", "Layer")
	
	item.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
	item.set_checked(1, layer_visibility)
	item.set_editable(1, true)
	item.set_icon(1, icon)
	item.set_text(1, text)

func _get_nice_name(layer: String):
	var name = layer.to_lower()
	name[0] = layer[0].to_upper()
	
	# Why the hell does String.replace() not work
	if "_" in name:
		var i = name.find("_")
		name[i] = " "
	
	if layer[-1].is_valid_int():
		name[-1] = " "
		name += layer[-1]
	
	return name

func custom_input_parser(item: TreeItem):
	if item.get_meta("type") == "Layer":
		var layer_name = item.get_meta("property_name")
		var visibility = item.is_checked(1)
		
		emit_signal("layer_visibility_changed", visibility, layer_name)
		
		var text := tr("Visible") if visibility else tr("Hidden")
		var icon := VISIBLE_ICON if visibility else HIDDEN_ICON
		
		item.set_text(1, text)
		item.set_icon(1, icon)
