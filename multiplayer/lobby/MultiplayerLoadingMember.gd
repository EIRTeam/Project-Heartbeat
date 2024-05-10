extends MarginContainer

class_name MultiplayerLoadingMember

@onready var loading_icon: Control = get_node("%LoadingIcon")
@onready var loaded_icon: Control = get_node("%LoadedIcon")
@onready var avatar_texture_rect: TextureRect = get_node("%AvatarTextureRect")
@onready var persona_name_label: Label = get_node("%PersonaNameLabel")

var member_meta: HeartbeatSteamLobby.MemberMetadata:
	set(val):
		if member_meta:
			member_meta.in_game_data.updated.disconnect(self._queue_update)
		member_meta = val
		member_meta.in_game_data.updated.connect(self._queue_update)
		_queue_update()

var update_queued := false

func _update():
	if update_queued:
		update_queued = false
		
		loaded_icon.visible = member_meta.in_game_data.state == HeartbeatSteamLobby.InGameState.LOADED
		loading_icon.visible = member_meta.in_game_data.state == HeartbeatSteamLobby.InGameState.LOADING
		persona_name_label.text = member_meta.member.persona_name
		avatar_texture_rect.texture = member_meta.member.avatar
func _queue_update():
	if not update_queued:
		update_queued = true
		if not is_node_ready():
			await self.ready
		_update.call_deferred()

func _process(delta: float) -> void:
	loading_icon.pivot_offset = loading_icon.size * 0.5
	loading_icon.rotation_degrees += delta * 180.0
