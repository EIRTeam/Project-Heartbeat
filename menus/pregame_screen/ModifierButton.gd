extends HBHovereableButton

signal edit_modifier
signal remove_modifier

var selected_button = null

@onready var buttons_container = get_node("VBoxContainer")
@onready var settings_button = get_node("VBoxContainer/SettingsButton")
@onready var remove_button = get_node("VBoxContainer/RemoveButton")
func _gui_input(event):
	buttons_container._gui_input(event)

func hover():
	super.hover()
	buttons_container._on_focus_entered()

func _ready():
	super._ready()
	settings_button.connect("pressed", Callable(self, "_on_settings_button_pressed"))
	connect("pressed", Callable(self, "_on_pressed"))
	remove_button.connect("pressed", Callable(self, "_on_remove_button_pressed"))
	
func _on_settings_button_pressed():
	emit_signal("edit_modifier")
	
func _on_remove_button_pressed():
	emit_signal("remove_modifier")
	
	
func _on_pressed():
	buttons_container.selected_button.emit_signal("pressed")
func stop_hover():
	super.stop_hover()
	if buttons_container:
		buttons_container._on_focus_exited()

func remove_settings_button():
	buttons_container.remove_child(settings_button)
	buttons_container.selected_button = null
	settings_button.queue_free()
