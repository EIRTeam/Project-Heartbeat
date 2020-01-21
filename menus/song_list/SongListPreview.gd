extends HBMenu

onready var preview_texture_rect = get_node("SongListPreview/VBoxContainer/SongCoverPanel/TextureRect")

const DEFAULT_IMAGE_PATH = "res://graphics/no_preview.png"
var default_image_texture = preload("res://graphics/no_preview.png")

func _ready():
	default_image_texture = preview_texture_rect.texture
	connect("resized", self, "_on_resized")
	_on_resized()
func select_song(song: HBSong):
	var bpm = "UNK"
	bpm = song.bpm
	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/BPMLabel.text = "%s BPM" % bpm

	var song_meta = song.get_meta_string()

	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/SongMetaLabel.text = PoolStringArray(song_meta).join('\n')
	$SongListPreview/VBoxContainer/TitleLabel.text = song.title
	var auth = ""
	if song.artist_alias:
		auth = song.artist_alias
	else:
		auth = song.artist
	if song.circle_image:
		$SongListPreview/VBoxContainer/AuthorInfo.hide()
		var circle_texture = ImageTexture.new()
		var circle_image = HBUtils.image_from_fs(song.get_song_circle_image_res_path())
		circle_texture.create_from_image(circle_image, Texture.FLAGS_DEFAULT)
		$SongListPreview/VBoxContainer/CirclePanel/MarginContainer/TextureRect2.texture = circle_texture
		$SongListPreview/VBoxContainer/CirclePanel.show()
	else:
		$SongListPreview/VBoxContainer/CirclePanel.hide()
		$SongListPreview/VBoxContainer/AuthorInfo.show()
	if song.original_title:
		$SongListPreview/VBoxContainer/OriginalTitleLabel.show()
		$SongListPreview/VBoxContainer/OriginalTitleLabel.text = song.original_title
	else:
		$SongListPreview/VBoxContainer/OriginalTitleLabel.hide()
		
	$SongListPreview/VBoxContainer/AuthorInfo/AuthorLabel.text = auth
		
	var image_path = song.get_song_preview_res_path()
	if image_path != DEFAULT_IMAGE_PATH:
		$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.texture = ImageTexture.new()
		var image = HBUtils.image_from_fs(image_path)
		$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.texture.create_from_image(image, Texture.FLAGS_DEFAULT)
	else:
		$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.texture = default_image_texture

func _on_resized():
	$SongListPreview/VBoxContainer/SongCoverPanel/TextureRect.rect_min_size.y = rect_size.x
	$SongListPreview/VBoxContainer/SongCoverPanel.rect_min_size.y = rect_size.x
