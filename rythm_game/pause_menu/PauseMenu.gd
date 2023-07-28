extends Control

var current_song: HBSong

signal resumed
signal restarted
signal quit

@onready var song_settings_editor = get_node("PerSongSettingsEditor")
@onready var list_container = get_node("SubViewportContainer/SubViewport/Node3D/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer")
@onready var song_preview = get_node("SubViewportContainer/SubViewport/Node3D/ViewportRight/Panel")
@onready var quit_popup = get_node("SubViewportContainer/SubViewport/Node3D/QuitPopup")
func _ready():
	get_viewport().connect("size_changed", Callable(self, "_on_viewport_size_changed"))
	_on_viewport_size_changed()
	hide()
	connect("resumed", Callable(self, "_on_resumed"))
	song_settings_editor.connect("back", Callable(list_container, "grab_focus"))
	
	connect("resized", Callable(self, "_on_resized"))

func _on_resized():
	$BackBufferCopy.rect = get_rect()
	$BackBufferCopy2.rect = get_rect()
	print(get_rect())
	
func _on_resumed():
	$SubViewportContainer/SubViewport/Node3D/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.hide()
	$SubViewportContainer/SubViewport/Node3D/RestartPopup.hide()
	$SubViewportContainer/SubViewport/Node3D/QuitPopup.hide()
	song_settings_editor.hide_editor()
func _on_viewport_size_changed():
	$SubViewportContainer/SubViewport.size = get_window().size

#func _input(event):
#	$Viewport.input(event)

func show_pause(song_id):
	current_song = SongLoader.songs[song_id]
	show()
	song_preview.select_song(current_song)
	$SubViewportContainer/SubViewport/Node3D/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.show()
	$SubViewportContainer/SubViewport/Node3D/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.grab_focus()
	UserSettings.enable_menu_fps_limits = true


func _on_quit():
	emit_signal("quit")


func _on_restart():
	emit_signal("restarted")
	hide()
	
func resume():
	emit_signal("resumed")
	
	
func disable_restart():
	$SubViewportContainer/SubViewport/Node3D/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/RestartButton.queue_free()


func _on_song_settings_open():
	song_settings_editor.ingame = true
	song_settings_editor.current_song = current_song
	song_settings_editor.show_editor()
