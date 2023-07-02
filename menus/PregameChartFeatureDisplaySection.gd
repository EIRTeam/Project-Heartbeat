extends Control

var title: String
var texture: Texture2D
var description: String
var actions: Array
var actions_plus_one: Array
var disable_axis_direction_display: bool = false

@onready var title_label = get_node("MarginContainer/VBoxContainer/Label2")
@onready var texture_rect = get_node("MarginContainer/VBoxContainer/TextureRect")
@onready var description_label = get_node("MarginContainer/VBoxContainer/Label")
@onready var vbox_container = get_node("MarginContainer/VBoxContainer")
const ACTION_SCENE = preload("res://third_party/joypad_support/Prompts/PromptInputAction.tscn")

func _ready():
	title_label.text = title
	texture_rect.texture = texture
	description_label.text = description
	var action_scenes = []
	for action in actions:
		var action_scene = ACTION_SCENE.instantiate()
		action_scene.input_action = action
		action_scene.disable_axis_direction_display = disable_axis_direction_display
		action_scenes.append(action_scene)
	for action in actions_plus_one:
		var action_scene = ACTION_SCENE.instantiate()
		action_scene.input_action = action
		action_scene.skip_inputs = 1
		action_scene.disable_axis_direction_display = disable_axis_direction_display
		action_scenes.append(action_scene)
	var curr_container: HBoxContainer
	for i in range(action_scenes.size()):
		if fmod(i, 4) == 0:
			curr_container = HBoxContainer.new()
			curr_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			curr_container.size_flags_stretch_ratio = 0.2
			curr_container.alignment = BoxContainer.ALIGNMENT_CENTER
			vbox_container.add_child(curr_container)
		curr_container.add_child(action_scenes[i])
