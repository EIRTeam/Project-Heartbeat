extends HBoxContainer

var layer_visible: bool setget set_layer_visible
var layer_name: String setget set_layer_name 
signal layer_visibility_changed(value)

onready var visibility_button = get_node("VisibilityButton")
onready var layer_name_label = get_node("LayerNameLabel")

const HIDDEN_ICON = preload("res://tools/icons/icon_GUI_visibility_hidden.svg")
const VISIBLE_ICON = preload("res://tools/icons/icon_GUI_visibility_visible.svg")

func _ready():
	visibility_button.connect("toggled", self, "_on_VisibilityButton_toggled")

func set_layer_visible(value):
	layer_visible = value
	visibility_button.pressed = value
	if layer_visible:
		visibility_button.icon = VISIBLE_ICON
	else:
		visibility_button.icon = HIDDEN_ICON

func _on_VisibilityButton_toggled(value):
	emit_signal("layer_visibility_changed", value)
	set_layer_visible(value)

func set_layer_name(value):
	layer_name = value
	layer_name_label.text = value
