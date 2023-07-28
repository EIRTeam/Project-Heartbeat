extends HBoxContainer
@onready var title_label = get_node("TitleLabel")
@onready var circle_text_rect = get_node("CircleLabel")
@onready var difficulty_label = get_node("DifficultyLabel")
var song: HBSong: set = set_song
var difficulty : set = set_difficulty

func set_song(value):
	song = value
	title_label.text_2 = song.get_visible_title()
	circle_text_rect.hide()
	if song.hide_artist_name:
		title_label.text_1 = ""
	elif song.artist_alias != "":
		title_label.text_1 = song.artist_alias
	else:
		title_label.text_1 = song.artist
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	
	if circle_logo_path:
#		author_label.hide()
		var token = SongAssetLoader.request_asset_load(song, [SongAssetLoader.ASSET_TYPES.CIRCLE_LOGO])
		token.assets_loaded.connect(_on_assets_loaded)
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
		if circle_text_rect.texture and circle_text_rect.texture.get_image():
			var image = circle_text_rect.texture.get_image() as Image
			var ratio = image.get_width() / image.get_height()
			var new_size = Vector2(size.y * ratio, size.y)
			new_size.x = clamp(new_size.x, 0, 250)
			circle_text_rect.custom_minimum_size = new_size
		else:
			circle_text_rect.custom_minimum_size = Vector2.ZERO
			circle_text_rect.size = Vector2.ZERO

func _ready():
	connect("resized", Callable(self, "_on_resized"))
	_on_resized()

func _on_assets_loaded(token: SongAssetLoader.AssetLoadToken):
#	author_label.hide()
	var circle_logo: Texture2D = token.get_asset(SongAssetLoader.ASSET_TYPES.CIRCLE_LOGO)
	if circle_logo:
		circle_text_rect.show()
		circle_text_rect.texture = circle_logo
	else:
		circle_text_rect = null
	_on_resized()
