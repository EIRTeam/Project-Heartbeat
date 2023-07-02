extends Node

# Platforms are what gives the game access to user data and communications, this can be Steam
# or another store, because the game is meant to be DRM-Free an offline service provider is also
# provided, it allows LAN connections amongst other things

var SteamPlatformServicePovider = load("res://autoloads/platform_service/SteamServiceProvider.gd")
var OfflinePlatformServicePovider = load("res://autoloads/platform_service/OfflinePlatformServiceProvider.gd")

const LOG_NAME = "PlatformService"

var service_provider : PlatformServiceProvider

const callbacks_rate: float = 1.0 / 30.0 # do steam callbacks 30 times a second
var callbacks_timer := Timer.new()

func _init():
	name = "PlatformService"
	
func _ready():
	add_child(callbacks_timer)
	callbacks_timer.wait_time = callbacks_rate
	callbacks_timer.connect("timeout", Callable(self, "_on_callbacks_timer_timeout"))
	callbacks_timer.start()
	
func _initialize_platform():
	if not Engine.has_singleton("Steam") or not HBGame.platform_settings is HBPlatformSettingsDesktop:
		set_service_provider(OfflinePlatformServicePovider.new())
		return
	# Try to load steam first, if not fallback to Offline
	if not HBGame.demo_mode:
		var service_init_result = set_service_provider(SteamPlatformServicePovider.new())
		if service_init_result != OK:
			set_service_provider(OfflinePlatformServicePovider.new())
			Log.log(self, "Loading Steamworks failed, falling back to offline service provider", Log.LogLevel.INFO)
	else:
		set_service_provider(OfflinePlatformServicePovider.new())
func set_service_provider(provider: PlatformServiceProvider):
	var init_result = provider.init_platform()
	if init_result != OK:
		return init_result
	
	service_provider = provider
	
	add_child(service_provider)
	
	return init_result

func _on_callbacks_timer_timeout():
	service_provider.run_callbacks()
