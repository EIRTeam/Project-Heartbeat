extends WindowDialog

var current_song: HBSong
onready var error_label = get_node("ErrorLabel")
func _ready():
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider
		ugc.connect("item_created", self, "_on_item_created")
		ugc.connect("item_update_result", self, "_on_item_updated")
	start_upload_song(SongLoader.songs["getaway"])
func start_upload_song(song: HBSong):
	current_song = song
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider
		if song.ugc_service_name == ugc.get_ugc_service_name():
			upload_song()
		else:
			ugc.create_item()
func _on_item_created(result, file_id, tos):
	var ugc = PlatformService.service_provider.ugc_provider
	if result == 1:
		current_song.ugc_id = file_id
		print("UGC ", file_id)
		current_song.ugc_service_name = ugc.get_ugc_service_name()
		current_song.save_song()
		upload_song()
	else:
		print("CREATION ERR!")
		pass
		
func show_error(error: String):
	error_label.text = "Error uploading song: %s" % [error]
func upload_song():
	var ugc = PlatformService.service_provider.ugc_provider
	var ugc_id = current_song.ugc_id
	var update_id = ugc.start_item_update(ugc_id)
	ugc.set_item_title(update_id, current_song.title)
	ugc.set_item_description(update_id, "Test description!!")
	ugc.set_item_metadata(update_id, JSON.print(current_song.serialize()))
	ugc.set_item_content_path(update_id, ProjectSettings.globalize_path(current_song.path))
	ugc.set_item_preview(update_id, ProjectSettings.globalize_path(current_song.get_song_preview_res_path()))
	Steam.setItemTags(update_id, ["song"])
	ugc.submit_item_update(update_id, "Test!")
func _on_item_updated(result, tos):
	Steam.activateGameOverlayToWebPage("steam://url/CommunityFilePage/%d" % [current_song.ugc_id])
