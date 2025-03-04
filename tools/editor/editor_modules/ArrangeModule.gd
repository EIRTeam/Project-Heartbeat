extends HBEditorModule

@onready var arrange_menu := get_node("ArrangeMenu")
@onready var arrange_pad := get_node("%ArrangeButtonPad")
@onready var arrange_mode_option_button := get_node("%ArrangeModeOptionButton")
@onready var arrange_angle_spinbox := get_node("%ArrangeAngleSpinBox")
@onready var arrange_diagonal_x_spinbox := get_node("%DiagonalStepXSpinBox")
@onready var arrange_diagonal_y_spinbox := get_node("%DiagonalStepYSpinBox")
@onready var arrange_vstep_spinbox := get_node("%VerticalStepSpinBox")
@onready var reverse_arrange_checkbox := get_node("%ReverseArrangeCheckBox")
@onready var autoangle_checkbox := get_node("%AutoAngleCheckBox")
@onready var standard_mode_options := get_node("%StandardHBoxContainer")
@onready var diagonal_mode_options := get_node("%DiagonalStepHBoxContainer")
@onready var fake_slope_mode_options := get_node("%FullWidthHBoxContainer")
@onready var circle_size_slider := get_node("%CircleSizeHSlider")
@onready var circle_size_spinbox := get_node("%CircleSizeSpinBox")
@onready var rotation_angle_slider := get_node("%RotationAngleHSlider")
@onready var rotation_angle_spinbox := get_node("%RotationAngleSpinBox")

@onready var autoarrange_menu_modes = [
	{"name": "Standard Line", "mode": HBUserSettings.EDITOR_ARRANGE_MODES.FREE, "options": standard_mode_options},
	{"name": "Diagonal Step Line", "mode": HBUserSettings.EDITOR_ARRANGE_MODES.DISTANCE, "options": diagonal_mode_options},
	{"name": "Full Width Line", "mode": HBUserSettings.EDITOR_ARRANGE_MODES.FAKE_SLOPE, "options": fake_slope_mode_options},
]

const autoarrange_shortcuts = [
	"editor_arrange_r",
	"editor_arrange_dr",
	"editor_arrange_d",
	"editor_arrange_dl",
	"editor_arrange_l",
	"editor_arrange_ul",
	"editor_arrange_u",
	"editor_arrange_ur",
]

var last_angle := 0.0

func _ready():
	super._ready()
	transforms = [
		HBEditorTransforms.MakeCircleTransform.new(1),  				# Clockwise, inside
		HBEditorTransforms.MakeCircleTransform.new(-1), 				# Counter-clockwise, inside
		HBEditorTransforms.MakeCircleTransform.new(1, true),    		# Clockwise, outside
		HBEditorTransforms.MakeCircleTransform.new(-1, true),   		# Counter-clockwise, outside
		HBEditorTransforms.FlipVerticallyTransformation.new(),  		# Global
		HBEditorTransforms.FlipHorizontallyTransformation.new(),    	# Global
		HBEditorTransforms.FlipVerticallyTransformation.new(true),  	# Local
		HBEditorTransforms.FlipHorizontallyTransformation.new(true),    # Local
		HBEditorTransforms.ArcInterpolationTransform.new(1, 1),     	# Clockwise, inside
		HBEditorTransforms.ArcInterpolationTransform.new(-1, 1),    	# Counter-clockwise, inside
		HBEditorTransforms.ArcInterpolationTransform.new(1, -1),    	# Clockwise, outside
		HBEditorTransforms.ArcInterpolationTransform.new(-1, -1),   	# Counter-clockwise, outside
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_RELATIVE_CENTER),
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_RELATIVE_LEFT),
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_RELATIVE_RIGHT),
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_ABSOLUTE),
		HBEditorTransforms.MakeCircleTransform.new(1), 					# Last used circle transform
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_RELATIVE_CENTER), # Last used rotation transform
		HBEditorTransforms.ArrangeTransformation.new(),
	]
	
	for i in range(autoarrange_shortcuts.size()):
		add_shortcut(autoarrange_shortcuts[i], "_apply_arrange_shortcut", [i])
	add_shortcut("editor_arrange_center", "_apply_center_arrange")
	
	for item in autoarrange_menu_modes:
		arrange_mode_option_button.add_item(item.name)
	
	add_shortcut("editor_circle_size_bigger", "increase_circle_size", [], true)
	add_shortcut("editor_circle_size_smaller", "decrease_circle_size", [], true)
	
	arrange_menu.connect("angle_changed", Callable(self, "_update_slope_info"))
	
	arrange_pad.hover_changed.connect(self._menu_arrange_button_hovered)
	arrange_pad.button.mouse_exited.connect(self._menu_arrange_button_mouse_exited)
	
	for i in range(4):
		circle_size_slider.connect("value_changed", Callable(transforms[i], "set_epr"))
	circle_size_slider.connect("value_changed", Callable(self, "preview_size"))
	circle_size_slider.connect("drag_started", Callable(self, "_toggle_dragging_size_slider"))
	circle_size_slider.connect("drag_ended", Callable(self, "_toggle_dragging_size_slider"))
	circle_size_slider.connect("drag_ended", Callable(self, "hide_transform"))
	circle_size_slider.share(circle_size_spinbox)
	
	for i in range(4):
		circle_size_spinbox.connect("value_changed", Callable(transforms[i], "set_epr"))
	circle_size_spinbox.connect("value_changed", Callable(self, "_set_circle_size"))
	
	rotation_angle_slider.connect("value_changed", Callable(self, "_set_rotation_angle"))
	rotation_angle_slider.connect("value_changed", Callable(self, "preview_angle"))
	rotation_angle_slider.connect("drag_started", Callable(self, "_toggle_dragging_angle_slider"))
	rotation_angle_slider.connect("drag_ended", Callable(self, "_toggle_dragging_angle_slider"))
	rotation_angle_slider.connect("drag_ended", Callable(self, "hide_transform"))
	rotation_angle_slider.share(rotation_angle_spinbox)
	
	rotation_angle_spinbox.connect("value_changed", Callable(self, "_set_rotation_angle"))
	
	remove_child(arrange_menu)

func set_editor(p_editor):
	super.set_editor(p_editor)
	
	arrange_menu.set_editor(p_editor)
	editor.game_preview.add_child(arrange_menu)
	editor.game_preview.clip_contents = true

var arranging := false
var selected_ring := "inner"
func _input(event: InputEvent):
	super._input(event)
	
	var selected = get_selected()
	
	if shortcuts_blocked():
		return
	
	if event.is_action_pressed("editor_show_arrange_menu"):
		if selected.size() >= 2 and editor.game_preview.get_global_rect().has_point(get_global_mouse_position()):
			arranging = true
			arrange_menu.show()
			var old_angle_translation := Vector2.ZERO
			
			if UserSettings.user_settings.editor_save_arrange_angle:
				var old_distance
				match selected_ring:
					"inner":
						old_distance = 32
					"middle":
						old_distance = 55
					"outer":
						old_distance = 80
				
				old_angle_translation = Vector2(old_distance, 0).rotated(last_angle)
				
				arrange_menu.menu_rotation = last_angle
				
				preview_arrange(last_angle, false, false)
			
			arrange_menu.set_global_position(get_global_mouse_position() - Vector2(120, 120) - old_angle_translation)
	elif event.is_action_released("editor_show_arrange_menu") and arranging:
		arranging = false
		arrange_menu.hide()
		
		var mouse_pos := get_global_mouse_position() - Vector2(120, 120)
		var mouse_distance := mouse_pos.distance_to(arrange_menu.position)
		
		selected_ring = "inner"
		if mouse_distance > 70:
			selected_ring = "outer"
		elif mouse_distance > 44:
			selected_ring = "middle"
		
		apply_transform(18)

func user_settings_changed():
	var mode_idx = 0
	for mode in autoarrange_menu_modes:
		if mode.mode == UserSettings.user_settings.editor_arrange_menu_mode:
			break
		else:
			mode_idx += 1
	
	arrange_mode_option_button.select(mode_idx)
	arrange_menu_mode_selected(mode_idx)
	
	arrange_angle_spinbox.set_value_no_signal(UserSettings.user_settings.editor_arrange_menu_angle)
	arrange_diagonal_x_spinbox.set_value_no_signal(UserSettings.user_settings.editor_arrange_menu_diagonal_step.x)
	arrange_diagonal_y_spinbox.set_value_no_signal(UserSettings.user_settings.editor_arrange_menu_diagonal_step.y)
	arrange_vstep_spinbox.set_value_no_signal(UserSettings.user_settings.editor_arrange_menu_vstep)
	
	autoangle_checkbox.button_pressed = UserSettings.user_settings.editor_auto_angle
	
	circle_size_spinbox.value = UserSettings.user_settings.editor_circle_size
	
	transforms[0].separation = UserSettings.user_settings.editor_circle_separation
	transforms[1].separation = UserSettings.user_settings.editor_circle_separation
	transforms[2].separation = UserSettings.user_settings.editor_circle_separation
	transforms[3].separation = UserSettings.user_settings.editor_circle_separation
	transforms[16].separation = UserSettings.user_settings.editor_circle_separation

func update_shortcuts():
	super.update_shortcuts()
	
	var arrange_event_list = InputMap.action_get_events("editor_show_arrange_menu")
	var arrange_ev = arrange_event_list[0] if arrange_event_list else null
	
	if arrange_ev:
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.show()
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.text = \
			"Hold " + get_event_text(arrange_ev) + " for quick placing."
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.tooltip_text = \
			"The arrange wheel helps you place notes quickly.\n" + \
			"Hold Shift for reverse arranging.\n" + \
			"Hold Control to toggle automatic angles.\n" + \
			"Shortcut: " + get_event_text(arrange_ev)
	else:
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.hide()
	
	var size_up_event_list = InputMap.action_get_events("editor_circle_size_bigger")
	var size_down_event_list = InputMap.action_get_events("editor_circle_size_smaller")
	var size_up_ev = size_up_event_list[0] if size_up_event_list else null
	var size_down_ev = size_down_event_list[0] if size_down_event_list else null
	
	$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2.tooltip_text = "Amount of 8th notes required for \na full revolution."
	$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2.tooltip_text += "\nShortcut (increase): " + get_event_text(size_up_ev)
	$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2.tooltip_text += "\nShortcut (decrease): " + get_event_text(size_down_ev)

func apply_transform(id: int):
	hide_transform()
	super.apply_transform(id)
	
	 # Set last used circle transform
	if id in [0, 1, 2, 3]:
		transforms[16] = transforms[id]
	
	# Set last used rotation transform
	if id in [12, 13, 14, 15]:
		transforms[17] = transforms[id]

func arrange_menu_mode_selected(idx: int):
	standard_mode_options.hide()
	diagonal_mode_options.hide()
	fake_slope_mode_options.hide()
	
	var new_mode = autoarrange_menu_modes[idx]
	new_mode.options.show()
	
	UserSettings.user_settings.editor_arrange_menu_mode = new_mode.mode
	UserSettings.save_user_settings()

func set_arrange_parameters(angle, reverse: bool, toggle_autoangle: bool, mode_info = null):
	self.transforms[18].angle = angle
	self.transforms[18].reverse = reverse
	self.transforms[18].toggle_autoangle = toggle_autoangle
	self.transforms[18].mode_info = mode_info if mode_info else arrange_menu.mode_info

func set_arrange_shortcut_parameters(direction: int):
	var angle = UserSettings.user_settings.editor_arrange_menu_angle
	
	var mode_info = {
		"mode": UserSettings.user_settings.editor_arrange_menu_mode,
		"diagonal_step": UserSettings.user_settings.editor_arrange_menu_diagonal_step,
		"vertical_step": UserSettings.user_settings.editor_arrange_menu_vstep,
	}
	
	if direction % 2:
		if direction > 3:
			angle = -angle 
		
		if direction in [3, 5]:
			angle = -angle
			angle += 180
		
		set_arrange_parameters(deg_to_rad(angle), reverse_arrange_checkbox.button_pressed, false, mode_info)
	else:
		set_arrange_parameters(direction * deg_to_rad(90) / 2.0, reverse_arrange_checkbox.button_pressed, false, mode_info)

# Arranges the selected notes in the playarea by a certain distance
func arrange_selected_notes_by_time(angle, reverse: bool, toggle_autoangle: bool, mode_info = null):
	set_arrange_parameters(angle, reverse, toggle_autoangle, mode_info)
	
	apply_transform(18)

func preview_arrange(angle, reverse: bool, toggle_autoangle: bool, mode_info = null):
	set_arrange_parameters(angle, reverse, toggle_autoangle, mode_info)
	
	show_transform(18)

func _apply_arrange_shortcut(direction: int):
	set_arrange_shortcut_parameters(direction)
	
	apply_transform(18)

func _apply_center_arrange():
	arrange_selected_notes_by_time(null, reverse_arrange_checkbox.button_pressed, false) 


var direction_map = [
	5, 6, 7,
	4, 8, 0,
	3, 2, 1,
]
func _menu_arrange_button_pressed(pad_direction: int):
	var arrange_direction: int = direction_map[pad_direction]
	
	if arrange_direction == 8:
		_apply_center_arrange()
	else:
		_apply_arrange_shortcut(arrange_direction)

func _menu_arrange_button_hovered(pad_direction: int):
	var arrange_direction: int = direction_map[pad_direction]
	
	if arrange_direction == 8:
		set_arrange_parameters(null, reverse_arrange_checkbox.button_pressed, false)
	else:
		set_arrange_shortcut_parameters(arrange_direction)
	
	show_transform(18)

func _menu_arrange_button_mouse_exited():
	hide_transform()


func _update_slope_info(angle: float, reverse: bool, toggle_autoangle: bool):
	last_angle = fmod(angle + 2*PI, 2*PI)
	
	preview_arrange(angle, reverse, toggle_autoangle)

func _on_arrange_angle_spinbox_value_changed(value: float) -> void:
	UserSettings.user_settings.editor_arrange_menu_angle = fmod(abs(value), 90.0)
	arrange_angle_spinbox.set_value_no_signal(UserSettings.user_settings.editor_arrange_menu_angle)
	
	UserSettings.save_user_settings()

func _on_arrange_diagonal_step_spinbox_value_changed(_value: float) -> void:
	UserSettings.user_settings.editor_arrange_menu_diagonal_step.x = arrange_diagonal_x_spinbox.value
	UserSettings.user_settings.editor_arrange_menu_diagonal_step.y = arrange_diagonal_y_spinbox.value
	
	UserSettings.save_user_settings()

func _on_arrange_vstep_spinbox_value_changed(_value: float) -> void:
	UserSettings.user_settings.editor_arrange_menu_vstep = arrange_vstep_spinbox.value
	
	UserSettings.save_user_settings()

func _on_auto_angle_check_box_toggled(value: bool) -> void:
	UserSettings.user_settings.editor_auto_angle = value
	
	UserSettings.save_user_settings()


func _set_circle_size(value: int):
	UserSettings.user_settings.editor_circle_size = value
	UserSettings.save_user_settings()

func increase_circle_size():
	circle_size_spinbox.value += 1

func decrease_circle_size():
	circle_size_spinbox.value -= 1

var dragging_size_slider := false
# Having a catchall arg is stupid but we need it for drag_ended pokeKMS
func _toggle_dragging_size_slider(catchall = null):
	dragging_size_slider = not dragging_size_slider

func preview_size(value: int):
	if dragging_size_slider:
		transforms[16].set_epr(value)
		show_transform(16)


func _set_rotation_angle(new_value: float):
	for i in range(12, 16):
		transforms[i].rotation = -new_value 	# Center

var dragging_angle_slider := false
# Having a catchall arg is stupid but we need it for drag_ended pokeKMS
func _toggle_dragging_angle_slider(catchall = null):
	dragging_angle_slider = not dragging_angle_slider

func preview_angle(value: float):
	if dragging_angle_slider:
		transforms[17].rotation = -value
		
		show_transform(17)
