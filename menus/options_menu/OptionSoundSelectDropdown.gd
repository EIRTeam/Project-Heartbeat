extends Panel

@onready var SOUND_SELECT_BUTTON = get_node("Button")

signal selected_sound_changed(sound_path)
@onready var pack_container = get_node("MarginContainer/Control/VBoxContainer")
@onready var scroll_container = get_node("MarginContainer/Control")
var sound_name

func get_button():
	var butt = SOUND_SELECT_BUTTON.duplicate()
	butt.show()
	return butt

func _ready():
	
	var default_button = get_button()
	default_button.text = tr("Default")
	default_button.connect("pressed", Callable(self, "_on_sound_selected").bind("default"))
	pack_container.add_child(default_button)
	default_button.set_meta("sound_name", "default")
	var dir = DirAccess.open(UserSettings.CUSTOM_SOUND_PATH)
	if DirAccess.get_open_error() == OK:
		dir.list_dir_begin() # TODOGODOT4 fill missing arguments https://github.com/godotengine/godot/pull/40547
		var dir_name = dir.get_next()

		
		
		while dir_name != "":
			if not dir.current_is_dir() and not dir_name.begins_with(".") and dir_name.ends_with(".wav"):
				var sound_select_button = get_button()
				pack_container.add_child(sound_select_button)
				sound_select_button.text = dir_name
				sound_select_button.connect("pressed", Callable(self, "_on_sound_selected").bind(dir_name))
				sound_select_button.set_meta("sound_name", dir_name)
			dir_name = dir.get_next()
	connect("focus_entered", Callable(self, "_on_focus_grabbed"))
	scroll_container.connect("focus_exited", Callable(self, "hide"))
func _on_focus_grabbed():
	scroll_container.grab_focus()
	for button in pack_container.get_children():
		if button.get_meta("sound_name") == UserSettings.user_settings.custom_sounds[sound_name]:
			scroll_container.select_item(button.get_index())
func _on_sound_selected(selected_sound):
	emit_signal("selected_sound_changed", selected_sound)

func _on_Control_back():
	_on_sound_selected(null)
