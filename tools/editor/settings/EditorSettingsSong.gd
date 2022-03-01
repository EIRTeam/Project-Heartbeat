extends HBEditorSettings

func _ready():
	settings = {
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
			{"name": tr("Selected variant"), "var": "selected_variant", "type": "List", "data_callback": "_get_variants", "options": {"parser": "_variants_parser"}},
		],
		"Grid": [
			{"name": tr("Snap to grid"), "var": "grid_snap", "type": "Bool"},
			{"name": tr("Show grid"), "var": "show_grid", "type": "Bool"},
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

func set_editor(val):
	editor = val
	settings_base = editor.song_editor_settings
	editor.connect("song_editor_settings_changed", self, "update")
	populate()

func update_setting(property_name: String, new_value):
	editor.disconnect("song_editor_settings_changed", self, "update")
	settings_base.set(property_name, new_value)
	editor.load_settings(settings_base, true)
	editor.connect("song_editor_settings_changed", self, "update")
	
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
