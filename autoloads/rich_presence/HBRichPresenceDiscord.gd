@uid("uid://bh143efp6hmdc") # Generated automatically, do not modify.
extends HBRichPresence

class_name HBRichPresenceDiscord

const POLL_RATE = 5 # polls per second

@onready var poll_timer = Timer.new()

@onready var rpc_rate_limit_timer := Timer.new()
var rate_limited_presence_data := {}

var presence_init_ok = false

func _ready():
	add_child(rpc_rate_limit_timer)
	if presence_init_ok:
		add_child(poll_timer)
		poll_timer.process_mode = Timer.TIMER_PROCESS_IDLE
		poll_timer.wait_time = 1.0/float(POLL_RATE)
		poll_timer.connect("timeout", Callable(self, "poll"))
		poll_timer.start()
	rpc_rate_limit_timer.one_shot = true
	rpc_rate_limit_timer.wait_time = 5.0
	rpc_rate_limit_timer.timeout.connect(_update_activity)
func init_presence():
	DiscordRPC.init("733416106123067465", "1216230")
	presence_init_ok = true
	return OK
	
func _update_activity():
	if rate_limited_presence_data.is_empty():
		return
	DiscordRPC.update_presence(rate_limited_presence_data)
	rate_limited_presence_data.clear()
	
func update_activity(state):
	var dict = HBUtils.merge_dict({
		"large_image_key": "default"
	}, state)
	if "details" in dict:
		var details_string := dict.details as String
		if details_string.length() > 128:
			dict.details = details_string.substr(0, 127)
	if rpc_rate_limit_timer.is_stopped():
		DiscordRPC.update_presence(dict)
		rpc_rate_limit_timer.start()
	else:
		print("RATE LIMIT")
		rate_limited_presence_data = dict
	
func poll():
	DiscordRPC.run_callbacks()
