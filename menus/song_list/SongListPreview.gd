extends HBMenu

onready var preview_texture_rect = get_node("SongListPreview/VBoxContainer/SongCoverPanel/TextureRect")

onready var author_info = get_node("SongListPreview/VBoxContainer/AuthorInfo")
onready var cover_art_texture2 = get_node("SongListPreview/VBoxContainer/SongCoverPanel/TextureRect/TextureRect2")
onready var cover_art_texture = get_node("SongListPreview/VBoxContainer/SongCoverPanel/TextureRect")
onready var circle_panel = get_node("SongListPreview/VBoxContainer/CirclePanel")
onready var circle_texture_rect = get_node("SongListPreview/VBoxContainer/CirclePanel/MarginContainer/TextureRect2")
onready var song_cover_panel = get_node("SongListPreview/VBoxContainer/SongCoverPanel")
const DEFAULT_IMAGE_PATH = "res://graphics/no_preview.png"
var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")
var current_task: SongAssetLoadAsyncTask
var current_song
onready var list_tween := Tween.new()
signal song_assets_loaded(song, assets)
func _ready():
	is_ready = true
	connect("resized", self, "_on_resized")
	hide()
	add_child(list_tween)
	_on_resized()
	
const ANIMATION_DURATION = 0.25
	
var startup_song_assets
	
var is_ready = false

func _notification(what):
	if (what == NOTIFICATION_POST_ENTER_TREE and is_ready) or what == NOTIFICATION_READY:
		if startup_song_assets:
			_on_song_assets_loaded(startup_song_assets)
		else:
			animate_cover_art()
	
func animate_cover_art():
	list_tween.stop_all()
	preview_texture_rect.rect_pivot_offset = preview_texture_rect.rect_size / 2.0
	cover_art_texture2.rect_position = Vector2(20, 20)
	var x_target = song_cover_panel.get_constant("margin_left")
	cover_art_texture.modulate.a = 0.0
	list_tween.interpolate_property(cover_art_texture, "rect_position:x", 500, x_target, ANIMATION_DURATION, Tween.TRANS_QUAD, Tween.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "rect_position:y", 0, 0, ANIMATION_DURATION, Tween.TRANS_QUAD, Tween.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "modulate:a", 0.0, 1.0, ANIMATION_DURATION, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "rect_rotation", 20, -4, ANIMATION_DURATION, Tween.TRANS_QUAD, Tween.EASE_OUT)
	list_tween.start()
func _on_song_assets_loaded(assets):
	if not get_tree():
		startup_song_assets =  assets
	else:
		if "circle_image" in assets:
			author_info.hide()
			circle_texture_rect.texture = assets.circle_image
			circle_panel.show()
		else:
			circle_panel.hide()
			author_info.show()
		if "preview" in assets:
			cover_art_texture.texture = assets.preview
		else:
			cover_art_texture.texture = DEFAULT_IMAGE_TEXTURE
		cover_art_texture2.texture = cover_art_texture.texture
		
		animate_cover_art()

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
