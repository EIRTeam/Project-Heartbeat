class_name HBUGCService

signal item_created(result, file_id, tos)
signal item_update_result(result, tos)
signal ugc_details_request_done(result, details)
signal ugc_item_installed(type, item)
func get_ugc_service_name():
	return null

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
