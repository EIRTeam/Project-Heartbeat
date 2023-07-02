extends HBRichPresence

class_name HBRichPresenceDiscord

#var discord_controller_class = preload("res://addons/discord/DiscordController.gdns")
var discord_controller

const POLL_RATE = 5 # polls per second

@onready var poll_timer = Timer.new()

var presence_init_ok = false

func _ready():
	if presence_init_ok:
		add_child(poll_timer)
		poll_timer.process_mode = Timer.TIMER_PROCESS_IDLE
		poll_timer.wait_time = 1.0/float(POLL_RATE)
		poll_timer.connect("timeout", Callable(self, "poll"))
		poll_timer.start()
	
func init_presence():
	#var lib := discord_controller_class.library as GDNativeLibrary
	#if lib.get_current_library_path().is_empty():
	#	print("Discord Rich presence is not available on this platform, falling back...")
	#	return ERR_BUG
	#discord_controller = discord_controller_class.new()
	if not discord_controller:
		return ERR_FILE_MISSING_DEPENDENCIES
	var init_result = discord_controller.init_discord(733416106123067465)
	if init_result == OK:
		presence_init_ok = true
	return init_result
	
func update_activity(state):
	var dict = HBUtils.merge_dict({
		"large_image_key": "default"
	}, state)
	if "details" in dict:
		var details_string := dict.details as String
		if details_string.length() > 128:
			dict.details = details_string.substr(0, 127)
	discord_controller.update_activity(dict)
	
func poll():
	discord_controller.run_callbacks()
