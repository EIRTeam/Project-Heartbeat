extends HBMenu
	
const NEWS_ITEM = preload("res://menus/news_list/NewsListItem.tscn")

signal left

onready var request = get_node("HTTPRequest")

const LOG_NAME = "NewsList"

onready var news_container = get_node("VBoxContainer/NewsButtons")

onready var discord_button = get_node("VBoxContainer/SocialButtons/DiscordButton")
onready var social_container = get_node("VBoxContainer/SocialButtons")
onready var twitter_button = get_node("VBoxContainer/SocialButtons/TwitterButton")
onready var open_profile_button = get_node("VBoxContainer/SocialButtons/OpenProfileButton")

func _ready():
	request.connect("request_completed", self, "_on_request_completed")
	request.request("https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=1216230&count=20")
	twitter_button.connect("pressed", OS, "shell_open", ["https://twitter.com/PHeartbeatGame"])
	discord_button.connect("pressed", OS, "shell_open", ["https://discord.com/invite/qGMdbez"])
	if not PlatformService.service_provider.ugc_provider is SteamUGCService:
		open_profile_button.queue_free()
	
func _on_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8()).result
		var news_items = []
		for item in json.appnews.newsitems:
			if not "tags" in item or not "patchnotes" in item.tags:
				news_items.append(item)
				if news_items.size() == 3:
					break
		for item in news_items:
			var button = NEWS_ITEM.instance()
			news_container.add_child(button)
			var date_time = OS.get_datetime_from_unix_time(item.date)
			button.date_label.text = "%d-%d-%d" % [date_time.day, date_time.month, date_time.year]
			button.title_label.text = item.title
			button.url = item.url
			button.reset_size()
	else:
		Log.log(self, "Error getting news: %s" % body.get_string_from_utf8(), Log.LogLevel.ERROR)

func _on_right_from_MainMenu():
	social_container.grab_focus()

func _input(event):
	if event.is_action_pressed("gui_left"):
		if news_container.has_focus() or social_container.has_focus():
			get_tree().set_input_as_handled()
			emit_signal("left")
			ShinobuGodot.fire_and_forget_sound(HBGame.MENU_PRESS_SFX, "sfx")


func _on_OpenProfileButton_pressed():
	var steam_id = PlatformService.service_provider.user_id
	OS.shell_open("https://ph.eirteam.moe/leaderboards/user/%s/1" % [steam_id])
