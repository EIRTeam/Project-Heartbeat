extends Panel

onready var avatar_texture_rect = get_node("MarginContainer/HBoxContainer/TextureRect")

onready var username_field = get_node("MarginContainer/HBoxContainer/VBoxContainer/Label")
onready var level_field = get_node("MarginContainer/HBoxContainer/VBoxContainer/Label2")

func _ready():
	avatar_texture_rect.texture = PlatformService.service_provider.get_avatar()
	HBBackend.connect("user_data_received", self, "load_from_user_data")
	load_from_user_data()

func load_from_user_data():
	level_field.text = "Level %d" % [HBBackend.user_info.level]
	username_field.text = PlatformService.service_provider.friendly_username
