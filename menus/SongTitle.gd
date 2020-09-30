extends HBoxContainer
onready var title_label = get_node("TitleLabel")
onready var author_label = get_node("AuthorLabel")
onready var circle_text_rect = get_node("CircleLabel")
onready var difficulty_label = get_node("DifficultyLabel")
var song: HBSong setget set_song
var difficulty setget set_difficulty

var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()


func set_song(value):
	song = value
	title_label.text = song.get_visible_title()
	circle_text_rect.hide()
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	if circle_logo_path:
#		author_label.hide()
		background_song_assets_loader.load_song_assets(song, ["circle_logo"])
	else:
		circle_text_rect.texture = null
		_on_resized()
func set_difficulty(value):
	if not value:
		difficulty_label.hide()
	else:
		difficulty_label.show()
		difficulty = value
		difficulty_label.text = "[%s]" % value
		
func _on_resized():
	if circle_text_rect:
		if circle_text_rect.texture and circle_text_rect.texture.get_data():
			var image = circle_text_rect.texture.get_data() as Image
			var ratio = image.get_width() / image.get_height()
			var new_size = Vector2(rect_size.y * ratio, rect_size.y)
			new_size.x = clamp(new_size.x, 0, 250)
			circle_text_rect.rect_min_size = new_size
		else:
			circle_text_rect.rect_min_size = Vector2.ZERO
			circle_text_rect.rect_size = Vector2.ZERO

func _ready():
	connect("resized", self, "_on_resized")
	background_song_assets_loader.connect("song_assets_loaded", self, "_on_assets_loaded")
	_on_resized()

func _on_assets_loaded(song, assets):
#	author_label.hide()
	if assets.circle_logo:
		circle_text_rect.show()
		circle_text_rect.texture = assets.circle_logo
	else:
		circle_text_rect = null
	_on_resized()
