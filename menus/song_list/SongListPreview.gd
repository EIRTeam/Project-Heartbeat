extends HBMenu

onready var preview_texture_rect = get_node("SongListPreview/VBoxContainer/TextureRect")

const DEFAULT_IMAGE_PATH = "res://graphics/no_preview.png"
var default_image_texture = preload("res://graphics/no_preview.png")

func _ready():
	default_image_texture = preview_texture_rect.texture

func select_song(song: HBSong):
	var bpm = "UNK"
	bpm = song.bpm
	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/BPMLabel.text = "%s BPM" % bpm

	var song_meta = song.get_meta_string()

	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/SongMetaLabel.text = PoolStringArray(song_meta).join('\n')
	$SongListPreview/VBoxContainer/TitleLabel.text = song.title
	var auth = ""
	if song.artist_alias != "":
		auth = song.artist_alias
	else:
		auth = song.artist
		
	$SongListPreview/VBoxContainer/HBoxContainer/AuthorLabel.text = auth
		
	var image_path = song.get_song_preview_res_path()
	if image_path != DEFAULT_IMAGE_PATH:
		preview_texture_rect.texture = ImageTexture.new()
		var image = HBUtils.image_from_fs(image_path)
		preview_texture_rect.texture.create_from_image(image, Texture.FLAGS_DEFAULT)
	else:
		$SongListPreview/VBoxContainer/TextureRect.texture = default_image_texture
