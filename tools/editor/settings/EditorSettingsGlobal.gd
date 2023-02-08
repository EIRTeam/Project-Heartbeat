extends HBEditorSettings

func _ready():
	settings = {
		"General": [
			{"name": tr("Automatically save when \"Play\" is pressed"), "var": "editor_autosave_enabled", "type": "Bool"},
			{"name": tr("Shift pitch when changing the speed"), "var": "editor_pitch_compensation", "type": "Bool"},
		],
		"Timeline": [
			{"name": tr("Show waveform"), "var": "editor_show_waveform", "type": "Bool"},
			{"name": tr("Show hold duration"), "var": "editor_show_hold_calculator", "type": "Bool"},
			{"name": tr("Smooth scrolling"), "var": "editor_smooth_scroll", "type": "Bool", "options": {"update_affects_conditions": true}},
		],
		"Placements": [
			{"name": tr("Place notes on a line"), "var": "editor_auto_place", "type": "Bool"},
			{"name": tr("Arranger separation per 8th"), "var": "editor_arrange_separation", "type": "Int", "options": {"suffix": "px"}},
		],
		"Angles": [
			{"name": tr("Automatically set multi params"), "var": "editor_auto_multi", "type": "Bool"},
			{"name": tr("Angle notes automatically"), "var": "editor_auto_angle", "type": "Bool"},
			{"name": tr("Angle snaps"), "var": "editor_angle_snaps", "type": "Int", "options": {"min": 1, "max": 92}},
			{"name": tr("Angle increment per straight 8th"), "var": "editor_straight_angle_increment", "type": "Float", "options": {"suffix": "º", "step": 0.01, "min": 0.0, "max": 90.0}},
			{"name": tr("Angle increment per diagonal 8th"), "var": "editor_diagonal_angle_increment", "type": "Float", "options": {"suffix": "º", "step": 0.01, "min": 0.0, "max": 90.0}},
		],
		"Transforms": [
			{"name": tr("Circle size"), "var": "editor_circle_size", "type": "Int", "options": {"suffix": "8ths", "min": 4, "max": 64, }},
			{"name": tr("Circle separation per 8th"), "var": "editor_circle_separation", "type": "Int", "options": {"suffix": "px"}},
		],
		"Grid": [
			{"name": tr("Snap to grid"), "var": "editor_grid_snap", "type": "Bool"},
			{"name": tr("Show grid"), "var": "editor_show_grid", "type": "Bool"},
			{"name": tr("Grid type"), "var": "editor_grid_type", "type": "List", "data_callback": "_get_grid_types", "options": {"update_affects_conditions": true}},
			{"name": tr("Draw grid only inside safe area"), "var": "editor_grid_safe_area_only", "type": "Bool"},
			{"name": tr("Enable multinote indicators"), "var": "editor_multinote_crosses_enabled", "type": "Bool", "options": {"update_affects_conditions": true}},
			{"x_name": tr("Grid row spacing"), "y_name": tr("Grid column spacing"), "var": "editor_grid_resolution", "type": "Vector2", "options": {"suffix": "px", "min": 1, "max": 368, "step": 1}},
			{"name": tr("Dashes per grid space"), "var": "editor_dashes_per_grid_space", "type": "Int", "options": {"condition": "_grid_is_dashes", "min": 3, "max": 10}},
			{"name": tr("Grid subdivisions"), "var": "editor_grid_subdivisions", "type": "Int", "options": {"condition": "_grid_is_subdivided", "min": 0, "max": 5}},
		],
		"Visual": [
			{"name": tr("Main grid line color"), "var": "editor_main_grid_color", "type": "Color", "presets": [Color(0.5, 0.5, 0.5)]},
			{"name": tr("Main grid line width"), "var": "editor_main_grid_width", "type": "Float", "options": {"step": 0.05, "min": 1.0, "max": 3.0}},
			{"name": tr("Secondary grid line color"), "var": "editor_secondary_grid_color", "type": "Color", "presets": [Color(0.5, 0.5, 0.5)], "options": {"condition": "_secondary_grid_enabled"}},
			{"name": tr("Secondary grid line width"), "var": "editor_secondary_grid_width", "type": "Float", "options": {"condition": "_secondary_grid_enabled", "step": 0.05, "min": 1.0, "max": 3.0}},
			{"name": tr("Multinote cross color"), "var": "editor_multinote_cross_color", "type": "Color", "presets": [Color.white], "options": {"condition": "_multinote_crosses_enabled"}},
			{"name": tr("Multinote cross width"), "var": "editor_multinote_cross_width", "type": "Float", "options": {"condition": "_multinote_crosses_enabled", "step": 0.05, "min": 1.0, "max": 3.0}},
		],
		"Scripts": [
			{"name": tr("Script editor font size"), "var": "editor_code_font_size", "type": "Int", "options": {"min": 1, "max": 50}}
		],
	}
	
	settings_base = UserSettings.user_settings
	UserSettings.user_settings.connect("editor_grid_resolution_changed", self, "update")

func update_setting(property_name: String, new_value):
	settings_base.set(property_name, new_value)
	UserSettings.save_user_settings()
	
	if "grid" in property_name or "multinote_cross" in property_name:
		editor.grid_renderer.update()
	
	if property_name == "editor_grid_resolution":
		UserSettings.user_settings.disconnect("editor_grid_resolution_changed", self, "update")
		UserSettings.user_settings.emit_signal("editor_grid_resolution_changed")
		UserSettings.user_settings.connect("editor_grid_resolution_changed", self, "update")
	
	if property_name == "editor_show_hold_calculator":
		editor.hold_calculator_toggled()
	
	editor.update_user_settings()


func _get_grid_types() -> Dictionary:
	var types := {}
	for possibility in UserSettings.user_settings.editor_grid_type__possibilities:
		types[possibility] = true
	return types

func _grid_is_dashes() -> bool:
	return UserSettings.user_settings.editor_grid_type == 1

func _grid_is_subdivided() -> bool:
	return UserSettings.user_settings.editor_grid_type == 2

func _secondary_grid_enabled() -> bool:
	return UserSettings.user_settings.editor_grid_type != 0

func _multinote_crosses_enabled() -> bool:
	return UserSettings.user_settings.editor_multinote_crosses_enabled

func _smooth_scroll_enabled() -> bool:
	return UserSettings.user_settings.editor_smooth_scroll
