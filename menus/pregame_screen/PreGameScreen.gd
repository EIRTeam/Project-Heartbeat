extends HBMenu

onready var song_title = get_node("MarginContainer/VBoxContainer/SongTitle")
onready var leaderboard = get_node("MarginContainer/VBoxContainer/HBoxContainer/Panel/Leaderboard")

func _ready():
	song_title.song = SongLoader.songs["imademo_2012"]
	leaderboard.song_id = "imademo_2012"
