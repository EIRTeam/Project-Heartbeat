extends Window

var current_song: HBSong
var current_resource_pack: HBResourcePack
@onready var compliance_checkbox = get_node("MarginContainer/VBoxContainer/CheckBox")
@onready var upload_button = get_node("MarginContainer/VBoxContainer/UploadButton")
@onready var data_label = get_node("MarginContainer/VBoxContainer/DataLabel")
@onready var description_line_edit = get_node("MarginContainer/VBoxContainer/DescriptionLineEdit")
@onready var title_line_edit = get_node("MarginContainer/VBoxContainer/TitleLineEdit")
@onready var changelog_label = get_node("MarginContainer/VBoxContainer/Label4")
@onready var changelog_line_edit = get_node("MarginContainer/VBoxContainer/UpdateDescriptionLineEdit")

@onready var upload_dialog = get_node("UploadDialog")
@onready var post_upload_dialog = get_node("PostUploadDialog")
@onready var error_dialog = get_node("ErrorDialog")
@onready var file_not_found_dialog = get_node("FileNotFoundDialog")
@onready var upload_status_label = get_node("UploadDialog/Panel/MarginContainer/VBoxContainer/Label")
@onready var upload_progress_bar = get_node("UploadDialog/Panel/MarginContainer/VBoxContainer/ProgressBar")
const LOG_NAME = "WorkshopUploadForm"

var uploading_new = false
var uploading_id = null

enum MODE {
	SONG,
	RESOURCE_PACK
}

@export var upload_form_mode: MODE = MODE.SONG

const UGC_STATUS_TEXTS = {
	0: "Invalid, BUG?",
	1: "Processing configuration data",
	2: "Reading and processing content files",
	3: "Uploading content to Steam",
	4: "Uploading preview image file",
	5: "Committing changes"
}

var ERR_MAP = {
	Steam.RESULT_OK: "",
	Steam.RESULT_FAIL: "Generic failure",
	Steam.RESULT_INVALID_PARAM: "Invalid parameter",
	Steam.RESULT_ACCESS_DENIED: "The user doesn't own a license for the provided app ID.",
	Steam.RESULT_FILE_NOT_FOUND: "The provided content folder is not valid.",
	Steam.RESULT_LIMIT_EXCEEDED: "The preview image is too large, it must be less than 1 Megabyte; or there is not enough space available on your Steam Cloud."
}

func _ready():
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider
		ugc.connect("item_created", Callable(self, "_on_item_created"))
		ugc.connect("item_update_result", Callable(self, "_on_item_updated"))
		ugc.connect("ugc_details_request_done", Callable(self, "_on_ugc_details_request_done"))
	compliance_checkbox.connect("toggled", Callable(self, "_on_compliance_checkbox_toggled"))
	post_upload_dialog.connect("confirmed", Callable(self, "_on_post_upload_accepted"))
	upload_button.connect("pressed", Callable(self, "start_upload"))
	file_not_found_dialog.connect("confirmed", Callable(self, "_on_file_not_found_confirmed"))
	file_not_found_dialog.get_cancel_button().connect("pressed", Callable(self, "hide"))
func _on_compliance_checkbox_toggled(pressed):
	upload_button.disabled = !pressed
	
func _on_file_not_found_confirmed():
	match mode:
		MODE.SONG:
			current_song.ugc_id = 0
			current_song.ugc_service_name = ""
			set_song(current_song)
		MODE.RESOURCE_PACK:
			current_resource_pack.ugc_id = 0
			current_resource_pack.ugc_service_name = ""
	
func set_resource_pack(resource_pack: HBResourcePack):
	upload_form_mode = MODE.RESOURCE_PACK
	current_resource_pack = resource_pack
	
	var ugc = PlatformService.service_provider.ugc_provider
	changelog_line_edit.text = ""
	description_line_edit.text = ""
	
	if not FileAccess.file_exists(resource_pack.get_pack_icon_path()):
		error_dialog.dialog_text = "Your pack needs an icon to be uploaded to the workshop!"
		error_dialog.popup_centered()
		await error_dialog.hide
		hide()
		return
	
	if resource_pack.ugc_service_name == ugc.get_ugc_service_name():
		changelog_label.show()
		changelog_line_edit.show()
		ugc.get_item_details(resource_pack.ugc_id)
		Log.log(self, "Song has been uploaded previously, requesting data.")
	else:
		Log.log(self, "Song hasn't been uploaded before to UGC.")
		changelog_label.hide()
		changelog_line_edit.hide()
		title_line_edit.text = resource_pack.pack_name
		data_label.text = "Updating new item: %s" % resource_pack.pack_name
	
func set_song(song: HBSong):
	upload_form_mode = MODE.SONG
	current_song = song
	var ugc = PlatformService.service_provider.ugc_provider
	changelog_line_edit.text = ""
	description_line_edit.text = ""
	if song.ugc_service_name == ugc.get_ugc_service_name():
		changelog_label.show()
		changelog_line_edit.show()
		ugc.get_item_details(song.ugc_id)
		Log.log(self, "Song has been uploaded previously, requesting data.")
	else:
		Log.log(self, "Song hasn't been uploaded before to UGC.")
		changelog_label.hide()
		changelog_line_edit.hide()
		title_line_edit.text = song.get_sanitized_field("title")
		data_label.text = "Updating new item: %s" % song.get_sanitized_field("title")
		
func do_metadata_size_check(dict: Dictionary) -> bool:
	if JSON.new().stringify(dict).to_utf8_buffer().size() > 5000:
		error_dialog.dialog_text = "There was an error uploading your item, %s" % ["Metadata encoding failed, maybe make the title or difficulty names smaller?"]
		error_dialog.popup_centered()
		return false
	return true
		
func start_upload():
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider
		if Steam.getAppOwner() != Steam.getSteamID():
			error_dialog.dialog_text = """
			There was an error uploading your item:
			Content can't be uploaded to the Steam workshop from a family shared copy of the game, this is a limitation imposed by Steam.
			"""
			error_dialog.popup_centered()
			return
		var has_service_name = false
		match mode:
			MODE.RESOURCE_PACK:
				if current_resource_pack.ugc_service_name == ugc.get_ugc_service_name():
					has_service_name = true
					uploading_new = false
					upload_resource_pack(current_resource_pack, current_resource_pack.ugc_id)
			MODE.SONG:
				if not do_metadata_size_check(get_song_meta_dict()):
					return
				if current_song.ugc_service_name == ugc.get_ugc_service_name():
					has_service_name = true
					uploading_new = false
					upload_song(current_song, current_song.ugc_id)
		if not has_service_name:
			uploading_new = true
			ugc.create_item()
func _on_item_created(result, file_id, tos):
	var ugc = PlatformService.service_provider.ugc_provider
	if result == 1:
		match mode:
			MODE.SONG:
				current_song.ugc_id = file_id
				current_song.ugc_service_name = ugc.get_ugc_service_name()
				current_song.save_song()
				upload_song(current_song, file_id)
			MODE.RESOURCE_PACK:
				current_resource_pack.ugc_id = file_id
				current_resource_pack.ugc_service_name = ugc.get_ugc_service_name()
				current_resource_pack.save_pack()
				upload_resource_pack(current_resource_pack, file_id)
	else:
		print("CREATION ERR!", result)
		pass
		
func _on_ugc_details_request_done(result, data):
	if result == 1:
		if (current_resource_pack and current_resource_pack.ugc_id == data.item_id) \
				or (current_song and data.item_id == current_song.ugc_id):
			data_label.text = "Updating existing item: %s" % data.title
			title_line_edit.text = data.title
			description_line_edit.text = data.description
	elif result == 9: # File not found, possibly because the user deleted it
		file_not_found_dialog.popup_centered()
		
func _process(delta):
	if uploading_id:
		var ugc = PlatformService.service_provider.ugc_provider
		var progress = ugc.get_update_progress(uploading_id)
		upload_status_label.text = UGC_STATUS_TEXTS[progress.status]
		if progress.total > 0:
			upload_progress_bar.value = progress.processed/float(progress.total)
			
func get_song_meta_dict() -> Dictionary:
	var serialized = current_song.serialize()
	var out_dir = {}
	for field in ["title", "charts", "type", "romanized_title"]:
		if field in serialized:
			out_dir[field] = serialized[field]
	return out_dir
	
func upload_song(song: HBSong, ugc_id):
	var handle: int = Steam.createQueryUGCDetailsRequest([ugc_id])
	Steam.setAllowCachedResponse(handle, 0)
	Steam.setReturnChildren(handle, true)
	Steam.sendQueryUGCRequest(handle)
	var new_handle := -1
	if new_handle != Steam.UGC_UPDATE_HANDLE_INVALID:
		while new_handle != handle:
			var data: Array = await Steam.ugc_query_completed
			new_handle = data[0]
			
		var result: Dictionary = Steam.getQueryUGCResult(handle, 0)
		if result.result == Steam.RESULT_OK:
			var dependencies: Dictionary = Steam.getQueryUGCChildren(handle, 0, result.num_children)
			for child_i in range(result.num_children):
				var child_ugc_id := dependencies.children[child_i] as int
				Steam.removeDependency(ugc_id, child_ugc_id)
	if song.skin_ugc_id != 0:
		Steam.addDependency(ugc_id, song.skin_ugc_id)
	var ugc = PlatformService.service_provider.ugc_provider
	var update_id = ugc.start_item_update(ugc_id)
	uploading_id = update_id
	ugc.set_item_title(update_id, title_line_edit.text)
	ugc.set_item_description(update_id, description_line_edit.text)
	song.save_chart_info()
	var out_dir = get_song_meta_dict()
	ugc.set_item_metadata(update_id, JSON.stringify(out_dir))
	ugc.set_item_content_path(update_id, ProjectSettings.globalize_path(current_song.path))
	if uploading_new:
		var video_id = YoutubeDL.get_video_id(song.youtube_url)
		if video_id:
			ugc.add_item_preview_video(update_id, video_id)
	ugc.set_item_preview(update_id, ProjectSettings.globalize_path(current_song.get_song_preview_res_path()))

	var tags := ["Charts"]
	for chart in song.charts:
		if song.charts[chart].has("stars"):
			var stars: float = song.charts[chart].stars
			for diff_string in HBGame.CHART_DIFFICULTY_TAGS:
				var min_stars: float = HBGame.CHART_DIFFICULTY_TAGS[diff_string][0]
				var max_stars: float = HBGame.CHART_DIFFICULTY_TAGS[diff_string][1]
				if stars >= min_stars and stars <= max_stars:
					if not diff_string in tags:
						tags.push_back(diff_string)

	Steam.setItemTags(update_id, tags)
	if uploading_new:
		ugc.submit_item_update(update_id, "Initial upload")
	else:
		ugc.submit_item_update(update_id, changelog_line_edit.text)
	upload_dialog.popup_centered()
	
func upload_resource_pack(resource_pack: HBResourcePack, ugc_id):
	var ugc = PlatformService.service_provider.ugc_provider
	var update_id = ugc.start_item_update(ugc_id)
	uploading_id = update_id
	ugc.set_item_title(update_id, title_line_edit.text)
	ugc.set_item_description(update_id, description_line_edit.text)
	ugc.set_item_metadata(update_id, JSON.stringify(resource_pack.serialize()))
	ugc.set_item_content_path(update_id, ProjectSettings.globalize_path(resource_pack._path))
	ugc.set_item_preview(update_id, ProjectSettings.globalize_path(resource_pack.get_pack_icon_path()))

	var tags := []

	if resource_pack.is_skin():
		Steam.setItemTags(update_id, ["Skins"])
	else:
		Steam.setItemTags(update_id, ["Note Packs"])
	if uploading_new:
		ugc.submit_item_update(update_id, "Initial upload")
	else:
		ugc.submit_item_update(update_id, changelog_line_edit.text)
	upload_dialog.popup_centered()
	
func _on_item_updated(result, tos):
	upload_dialog.hide()
	uploading_id = null
	if result == 1:
		var text = """Item uploaded succesfully, you wil now be redirected to your item's workshop page,
		if this is the first time you upload this item you will need to set your song's visibility and if you've never uploaded
		a workshop item before you will need to accept the workshop's terms of service.'"""
		post_upload_dialog.dialog_text = text
		post_upload_dialog.popup_centered()
		match mode:
			MODE.SONG:
				current_song.save_song()
			MODE.RESOURCE_PACK:
				current_resource_pack.save_pack()
	else:
		var ugc = PlatformService.service_provider.ugc_provider
		error_dialog.dialog_text = "There was an error uploading your item, %s" % [ERR_MAP.get(result, "Unknown Error")]
		if uploading_new:
			match mode:
				MODE.SONG:
					current_song.ugc_id = 0
					current_song.ugc_service_name = ""
					current_song.save_song()
					ugc.delete_item(current_song.ugc_id)
					
					
				MODE.RESOURCE_PACK:
					current_resource_pack.ugc_id = 0
					current_resource_pack.ugc_service_name = ""
					current_resource_pack.save_pack()
					ugc.delete_item(current_resource_pack.ugc_id)
		error_dialog.popup_centered()
	
func _on_post_upload_accepted():
	match mode:
		MODE.SONG:
			Steam.activateGameOverlayToWebPage("steam://url/CommunityFilePage/%d" % [current_song.ugc_id])
		MODE.RESOURCE_PACK:
			Steam.activateGameOverlayToWebPage("steam://url/CommunityFilePage/%d" % [current_resource_pack.ugc_id])
			
	hide()
