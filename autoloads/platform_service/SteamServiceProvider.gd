extends PlatformServiceProvider

const LOG_NAME = "SteamServiceProvider"

func _init():
	implements_lobby_list = true
	implements_leaderboards = true

func init_platform() -> int:
	if Engine.has_singleton("Steam"):

		var init = Steam.steamInit()
		
		Log.log(self, init.verbal)
		if init.status != OK:
			return init.status
		
		friendly_username = Steam.getPersonaName()
		user_id = Steam.getSteamID()
		multiplayer_provider = SteamMultiplayerService.new()
		leaderboard_provider = SteamLeaderboardService.new()
		
		return OK
	else:
		Log.log(self, "Engine was not built with Steam support, aborting...")
		return ERR_METHOD_NOT_FOUND
func run_callbacks():
	Steam.run_callbacks()
