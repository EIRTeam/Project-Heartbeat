class_name HeartbeatSteamLobby

signal lobby_disconnected
signal lobby_data_updated(lobby_data: HeartbeatSteamLobbyData)
## Emitted when a text message is received through the chat system
signal chat_message_received(sender: HBSteamFriend, chat_message: String)
## Emitted when a user joins the lobby
signal member_joined(member_meta: MemberMetadata)
## Emitted when a user leaves the lobby, for whatever reason
signal member_left(member_meta: MemberMetadata)
signal member_kicked(member_meta: MemberMetadata)
## Emitted when the local user gets kicked from the lobby
signal kicked
signal download_song_media_request_received
signal game_results_updated
signal begin_loading_game_request_received

const LOBBY_DATA_KEY := "data"
const MEMBER_SONG_AVAILABILITY_DATA_KEY = "song_availability"
const MEMBER_IN_GAME_DATA_KEY = "in_game_data"
const RPC_PREAMBLE: PackedByteArray = [0x2F, 0x72, 0x70, 0x63] # /rpc

## RPC Call types
enum RPCPacketType {
	## Prompt other users to download the song data
	REQUEST_SONG_DATA_DOWNLOAD,
	## Prompt other clients to begin loading the game
	REQUEST_BEGIN_GAME_LOAD,
	## Sent by each member to notify that they've hit a note
	NOTE_HIT_UPDATE,
	## Sent by each member once the game is finished
	GAME_FINISHED,
	## Sent by authority to let every one know someone has been kicked
	KICK_MEMBER,
	PACKET_TYPE_MAX
}

## Changes who can or can't call RPC methods
enum RPCPrivileges {
	## Only the lobby owner can call this method
	FROM_AUTHORITY_ONLY,
	## Anyone can call this method
	FROM_ANYONE
}

## State of song data availability of each client
enum SongAvailabilityStatus {
	## User has all the data needed to start the game
	HAS_DATA,
	## The user doesn't have the song data, but it can be downloaded from the workshop
	NEEDS_UGC_SONG_DOWNLOAD,
	## User has the song, but it needs to download media
	NEEDS_UGC_MEDIA_DOWNLOAD,
	## User doesn't have the song and it can't be downloaded from anywhere
	MISSING_SONG,
	## User doesn't have the song media and it can't be downloaded from anywhere
	MISSING_SONG_MEDIA
}

## State of the game's requirements to start
enum GameStartResponseStatus {
	## Game is ready to begin
	OK,
	## User needs media, see [member HeartbeatSteamLobby.MemberMetadata.song_availability_meta]
	USER_LACKS_MEDIA,
	## Song data is still dirty and awaiting user response
	SONG_AVAILABILITY_METADATA_DIRTY
}

## Contains information on the state of user song data
class MemberSongAvailabilityMetadata:
	signal updated
	var _song_availability_dirty := true
	var song_availability_status: SongAvailabilityStatus
	var song_id: String
	var song_variant: int
	
	func notify_updated():
		updated.emit()
	
	func update_from_dictionary(dict: Dictionary):
		assert("song_availability_status" in dict)
		assert("song_id" in dict)
		assert("song_variant" in dict)
		song_availability_status = dict.get("song_availability_status", 0)
		song_id = dict.get("song_id", "")
		song_variant = dict.get("song_variant", -1)
	
	func to_dictionary() -> Dictionary:
		return {
			"song_availability_status": song_availability_status,
			"song_id": song_id,
			"song_variant": song_variant
		}

enum InGameState {
	LOADING,
	LOADED,
	IN_GAME,
	FINISHED
}

class MemberInGameData:
	signal updated
	
	var state := InGameState.LOADING
	
	func notify_update():
		updated.emit()
	
	func to_dictionary() -> Dictionary:
		return {
			"state": state
		}
		
	func update_from_dictionary(dict: Dictionary):
		assert("state" in dict)
		state = dict.get("state", InGameState.LOADING)

## Per lobby member information
class MemberMetadata:
	signal note_hit_received(last_judgement: HBJudge.JUDGE_RATINGS, score: int)
	signal result_received

	var member: HBSteamFriend
	var song_availability_meta := MemberSongAvailabilityMetadata.new()
	var in_game_data := MemberInGameData.new()
	var result: HBResult

## Response of [method HeartbeatSteamLobby.try_start_game]
class GameStartResponse:
	var status: GameStartResponseStatus

## Internal RPC definition
class RPCPacketInfo:
	var packet_type: RPCPacketType
	var rpc_privileges: RPCPrivileges = RPCPrivileges.FROM_AUTHORITY_ONLY
	var callback: Callable
	
	func _init(_packet_type: RPCPacketType):
		packet_type = _packet_type
	
var rpc_packet_types: Array[RPCPacketInfo]
var lobby_data := HeartbeatSteamLobbyData.new()
var song: HBSong
var steam_lobby: HBSteamLobby
var member_metadata: Array[MemberMetadata]

# Constructors

## Creates a lobby from scratch
static func create_lobby(lobby_type: SteamworksConstants.LobbyType, max_members := 8) -> HeartbeatSteamLobby:
	var lobby := HBSteamLobby.create_lobby(lobby_type, max_members)
	var creation_result := await lobby.lobby_created as int
	if creation_result != SteamworksConstants.RESULT_OK:
		printerr("Error creating lobby! Error code %d" % [creation_result])
		return null
	var ph_lobby := HeartbeatSteamLobby.new(lobby)
	var default_song = SongLoader.songs.values()[0] as HBSong
	ph_lobby.update_lobby_song_data(default_song, -1, default_song.charts.keys()[0])
	ph_lobby.update_lobby_name("%s's lobby" % [Steamworks.user.get_local_user().persona_name])
	ph_lobby.send_lobby_data_update()
	return ph_lobby

## Joins an existing lobby
static func join_lobby(steam_lobby: HBSteamLobby) -> HeartbeatSteamLobby:
	steam_lobby.join_lobby()
	var enter_result := await steam_lobby.lobby_entered as int
	if enter_result != SteamworksConstants.RESULT_OK:
		printerr("Error joining lobby! Error code %d" % [enter_result])
		return null
	var ph_lobby := HeartbeatSteamLobby.new(steam_lobby)
	for member in steam_lobby.get_members():
		ph_lobby._on_lobby_member_data_updated(member)
	return ph_lobby

# Steam callbacks

func _on_lobby_chat_updated(changed: HBSteamFriend, making_change: HBSteamFriend, change: int):
	if changed == Steamworks.user.get_local_user():
		if change & SteamworksConstants.CHAT_MEMBER_STATE_CHANGE_DISCONNECTED:
			lobby_disconnected.emit()
	if change & SteamworksConstants.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		var member_meta := get_member_metadata(changed)
		member_joined.emit(member_meta)
	if change & (SteamworksConstants.CHAT_MEMBER_STATE_CHANGE_LEFT | change & SteamworksConstants.CHAT_MEMBER_STATE_CHANGE_LEFT):
		var member_meta := get_member_metadata(changed)
		member_left.emit(member_meta)
		member_metadata.erase(member_meta)
		
func _on_lobby_data_updated():
	var lobby_data_str := steam_lobby.get_data(LOBBY_DATA_KEY)
	var dict: Dictionary = str_to_var(lobby_data_str)
	if not dict.is_empty():
		var new_lobby_data := HeartbeatSteamLobbyData.from_dictionary(dict)
		
		var song_info_changed := new_lobby_data.song_id != lobby_data.song_id \
			or new_lobby_data.song_ugc_id != lobby_data.song_ugc_id \
			or new_lobby_data.song_variant != lobby_data.song_variant
		
		lobby_data = new_lobby_data
		
		if song_info_changed:
			_update_song_availability_information()
		
		lobby_data_updated.emit(lobby_data)

func _on_lobby_member_data_updated(sender: HBSteamFriend):
	var data_keys := [
		MEMBER_SONG_AVAILABILITY_DATA_KEY,
		MEMBER_IN_GAME_DATA_KEY
	]
	
	var metadata := get_member_metadata(sender)

	for key in data_keys:
		var data_str := steam_lobby.get_member_data(sender, key)
		if data_str.is_empty():
			return
		var data_dict: Dictionary = str_to_var(data_str)
		if data_dict.is_empty():
			return
		match key:
			MEMBER_IN_GAME_DATA_KEY:
				metadata.in_game_data.update_from_dictionary(data_dict)
				metadata.in_game_data.notify_update()
			MEMBER_SONG_AVAILABILITY_DATA_KEY:
				metadata.song_availability_meta.update_from_dictionary(data_dict)
				metadata.song_availability_meta._song_availability_dirty = false
				metadata.song_availability_meta.notify_updated()

func _on_lobby_chat_message_received(sender: HBSteamFriend, type: int, data: PackedByteArray):
	if type != SteamworksConstants.CHAT_ENTRY_TYPE_CHAT_MSG:
		# We don't care about other chat message types
		return
	if data.size() > 7:
		# RPC calls look like this:
		# /rpc <opcode as u8> <arguments as array>
		# 0123 5              7
		const RPC_CALL_OPCODE_POSITION := 5
		const RPC_ARGUMENTS_PAYLOAD_POSITION := 7
		if data.slice(0, 4) == RPC_PREAMBLE:
			var rpc_opcode := data.decode_u8(RPC_CALL_OPCODE_POSITION)
			if rpc_opcode >= RPCPacketType.PACKET_TYPE_MAX or rpc_opcode < 0:
				printerr("Received chat RPC packet with invalid opcode, %d" % [rpc_opcode])
				return
			var packet_type := rpc_packet_types[rpc_opcode]
			if packet_type.rpc_privileges == RPCPrivileges.FROM_AUTHORITY_ONLY and sender != steam_lobby.owner:
				printerr("Tried to execute an authority only RPC call from non-authority user %s %d" % [sender.persona_name, sender.steam_id])
				return
			
			var packet_arguments: Array = bytes_to_var(data.slice(RPC_ARGUMENTS_PAYLOAD_POSITION))
			
			if not packet_type.callback or not packet_type.callback.is_valid():
				printerr("Received packet of type %s but it doesn't have a valid callback!" % [RPCPacketType.find_key(rpc_opcode)])
				return
			packet_type.callback.callv([sender] + packet_arguments)
			return
	# We got a normal chat message, so let's emit it
	chat_message_received.emit(sender, data.get_string_from_utf8())

func _update_song_availability_information():
	var meta := MemberSongAvailabilityMetadata.new()
	meta.song_availability_status = get_song_availability_status(lobby_data.is_song_from_ugc, lobby_data.song_id, lobby_data.song_variant)
	meta.song_id = lobby_data.song_id
	meta.song_variant = lobby_data.song_variant
	steam_lobby.set_member_data(MEMBER_SONG_AVAILABILITY_DATA_KEY, var_to_str(meta.to_dictionary()))

func _on_download_song_media_request_received(sender: HBSteamFriend):
	if steam_lobby.is_owned_by_local_user():
		return
	download_song_media_request_received.emit()
	
func _on_begin_game_load_request_received(sender: HBSteamFriend):
	for member in steam_lobby.get_members():
		get_member_metadata(member).result = null
	begin_loading_game_request_received.emit()
	# A bit hacky but it should work...
	var tree: SceneTree = Engine.get_main_loop()
	var rhythm_game_multiplayer_scene = preload("res://rythm_game/rhythm_game_multiplayer.tscn").instantiate()
	tree.current_scene.queue_free()
	tree.root.add_child(rhythm_game_multiplayer_scene)
	tree.current_scene = rhythm_game_multiplayer_scene
	rhythm_game_multiplayer_scene.lobby = self
	rhythm_game_multiplayer_scene.start_game()
	
func _on_note_hit_received(sender: HBSteamFriend, judgement: HBJudge.JUDGE_RATINGS, score: int):
	var member_meta := get_member_metadata(sender)
	member_meta.note_hit_received.emit(judgement, score)
	
func _on_game_finished_received(sender: HBSteamFriend, result_dict: Dictionary):
	var result := HBResult.deserialize(result_dict) as HBResult
	
	if result:
		var meta := get_member_metadata(sender)
		meta.result = result
		meta.result_received.emit()
	
	if steam_lobby.is_owned_by_local_user():
		pass
	
func _on_member_kicked(_sender: HBSteamFriend, steam_id: int):
	var steam_user := HBSteamFriend.from_steam_id(steam_id)
	if steam_user in steam_lobby.get_members():
		member_kicked.emit(get_member_metadata(steam_user))
		if steam_user == Steamworks.user.get_local_user():
			steam_lobby.leave_lobby()
			kicked.emit()
	
# Public functions

## Returns the [HeartbeatSteamLobby.MemberMetadata] for each member
func get_all_members_metadata() -> Array[MemberMetadata]:
	var out: Array[MemberMetadata]
	for member in steam_lobby.get_members():
		out.push_back(get_member_metadata(member))
	return out

## Returns the [HeartbeatSteamLobby.MemberMetadata] for a specific Steam user
func get_member_metadata(member: HBSteamFriend) -> MemberMetadata:
	for data in member_metadata:
		if data.member == member:
			return data
	
	var new_member_data := MemberMetadata.new()
	new_member_data.member = member
	member_metadata.push_back(new_member_data)
	assert(member in steam_lobby.get_members())
	return new_member_data

## Returns the availability status of a given song
func get_song_availability_status(song_comes_from_ugc: bool, song_id: String, variant := -1) -> SongAvailabilityStatus:
	if not song_id in SongLoader.songs:
		if song_comes_from_ugc:
			return SongAvailabilityStatus.NEEDS_UGC_SONG_DOWNLOAD
		else:
			return SongAvailabilityStatus.MISSING_SONG
	var song := SongLoader.songs[song_id] as HBSong
	if not song.is_cached(variant):
		if song_comes_from_ugc and song.comes_from_ugc():
			return SongAvailabilityStatus.NEEDS_UGC_MEDIA_DOWNLOAD
		else:
			return SongAvailabilityStatus.MISSING_SONG_MEDIA
	return SongAvailabilityStatus.HAS_DATA

## Propagates a lobby data update, call after you've changed the lobby data (from authority only)
func send_lobby_data_update():
	assert(steam_lobby.is_owned_by_local_user())
	if not steam_lobby.set_data(LOBBY_DATA_KEY, var_to_str(lobby_data.to_dictionary())):
		printerr("Error setting steam lobby data!")
		return
	for member in steam_lobby.get_members():
		get_member_metadata(member).song_availability_meta._song_availability_dirty = true
		get_member_metadata(member).song_availability_meta.notify_updated()

## Sends an RPC call, you're more likely to find some function that wraps it around a type safe interface
func send_rpc_call(rpc_type: int, args: Array):
	var args_payload := var_to_bytes(args)
	var spb := StreamPeerBuffer.new()
	spb.put_data(RPC_PREAMBLE)# 	preamble (/rpc)
	spb.put_8(0x20) # 				space
	spb.put_8(rpc_type) # 			rpc opcode
	spb.put_8(0x20) # 				space
	spb.put_data(args_payload) # 	payload
	if not steam_lobby.send_chat_binary(spb.data_array):
		printerr("Failed to send lobby chat RPC message")

## Sets the current lobby name, only callable from authority
func update_lobby_name(lobby_name: String):
	lobby_data.lobby_name = lobby_name

## Sets the current lobby song, only callable from authority
func update_lobby_song_data(song: HBSong, variant: int, difficulty: String):
	assert(steam_lobby.is_owned_by_local_user())
	lobby_data.song_id = song.id
	lobby_data.is_song_from_ugc = song.comes_from_ugc()
	if lobby_data.is_song_from_ugc:
		lobby_data.song_ugc_id = song.ugc_id
	else:
		lobby_data.song_ugc_id = -1
	lobby_data.song_variant = variant
	lobby_data.difficulty = difficulty
	lobby_data.song_title = song.title
	_update_song_availability_information()

func update_in_game_state(game_state: InGameState):
	var meta := get_member_metadata(Steamworks.user.get_local_user())
	meta.in_game_data.state = game_state
	steam_lobby.set_member_data(MEMBER_IN_GAME_DATA_KEY, var_to_str(meta.in_game_data.to_dictionary()))

## Checks if a game can be started
func check_game_can_be_started() -> GameStartResponse:
	# Check that we have the required song data
	steam_lobby.set_lobby_joinable(false)
	var response := GameStartResponse.new()
	for member in steam_lobby.get_members():
		var meta := get_member_metadata(member)
		if meta.song_availability_meta._song_availability_dirty:
			response.status = GameStartResponseStatus.SONG_AVAILABILITY_METADATA_DIRTY
			steam_lobby.set_lobby_joinable(true)
		elif meta.song_availability_meta.song_availability_status != SongAvailabilityStatus.HAS_DATA:
			response.status = GameStartResponseStatus.USER_LACKS_MEDIA
			steam_lobby.set_lobby_joinable(true)
	return response

## Sends a standard chat message
func send_chat_text_message(text: String) -> bool:
	return steam_lobby.send_chat_string(text)

## Tells users that don't have the song data and/or media to be prompted to download it
## only callable from authority
func send_download_song_data_request():
	send_rpc_call(RPCPacketType.REQUEST_SONG_DATA_DOWNLOAD, [])

## Tells users to begin loading the game
## only callable from authority
func send_begin_game_load_request():
	assert(check_game_can_be_started().status == GameStartResponseStatus.OK)
	send_rpc_call(RPCPacketType.REQUEST_BEGIN_GAME_LOAD, [])

func notify_game_finished(result: HBResult):
	send_rpc_call(RPCPacketType.GAME_FINISHED, [result.serialize()])
	if steam_lobby.is_owned_by_local_user():
		if not steam_lobby.set_lobby_joinable(true):
			printerr("Failed to set lobby as joinable")

func send_note_hit(judgement: HBJudge.JUDGE_RATINGS, score: int):
	send_rpc_call(RPCPacketType.NOTE_HIT_UPDATE, [judgement, score])

func kick_member(member: MemberMetadata):
	send_rpc_call(RPCPacketType.KICK_MEMBER, [member.member.steam_id])

func get_lobby_name() -> String:
	return lobby_data.lobby_name

static func get_localized_lobby_privacy_text(lobby_type: int) -> String:
	match lobby_type:
		SteamworksConstants.LobbyType.LOBBY_TYPE_PUBLIC:
			return TranslationServer.tr("Public", &"Lobby privacy setting")
		SteamworksConstants.LobbyType.LOBBY_TYPE_FRIENDS_ONLY:
			return TranslationServer.tr("Friends only", &"Lobby privacy setting")
		SteamworksConstants.LobbyType.LOBBY_TYPE_PRIVATE:
			return TranslationServer.tr("Private", &"Lobby privacy setting")
	assert(false)
	return ""
## Constructor, do not use, use [method create_lobby] or [method join_lobby]
func _init(_steam_lobby: HBSteamLobby) -> void:
	steam_lobby = _steam_lobby
	steam_lobby.lobby_chat_updated.connect(self._on_lobby_chat_updated)
	steam_lobby.chat_message_received.connect(self._on_lobby_chat_message_received)
	steam_lobby.lobby_data_updated.connect(self._on_lobby_data_updated)
	steam_lobby.lobby_member_data_updated.connect(self._on_lobby_member_data_updated)
	
	for i in range(RPCPacketType.PACKET_TYPE_MAX):
		rpc_packet_types.push_back(RPCPacketInfo.new(i))
	# Packet type init
	rpc_packet_types[RPCPacketType.REQUEST_SONG_DATA_DOWNLOAD].callback = self._on_download_song_media_request_received
	rpc_packet_types[RPCPacketType.REQUEST_BEGIN_GAME_LOAD].callback = self._on_begin_game_load_request_received

	rpc_packet_types[RPCPacketType.NOTE_HIT_UPDATE].callback = self._on_note_hit_received
	rpc_packet_types[RPCPacketType.NOTE_HIT_UPDATE].rpc_privileges = RPCPrivileges.FROM_ANYONE
	rpc_packet_types[RPCPacketType.GAME_FINISHED].rpc_privileges = RPCPrivileges.FROM_ANYONE
	rpc_packet_types[RPCPacketType.GAME_FINISHED].callback = self._on_game_finished_received
	rpc_packet_types[RPCPacketType.KICK_MEMBER].callback = self._on_member_kicked
