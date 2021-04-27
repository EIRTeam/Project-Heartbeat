extends HBHovereableButton

onready var date_label = get_node("MarginContainer/VBoxContainer/DateLabel")
onready var title_label = get_node("MarginContainer/VBoxContainer/TitleLabel")

onready var margin_container := get_node("MarginContainer") as MarginContainer

var url

func reset_size():
	var min_height = margin_container.get_combined_minimum_size().y
	rect_min_size.y = min_height
	rect_size.y = min_height

func _ready():
	connect("resized", self, "call_deferred", ["reset_size"])
	connect("pressed", self, "_on_pressed")
func _on_pressed():
	OS.shell_open(url)
