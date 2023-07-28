extends Node3D

signal resumed
signal quitted
signal restarted
signal song_settings
@onready var resume_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/ResumeButton")
@onready var restart_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/RestartButton")
@onready var song_settings_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/SongSettingsButton")
@onready var quit_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/QuitButton")
@onready var restart_popup = get_node("RestartPopup")
@onready var quit_popup = get_node("QuitPopup")
@onready var pause_menu_list = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer")
func _ready():
	resume_button.connect("pressed", Callable(self, "resume"))
	restart_button.connect("pressed", Callable(restart_popup, "popup_centered_ratio").bind(0.35))
	quit_button.connect("pressed", Callable(quit_popup, "popup_centered_ratio").bind(0.35))
	quit_popup.connect("cancel", Callable(pause_menu_list, "grab_focus"))
	restart_popup.connect("cancel", Callable(pause_menu_list, "grab_focus"))
	song_settings_button.connect("pressed", Callable(self, "show_song_settings"))

func resume():
	emit_signal("resumed")
func show_song_settings():
	emit_signal("song_settings")
func restart():
	emit_signal("restarted")
func quit():
	emit_signal("quitted")


func _on_area_left_input_event(camera, event, position, normal, shape_idx):
	print(event)
