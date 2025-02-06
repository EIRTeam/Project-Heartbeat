extends HBRichPresenceProvider

class_name HBRichPresenceProviderDiscord

var current_time := 0.0
var last_activity_update_time := 0.0
var update_queued := false
var queued_update_data := {}

# Discord docs say "This has a rate limit of 5 updates per 20 seconds"
# technically we could get away with more updates in short bursts with a 20 second cooldown, but this is
# probably good enough, not sure why the discord client doesn't do some sort of soft rate-limiting by
# itself like steam does, a mystery we will take to our graves
const RATE_LIMIT_TIME_BETWEEN_ACTIVITY_UPDATES := 20.0/5.0

func _get_tick_rate() -> float:
	return 1.0/5.0
	
func can_send_activity_update() -> bool:
	return current_time - last_activity_update_time > RATE_LIMIT_TIME_BETWEEN_ACTIVITY_UPDATES
	
# HACK-y, but who will complain? not me
const SONGS_WITH_IMAGE = [
	"imademo_2012",
	"cloud_sky_2019",
	"hyperspeed_out_of_control",
	"music_play_in_the_floor",
	"connected"
]
	
func _get_stage_status_text(stage: HBRichPresence.RichPresenceStage) -> String:
	var out := "At the main menu"
	match stage:
		HBRichPresence.RichPresenceStage.STAGE_AT_MAIN_MENU:
			out = "At the main menu"
		HBRichPresence.RichPresenceStage.STAGE_AT_SONG_LIST:
			out = "At the song list"
		HBRichPresence.RichPresenceStage.STAGE_AT_EDITOR, HBRichPresence.RichPresenceStage.STAGE_AT_EDITOR:
			out = "At the editor"
		HBRichPresence.RichPresenceStage.STAGE_PLAYING:
			out = "Playing a song"
		HBRichPresence.RichPresenceStage.STAGE_MULTIPLAYER_LOBBY:
			out = "In a multiplayer lobby"
		HBRichPresence.RichPresenceStage.STAGE_MULTIPLAYER_PLAYING:
			out = "Playing multiplayer"
	return out
	
func _update_rich_presence(rich_presence_data: HBRichPresence):
	queued_update_data.clear()
	queued_update_data = {
		"state": _get_stage_status_text(rich_presence_data.current_stage),
		"large_image_key": "default"
	}
	
	match rich_presence_data.current_stage:
		HBRichPresence.RichPresenceStage.STAGE_AT_SONG_LIST, HBRichPresence.RichPresenceStage.STAGE_AT_EDITOR_SONG, HBRichPresence.RichPresenceStage.STAGE_PLAYING, HBRichPresence.RichPresenceStage.STAGE_MULTIPLAYER_PLAYING:
			var song_preview_url := rich_presence_data.current_song._ugc_preview_url
			var large_image_name := "default"
			if rich_presence_data.current_song.id in SONGS_WITH_IMAGE or not song_preview_url.is_empty():
				large_image_name = rich_presence_data.current_song.id if song_preview_url.is_empty() else song_preview_url
			
			var song_title := rich_presence_data.current_song.get_visible_title(-1)
			var details_title = song_title
			# Only some stages get a difficulty label
			if rich_presence_data.current_stage in [HBRichPresence.RichPresenceStage.STAGE_MULTIPLAYER_PLAYING, HBRichPresence.RichPresenceStage.STAGE_PLAYING, HBRichPresence.RichPresenceStage.STAGE_AT_EDITOR_SONG]:
				details_title += " - %s" % [rich_presence_data.current_difficulty.to_upper()]
				queued_update_data["start_timestamp"] = rich_presence_data.current_start_time
			# Only some stages get a score label
			if rich_presence_data.current_stage in [HBRichPresence.RichPresenceStage.STAGE_MULTIPLAYER_PLAYING, HBRichPresence.RichPresenceStage.STAGE_PLAYING]:
				details_title += " (%s pts)" % [HBUtils.thousands_sep(rich_presence_data.current_score)]
				
			# Discord has a character limit... trim it
			if details_title.length() > 128:
				details_title = details_title.substr(0, 127)
			queued_update_data["details"] = details_title
			queued_update_data["large_image_key"] = large_image_name
			queued_update_data["large_image_tooltip"] = song_title
	update_queued = true
func _init_rich_presence() -> int:
	# Maybe we should add error checking here...
	DiscordRPC.init("733416106123067465", "1216230")
	return OK
	
func _push_update():
	DiscordRPC.update_presence(queued_update_data)
	last_activity_update_time = current_time

func _tick():
	# This is probably imprecise, so be careful if we ever need more precision for
	# some godforsaken reason
	current_time += _get_tick_rate()
	if update_queued and can_send_activity_update():
		_push_update()
		update_queued = false
	DiscordRPC.run_callbacks()
