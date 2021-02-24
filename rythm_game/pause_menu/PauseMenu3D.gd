extends Spatial

signal resumed
signal quit
signal restart
signal song_settings
onready var resume_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/ResumeButton")
onready var restart_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/RestartButton")
onready var song_settings_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/SongSettingsButton")
onready var quit_button = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/QuitButton")
onready var restart_popup = get_node("RestartPopup")
onready var quit_popup = get_node("QuitPopup")
onready var pause_menu_list = get_node("ViewportLeft/MarginContainer/VBoxContainer/HBListContainer")
func _ready():
	resume_button.connect("pressed", self, "resume")
	restart_button.connect("pressed", restart_popup, "popup_centered_ratio", [0.35])
	quit_button.connect("pressed", quit_popup, "popup_centered_ratio", [0.35])
	quit_popup.connect("cancel", pause_menu_list, "grab_focus")
	restart_popup.connect("cancel", pause_menu_list, "grab_focus")
	song_settings_button.connect("pressed", self, "show_song_settings")

func resume():
	emit_signal("resumed")
func show_song_settings():
	emit_signal("song_settings")
func restart():
	emit_signal("restart")
func quit():
	emit_signal("quit")
