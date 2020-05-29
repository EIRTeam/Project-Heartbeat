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

const FILE_TO_UGC_TYPE = {
	"song.json": "song"
}

const DOWNLOAD_PROGRESS_THING = preload("res://autoloads/DownloadProgressThing.tscn")

func _init().():
	LOG_NAME = "SteamUGCService"
	Steam.connect("item_created", self, "_on_item_created")
	Steam.connect("item_updated", self, "_on_item_updated")
	Steam.connect("ugc_query_completed", self, "_on_ugc_query_completed")
	Steam.connect("item_downloaded", self, "_on_item_downloaded")
	Steam.connect("item_installed", self, "_on_item_installed")
	_init_ugc()
func _init_ugc():
	for item_id in Steam.getSubscribedItems():
		var state = Steam.getItemState(item_id)
		if state & UGC_STATES.DOWNLOADING:
			updating_items.append(item_id)
		elif state & UGC_STATES.NEEDS_UPDATE:
			var r = Steam.downloadItem(item_id, false)
			if r:
				updating_items.append(item_id)
		elif state & UGC_STATES.INSTALLED:
			_add_downloaded_item(item_id)

func _track_item_download(item_id):
	var notification = DOWNLOAD_PROGRESS_THING.instance()
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

func _add_downloaded_item(item_id, fire_signal=false):
	var install_info = Steam.getItemInstallInfo(item_id)
	var folder = install_info.folder
	var file = File.new()
	var item
	var item_type
	for file_name in FILE_TO_UGC_TYPE:
		item_type = FILE_TO_UGC_TYPE[file_name]
		if file.file_exists(folder + "/%s" % [file_name]):
			var type = FILE_TO_UGC_TYPE[file_name]
			if type == "song":
#				Log.log(self, "Loading workshop song from %s" % folder)
				var song = SongLoader.load_song_meta(folder + "/%s" % [file_name], "ugc_" + str(item_id))
				song._comes_from_ugc = true
				song.ugc_id = item_id
				song.ugc_service_name = get_ugc_service_name()
				SongLoader.add_song(song)
				item = song
#				if not song.is_cached():
#					song.cache_data()
				break
	if item and fire_signal:
		emit_signal("ugc_item_installed", item_type, item)
func _on_item_installed(app_id, item_id):
	if app_id == Steam.getAppID():
		_add_downloaded_item(item_id, true)
		var result_notification = DOWNLOAD_PROGRESS_THING.instance()
		result_notification.life_timer = 2.0
		result_notification.type = HBDownloadProgressThing.TYPE.SUCCESS
		success_install_things[item_id] = result_notification
		if item_id in cached_items_data:
			_on_show_success(item_id)
		else:
			get_item_details(item_id)
		print("DOWNLOADED ITEM!")
		
		

func _on_item_downloaded(result, item_id, app_id):
	if app_id == Steam.getAppID():
		
		if item_id in update_items_notification_thing:
			var notification_thing = update_items_notification_thing[item_id]
			DownloadProgress.remove_notification(notification_thing)
		

		if result != 1:
			if item_id in cached_items_data:
				var item_name = str(item_id)
				item_name = cached_items_data[item_id]
			
			var result_notification = DOWNLOAD_PROGRESS_THING.instance()
			result_notification.life_timer = 2.0
			DownloadProgress.add_notification(result_notification, true)
			result_notification.type = HBDownloadProgressThing.TYPE.ERROR
			result_notification.text = "Error downloading item id %d, error: %d" % [item_id, result]
			Log.log(self, "Error downloading UGC item id %d, error: %d" % [item_id, result])
		updating_items.erase(item_id)

func _on_item_created(result, file_id, tos):
	emit_signal("item_created", result, file_id, tos)

func _on_item_updated(result, tos):
	emit_signal("item_update_result", result, tos)
	
func _on_show_success(item_id):
	var thing = success_install_things[item_id]
	var data = cached_items_data[item_id]
	thing.text = "Succesfully installed %s!" % [data.title]
	success_install_things.erase(item_id)
	DownloadProgress.add_notification(thing, true)
	print("HSOWING SUCC")
	
func _on_ugc_query_completed(update_handle, result, number_of_results, number_of_matching_results, cached):
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
func create_item():
	Steam.createItem(Steam.getAppID(), WORKSHOP_FILE_TYPES.COMMUNITY)
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
func get_user_item_vote(item_id):
	if item_id in ugc_data.skipped_votes:
		return USER_ITEM_VOTE.SKIP
	else:
		Steam.getUserItemVote(item_id)
		var r = yield(Steam, "get_item_vote_result")
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
