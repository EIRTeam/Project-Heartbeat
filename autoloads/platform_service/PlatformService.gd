extends Node

# Platforms are what gives the game access to user data and communications, this can be Steam
# or another store, because the game is meant to be DRM-Free an offline service provider is also
# provided, it allows LAN connections amongst other things

const SteamPlatformServicePovider = preload("res://autoloads/platform_service/SteamServiceProvider.gd")
const OfflinePlatformServicePovider = preload("res://autoloads/platform_service/OfflinePlatformServiceProvider.gd")

const LOG_NAME = "PlatformService"

var service_provider : PlatformServiceProvider


func _ready():
	pass
	
func _initialize_platform():
	# Try to load steam first, if not fallback to Offline
	var service_init_result = set_service_provider(SteamPlatformServicePovider.new())
	if service_init_result != OK:
		set_service_provider(OfflinePlatformServicePovider.new())
		Log.log(self, "Loading Steamworks failed, falling back to offline service provider", Log.LogLevel.INFO)
func set_service_provider(provider: PlatformServiceProvider):
	var init_result = provider.init_platform()
	if init_result != OK:
		return init_result
	
	service_provider = provider
	
	return init_result

func _process(delta):
	service_provider.run_callbacks()
