extends HBRichPresenceProvider

class_name HBRichPresenceProviderSteam

func _init_presence() -> int:
	if Steamworks.is_valid():
		return OK
	return ERR_UNAVAILABLE

func _get_stage_status_localization_key(stage: HBRichPresence.RichPresenceStage) -> String:
	var out := "#Status_AtMainMenu"
	match stage:
		HBRichPresence.RichPresenceStage.STAGE_AT_MAIN_MENU:
			out = "#Status_AtMainMenu"
		HBRichPresence.RichPresenceStage.STAGE_AT_SONG_LIST:
			out = "#Status_AtSongList"
		HBRichPresence.RichPresenceStage.STAGE_AT_EDITOR:
			out = "#Status_AtEditor"
		HBRichPresence.RichPresenceStage.STAGE_AT_EDITOR_SONG:
			out = "#Status_AtEditorSong"
		HBRichPresence.RichPresenceStage.STAGE_PLAYING:
			out = "#Status_PlayingSong"
		HBRichPresence.RichPresenceStage.STAGE_MULTIPLAYER_LOBBY:
			out = "#Status_InLobby"
		HBRichPresence.RichPresenceStage.STAGE_MULTIPLAYER_PLAYING:
			out = "#Status_PlayingMultiplayer"
	return out

func _cap_to_length(str: String, length: int) -> String:
	if str.length() > length:
		return str.substr(0, length)
	return str

func _update_rich_presence(rich_presence_data: HBRichPresence):
	const STEAM_DETAIL_MAX_LENGTH := 256
	Steamworks.friends.set_rich_presence("steam_display", _get_stage_status_localization_key(rich_presence_data.current_stage))
	if rich_presence_data.current_song:
		Steamworks.friends.set_rich_presence("song", _cap_to_length(rich_presence_data.current_song.get_visible_title(rich_presence_data.current_song_variant), STEAM_DETAIL_MAX_LENGTH))
		Steamworks.friends.set_rich_presence("difficulty", _cap_to_length(rich_presence_data.current_difficulty.to_upper(), STEAM_DETAIL_MAX_LENGTH))
		Steamworks.friends.set_rich_presence("score", HBUtils.thousands_sep(rich_presence_data.current_score))
