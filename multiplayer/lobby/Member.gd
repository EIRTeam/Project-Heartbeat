extends MarginContainer

var member: HBLobbyMember setget set_member
var is_owner: bool setget set_is_owner

onready var member_name_label = get_node("VBoxContainer/HBoxContainer/HBoxContainer/VBoxContainer/Label")
onready var avatar_texture_rect = get_node("VBoxContainer/HBoxContainer/TextureRect")
onready var owner_crown = get_node("VBoxContainer/HBoxContainer/HBoxContainer/TextureRect")

func set_member(val: HBLobbyMember):
	member = val
	member_name_label.text = member.member_name
	avatar_texture_rect.texture = member.avatar
	
func set_is_owner(val):
	is_owner = val
	owner_crown.visible = is_owner
		
	
func _ready():
	connect("resized", self, "_on_resized")
	
func _on_resized():
	var new_size = clamp(rect_size.y, 25, 50)
	avatar_texture_rect.rect_min_size = Vector2(new_size, new_size)
	avatar_texture_rect.rect_size = Vector2(new_size, new_size)
