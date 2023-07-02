extends Panel

const MemberScene = preload("res://multiplayer/lobby/Member.tscn")

@onready var members_container = get_node("MarginContainer/VBoxContainer")

var lobby: HBLobby

func add_member(member: HBServiceMember, is_owner, owned_by_local_user):
	var scene = MemberScene.instantiate()
	scene.size_flags_horizontal = scene.SIZE_EXPAND_FILL
	members_container.add_child(scene)
	scene.lobby = lobby
	scene.member = member
	scene.is_owner = is_owner
	scene.owned_by_local_user = owned_by_local_user

func clear_members():
	for member in members_container.get_children():
		member.queue_free()
