extends VBoxContainer

class_name MultiplayerLoadingMemberList

const MULTIPLAYER_LOADING_MEMBER_SCENE: PackedScene = preload("res://multiplayer/lobby/MultiplayerLoadingMember.tscn")

func add_member(member: HeartbeatSteamLobby.MemberMetadata):
	var member_scene := MULTIPLAYER_LOADING_MEMBER_SCENE.instantiate() as MultiplayerLoadingMember
	member_scene.member_meta = member
	add_child(member_scene)
