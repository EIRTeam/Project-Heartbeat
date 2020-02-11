extends HBoxContainer
onready var title_label = get_node("TitleLabel")
onready var author_label = get_node("AuthorLabel")
onready var circle_text_rect = get_node("CircleLabel")
onready var difficulty_label = get_node("DifficultyLabel")
var song: HBSong setget set_song
var difficulty setget set_difficulty
func set_song(value):
	song = value
	title_label.text = song.get_visible_title()
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	if circle_logo_path:
		author_label.hide()
		circle_text_rect.show()
		var image = HBUtils.image_from_fs(circle_logo_path)
		var it = ImageTexture.new()
		it.create_from_image(image, Texture.FLAGS_DEFAULT)
		circle_text_rect.texture = it
		_on_resized()
	else:
		author_label.show()
		circle_text_rect.hide()
func set_difficulty(value):
	if not value:
		difficulty_label.hide()
	else:
		difficulty_label.show()
		difficulty = value
		difficulty_label.text = "[%s]" % value
		
func _on_resized():
	if circle_text_rect.texture:
		var image = circle_text_rect.texture.get_data() as Image
		var ratio = image.get_width() / image.get_height()
		var new_size = Vector2(rect_size.y * ratio, rect_size.y)
		new_size.x = clamp(new_size.x, 0, 250)
		circle_text_rect.rect_min_size = new_size

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()
