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
	OK = 1,
	NO_CONNECTION = 3,
	TIMEOUT = 16,
	FAIL = 2,
	ACCESS_DENIED = 16,
	LIMIT_EXCEEDED = 25
}

enum LOBBY_CHAT_UPDATE_STATUS {
	JOINED = 1,
	LEFT = 2,
	DISCONNECTED = 4,
	KICKED  = 8,
	BANNED = 16
}

enum PACKET_SEND_TYPE {
	UNREALIABLE = 0,
	UNREALIABLE_NO_DELAY = 1,
	RELIABLE = 2,
	RELIABLE_BUFFERED = 3
}

enum PACKET_TYPE {
	HANDSHAKE,
	LOADED,
	START_GAME,
	NOTE_HIT,
	HEART_POWER_ACTIVATED,
	GAME_DONE
}

# when we joined a lobby
# warning-ignore:unused_signal
signal lobby_joined(response)
# reception of chat message
# warning-ignore:unused_signal
signal lobby_chat_message(member, message, type)
# lobby data changed
# warning-ignore:unused_signal
signal lobby_data_updated()
# warning-ignore:unused_signal
signal lobby_user_data_updated(user)
# warning-ignore:unused_signal
signal lobby_created(result)
# warning-ignore:unused_signal
signal lobby_left
# warning-ignore:unused_signal
signal lobby_chat_update(changed, making_change, state)
# warning-ignore:unused_signal
signal member_left(member)
# warning-ignore:unused_signal
signal host_changed()

# warning-ignore:unused_signal
signal lobby_loading_start # sent by authority
# warning-ignore:unused_signal
signal game_member_loading_finished(member)
# warning-ignore:unused_signal
signal game_start # sent by authority
# warning-ignore:unused_signal
signal game_note_hit(member, score, rating)
# warning-ignore:unused_signal
signal game_done(results, game_info) # sent when we realise that all other members have finished
# warning-ignore:unused_signal
signal user_song_availability_update(user, song_id, available)
# warning-ignore:unused_signal
signal check_songs_request_received(song_id)
# warning-ignore:unused_signal
signal reported_ugc_song_downloaded(user, ugc_id)

var _lobby_id

var lobby_name := "How can my little lobby can be this cute": get = get_lobby_name, set = set_lobby_name
var connected := false
var member_count: int = 1: get = get_lobby_member_count
var max_members: int = 10: get = get_max_lobby_members
var song_name: String = "imademo_2012": get = get_song_name, set = set_song_name
var song_id: String = "imademo_2012": get = get_song_id, set = set_song_id
var song_difficulty: String = "extreme": get = get_song_difficulty, set = set_song_difficulty
var members: Dictionary = {}
var lobby_owner: HBServiceMember: get = get_lobby_owner
var pure = true # pure lobbies perform checks
var game_results = {}
var game_info: HBGameInfo = HBGameInfo.new()

func set_lobby_name(val):
	lobby_name = val
func set_song_name(val):
	song_name = val
func set_song_id(val):
	game_info.song_id = val
func set_song_difficulty(val):
	game_info.difficulty = val
func get_lobby_name():
	return lobby_name
func get_lobby_member_count():
	return member_count
func get_max_lobby_members():
	return max_members
	
func get_song_name():
	return song_name
	
func get_song_id():
	return game_info.song_id

func get_song_difficulty():
	return game_info.difficulty

func get_song() -> HBSong:
	var sid = get_song_id()
	if sid in SongLoader.songs:
		return SongLoader.songs[sid]
	else:
		return null

func send_game_info_update():
	pass
func _init(lobby_id):
	self._lobby_id = lobby_id
	game_info.song_id = "imademo_2012"
	game_info.difficulty = "extreme"
		
func get_lobby_owner() -> HBServiceMember:
	return members.values()[0]
func set_lobby_owner(val):
	pass
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

func start_session():
	pass
func send_packet(data, send_type, channel):
	pass
# Used to let authority know we've loaded the current song and we are ready to play
func notify_game_loaded():
	pass

# Called by authority to start the game
func start_game():
	pass

# Lets everyone else know that our score (and last rating) has changed
func send_note_hit_update(score, rating):
	pass
	
func notify_game_finished(result: HBResult):
	pass

func check_if_lobby_members_have_song():
	pass
