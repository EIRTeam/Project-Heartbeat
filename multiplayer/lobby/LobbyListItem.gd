extends HBHovereableButton

var lobby_name: String = "I can't believe my little lobby can be this cute": set = set_lobby_name
var lobby_max_members: int = 10: set = set_lobby_max_members
var lobby_members: int = 1: set = set_lobby_members

var lobby: HBLobby

@onready var lobby_title_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/LobbyTitleLabel")
@onready var lobby_member_count_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/HBoxContainer2/MemberCountLabel")
@onready var song_status_icon = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/HBoxContainer/TextureRect2")
@onready var song_name_label = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer3/HBoxContainer/SongNameLabel")
const NOTE_ERR_ICON = preload("res://graphics/icons/icon_note_ERR.svg")
const NOTE_OK_ICON = preload("res://graphics/icons/icon_note_OK.svg")

func set_lobby_name(val):
	lobby_name = val
	lobby_title_label.text = lobby_name
func set_lobby_members(val):
	lobby_members = val
	lobby_member_count_label.text = "%d/%d" % [lobby_members, lobby_max_members]
	
func set_lobby_max_members(val):
	lobby_max_members = val
	lobby_member_count_label.text = "%d/%d" % [lobby_members, lobby_max_members]


func set_lobby(_lobby: HBLobby):
	lobby = _lobby
	if lobby.get_song() == null or not lobby.get_song().has_audio():
		song_status_icon.texture = NOTE_ERR_ICON
	else:
		song_status_icon.texture = NOTE_OK_ICON
	
	song_name_label.text = lobby.get_song_name()
	set_lobby_name(lobby.lobby_name)
	set_lobby_members(lobby.member_count)
	set_lobby_max_members(lobby.max_members)
