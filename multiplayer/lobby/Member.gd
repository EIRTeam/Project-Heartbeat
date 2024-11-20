extends MarginContainer

class_name LobbyMemberListMember

var member: HeartbeatSteamLobby.MemberMetadata:
	set(val):
		if member:
			member.member.information_updated.disconnect(self._queue_update)
			member.song_availability_meta.updated.disconnect(self._queue_update)
			
		member = val
		member.member.information_updated.connect(self._queue_update)
		member.song_availability_meta.updated.connect(self._queue_update)
		_queue_update()

var is_owner := false:
	set(val):
		is_owner = val
		_queue_update()
var is_lobby_owned_by_local_user := false:
	set(val):
		is_lobby_owned_by_local_user = val
		_queue_update()

signal make_owner_button_pressed
signal kick_member_button_pressed

@onready var member_name_label = get_node("%PersonaNameLabel")
@onready var avatar_texture_rect = get_node("%AvatarTextureRect")
@onready var owner_crown: TextureRect = get_node("%OwnerCrown")
@onready var make_host_button: Button = get_node("%MakeHostButton")
@onready var kick_member_button: Button = get_node("%KickButton")
@onready var data_status_label: Label = get_node("%DataStatusLabel")
@onready var meta_reloading_icon: TextureRect = get_node("%MetaReloadingIcon")

var update_queued := false

func _ready() -> void:
	set_process(false)
	make_host_button.pressed.connect(make_owner_button_pressed.emit)
	kick_member_button.pressed.connect(kick_member_button_pressed.emit)

func _process(delta: float) -> void:
	meta_reloading_icon.pivot_offset = meta_reloading_icon.size * 0.5
	meta_reloading_icon.rotation_degrees += delta * 180.0

func _update():
	update_queued = false
	if not is_inside_tree():
		await ready
	if member:
		member_name_label.text = member.member.persona_name
		avatar_texture_rect.texture = member.member.avatar
		
		owner_crown.visible = is_owner
		make_host_button.visible = !is_owner && is_lobby_owned_by_local_user
		kick_member_button.visible = !is_owner && is_lobby_owned_by_local_user
		
		if member.song_availability_meta._song_availability_dirty:
			meta_reloading_icon.show()
			data_status_label.hide()
			set_process(true)
		else:
			meta_reloading_icon.hide()
			data_status_label.show()
			set_process(false)
			match member.song_availability_meta.song_availability_status:
				HeartbeatSteamLobby.SongAvailabilityStatus.HAS_DATA:
					data_status_label.text = tr("OK!", &"Used in the lobby menu for when the player has all song data")
				HeartbeatSteamLobby.SongAvailabilityStatus.NEEDS_UGC_SONG_DOWNLOAD:
					data_status_label.text = tr("SONG MISSING", &"Used in the lobby menu for when the player doesn't have a workshop song")
				HeartbeatSteamLobby.SongAvailabilityStatus.NEEDS_UGC_MEDIA_DOWNLOAD:
					data_status_label.text = tr("SONG MEDIA MISSING", &"Used in the lobby menu for when the player doesn't have the media for a workshop song")
				HeartbeatSteamLobby.SongAvailabilityStatus.MISSING_SONG:
					data_status_label.text = tr("SONG MISSING", &"Used in the lobby menu for when the player doesn't have a non-workshop song")
				HeartbeatSteamLobby.SongAvailabilityStatus.MISSING_SONG_MEDIA:
					data_status_label.text = tr("SONG MEDIA MISSING", &"Used in the lobby menu for when the player doesn't have a non-workshop song")
func _queue_update():
	if not update_queued:
		update_queued = true
		_update.call_deferred()
