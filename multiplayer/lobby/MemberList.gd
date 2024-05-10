extends PanelContainer

class_name LobbyMemberList

const MemberScene = preload("res://multiplayer/lobby/Member.tscn")

@onready var members_container = get_node("MarginContainer/VBoxContainer")

class MemberSceneInfo:
	var member: HBSteamFriend
	var scene: LobbyMemberListMember
	
var scene_infos: Array[MemberSceneInfo]

signal lobby_owner_change_pressed(new_owner: HBSteamFriend)
signal kick_member_pressed(member: HBSteamFriend)

var lobby_owner: HBSteamFriend:
	set(val):
		if lobby_owner != val:
			_queue_update_lobby_ownership_display()
		lobby_owner = val

var update_lobby_ownership_display_queued := false

func _queue_update_lobby_ownership_display():
	if not update_lobby_ownership_display_queued:
		update_lobby_ownership_display_queued = true
		if not is_node_ready():
			await ready
		_update_lobby_ownwership_display.call_deferred()
		
func _update_scene_info_lobby_ownership_display(scene_info: MemberSceneInfo):
	scene_info.scene.is_lobby_owned_by_local_user = is_owned_by_local_user
	scene_info.scene.is_owner = lobby_owner == scene_info.member
		
func _update_lobby_ownwership_display():
	if update_lobby_ownership_display_queued:
		update_lobby_ownership_display_queued = false
		
		for scene_info in scene_infos:
			_update_scene_info_lobby_ownership_display(scene_info)
			
var is_owned_by_local_user := false:
	set(val):
		is_owned_by_local_user = val
		_queue_update_lobby_ownership_display()
		
func add_member(member: HeartbeatSteamLobby.MemberMetadata):
	for scene in scene_infos:
		if scene.member == member.member:
			return
	var scene = MemberScene.instantiate()
	scene.size_flags_horizontal = scene.SIZE_EXPAND_FILL
	members_container.add_child(scene)
	scene.member = member
	var scene_info := MemberSceneInfo.new()
	scene_info.member = member.member
	scene_info.scene = scene
	scene_info.scene.make_owner_button_pressed.connect(lobby_owner_change_pressed.emit.bind(member.member))
	scene_info.scene.kick_member_button_pressed.connect(kick_member_pressed.emit.bind(member))
	scene_infos.push_back(scene_info)
	_update_scene_info_lobby_ownership_display(scene_info)

func remove_member(member: HeartbeatSteamLobby.MemberMetadata):
	for scene_info in scene_infos:
		if scene_info.member == member.member:
			scene_info.scene.queue_free()
			scene_infos.erase(scene_info)
			
func clear():
	for member in members_container.get_children():
		member.queue_free()
	scene_infos.clear()
