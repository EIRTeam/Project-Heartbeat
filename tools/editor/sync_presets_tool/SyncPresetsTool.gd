extends MarginContainer

var static_sync_presets = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().static_presets
# presets presented as two buttons side by side
var static_sync_presets_dual = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().dual_presets
var dynamic_sync_presets = preload("res://tools/editor/sync_presets_tool/SyncPresets.gd").new().dynamic_presets

onready var sync_button_container = get_node("ScrollContainer/SyncButtonContainer")

signal show_transform(transform_data)
signal hide_transform()
signal apply_transform(transform_data)
signal set_size(size)

class circle_transformation:
	extends EditorTransformation
	
	var _editor: HBEditor
	
	# Circle Size
	var _size: float
	# 1 for c, -1 for cc
	var dir: int
	
	func _init(editor: HBEditor, direction: int):
		_editor = editor
		dir = direction
		_size = 2.5
	
	func set_size(size: float):
		_size = size
	
	func transform_notes(notes: Array):
		var bpm = _editor.get_bpm()
		# Amplitude = Spacing * Circle Size
		var amp = _editor.time_arrange_hv_spinbox.value * _size
		# Every 4 quarter time is a full Circle on 240000 frq.
		var frq = 180000 * _size
		# get_center_for_notes() drifts for this use case. hmmm.
		var center = Vector2(960, 540)
		
		var sustain_compensation = 0
		
		var transformation_result = {}
		
		for n in notes:
			# Idk ask neo
			var t = n.time - sustain_compensation
			var z = t * TAU
			var x = amp * cos(z * dir * bpm / frq) + center.x
			var y = amp * sin(z * dir * bpm / frq) + center.y
			
			# Compensate for sustain notes
			if n is HBSustainNote:
				sustain_compensation += n.end_time - n.time
			
			# Calculate the angle and oscillation
			var a = atan2(y - center.y, x - center.x) 
			a *= (180 / PI) 
			a += 180
			var o = abs(n.oscillation_frequency) * dir
			
			# Populate the transformation matrix
			transformation_result[n] = {
				"position": Vector2(x, y),
				"entry_angle": a,
				"oscillation_frequency": o
			}
			
		return transformation_result

func make_button(preset_name: String, preset_list, dynamic_preset = false) -> Button:
	var button = Button.new()
	button.text = preset_name
	var transformation = EditorTransformationTemplate.new()
	transformation.dynamic = dynamic_preset
	transformation.template = preset_list[preset_name]
	button.connect("mouse_entered", self, "_show_preset_preview", [transformation])
	button.connect("pressed", self, "_apply_transform", [transformation])
	button.connect("mouse_exited", self, "_hide_preset_preview")

	return button
	
func add_button_row(button, button2):
	var hbox_container = HBoxContainer.new()
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button2.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox_container.add_child(button)
	hbox_container.add_child(button2)
	sync_button_container.add_child(hbox_container)

var clockwise_circle_transformation: circle_transformation
var counterclockwise_circle_transformation: circle_transformation

func _ready():
	for preset_name in static_sync_presets:
		sync_button_container.add_child(make_button(preset_name, static_sync_presets))
	if static_sync_presets_dual.size() % 2 != 0:
		assert("Dual static sync presets should be two per row")
	for i in range(0, static_sync_presets_dual.size(), 2):
		var preset_name = static_sync_presets_dual.keys()[i]
		var preset_name2 = static_sync_presets_dual.keys()[i+1]
		var button = make_button(preset_name, static_sync_presets_dual)
		var button2 = make_button(preset_name2, static_sync_presets_dual)
		add_button_row(button, button2)
	
	var dynamic_preset_label = Label.new()
	dynamic_preset_label.text = "Dynapresets™"
	sync_button_container.add_child(dynamic_preset_label)
	
	if dynamic_sync_presets.size() % 2 != 0:
		assert("Dynamic sync presets should be two per row")
		
	for i in range(0, dynamic_sync_presets.size(), 2):
		var preset_name = dynamic_sync_presets.keys()[i]
		var preset_name2 = dynamic_sync_presets.keys()[i+1]
		var button = make_button(preset_name, dynamic_sync_presets, true)
		var button2 = make_button(preset_name2, dynamic_sync_presets, true)
		add_button_row(button, button2)
	
	clockwise_circle_transformation = circle_transformation.new($"/root/Editor", 1)
	counterclockwise_circle_transformation = circle_transformation.new($"/root/Editor", -1)
	
	var circle_label = Label.new()
	circle_label.text = "Circle presets"
	circle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var circle_size_label = Label.new()
	circle_size_label.text = "Circle size: "
	circle_size_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var size_spinbox = SpinBox.new()
	size_spinbox.editable = true
	size_spinbox.min_value = 1
	size_spinbox.max_value = 5
	size_spinbox.value = 2.5
	size_spinbox.connect("value_changed", self, "_set_size")
	
	var size_label_hbox = HBoxContainer.new()
	size_label_hbox.add_child(circle_size_label)
	size_label_hbox.add_child(size_spinbox)
	
	var size_slider = HSlider.new()
	size_slider.min_value = 1
	size_slider.max_value = 5
	size_slider.value = 2.5
	size_slider.tick_count = 9
	size_slider.step = 0.1
	size_slider.ticks_on_borders = true
	size_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	size_slider.connect("mouse_entered", self, "emit_signal", ["show_transform", clockwise_circle_transformation])
	size_slider.connect("mouse_exited", self, "emit_signal", ["hide_transform"])
	
	size_slider.share(size_spinbox)
	
	sync_button_container.add_child(circle_label)
	sync_button_container.add_child(size_label_hbox)
	sync_button_container.add_child(size_slider)
	
	var clockwise_circle_button = Button.new()
	clockwise_circle_button.text = "Clockwise"
	clockwise_circle_button.connect("mouse_entered", self, "_show_preset_preview", [clockwise_circle_transformation])
	clockwise_circle_button.connect("pressed", self, "_apply_transform", [clockwise_circle_transformation])
	clockwise_circle_button.connect("mouse_exited", self, "_hide_preset_preview")
	
	var counterclockwise_circle_button = Button.new()
	counterclockwise_circle_button.text = "Counterclockwise"
	counterclockwise_circle_button.connect("mouse_entered", self, "_show_preset_preview", [counterclockwise_circle_transformation])
	counterclockwise_circle_button.connect("pressed", self, "_apply_transform", [counterclockwise_circle_transformation])
	counterclockwise_circle_button.connect("mouse_exited", self, "_hide_preset_preview")
	
	add_button_row(clockwise_circle_button, counterclockwise_circle_button)
func _show_preset_preview(transformation):
	emit_signal("show_transform", transformation)
func _hide_preset_preview():
	emit_signal("hide_transform")
func _apply_transform(transformation):
	emit_signal("apply_transform", transformation)

func _set_size(value):
	clockwise_circle_transformation.set_size(value)
	counterclockwise_circle_transformation.set_size(value)
	emit_signal("show_transform", clockwise_circle_transformation)
