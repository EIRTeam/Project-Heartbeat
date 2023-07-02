extends HBHovereableButton

@onready var date_label = get_node("MarginContainer/VBoxContainer/DateLabel")
@onready var title_label = get_node("MarginContainer/VBoxContainer/TitleLabel")

@onready var margin_container := get_node("MarginContainer") as MarginContainer

var url

func _do_reset_size():
	var min_height = margin_container.get_combined_minimum_size().y
	custom_minimum_size.y = min_height
	size.y = min_height

func _ready():
	super._ready()
	connect("resized", Callable(self, "call_deferred").bind("_do_reset_size"))
	connect("pressed", Callable(self, "_on_pressed"))
func _on_pressed():
	OS.shell_open(url)
