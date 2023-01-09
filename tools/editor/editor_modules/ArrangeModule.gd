extends HBEditorModule

onready var arrange_menu := get_node("ArrangeMenu")
onready var arrange_angle_spinbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/HBEditorSpinBox")
onready var reverse_arrange_checkbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/CheckBox")
onready var circle_size_slider := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2/HSlider")
onready var circle_size_spinbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2/HBoxContainer/HBEditorSpinBox")
onready var rotation_angle_slider := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer5/HSlider")
onready var rotation_angle_spinbox := get_node("MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer5/HBoxContainer/HBEditorSpinBox")

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
	add_shortcut("editor_arrange_center", "arrange_selected_notes_by_time", [null, false, false])
	
	add_shortcut("editor_circle_size_bigger", "increase_circle_size", [], true)
	add_shortcut("editor_circle_size_smaller", "decrease_circle_size", [], true)
	
	arrange_menu.connect("angle_changed", self, "arrange_selected_notes_by_time", [true])
	arrange_menu.connect("angle_changed", self, "_update_slope_info")
	
	for i in range(4):
		circle_size_slider.connect("value_changed", transforms[i], "set_epr")
	circle_size_slider.connect("value_changed", self, "preview_size")
	circle_size_slider.connect("drag_started", self, "_toggle_dragging_size_slider")
	circle_size_slider.connect("drag_ended", self, "_toggle_dragging_size_slider")
	circle_size_slider.connect("drag_ended", self, "hide_transform")
	circle_size_slider.share(circle_size_spinbox)
	
	for i in range(4):
		circle_size_spinbox.connect("value_changed", transforms[i], "set_epr")
	circle_size_spinbox.connect("value_changed", self, "_set_circle_size")
	
	rotation_angle_slider.connect("value_changed", self, "_set_rotation_angle")
	rotation_angle_slider.connect("value_changed", self, "preview_angle")
	rotation_angle_slider.connect("drag_started", self, "_toggle_dragging_angle_slider")
	rotation_angle_slider.connect("drag_ended", self, "_toggle_dragging_angle_slider")
	rotation_angle_slider.connect("drag_ended", self, "hide_transform")
	rotation_angle_slider.share(rotation_angle_spinbox)
	
	rotation_angle_spinbox.connect("value_changed", self, "_set_rotation_angle")
	
	remove_child(arrange_menu)

func set_editor(p_editor):
	.set_editor(p_editor)
	
	editor.game_preview.add_child(arrange_menu)
	editor.game_preview.rect_clip_content = true

var arranging := false
func _input(event: InputEvent):
	var selected = get_selected()
	
	if shortcuts_blocked():
		return
	
	if event.is_action_pressed("editor_show_arrange_menu"):
		if selected and editor.game_preview.get_global_rect().has_point(get_global_mouse_position()):
			arranging = true
			arrange_menu.popup()
			arrange_menu.set_global_position(get_global_mouse_position() - Vector2(120, 120))
			
			selected.sort_custom(self, "_order_items")
			
			original_notes.clear()
			for item in selected:
				original_notes.append(item.data.clone())
	elif event.is_action_released("editor_show_arrange_menu") and arranging:
		arranging = false
		arrange_menu.hide()
		
		undo_redo.create_action("Arrange selected notes by time")
		commit_selected_property_change("position", false)
		commit_selected_property_change("entry_angle", false)
		commit_selected_property_change("oscillation_frequency", false)
		undo_redo.commit_action()
		
		original_notes.clear()

func user_settings_changed():
	circle_size_spinbox.value = UserSettings.user_settings.editor_circle_size
	transforms[0].separation = UserSettings.user_settings.editor_circle_separation
	transforms[1].separation = UserSettings.user_settings.editor_circle_separation
	transforms[2].separation = UserSettings.user_settings.editor_circle_separation
	transforms[3].separation = UserSettings.user_settings.editor_circle_separation
	size_testing_circle_transform.separation = UserSettings.user_settings.editor_circle_separation

func update_shortcuts():
	.update_shortcuts()
	
	var arrange_event_list = InputMap.get_action_list("editor_show_arrange_menu")
	var arrange_ev = arrange_event_list[0] if arrange_event_list else null
	
	if arrange_ev:
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.show()
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.text = \
			"Hold " + get_event_text(arrange_ev) + " for quick placing."
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.hint_tooltip = \
			"The arrange wheel helps you place notes quickly.\n" + \
			"Hold Shift for reverse arranging.\n" + \
			"Hold Control to toggle automatic angles.\n" + \
			"Shortcut: " + get_event_text(arrange_ev)
	else:
		$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer/VBoxContainer/Label.hide()
	
	var size_up_event_list = InputMap.get_action_list("editor_circle_size_bigger")
	var size_down_event_list = InputMap.get_action_list("editor_circle_size_smaller")
	var size_up_ev = size_up_event_list[0] if size_up_event_list else null
	var size_down_ev = size_down_event_list[0] if size_down_event_list else null
	
	$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2.hint_tooltip = "Amount of 8th notes required for \na full revolution."
	$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2.hint_tooltip += "\nShortcut (increase): " + get_event_text(size_up_ev)
	$MarginContainer/ScrollContainer/VBoxContainer/HBoxContainer2.hint_tooltip += "\nShortcut (decrease): " + get_event_text(size_down_ev)


func _update_slope_info(angle: float, reverse: bool, _autoangle_toggle: bool):
	arrange_angle_spinbox.value = rad2deg(fmod(-angle + 2*PI, 2*PI))
	reverse_arrange_checkbox.pressed = reverse

func _apply_arrange():
	arrange_selected_notes_by_time(deg2rad(-arrange_angle_spinbox.value), reverse_arrange_checkbox.pressed, false)

func _apply_arrange_shortcut(direction: int):
	var angle = 45
	
	if direction % 2:
		if direction > 3:
			angle = -angle 

		if direction in [3, 5]:
			angle = -angle
			angle += 180

		arrange_selected_notes_by_time(deg2rad(angle), reverse_arrange_checkbox.pressed, false)
	else:
		arrange_selected_notes_by_time(direction * deg2rad(90) / 2.0, reverse_arrange_checkbox.pressed, false)


func _order_items(a, b):
	return a.data.time < b.data.time

# Arranges the selected notes in the playarea by a certain distances
var original_notes: Array
func arrange_selected_notes_by_time(angle, reverse: bool, toggle_autoangle: bool, preview_only: bool = false):
	if reverse:
		angle += PI
	
	var selected = get_selected()
	selected.sort_custom(self, "_order_items")
	if not selected:
		return
	
	if not preview_only:
		original_notes = []
		for item in selected:
			original_notes.append(item.data)
		undo_redo.create_action("Arrange selected notes by time")
	
	var separation: Vector2 = Vector2.ZERO
	var slide_separation: Vector2 = Vector2.ZERO
	var eight_separation = UserSettings.user_settings.editor_arrange_separation
	
	if angle != null:
		separation.x = eight_separation * cos(angle)
		separation.y = eight_separation * sin(angle)
		slide_separation.x = 32 * cos(angle)
		slide_separation.y = 32 * sin(angle)
	
	# Never remove these, it makes the mikuphile mad
	var direction = Vector2.ZERO
	if abs(direction.x) > 0 and abs(direction.y) > 0:
		pass
	
	var pos_compensation: Vector2
	var time_compensation := 0
	var slide_index := 0
	var eight_map := get_normalized_timing_map()
	
	var anchor = original_notes[0]
	if reverse:
		anchor = original_notes[-1]
	
	pos_compensation = anchor.position
	time_compensation = anchor.time
	
	for selected_item in selected:
		if selected_item.data is HBBaseNote:
			# Real snapping hours
			var eight_diff = linear_bound(eight_map, selected_item.data.time) - \
							 linear_bound(eight_map, time_compensation)
			
			if selected_item.data is HBNoteData and selected_item.data.is_slide_note():
				if slide_index > 1:
					eight_diff = 1
				
				slide_index = 1
			elif selected_item.data is HBNoteData and slide_index and selected_item.data.is_slide_hold_piece():
				slide_index += 1
			elif slide_index:
				slide_index = 0
				
				eight_diff = 1
			
			var new_pos = pos_compensation + (separation * eight_diff)
			
			if selected_item.data is HBNoteData and selected_item.data.is_slide_hold_piece() and slide_index:
				if slide_index == 2:
					new_pos = pos_compensation + separation / 2
				else:
					new_pos = pos_compensation + slide_separation
			
			if not preview_only:
				undo_redo.add_do_property(selected_item.data, "position", new_pos)
				undo_redo.add_do_property(selected_item.data, "pos_modified", true)
				undo_redo.add_undo_property(selected_item.data, "position", selected_item.data.position)
				undo_redo.add_undo_property(selected_item.data, "pos_modified", selected_item.data.pos_modified)
				
				undo_redo.add_do_method(selected_item, "update_widget_data")
				undo_redo.add_undo_method(selected_item, "update_widget_data")
			else:
				change_selected_property_single_item(selected_item, "position", new_pos)
			
			pos_compensation = new_pos
			if selected_item.data is HBSustainNote:
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
			
			var new_angle_params = [original_notes[i].entry_angle, original_notes[i].oscillation_frequency]
			if autoangle_enabled:
				new_angle_params = autoangle(note, selected[0].data.position, angle)
			
			if not preview_only:
				undo_redo.add_do_property(note, "entry_angle", new_angle_params[0])
				undo_redo.add_undo_property(note, "entry_angle", note.entry_angle)
				undo_redo.add_do_property(note, "oscillation_frequency", new_angle_params[1])
				undo_redo.add_undo_property(note, "oscillation_frequency", note.oscillation_frequency)
				
				undo_redo.add_do_method(selected_item, "update_widget_data")
				undo_redo.add_undo_method(selected_item, "update_widget_data")
			else:
				change_selected_property_single_item(selected_item, "entry_angle", new_angle_params[0])
				change_selected_property_single_item(selected_item, "oscillation_frequency", new_angle_params[1])
	
	if not preview_only:
		undo_redo.add_do_method(self, "timing_points_changed")
		undo_redo.add_undo_method(self, "timing_points_changed")
		undo_redo.add_do_method(self, "sync_inspector_values")
		undo_redo.add_undo_method(self, "sync_inspector_values")
		
		undo_redo.commit_action()
		
		original_notes.clear()
	else:
		timing_points_params_changed()

func autoangle(note: HBBaseNote, new_pos: Vector2, arrange_angle):
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
			
			var left_point = Geometry.get_closest_point_to_segment_2d(new_pos, Vector2(0, 0), Vector2(0, 1080))
			var right_point = Geometry.get_closest_point_to_segment_2d(new_pos, Vector2(1920, 0), Vector2(1920, 1080))
			
			var left_distance = new_pos.distance_to(left_point)
			var right_distance = new_pos.distance_to(right_point)
			
			# Point towards closest side
			new_angle += PI if right_distance > left_distance else 0.0
		else:
			new_angle += PI if quadrant in [1, 2] else 0.0
			
			var top_point = Geometry.get_closest_point_to_segment_2d(new_pos, Vector2(0, 0), Vector2(1920, 0))
			var bottom_point = Geometry.get_closest_point_to_segment_2d(new_pos, Vector2(0, 1080), Vector2(1920, 1080))
			
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
		
		if not rotated_quadrant in positive_quadrants:
			oscillation_frequency = -oscillation_frequency
		
		oscillation_frequency *= sign(note.oscillation_amplitude)
		
		return [fmod(rad2deg(new_angle), 360.0), oscillation_frequency]
	else:
		return [note.entry_angle, note.oscillation_frequency]


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
