extends Spatial

onready var song_menu = get_node("ViewportLeft/MainMenuLeft/SongListMenu/VBoxContainer/ScrollContainer")
onready var main_menu_music_player = get_node("ViewportRight/MusicPlayer/MainMenuMusicPlayer")
func _ready():
	song_menu.connect("song_hovered", main_menu_music_player, "play_song")
