extends HBMenu

onready var preview_texture_rect = get_node("SongListPreview/VBoxContainer/SongCoverPanel/TextureRect")

const DEFAULT_IMAGE_PATH = "res://graphics/no_preview.png"
var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")
var current_task: SongAssetLoadAsyncTask
var current_song
signal song_assets_loaded(song, assets)
func _ready():
	connect("resized", self, "_on_resized")
	hide()
	_on_resized()
func _on_song_assets_loaded(assets):
	if "circle_image" in assets:
		$SongListPreview/VBoxContainer/AuthorInfo.hide()
		$SongListPreview/VBoxContainer/CirclePanel/MarginContainer/TextureRect2.texture = assets.circle_image
		$SongListPreview/VBoxContainer/CirclePanel.show()
	else:
		$SongListPreview/VBoxContainer/CirclePanel.hide()
		$SongListPreview/VBoxContainer/AuthorInfo.show()
	if "preview" in assets:
		$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.texture = assets.preview
	else:
		$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.texture = DEFAULT_IMAGE_TEXTURE
	emit_signal("song_assets_loaded", current_song, assets)
	
	
func select_song(song: HBSong):
	show()
	var bpm = "UNK"
	bpm = song.bpm
	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/BPMLabel.text = "%s BPM" % bpm

	var song_meta = song.get_meta_string()

	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/SongMetaLabel.text = PoolStringArray(song_meta).join('\n')
	$SongListPreview/VBoxContainer/TitleLabel.text = song.get_visible_title()
	var auth = ""
	if song.artist_alias:
		auth = song.artist_alias
	else:
		auth = song.artist

	if song.original_title:
		$SongListPreview/VBoxContainer/OriginalTitleLabel.show()
		$SongListPreview/VBoxContainer/OriginalTitleLabel.text = song.original_title
	else:
		$SongListPreview/VBoxContainer/OriginalTitleLabel.hide()
		
	$SongListPreview/VBoxContainer/AuthorInfo/AuthorLabel.text = auth
	
	if current_task:
		AsyncTaskQueue.abort_task(current_task)
		
	current_song = song
	
	current_task = SongAssetLoadAsyncTask.new(["circle_image", "preview", "background", "circle_logo"], song)
	current_task.connect("assets_loaded", self, "_on_song_assets_loaded")
	AsyncTaskQueue.queue_task(current_task)

func _on_resized():
	$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.rect_min_size.y = rect_size.x
	$SongListPreview/VBoxContainer/SongCoverPanel.rect_min_size.y = rect_size.x
