class_name HBLobby

enum CHAT_MESSAGE_TYPE {
	INVALID = 0,
	MESSAGE = 1,
	TYPING = 2,
	INVITE_GAME = 3,
	EMOTE = 4,
	LEFT_CONVERSATION = 6,
	ENTERED = 7,
	WAS_KICKED = 8,
	WAS_BANNED = 9,
	DISCONNECTED = 10,
	HISTORICAL_CHAT = 11,
	LINK_BLOCKED = 14
}

enum LOBBY_ENTER_RESPONSE {
	SUCCESS = 1,
	DOESNT_EXIST = 2,
	NOT_ALLOWED = 3,
	FULL = 4,
	UNEXPECTED = 5,
	BANNED = 6,
	LIMITED = 7,
	COMMUNITY_BAN = 9,
	BLOCKED_YOU = 10,
	BLOCKED_USER = 11,
}

enum LOBBY_TYPE {
	PRIVATE = 0,
	FRIENDS_ONLY = 1,
	PUBLIC = 2
}

enum LOBBY_CREATION_RESULT {
	OK = 0,
	NO_CONNECTION = 1,
	TIMEOUT = 2,
	FAIL = 3,
	ACCESS_DENIED = 4,
	LIMIT_EXCEEDED = 5
}

enum LOBBY_CHAT_UPDATE_STATUS {
	JOINED = 1,
	LEFT = 2,
	DISCONNECTED = 4,
	KICKED  = 8,
	BANNED = 16
}

signal lobby_joined(response)
signal lobby_chat_message(member, message, type)
signal lobby_data_updated()
signal lobby_user_data_updated(user)
signal lobby_created(result)
signal lobby_chat_update(changed, making_change, state)
signal lobby_left

var _lobby_id

var lobby_name := "How can my little lobby can be this cute" setget set_lobby_name, get_lobby_name
var connected := false
var member_count: int = 1 setget ,get_lobby_member_count
var max_members: int = 10 setget ,get_max_lobby_members
var song_name: String = "melody" setget set_song_name,get_song_name
var song_id: String = "melody" setget set_song_id,get_song_id
var song_difficulty: String = "extreme" setget set_song_difficulty,get_song_difficulty
var members: Dictionary = {}
var lobby_owner: HBLobbyMember setget ,get_lobby_owner
var pure = true # pure lobbies perform checks

func set_lobby_name(val):
	lobby_name = val
func set_song_name(val):
	song_name = val
func set_song_id(val):
	song_id = val
func set_song_difficulty(val):
	song_difficulty = val
func get_lobby_name():
	return lobby_name
func get_lobby_member_count():
	return member_count
func get_max_lobby_members():
	return max_members
	
func get_song_name():
	return song_name
	
func get_song_id():
	return song_id

func get_song_difficulty():
	return song_difficulty

func get_song() -> HBSong:
	if get_song_id() in SongLoader.songs:
		return SongLoader.songs[get_song_id()]
	else:
		return null

func _init(lobby_id):
	self._lobby_id = lobby_id
		
func get_lobby_owner():
	return members.values()[0]
func join_lobby():
	pass

func send_chat_message(message: String):
	pass
	
func create_lobby():
	pass
	
func leave_lobby():
	pass

func is_owned_by_local_user():
	pass

