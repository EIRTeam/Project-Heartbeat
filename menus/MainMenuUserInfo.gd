extends Panel

@onready var avatar_texture_rect = get_node("MarginContainer/HBoxContainer/TextureRect")

@onready var username_field = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer2/NameLabel")
@onready var level_field = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/LevelLabel")
@onready var exp_progress_bar = get_node("MarginContainer/HBoxContainer/VBoxContainer/HBoxContainer/ProgressBar")

func _ready():
	avatar_texture_rect.texture = PlatformService.service_provider.get_avatar()
	HBBackend.connect("user_data_received", Callable(self, "load_from_user_data"))
	load_from_user_data()

func load_from_user_data():
	level_field.text = tr("Lvl. %d") % [HBBackend.user_info.level]
	var max_exp = HBUtils.get_experience_to_next_level(HBBackend.user_info.level)
	exp_progress_bar.max_value = max_exp
	exp_progress_bar.value = HBBackend.user_info.experience
	username_field.text = PlatformService.service_provider.friendly_username
	level_field.visible = HBBackend.has_user_data
	exp_progress_bar.visible = HBBackend.has_user_data
