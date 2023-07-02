extends PanelContainer

class_name AnimatedTextureFrameEditor

@onready var frame_rect: TextureRect = get_node("%FrameRect")
@onready var button_up: Button = get_node("%ButtonUp")
@onready var button_down: Button = get_node("%ButtonDown")
@onready var duration_spinbox: SpinBox = get_node("%DurationSpinbox")
@onready var frame_label: Label = get_node("%FrameLabel")
@onready var filename_label: Label = get_node("%FilenameLabel")

var current_animated_texture: AnimatedTexture
var current_frame_number: int

signal move_up_pressed
signal move_down_pressed

var undo_redo: UndoRedo

func edit(animated_texture: AnimatedTexture, frame_number: int):
	current_animated_texture = animated_texture
	current_frame_number = frame_number
	frame_rect.texture = animated_texture.get_frame_texture(frame_number)
	duration_spinbox.set_block_signals(true)
	duration_spinbox.value = animated_texture.get_frame_duration(frame_number)
	duration_spinbox.set_block_signals(false)
	frame_label.text = str(frame_number)
	filename_label.text = frame_rect.texture.get_meta("animated_texture_path").get_file()

func _ready():
	duration_spinbox.connect("value_changed", Callable(self, "_on_duration_value_changed"))
	button_up.connect("pressed", Callable(self, "emit_signal").bind("move_up_pressed"))
	button_down.connect("pressed", Callable(self, "emit_signal").bind("move_down_pressed"))

func _on_duration_value_changed(new_value: float):
	if undo_redo:
		undo_redo.create_action("Set frame delay for frame %d" % [current_frame_number])
		
		var old_value := current_animated_texture.get_frame_duration(current_frame_number)
		
		undo_redo.add_do_method(current_animated_texture.set_frame_delay.bind(current_frame_number, new_value))
		undo_redo.add_do_method(duration_spinbox.set_block_signals.bind(true))
		undo_redo.add_do_method(duration_spinbox.set_value.bind(new_value))
		undo_redo.add_do_method(duration_spinbox.set_block_signals.bind(false))
		undo_redo.add_do_method(duration_spinbox.get_line_edit().release_focus)
		
		undo_redo.add_undo_method(current_animated_texture.set_frame_duration.bind(current_frame_number, old_value))
		undo_redo.add_undo_method(duration_spinbox.set_block_signals.bind(true))
		undo_redo.add_undo_method(duration_spinbox.set_value.bind(old_value))
		undo_redo.add_undo_method(duration_spinbox.set_block_signals.bind(false))
		undo_redo.add_undo_method(duration_spinbox.get_line_edit().release_focus)
		
		undo_redo.commit_action()
	else:
		current_animated_texture.set_frame_delay(current_frame_number, new_value)
