extends HBRichPresence

class_name HBRichPresenceDiscord

var discord_controller_class = preload("res://addons/discord/DiscordController.gdns")
var discord_controller
func init_presence():
	var lib := discord_controller_class.library as GDNativeLibrary
	if lib.get_current_library_path().empty():
		print("Discord Rich presence is not available on this platform, falling back...")
		return ERR_BUG
	discord_controller = discord_controller_class.new()
	return discord_controller.init_discord(733416106123067465)
	
func update_activity(state):
	var dict = HBUtils.merge_dict({
		"large_image_key": "default"
	}, state)
	discord_controller.update_activity(dict)
	
func _process(delta):
	discord_controller.run_callbacks()
