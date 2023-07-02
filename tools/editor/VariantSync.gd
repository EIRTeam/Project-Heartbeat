extends Window

@onready var base_editor = $VBoxContainer/PHAudioStreamEditor
@onready var variant_editor = $VBoxContainer/PHAudioStreamEditor2

signal position_offset_changed(new_offset)

var variant_offset = 0.0: set = set_variant_offset
var variant_size = 90.0: set = set_variant_size

var _drag_offset_start = 0.0
var _drag_x_start = 0.0
var dragging = false

func _ready():
	variant_editor.share_red_line(base_editor)

func set_variant_size(val):
	variant_size = val
	base_editor.variant_size = val
	variant_editor.variant_size = val

func set_variant_offset(val):
	variant_offset = val
	base_editor.variant_offset = val
	variant_editor.variant_offset = val

func _input(event):
	if not visible:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_drag_x_start = base_editor.get_local_mouse_position().x
			_drag_offset_start = variant_offset
			get_viewport().set_input_as_handled()
			if event.is_pressed():
				dragging = true
			else:
				dragging = false
	if dragging:
		if event is InputEventMouseMotion:
			var new_offset = _drag_x_start - base_editor.get_local_mouse_position().x
			new_offset = new_offset / base_editor.size.x
			new_offset *= base_editor.size
			new_offset = _drag_offset_start + new_offset
			set_variant_offset(max(new_offset, 0))
			
			get_viewport().set_input_as_handled()

var stream_base: AudioStream
var stream_variant: AudioStream

func show_comparison(song: HBSong, variant: HBSongVariantData, offset: float):
	stream_base = song.get_audio_stream()
	base_editor.max_t = stream_base.get_length()
	base_editor.stream_editor.edit(stream_base)
#	base_editor.start_point = song.start_time / 1000.0
#	base_editor.end_point = (song.start_time / 1000.0) + 10.0
#	base_editor.start = song.start_time / 1000.0
	stream_variant = HBUtils.load_ogg(YoutubeDL.get_audio_path(YoutubeDL.get_video_id(variant.variant_url)))
	var ogg = stream_variant
	variant_editor.stream_editor.edit(ogg)
	variant_editor.max_t = stream_variant.get_length()
	base_editor.start = 0.0
	variant_editor.start = -offset
	$VBoxContainer/SpinBox.value = 0.0
	set_variant_offset(0.0)
	popup_centered_ratio(0.5)
			

func _on_SpinBox_value_changed(value):
	set_variant_size((1.0 - (value / 100.0)) * 100.0)

func _on_WindowDialog_confirmed():
	emit_signal("position_offset_changed", -variant_editor.start)

func _on_WindowDialog_about_to_show():
	set_process_input(true)
func _on_WindowDialog_popup_hide():
	set_process_input(false)
	
