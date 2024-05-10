extends HBHovereableButton

var lobby_name: String = "I can't believe my little lobby can be this cute": set = set_lobby_name
var lobby_max_members: int = 10: set = set_lobby_max_members
var lobby_members: int = 1: set = set_lobby_members

var lobby: HBSteamLobby

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


func set_lobby(_lobby: HBSteamLobby):
	lobby = _lobby
	var lobby_data := lobby.get_data(HeartbeatSteamLobby.LOBBY_DATA_KEY)
	if lobby_data.is_empty():
		return
	var data_dict: Dictionary = str_to_var(lobby_data)

	var data := HeartbeatSteamLobbyData.from_dictionary(data_dict)
	if data:
		set_lobby_name(data.lobby_name)
		song_name_label.text = data.song_title
		set_lobby_members(lobby.get_members_count())
		set_lobby_max_members(lobby.max_members)
