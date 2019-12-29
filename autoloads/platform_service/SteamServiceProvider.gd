extends PlatformServiceProvider

const LOG_NAME = "SteamServiceProvider"

func init_platform() -> int:
	var init = Steam.steamInit()
	
	Log.log(self, init.verbal)
	if init.status != OK:
		return init.status
	
	friendly_username = Steam.getPersonaName()
	user_id = Steam.getSteamID()
	
	return OK
