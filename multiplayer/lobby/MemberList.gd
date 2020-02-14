extends Panel

const MemberScene = preload("res://multiplayer/lobby/Member.tscn")

onready var members_container = get_node("MarginContainer/VBoxContainer")

func add_member(member: HBServiceMember, is_owner):
	var scene = MemberScene.instance()
	members_container.add_child(scene)
	scene.member = member
	scene.is_owner = is_owner

func clear_members():
	for member in members_container.get_children():
		member.queue_free()
