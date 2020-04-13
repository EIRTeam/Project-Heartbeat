extends WindowDialog

var current_song: HBSong
onready var compliance_checkbox = get_node("MarginContainer/VBoxContainer/CheckBox")
onready var upload_button = get_node("MarginContainer/VBoxContainer/UploadButton")
onready var data_label = get_node("MarginContainer/VBoxContainer/DataLabel")
onready var description_line_edit = get_node("MarginContainer/VBoxContainer/DescriptionLineEdit")
onready var title_line_edit = get_node("MarginContainer/VBoxContainer/TitleLineEdit")
onready var changelog_label = get_node("MarginContainer/VBoxContainer/Label4")
onready var changelog_line_edit = get_node("MarginContainer/VBoxContainer/UpdateDescriptionLineEdit")

onready var upload_dialog = get_node("UploadDialog")
onready var post_upload_dialog = get_node("PostUploadDialog")
onready var error_dialog = get_node("ErrorDialog")
onready var file_not_found_dialog = get_node("FileNotFoundDialog")
onready var upload_status_label = get_node("UploadDialog/Panel/MarginContainer/VBoxContainer/Label")
onready var upload_progress_bar = get_node("UploadDialog/Panel/MarginContainer/VBoxContainer/ProgressBar")
const LOG_NAME = "WorkshopUploadForm"

var uploading_new = false
var uploading_id = null

const UGC_STATUS_TEXTS = {
	0: "Invalid, BUG?",
	1: "Processing configuration data",
	2: "Reading and processing content files",
	3: "Uploading content to Steam",
	4: "Uploading preview image file",
	5: "Committing changes"
}

func _ready():
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider
		ugc.connect("item_created", self, "_on_item_created")
		ugc.connect("item_update_result", self, "_on_item_updated")
		ugc.connect("ugc_details_request_done", self, "_on_ugc_details_request_done")
	compliance_checkbox.connect("toggled", self, "_on_compliance_checkbox_toggled")
	post_upload_dialog.connect("confirmed", self, "_on_post_upload_accepted")
	upload_button.connect("pressed", self, "start_upload_song")
	file_not_found_dialog.connect("confirmed", self, "_on_file_not_found_confirmed")
	file_not_found_dialog.get_close_button().hide()
	file_not_found_dialog.get_cancel().connect("pressed", self, "hide")
func _on_compliance_checkbox_toggled(pressed):
	upload_button.disabled = !pressed
	
func _on_file_not_found_confirmed():
	current_song.ugc_id = 0
	current_song.ugc_service_name = ""
	set_song(current_song)
	
func set_song(song: HBSong):
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
		title_line_edit.text = song.title
		
func start_upload_song():
	if PlatformService.service_provider.implements_ugc:
		var ugc = PlatformService.service_provider.ugc_provider
		if current_song.ugc_service_name == ugc.get_ugc_service_name():
			uploading_new = false
			upload_song(current_song, current_song.ugc_id)
		else:
			uploading_new = true
			ugc.create_item()
func _on_item_created(result, file_id, tos):
	var ugc = PlatformService.service_provider.ugc_provider
	if result == 1:
		current_song.ugc_id = file_id
		print("UGC ", file_id)
		current_song.ugc_service_name = ugc.get_ugc_service_name()
		upload_song(current_song, file_id)
	else:
		print("CREATION ERR!", result)
		pass
		
func _on_ugc_details_request_done(result, data):
	if result == 1:
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
func upload_song(song: HBSong, ugc_id):
	var ugc = PlatformService.service_provider.ugc_provider
	var update_id = ugc.start_item_update(ugc_id)
	uploading_id = update_id
	ugc.set_item_title(update_id, title_line_edit.text)
	ugc.set_item_description(update_id, description_line_edit.text)
	ugc.set_item_metadata(update_id, JSON.print(current_song.serialize()))
	ugc.set_item_content_path(update_id, ProjectSettings.globalize_path(current_song.path))
	if uploading_new:
		ugc.add_item_preview_video(update_id, YoutubeDL.get_video_id(song.youtube_url))
	ugc.set_item_preview(update_id, ProjectSettings.globalize_path(current_song.get_song_preview_res_path()))

	Steam.setItemTags(update_id, ["Charts"])
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
		current_song.save_song()
	else:
		var ugc = PlatformService.service_provider.ugc_provider
		error_dialog.dialog_text = "There was an error uploading your item, error code %d" % [result]
		if uploading_new:
			ugc.delete_item(current_song.ugc_id)
			current_song.ugc_id = 0
			current_song.ugc_service_name = ""
		error_dialog.popup_centered()
		current_song.save_song()
	
func _on_post_upload_accepted():
	Steam.activateGameOverlayToWebPage("steam://url/CommunityFilePage/%d" % [current_song.ugc_id])
	hide()
