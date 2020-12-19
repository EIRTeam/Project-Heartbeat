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
	circle_text_rect.hide()
	author_label.visible = !song.hide_artist_name
	if song.artist_alias != "":
		author_label.text = song.artist_alias
	else:
		author_label.text = song.artist
	var circle_logo_path = song.get_song_circle_logo_image_res_path()
	if circle_logo_path:
		var task = SongAssetLoadAsyncTask.new(["circle_logo"], song)
		task.connect("assets_loaded", self, "_on_assets_loaded")
		AsyncTaskQueue.queue_task(task)
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
			new_size.x = clamp(new_size.x, 0, 350)
			circle_text_rect.rect_min_size = new_size
		else:
			circle_text_rect.rect_min_size = Vector2.ZERO
			circle_text_rect.rect_size = Vector2.ZERO

func _ready():
	connect("resized", self, "_on_resized")
	_on_resized()

func _on_assets_loaded(assets):
#	author_label.hide()
	if assets.circle_logo:
		circle_text_rect.show()
		circle_text_rect.texture = assets.circle_logo
	else:
		circle_text_rect = null
	_on_resized()
