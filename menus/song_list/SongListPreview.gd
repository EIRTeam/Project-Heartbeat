extends HBMenu

onready var preview_texture_rect = get_node("SongListPreview/VBoxContainer/SongCoverPanel/TextureRect")

const DEFAULT_IMAGE_PATH = "res://graphics/no_preview.png"
var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")
var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()
func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
	background_song_assets_loader.connect("song_assets_loaded", self, "_on_song_assets_loaded")
func _on_song_assets_loaded(song, assets):
	if song.circle_image:
		$SongListPreview/VBoxContainer/AuthorInfo.hide()
		$SongListPreview/VBoxContainer/CirclePanel/MarginContainer/TextureRect2.texture = assets.circle_image
		$SongListPreview/VBoxContainer/CirclePanel.show()
	else:
		$SongListPreview/VBoxContainer/CirclePanel.hide()
		$SongListPreview/VBoxContainer/AuthorInfo.show()
	if song.preview_image:
		$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.texture = assets.preview
	else:
		$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.texture = DEFAULT_IMAGE_TEXTURE
func select_song(song: HBSong):
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
	
	background_song_assets_loader.load_song_assets(song, ["circle_image", "preview"])

func _on_resized():
	$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.rect_min_size.y = rect_size.x
	$SongListPreview/VBoxContainer/SongCoverPanel.rect_min_size.y = rect_size.x
