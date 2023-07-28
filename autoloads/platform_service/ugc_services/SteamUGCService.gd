extends HBUGCService

class_name SteamUGCService

enum WORKSHOP_FILE_TYPES {
	COMMUNITY = 0,
	MICROTRANSACTION = 1
}

var updating_items = []
var update_items_notification_thing = {}
var cached_items_data = {}

var query_id_to_item = {}

var success_install_things = {}

var added_time_map = {}

const FILE_TO_UGC_TYPE = {
	"song.json": "song",
	"resource_pack.json": "resource_pack"
}

const DOWNLOAD_PROGRESS_THING = preload("res://autoloads/DownloadProgressThing.tscn")

func _init():
	super()
	LOG_NAME = "SteamUGCService"

	_init_ugc()
func _init_ugc():
	Steamworks.ugc.item_installed.connect(self._on_item_installed)
	
# we get the item add time on startup, this is what this variable and method below do
var meta_update_queries: Array[HBSteamUGCQuery]

func _make_user_song_ugc_request(page: int) -> void:
	var query := HBSteamUGCQuery.create_query(SteamworksConstants.UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE) \
		.where_user_subscribed() \
		.with_user(Steamworks.user.get_local_user()) \
		.with_tag("Charts")
	query.request_page(page)

func _reload_ugc_item_added_dates():
	var query := HBSteamUGCQuery.create_query(SteamworksConstants.UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE) \
		.where_user_subscribed() \
		.with_user(Steamworks.user.get_local_user()) \
		.with_tag("Charts")
	var do_req := func do_req(page: int):
		query.request_page(page)
		var result: HBSteamUGCQueryPageResult = await query.query_completed 
		var results := result.results
		_on_ugc_meta_query_update_completed(results)
		print("META QUERY DONE", page)
		return result
	var page := 1
	var result := await do_req.call(page) as HBSteamUGCQueryPageResult
	var results := result.results
	
	var total_results_until_now := results.size()
	while total_results_until_now < result.total_results:
		page += 1
		result = await do_req.call(page)
		results = result.results
		total_results_until_now += results.size()

func reload_ugc_songs():
	var atlas_rebuild_needed = false
	var skin_reload_needed = false
	for item in Steamworks.ugc.get_subscribed_items():
		var state = item.item_state
		# Removed in SW2
		#if state & SteamworksConstants.ITEM_STATE_DOWNLOADING:
			#updating_items.append(item_id)
		if state & SteamworksConstants.ITEM_STATE_NEEDS_UPDATE:
			var r = item.download(false)
			#if r:
				#updating_items.append(item_id)
		elif state & SteamworksConstants.ITEM_STATE_INSTALLED:
			var o = _add_downloaded_item(item.item_id)
			if o == "resource_pack":
				var ugc_n = "ugc_%s" % [str(item.item_id)]
				if ugc_n == UserSettings.user_settings.resource_pack:
					atlas_rebuild_needed = true
				if ugc_n == UserSettings.user_settings.ui_skin:
					skin_reload_needed = true
	_reload_ugc_item_added_dates()
	if atlas_rebuild_needed:
		ResourcePackLoader.rebuild_final_atlases()
	if skin_reload_needed:
		ResourcePackLoader.reload_skin()

func _track_item_download(item_id):
	var notification = DOWNLOAD_PROGRESS_THING.instantiate()
	notification.type = HBDownloadProgressThing.TYPE.NORMAL
	updating_items.append(item_id)
	update_items_notification_thing[item_id] = notification
func _process(delta):
	pass

func _add_downloaded_item(item_id, fire_signal=false) -> String:
	var steam_item := HBSteamUGCItem.from_id(item_id)
	if steam_item.item_state == 0:
		return ""
	var install_directory = steam_item.install_directory
	if install_directory.is_empty():
		printerr("Failed to get install info dir for item %s" % item_id)
		return ""
	var item_type
	var item: Variant
	for file_name in FILE_TO_UGC_TYPE:
		item_type = FILE_TO_UGC_TYPE[file_name]
		if FileAccess.file_exists(install_directory + "/%s" % [file_name]):
			var type = FILE_TO_UGC_TYPE[file_name]
			if type == "song":
#				Log.log(self, "Loading workshop song from %s" % folder)
				var song = SongLoader.load_song_meta(install_directory + "/%s" % [file_name], "ugc_" + str(item_id))
				if song:
					song._comes_from_ugc = true
					song.ugc_id = item_id
					song.ugc_service_name = get_ugc_service_name()
					# We give UGC songs the highest value possible, so that new downloads show up on top.
					# since godot dictionaries hold order properly, this is all we need
					song._added_time = 0x7FFFFFFFFFFFFFFF
					if song.ugc_id in added_time_map:
						song._added_time = added_time_map[song.ugc_id]
					SongLoader.add_song(song)
					item = song
	#				if not song.is_cached():
	#					song.cache_data()
					break
				else:
					breakpoint
			if type == "resource_pack":
				var id = "ugc_" + str(item_id)
				var pack := HBResourcePack.load_from_directory(install_directory) as HBResourcePack
				pack._id = id
				if pack:
					pack.ugc_id = item_id
					pack.ugc_service_name = get_ugc_service_name()
					ResourcePackLoader.resource_packs[id] = pack
					
	if item and fire_signal:
		emit_signal("ugc_item_installed", item_type, item)
	return item_type
func _on_item_installed(app_id: int, item_id: int):
	if app_id == Steamworks.get_app_id():
		_add_downloaded_item(item_id, true)
		var result_notification = DOWNLOAD_PROGRESS_THING.instantiate()
		result_notification.life_timer = 2.0
		result_notification.type = HBDownloadProgressThing.TYPE.SUCCESS
		success_install_things[item_id] = result_notification
		if item_id in cached_items_data:
			_on_show_success(item_id)
		else:
			get_item_details(item_id)
		
		

func _on_item_downloaded(result, app_id, item_id):
	#TODOSW2
	if app_id == Steamworks.get_app_id():
		
		if item_id in update_items_notification_thing:
			var notification_thing = update_items_notification_thing[item_id]
			DownloadProgress.remove_notification(notification_thing)
		

		if result != 1:
			var result_notification = DOWNLOAD_PROGRESS_THING.instantiate()
			result_notification.life_timer = 2.0
			DownloadProgress.add_notification(result_notification, true)
			result_notification.type = HBDownloadProgressThing.TYPE.ERROR
			result_notification.text = "Error downloading item id %d, error: %d" % [item_id, result]
			Log.log(self, "Error downloading UGC item id %d, error: %d" % [item_id, result])
		updating_items.erase(item_id)
		_add_downloaded_item(item_id, true)

func _on_item_created(result, file_id, tos):
	emit_signal("item_created", result, file_id, tos)

func _on_item_updated(result, tos):
	emit_signal("item_update_result", result, tos)
	
func _on_show_success(item_id):
	var thing = success_install_things[item_id]
	DownloadProgress.add_notification(thing, true)
	var data = cached_items_data[item_id]
	thing.text = "Succesfully installed  %s!" % [data.title]
	success_install_things.erase(item_id)
	
func _on_ugc_meta_query_update_completed(results: Array[HBSteamUGCItem]):
	for detail in results:
		var f_name = "ugc_" + str(detail.item_id)
		if f_name in SongLoader.songs:
			var song = SongLoader.songs[f_name] as HBSong
			song._added_time = detail.time_added_to_user_list
			song._released_time = detail.time_created
			song._updated_time = detail.time_updated
			added_time_map[song.ugc_id] = detail.time_added_to_user_list
	if results.size() > 0:
		emit_signal("ugc_song_meta_updated")
func get_ugc_service_name():
	return "Steam Workshop"
func delete_item(item_id):
	HBSteamUGCItem.from_id(item_id).delete_item()
	
func has_user_item_vote(item_id):
	if item_id in ugc_data.skipped_votes:
		return true
	
func get_user_item_vote(item_id):
	var item := HBSteamUGCItem.from_id(item_id)
	item.request_user_vote()
	var vote_result: HBSteamUGCUserItemVoteResult = await item.user_item_vote_received
	if vote_result.vote_up:
		return USER_ITEM_VOTE.UPVOTE
	elif vote_result.vote_down:
		return USER_ITEM_VOTE.DOWNVOTE
	elif vote_result.vote_skipped:
		return USER_ITEM_VOTE.SKIP
	else:
		return USER_ITEM_VOTE.NOT_VOTED

func set_user_item_vote(item_id, vote):
	var item := HBSteamUGCItem.from_id(item_id)
	if vote == USER_ITEM_VOTE.UPVOTE:
		item.set_user_item_vote(true)
	elif vote == USER_ITEM_VOTE.DOWNVOTE:
		item.set_user_item_vote(false)
	else:
		skip_vote(item_id)
