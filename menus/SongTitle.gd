extends HBoxContainer
@onready var title_label = get_node("TitleLabel")
@onready var author_label = get_node("AuthorLabel")
@onready var circle_text_rect = get_node("CircleLabel")
@onready var difficulty_label = get_node("DifficultyLabel")
var song: HBSong: set = set_song
var difficulty : set = set_difficulty

func queue_asset_load():
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	if circle_logo_path:
		var token := SongAssetLoader.request_asset_load(song, [SongAssetLoader.ASSET_TYPES.CIRCLE_LOGO])
		token.assets_loaded.connect(_on_assets_loaded)
	else:
		circle_text_rect.texture = null
		_on_resized()

func set_song(value):
	song = value
	
	var _title_label = get_node("TitleLabel")
	var _author_label = get_node("AuthorLabel")
	var _circle_text_rect = get_node("CircleLabel")
	
	_title_label.text = song.get_visible_title()
	_circle_text_rect.hide()
	_author_label.visible = !song.hide_artist_name
	if song.artist_alias != "":
		_author_label.text = song.artist_alias
	else:
		_author_label.text = song.artist
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	if is_inside_tree():
		queue_asset_load()
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
			var ratio = circle_text_rect.texture.get_width() / float(circle_text_rect.texture.get_height())
			circle_text_rect.custom_minimum_size.x = min(size.y * ratio, 350)
			circle_text_rect.custom_minimum_size.y = size.y
		else:
			circle_text_rect.custom_minimum_size = Vector2.ZERO
			circle_text_rect.size = Vector2.ZERO

func _ready():
	connect("resized", Callable(self, "_on_resized"))
	_on_resized()
	queue_asset_load()

func _on_assets_loaded(token: SongAssetLoader.AssetLoadToken):
#	author_label.hide()
	var circle_logo: Texture2D = token.get_asset(SongAssetLoader.ASSET_TYPES.CIRCLE_LOGO)
	
	if circle_logo:
		circle_text_rect.show()
		circle_text_rect.texture = circle_logo
	else:
		circle_text_rect.hide()
		circle_text_rect.texture = null
	_on_resized()
