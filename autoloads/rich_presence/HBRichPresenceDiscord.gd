extends HBRichPresence

class_name HBRichPresenceDiscord

var discord_controller = preload("res://addons/discord/DiscordController.gdns").new()

func init_presence():
	return discord_controller.init_discord(733416106123067465)
	
func update_activity(state):
	var dict = HBUtils.merge_dict({
		"large_image_key": "default"
	}, state)
	discord_controller.update_activity(dict)
	
func _process(delta):
	discord_controller.run_callbacks()
