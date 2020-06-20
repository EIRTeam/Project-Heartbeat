extends Panel

var current_song: HBSong

signal resumed
signal restarted
signal quit

onready var song_settings_editor = get_node("PerSongSettingsEditor")
onready var list_container = get_node("ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer")
onready var song_preview = get_node("ViewportContainer/Viewport/Spatial/ViewportRight/Panel")
func _ready():
	get_viewport().connect("size_changed", self, "_on_viewport_size_changed")
	_on_viewport_size_changed()
	hide()
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.hide()
	connect("resumed", self, "_on_resumed")
	song_settings_editor.connect("back", list_container, "grab_focus")
	
	if OS.get_current_video_driver() == OS.VIDEO_DRIVER_GLES2:
		var tex = $TextureRect.texture as ViewportTexture
		tex.flags = tex.FLAG_FILTER
	
func _on_resumed():
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.hide()
	$ViewportContainer/Viewport/Spatial/RestartPopup.hide()
	$ViewportContainer/Viewport/Spatial/QuitPopup.hide()
func _on_viewport_size_changed():
	$ViewportContainer/Viewport.size = OS.window_size

#func _input(event):
#	$Viewport.input(event)

func show_pause(song_id):
	current_song = SongLoader.songs[song_id]
	show()
	song_preview.select_song(current_song)
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.show()
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer.grab_focus()


func _on_quit():
	emit_signal("quit")


func _on_restart():
	emit_signal("restarted")
	hide()
func disable_restart():
	$ViewportContainer/Viewport/Spatial/ViewportLeft/MarginContainer/VBoxContainer/HBListContainer/RestartButton.queue_free()


func _on_song_settings_open():
	song_settings_editor.current_song = current_song
	song_settings_editor.show_editor()
