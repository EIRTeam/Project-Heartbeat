extends HBEditorModule

@onready var arrange_menu := get_node("ArrangeMenu")
@onready var arrange_angle_spinbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/HBEditorSpinBox")
@onready var reverse_arrange_checkbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/CheckBox")
@onready var circle_size_slider := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2/HSlider")
@onready var circle_size_spinbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2/HBoxContainer/HBEditorSpinBox")
@onready var rotation_angle_slider := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer5/HSlider")
@onready var rotation_angle_spinbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer5/HBoxContainer/HBEditorSpinBox")

var autoarrange_shortcuts = [
	"editor_arrange_r",
	"editor_arrange_dr",
	"editor_arrange_d",
	"editor_arrange_dl",
	"editor_arrange_l",
	"editor_arrange_ul",
	"editor_arrange_u",
	"editor_arrange_ur",
]

var size_testing_circle_transform := HBEditorTransforms.MakeCircleTransform.new(1)

func _ready():
	super._ready()
	transforms = [
		HBEditorTransforms.MakeCircleTransform.new(1),
		HBEditorTransforms.MakeCircleTransform.new(-1),
		HBEditorTransforms.MakeCircleTransform.new(1, true),
		HBEditorTransforms.MakeCircleTransform.new(-1, true),
		HBEditorTransforms.FlipVerticallyTransformation.new(),
		HBEditorTransforms.FlipHorizontallyTransformation.new(),
		HBEditorTransforms.FlipVerticallyTransformation.new(true),
		HBEditorTransforms.FlipHorizontallyTransformation.new(true),
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_RELATIVE_CENTER),
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_RELATIVE_LEFT),
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_RELATIVE_RIGHT),
		HBEditorTransforms.RotateTransformation.new(HBEditorTransforms.RotateTransformation.PIVOT_MODE_ABSOLUTE),
	]
	
	for i in range(autoarrange_shortcuts.size()):
		add_shortcut(autoarrange_shortcuts[i], "_apply_arrange_shortcut", [i])
	add_shortcut("editor_arrange_center", "_apply_center_arrange")
	
	add_shortcut("editor_circle_size_bigger", "increase_circle_size", [], true)
	add_shortcut("editor_circle_size_smaller", "decrease_circle_size", [], true)
	
	arrange_menu.connect("angle_changed", Callable(self, "arrange_selected_notes_by_time"))
	arrange_menu.connect("angle_changed", Callable(self, "_update_slope_info"))
	
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
	var selected = get_selected()
	
	if shortcuts_blocked():
		return
	
	if event.is_action_pressed("editor_show_arrange_menu"):
		if selected.size() >= 2 and editor.game_preview.get_global_rect().has_point(get_global_mouse_position()):
			selected.sort_custom(Callable(self, "_order_items"))
			
			original_notes.clear()
			for item in selected:
				original_notes.append(item.data.clone())
			
			original_notes.sort_custom(Callable(self, "_order_timing_points"))
			
			arranging = true
			arrange_menu.popup()
			var old_angle_translation := Vector2.ZERO
			
			if UserSettings.user_settings.editor_save_arrange_angle:
				var old_angle = arrange_angle_spinbox.value
				if old_angle > 180:
					old_angle = old_angle - 360
				
				old_angle = deg_to_rad(-old_angle)
				
				var old_distance
				match selected_ring:
					"inner":
						old_distance = 32
					"middle":
						old_distance = 55
					"outer":
						old_distance = 80
				
				old_angle_translation = Vector2(old_distance, 0).rotated(old_angle)
				
				arrange_menu.rotation = old_angle
				
				arrange_selected_notes_by_time(old_angle, false, false)
			
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
		
		commit_arrange()

func user_settings_changed():
	circle_size_spinbox.value = UserSettings.user_settings.editor_circle_size
	transforms[0].separation = UserSettings.user_settings.editor_circle_separation
	transforms[1].separation = UserSettings.user_settings.editor_circle_separation
	transforms[2].separation = UserSettings.user_settings.editor_circle_separation
	transforms[3].separation = UserSettings.user_settings.editor_circle_separation
	size_testing_circle_transform.separation = UserSettings.user_settings.editor_circle_separation

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


func _update_slope_info(angle: float, reverse: bool, _autoangle_toggle: bool):
	arrange_angle_spinbox.value = rad_to_deg(fmod(angle + 2*PI, 2*PI))
	reverse_arrange_checkbox.button_pressed = reverse

func _apply_arrange():
	original_notes.clear()
	for item in get_selected():
		original_notes.append(item.data.clone())
	
	original_notes.sort_custom(Callable(self, "_order_timing_points"))
	
	arrange_selected_notes_by_time(deg_to_rad(-arrange_angle_spinbox.value), reverse_arrange_checkbox.pressed, false)
	
	commit_arrange()

func _apply_arrange_shortcut(direction: int):
	original_notes.clear()
	for item in get_selected():
		original_notes.append(item.data.clone())
	
	original_notes.sort_custom(Callable(self, "_order_timing_points"))
	
	var angle = 45
	
	if direction % 2:
		if direction > 3:
			angle = -angle 
		
		if direction in [3, 5]:
			angle = -angle
			angle += 180
		
		arrange_selected_notes_by_time(deg_to_rad(angle), reverse_arrange_checkbox.pressed, false)
	else:
		arrange_selected_notes_by_time(direction * deg_to_rad(90) / 2.0, reverse_arrange_checkbox.pressed, false)
	
	commit_arrange()

func _apply_center_arrange():
	original_notes.clear()
	for item in get_selected():
		original_notes.append(item.data.clone())
	
	original_notes.sort_custom(Callable(self, "_order_timing_points"))
	
	arrange_selected_notes_by_time(null, reverse_arrange_checkbox.pressed, false)
	
	commit_arrange()

static func _order_items(a: EditorTimelineItemNote, b: EditorTimelineItemNote):
	return a.data.time < b.data.time

static func _order_timing_points(a: HBTimingPoint, b: HBTimingPoint):
	return a.time < b.time

# Arranges the selected notes in the playarea by a certain distances
var original_notes: Array
func arrange_selected_notes_by_time(angle, reverse: bool, toggle_autoangle: bool):
	var selected = get_selected()
	selected.sort_custom(Callable(self, "_order_items"))
	if selected.size() < 2:
		return
	
	var separation: Vector2 = Vector2.ZERO
	var slide_separation: Vector2 = Vector2.ZERO
	var eight_separation = UserSettings.user_settings.editor_arrange_separation
	
	if angle != null:
		separation.x = eight_separation * cos(angle)
		separation.y = eight_separation * sin(angle)
		
		slide_separation.x = 32 * cos(angle)
		slide_separation.y = 32 * sin(angle)
		
		if not angle in [0, PI/2, PI, -PI/2]:
			var quadrant = 0
			if angle > -PI and angle < -PI/2:
				quadrant = 1
			elif angle > PI/2 and angle < PI:
				quadrant = 2
			elif angle > 0 and angle < PI:
				quadrant = 3
			
			match arrange_menu.mode_info.mode:
				HBUserSettings.EDITOR_ARRANGE_MODES.DISTANCE:
					separation.x = arrange_menu.mode_info.diagonal_step.x
					separation.y = -arrange_menu.mode_info.diagonal_step.y
					
					if quadrant in [1, 2]:
						separation.x = -separation.x
					if quadrant in [2, 3]:
						separation.y = -separation.y
				HBUserSettings.EDITOR_ARRANGE_MODES.FAKE_SLOPE:
					separation.x = eight_separation
					separation.y = -arrange_menu.mode_info.vertical_step
					
					if quadrant in [1, 2]:
						separation.x = -separation.x
					if quadrant in [2, 3]:
						separation.y = -separation.y
		
		if reverse:
			separation = -separation
			slide_separation = -slide_separation
	
	# Never remove these, it makes the mikuphile mad
	var direction = Vector2.ZERO
	if abs(direction.x) > 0 and abs(direction.y) > 0:
		pass
	
	var pos_compensation: Vector2
	var time_compensation := 0
	var slide_index := 0
	
	var anchor = original_notes[0]
	if reverse:
		anchor = original_notes[-1]
		selected.reverse()
	
	pos_compensation = anchor.position
	time_compensation = anchor.time
	
	if anchor is HBSustainNote and reverse:
		time_compensation = anchor.end_time
	
	for selected_item in selected:
		if selected_item.data is HBBaseNote:
			# Real snapping hours
			var eight_diff = get_time_as_eight(selected_item.data.time) - \
							 get_time_as_eight(time_compensation)
			
			if reverse and selected_item.data is HBSustainNote:
				eight_diff = get_time_as_eight(selected_item.data.end_time) - \
							 get_time_as_eight(time_compensation)
			
			if selected_item.data is HBNoteData and selected_item.data.is_slide_note():
				if slide_index > 1:
					eight_diff = max(1, eight_diff)
				
				slide_index = 1
			elif selected_item.data is HBNoteData and slide_index and selected_item.data.is_slide_hold_piece():
				slide_index += 1
			elif slide_index:
				if slide_index > 1:
					eight_diff = max(1, eight_diff)
				
				slide_index = 0
			
			var new_pos = pos_compensation + (separation * eight_diff)
			
			if selected_item.data is HBNoteData and selected_item.data.is_slide_hold_piece() and slide_index:
				if slide_index == 2:
					new_pos = pos_compensation + separation / 2
				else:
					new_pos = pos_compensation + slide_separation
			
			change_selected_property_single_item(selected_item, "position", new_pos)
			
			pos_compensation = new_pos
			if selected_item.data is HBSustainNote:
				if reverse:
					time_compensation = selected_item.data.time
				else:
					time_compensation = selected_item.data.end_time
			else:
				time_compensation = selected_item.data.time
	
	for i in range(selected.size()):
		var selected_item = selected[i]
		var note = selected_item.data
		
		if note is HBBaseNote:
			var autoangle_enabled := UserSettings.user_settings.editor_auto_angle
			if toggle_autoangle:
				autoangle_enabled = not autoangle_enabled
			
			var _i = i
			if reverse:
				_i = -i - 1
			
			var new_angle_params = [original_notes[_i].entry_angle, original_notes[_i].oscillation_frequency]
			
			if autoangle_enabled:
				new_angle_params = autoangle(note, selected[0].data.position, angle, reverse)
			
			change_selected_property_single_item(selected_item, "entry_angle", new_angle_params[0])
			change_selected_property_single_item(selected_item, "oscillation_frequency", new_angle_params[1])
	
	timing_points_params_changed()

func autoangle(note: HBBaseNote, new_pos: Vector2, arrange_angle, reverse: bool):
	if arrange_angle != null:
		var new_angle: float
		var oscillation_frequency = abs(note.oscillation_frequency)
		
		# Normalize the arrange angle to be between 0 and 2PI
		arrange_angle = fmod(fmod(arrange_angle, 2*PI) + 2*PI, 2*PI)
		
		# Get the quadrant and rotated quadrant
		var quadrant = int(arrange_angle / (PI/2.0))
		var rotated_quadrant = int((arrange_angle + PI/4.0) / (PI/2.0)) % 4
		
		new_angle = arrange_angle + PI/2.0
		
		if rotated_quadrant in [1, 3]:
			new_angle += PI if quadrant in [0, 1] else 0.0
			
			var left_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(0, 0), Vector2(0, 1080))
			var right_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(1920, 0), Vector2(1920, 1080))
			
			var left_distance = new_pos.distance_to(left_point)
			var right_distance = new_pos.distance_to(right_point)
			
			# Point towards closest side
			new_angle += PI if right_distance > left_distance else 0.0
		else:
			new_angle += PI if quadrant in [1, 2] else 0.0
			
			var top_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(0, 0), Vector2(1920, 0))
			var bottom_point = Geometry2D.get_closest_point_to_segment(new_pos, Vector2(0, 1080), Vector2(1920, 1080))
			
			var top_distance = new_pos.distance_to(top_point)
			var bottom_distance = new_pos.distance_to(bottom_point)
			
			# Point towards furthest side
			new_angle += PI if top_distance > bottom_distance else 0.0
		
		var positive_quadrants = []
		
		if new_pos.x > 960:
			positive_quadrants.append(3)
		else:
			positive_quadrants.append(1)
		
		if new_pos.y > 540:
			positive_quadrants.append(2)
		else:
			positive_quadrants.append(0)
		
		var is_negative_quadrant = not rotated_quadrant in positive_quadrants
		var is_odd = fposmod(oscillation_frequency, 2.0) != 0
		
		if is_negative_quadrant:
			oscillation_frequency = -oscillation_frequency
		if is_odd:
			oscillation_frequency = -oscillation_frequency
		
		oscillation_frequency *= sign(note.oscillation_amplitude)
		if reverse:
			oscillation_frequency = -oscillation_frequency
		
		return [fmod(rad_to_deg(new_angle), 360.0), oscillation_frequency]
	else:
		return [note.entry_angle, note.oscillation_frequency]

func commit_arrange():
	undo_redo.create_action("Arrange selected notes by time")
	commit_selected_property_change("position", false)
	commit_selected_property_change("entry_angle", false)
	commit_selected_property_change("oscillation_frequency", false)
	undo_redo.commit_action()
	
	original_notes.clear()


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
		transforms[0].set_epr(value)
		show_transform(0)


func _set_rotation_angle(new_value: float):
	for i in range(8, 12):
		transforms[i].rotation = -new_value 	# Center

var dragging_angle_slider := false
# Having a catchall arg is stupid but we need it for drag_ended pokeKMS
func _toggle_dragging_angle_slider(catchall = null):
	dragging_angle_slider = not dragging_angle_slider

func preview_angle(value: float):
	if dragging_angle_slider:
		show_transform(8)
