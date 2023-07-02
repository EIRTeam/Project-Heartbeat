class_name HBUGCService

# warning-ignore:unused_signal
signal item_created(result, file_id, tos)
# warning-ignore:unused_signal
signal item_update_result(result, tos)
# warning-ignore:unused_signal
signal ugc_details_request_done(result, details)
# warning-ignore:unused_signal
signal ugc_item_installed(type, item)
# warning-ignore:unused_signal
signal ugc_item_deleted(type, item)
# warning-ignore:unused_signal
signal ugc_item_downloaded(item)
# warning-ignore:unused_signal
signal ugc_song_meta_updated()

const UGC_DATA_PATH = "user://ugc.json"
var LOG_NAME = "HBUGCService"
var ugc_data = {
	"skipped_votes": []
}

enum USER_ITEM_VOTE {
	UPVOTE,
	DOWNVOTE,
	SKIP,
	NOT_VOTED
}

func _init():
	if FileAccess.file_exists(UGC_DATA_PATH):
		
		var file = FileAccess.open(UGC_DATA_PATH, FileAccess.READ)
		var err = FileAccess.get_open_error()
		if err == OK:
			var content = file.get_as_text()
			var test_json_conv = JSON.new()
			var json_err := test_json_conv.parse(content)
			var result = test_json_conv.data
			if json_err == OK:
				ugc_data = HBUtils.merge_dict(ugc_data, result)
			else:
				Log.log(self, "Error deserializing ugc data with error on line %d %s" % [result.error_line, result.error_string])
		else:
			Log.log(self, "Error loading UGC data, with error: %d" % [err])
	
func reload_ugc_songs():
	pass
func get_ugc_service_name():
	return null

func download_item(item_id: int):
	return
func create_item():
	return
func set_item_title(update_id, title: String):
	return
func set_item_description(update_id, description: String):
	return
func set_item_metadata(update_id, metadata: String):
	return
func set_item_content_path(update_id, content_path: String):
	return
func set_item_preview(update_id, preview_path: String):
	return
func start_item_update(published_id):
	return
func submit_item_update(update_id, change_note: String):
	return
func get_item_details(item_id):
	pass
func delete_item(item_id):
	pass
func get_update_progress(update_id):
	pass
	
func save_ugc_data():
	var file := FileAccess.open(UGC_DATA_PATH, FileAccess.WRITE)
	var json = JSON.stringify(ugc_data, "  ")
	file.store_string(json)
	
func skip_vote(item_id):
	ugc_data.skipped_votes.append(item_id)
	save_ugc_data()
func set_user_item_vote(item_id, vote):
	pass
func add_item_preview_video(update_id, video_id):
	pass
func get_user_item_vote(item_id):
	pass

func has_user_item_vote(item_id):
	pass
