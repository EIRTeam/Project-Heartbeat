extends HBEditorSettings

func _ready():
	settings = {
		"General": [
			{"name": tr("Automatically save when \"Play\" is pressed"), "var": "editor_autosave_enabled", "type": "Bool"}
		],
		"Grid": [
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
			
		]
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


func _get_grid_types():
	return UserSettings.user_settings.editor_grid_type__possibilities

func _grid_is_dashes():
	return UserSettings.user_settings.editor_grid_type == 1

func _grid_is_subdivided():
	return UserSettings.user_settings.editor_grid_type == 2

func _secondary_grid_enabled():
	return UserSettings.user_settings.editor_grid_type != 0

func _multinote_crosses_enabled():
	return UserSettings.user_settings.editor_multinote_crosses_enabled
