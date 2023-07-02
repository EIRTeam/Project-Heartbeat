extends Control

class_name AnimatedTextureEditor

const FRAME_EDITOR_SCENE = preload("res://tools/resource_pack_editor/skin_editor/AnimatedTextureFrameEditor.tscn")

@onready var frame_container: VBoxContainer = get_node("%FrameContainer")
@onready var preview_texture_rect: TextureRect = get_node("%PreviewTextureRect")

var current_animated_texture: AnimatedTexture

var undo_redo := UndoRedo.new()

func edit(animated_texture: AnimatedTexture):
	preview_texture_rect.texture = animated_texture
	for child in frame_container.get_children():
		child.queue_free()
	current_animated_texture = animated_texture
	undo_redo.clear_history()
	populate_frame_list()

func populate_frame_list():
	for frame_i in range(current_animated_texture.frames):
		var scene := FRAME_EDITOR_SCENE.instantiate()
		frame_container.add_child(scene)
		scene.edit(current_animated_texture, frame_i)
		scene.undo_redo = undo_redo
		scene.connect("move_up_pressed", Callable(self, "move_frame_up").bind(frame_i))
		scene.connect("move_down_pressed", Callable(self, "move_frame_down").bind(frame_i))

func get_frame_editor(frame_i: int) -> AnimatedTextureFrameEditor:
	assert(frame_i < frame_container.get_child_count())
	assert(frame_container.get_child(frame_i) is AnimatedTextureFrameEditor)
	return frame_container.get_child(frame_i) as AnimatedTextureFrameEditor

func move_frame_up(frame_i: int):
	if frame_i > 0:
		undo_redo.create_action("Move frame %d up", frame_i)
		undo_redo.add_do_method(self.swap_frames.bind(frame_i, frame_i-1))
		undo_redo.add_undo_method(self.swap_frames.bind(frame_i, frame_i-1))
		undo_redo.commit_action()

func move_frame_down(frame_i: int):
	if frame_i < frame_container.get_child_count()-1:
		undo_redo.create_action("Move frame %d down", frame_i)
		undo_redo.add_do_method(self.swap_frames.bind(frame_i, frame_i+1))
		undo_redo.add_undo_method(self.swap_frames.bind(frame_i, frame_i+1))
		undo_redo.commit_action()

func swap_frames(first_frame_i: int, second_frame_i: int):
	assert(first_frame_i < frame_container.get_child_count())
	assert(second_frame_i < frame_container.get_child_count())
	var first_texture := current_animated_texture.get_frame_texture(first_frame_i)
	var first_duration := current_animated_texture.get_frame_duration(first_frame_i)
	var second_texture := current_animated_texture.get_frame_texture(second_frame_i)
	var second_duration := current_animated_texture.get_frame_duration(second_frame_i)
	
	var first_editor := get_frame_editor(first_frame_i)
	var second_editor := get_frame_editor(second_frame_i)
	
	current_animated_texture.set_frame_texture(first_frame_i, second_texture)
	current_animated_texture.set_frame_texture(second_frame_i, first_texture)
	current_animated_texture.set_frame_duration(first_frame_i, second_duration)
	current_animated_texture.set_frame_duration(second_frame_i, first_duration)
	
	first_editor.edit(current_animated_texture, first_frame_i)
	second_editor.edit(current_animated_texture, second_frame_i)

func _unhandled_input(event):
	if event.is_action_pressed("gui_undo"):
		undo_redo.undo()
	elif event.is_action("gui_redo"):
		undo_redo.redo()
	
