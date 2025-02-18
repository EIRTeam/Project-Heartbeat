extends HBHovereableButton

@onready var date_label = get_node("MarginContainer/VBoxContainer/DateLabel")
@onready var title_label = get_node("MarginContainer/VBoxContainer/TitleLabel")

@onready var margin_container := get_node("MarginContainer") as MarginContainer

var url

func _get_minimum_size() -> Vector2:
	return margin_container.get_combined_minimum_size()

func _on_minimum_size_changed():
	custom_minimum_size = margin_container.get_combined_minimum_size()

func _ready():
	super._ready()
	margin_container.minimum_size_changed.connect(_on_minimum_size_changed)
	connect("pressed", Callable(self, "_on_pressed"))
func _on_pressed():
	OS.shell_open(url)
