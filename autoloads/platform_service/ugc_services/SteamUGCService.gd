extends HBUGCService

class_name SteamUGCService

enum WORKSHOP_FILE_TYPES {
	COMMUNITY = 0,
	MICROTRANSACTION = 1
}

func _init():
	Steam.connect("item_created", self, "_on_item_created")
	Steam.connect("item_updated", self, "_on_item_updated")
func _on_item_created(result, file_id, tos):
	emit_signal("item_created", result, file_id, tos)

func _on_item_updated(result, tos):
	emit_signal("item_update_result", result, tos)
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
func get_ugc_service_name():
	return "Steam Workshop"
func submit_item_update(update_id, change_note: String):
	Steam.submitItemUpdate(update_id, change_note)
