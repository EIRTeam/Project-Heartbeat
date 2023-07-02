extends HBUGCService

class_name SteamUGCService

enum WORKSHOP_FILE_TYPES {
	COMMUNITY = 0,
	MICROTRANSACTION = 1
}

enum UGC_STATES {
	NONE = 0,
	SUBSCRIBED = 1,
	LEGACY = 2,
	INSTALLED = 4,
	NEEDS_UPDATE = 8,
	DOWNLOADING = 16,
	PENDING = 32
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
	Steam.connect("item_created", Callable(self, "_on_item_created"))
	Steam.connect("item_updated", Callable(self, "_on_item_updated"))
	Steam.connect("ugc_query_completed", Callable(self, "_on_ugc_query_completed"))
	Steam.connect("item_downloaded", Callable(self, "_on_item_downloaded"))
	Steam.connect("item_installed", Callable(self, "_on_item_installed"))
	_init_ugc()
func _init_ugc():
	pass
	
# we get the item add time on startup, this is what this variable and method below do
var update_handles = {}

func _make_user_song_ugc_request(page: int) -> int:
	var u = Steam.createQueryUserUGCRequest(Steam.getSteamID() & Steam.STEAM_ACCOUNT_ID_MASK,
		Steam.USER_UGC_LIST_SUBSCRIBED,
		Steam.UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE, 0, 
		Steam.getAppID(), Steam.getAppID(), page)
	Steam.addRequiredTag(u, "Charts")
	Steam.sendQueryUGCRequest(u)
	if u != Steam.UGC_QUERY_HANDLE_INVALID:
		update_handles[u] = page
	return u

func _reload_ugc_item_added_dates():
	_make_user_song_ugc_request(1)
	

func reload_ugc_songs():
	var atlas_rebuild_needed = false
	var skin_reload_needed = false
	for item_id in Steam.getSubscribedItems():
		var state = Steam.getItemState(item_id)
		if state & UGC_STATES.DOWNLOADING:
			updating_items.append(item_id)
		elif state & UGC_STATES.NEEDS_UPDATE:
			var r = Steam.downloadItem(item_id, false)
			if r:
				updating_items.append(item_id)
		elif state & UGC_STATES.INSTALLED:
			var o = _add_downloaded_item(item_id)
			if o == "resource_pack":
				var ugc_n = "ugc_%s" % [str(item_id)]
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
	for item_id in updating_items:
		if item_id in update_items_notification_thing:
			var p = Steam.getItemDownloadInfo(item_id)
			var progress = p.downloaded / float(p.total)
			var text = "Downloading %s: %.2f (%.2f MB / %.2f MB )"
			var item_name = str(item_id)
			if item_id in cached_items_data:
				item_name = cached_items_data[item_id].title
			text = text % [item_name, progress*100, p.downloaded*1000000.0, p.total*1000000.0]
			text += "%"

func _add_downloaded_item(item_id, fire_signal=false) -> String:
	if Steam.getItemState(item_id) == 0:
		return ""
	var install_info = Steam.getItemInstallInfo(item_id)
	if install_info.ret:
		var folder = install_info.folder
		var item
		var item_type
		for file_name in FILE_TO_UGC_TYPE:
			item_type = FILE_TO_UGC_TYPE[file_name]
			if FileAccess.file_exists(folder + "/%s" % [file_name]):
				var type = FILE_TO_UGC_TYPE[file_name]
				if type == "song":
	#				Log.log(self, "Loading workshop song from %s" % folder)
					var song = SongLoader.load_song_meta(folder + "/%s" % [file_name], "ugc_" + str(item_id))
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
				if type == "resource_pack":
					var id = "ugc_" + str(item_id)
					var pack := HBResourcePack.load_from_directory(folder) as HBResourcePack
					pack._id = id
					if pack:
						pack.ugc_id = item_id
						pack.ugc_service_name = get_ugc_service_name()
						ResourcePackLoader.resource_packs[id] = pack
						
		if item and fire_signal:
			emit_signal("ugc_item_installed", item_type, item)
		return item_type
	prints("Error adding item", item_id)
	return ""
func _on_item_installed(app_id, item_id):
	if app_id == Steam.getAppID():
		_add_downloaded_item(item_id, true)
		var result_notification = DOWNLOAD_PROGRESS_THING.instantiate()
		result_notification.life_timer = 2.0
		result_notification.type = HBDownloadProgressThing.TYPE.SUCCESS
		success_install_things[item_id] = result_notification
		if item_id in cached_items_data:
			_on_show_success(item_id)
		else:
			get_item_details(item_id)
		
		

func _on_item_downloaded(result, item_id, app_id):
	if app_id == Steam.getAppID():
		
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
	
func _on_ugc_query_completed(update_handle, result, number_of_results, number_of_matching_results, cached):
	if update_handle in update_handles:
		var page = update_handles[update_handle]
		update_handles.erase(update_handle)
		var total_results_until_now = page * 50
		if total_results_until_now < number_of_matching_results:
			_make_user_song_ugc_request(page+1)
		for result_i in range(number_of_results):
			var details = Steam.getQueryUGCResult(update_handle, result_i)
			var f_name = "ugc_" + str(details.file_id)
			if f_name in SongLoader.songs:
				var song = SongLoader.songs[f_name] as HBSong
				song._added_time = details.time_added_to_user_list
				song._released_time = details.time_created
				song._updated_time = details.time_updated
				added_time_map[song.ugc_id] = details.time_added_to_user_list
		if number_of_results > 0:
			emit_signal("ugc_song_meta_updated")
	if update_handle in query_id_to_item:
		var details = Steam.getQueryUGCResult(update_handle, 0)
		var item_id = query_id_to_item[update_handle]
		query_id_to_item.erase(update_handle)
		details["item_id"] = item_id
		cached_items_data[item_id] = details
		if item_id in success_install_things:
			if result != 1:
				success_install_things[item_id].queue_free()
				success_install_things.erase(item_id)
				Log.log(self, "Issue obtaining data for install success notification")
			else:
				_on_show_success(item_id)
		emit_signal("ugc_details_request_done", details.result, details)
		Steam.releaseQueryUGCRequest(update_handle)
func download_item(item_id: int):
	return Steam.downloadItem(item_id, true)
func create_item():
	Steam.createItem(Steam.getAppID(), int(WORKSHOP_FILE_TYPES.COMMUNITY))
func set_item_title(update_id, title: String):
	Steam.setItemTitle(update_id, title)
func set_item_description(update_id, description: String):
	Steam.setItemDescription(update_id, description)
func set_item_metadata(update_id, metadata: String):
	Steam.setItemMetadata(update_id, metadata)
func set_item_content_path(update_id, content_path: String):
	Steam.setItemContent(update_id, content_path)
func set_item_preview(update_id, preview_path: String):
	Steam.setItemPreview(update_id, preview_path)
func start_item_update(published_id):
	return Steam.startItemUpdate(Steam.getAppID(), published_id)
func set_item_tags(update_id, tags):
	return Steam.setItemTags(update_id, tags)
func get_ugc_service_name():
	return "Steam Workshop"
func submit_item_update(update_id, change_note: String):
	Steam.submitItemUpdate(update_id, change_note)
func get_item_details(ugc_id):
	var req_id = Steam.createQueryUGCDetailsRequest([ugc_id])
	query_id_to_item[req_id] = ugc_id
	Steam.setReturnLongDescription(req_id, true)
	Steam.sendQueryUGCRequest(req_id)
func delete_item(item_id):
	Steam.deleteItem(item_id)
func get_update_progress(update_id):
	return Steam.getItemUpdateProgress(update_id)
func add_item_preview_video(update_id, video_id):
	Steam.addItemPreviewVideo(update_id, video_id)
	
func has_user_item_vote(item_id):
	if item_id in ugc_data.skipped_votes:
		return true
	
func get_user_item_vote(item_id):
	Steam.getUserItemVote(item_id)
	var r = await Steam.get_item_vote_result
	var result = {
		"result": r[0],
		"file_id": r[1],
		"vote_up": r[2],
		"vote_down": r[3],
		"vote_skipped": r[4]
	}
	if result.result == 1:
		if result.vote_up:
			return USER_ITEM_VOTE.UPVOTE
		elif result.vote_down:
			return USER_ITEM_VOTE.DOWNVOTE
		else:
			return USER_ITEM_VOTE.NOT_VOTED
#		else:
			
#			pass
		# TODO: Skip logic
	else:
		return USER_ITEM_VOTE.SKIP

func set_user_item_vote(item_id, vote):
	if vote == USER_ITEM_VOTE.UPVOTE:
		Steam.setUserItemVote(item_id, true)
	elif vote == USER_ITEM_VOTE.DOWNVOTE:
		Steam.setUserItemVote(item_id, false)
	else:
		skip_vote(item_id)
