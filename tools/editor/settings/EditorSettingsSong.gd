extends HBEditorSettings

signal layer_visibility_changed(visibility, layer)

const HIDDEN_ICON = preload("res://tools/icons/icon_GUI_visibility_hidden.svg")
const VISIBLE_ICON = preload("res://tools/icons/icon_GUI_visibility_visible.svg")

var layers_item: TreeItem
var note_resolution_item: TreeItem

signal song_variant_download_requested(song: HBSong, variant: int)

enum VariantAvailability {
	AVAILABLE,
	AUDIO_NOT_FOUND,
	VIDEO_NOT_FOUND,
	YT_DLP_AUDIO_NOT_CACHED,
	YT_DLP_VIDEO_NOT_CACHED,
}

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

func update_setting(property_name: String, new_value: Variant):
	var old_value: Variant = settings_base.get(property_name)
	if property_name == "selected_variant":
		var availabilities := _get_variant_availability()
		var availability := availabilities[new_value]
		if availability in [VariantAvailability.YT_DLP_VIDEO_NOT_CACHED, VariantAvailability.YT_DLP_AUDIO_NOT_CACHED]:
				song_variant_download_requested.emit(editor.current_song, new_value)
		
		if availability != VariantAvailability.AVAILABLE:
			# Undo change...
			_update_settings_tree(tree.get_root())
			return
	editor.disconnect("song_editor_settings_changed", Callable(self, "update"))
	settings_base.set(property_name, new_value)
	editor.load_settings(settings_base, true)
	editor.connect("song_editor_settings_changed", Callable(self, "update"))
	if property_name == "selected_variant":
		editor.update_media()

func _grid_column_spacing_parser(value, _mode):
	var new_value = {"x": 1080.0 / value.x, "y": 1920.0 / value.y}
	return new_value

func _get_variant_availability() -> Dictionary[int, VariantAvailability]:
	var variants: Dictionary[int, VariantAvailability] = {-1: VariantAvailability.AVAILABLE}
	if editor.current_song:
		for variant_idx in range(editor.current_song.song_variants.size()):
			var variant := editor.current_song.song_variants[variant_idx] as HBSongVariantData
			var availability := VariantAvailability.AVAILABLE
			var audio_status = YoutubeDL.get_cache_status(variant.variant_url, false, true) == YoutubeDL.CACHE_STATUS.OK
			
			# youtube URL
			if variant.variant_url:
				if not audio_status:
					availability = VariantAvailability.YT_DLP_AUDIO_NOT_CACHED
				elif not variant.audio_only:
					if not YoutubeDL.get_cache_status(variant.variant_url, true, true) == YoutubeDL.CACHE_STATUS.OK:
						availability = VariantAvailability.YT_DLP_VIDEO_NOT_CACHED
			else:
				# built-in audio file
				if variant.variant_audio.is_empty() or not FileAccess.file_exists(editor.current_song.get_variant_audio_res_path(variant_idx)):
					availability = VariantAvailability.AUDIO_NOT_FOUND
				if not variant.audio_only:
					if variant.variant_video.is_empty() or not FileAccess.file_exists(editor.current_song.get_variant_video_res_path(variant_idx)):
						availability = VariantAvailability.VIDEO_NOT_FOUND
			

			variants[variant_idx] = availability
	return variants
func _get_variants():
	var variants = {"Default": true}
	var availabilities := _get_variant_availability()
	if editor.current_song:
		for variant_idx in range(editor.current_song.song_variants.size()):
			var variant := editor.current_song.song_variants[variant_idx] as HBSongVariantData
			var availability := availabilities[variant_idx]
			var display_name = variant.variant_name
			var audio_status = YoutubeDL.get_cache_status(variant.variant_url, false, true) == YoutubeDL.CACHE_STATUS.OK
			match availabilities[variant_idx]:
				VariantAvailability.AVAILABLE:
					pass
				VariantAvailability.AUDIO_NOT_FOUND:
					display_name += " (audio not found in disk)"
				VariantAvailability.VIDEO_NOT_FOUND:
					display_name += " (video not found in disk)"
				VariantAvailability.YT_DLP_AUDIO_NOT_CACHED:
					display_name += " (audio not downloaded)"
				VariantAvailability.YT_DLP_VIDEO_NOT_CACHED:
					display_name += " (video not downloaded)"
			variants[display_name] = true
	
	return variants

func _variants_parser(value, mode):
	if mode == "update":
		return value + 1
	else:
		return value - 1

func clear_layers():
	var children := layers_item.get_children()
	for tree_item: TreeItem in children:
		tree_item.free()

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

func notify_song_media_cached():
	_update_settings_tree(tree.get_root())
