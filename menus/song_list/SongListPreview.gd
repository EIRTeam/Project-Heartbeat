extends HBMenu

@onready var author_info = get_node("SongListPreview/VBoxContainer/AuthorInfo")
@onready var cover_art_texture2 = get_node("%CoverTextureRectShadow")
@onready var cover_art_texture = get_node("%CoverTextureRect")
@onready var circle_panel = get_node("SongListPreview/VBoxContainer/CirclePanel")
@onready var circle_texture_rect = get_node("SongListPreview/VBoxContainer/CirclePanel/MarginContainer/TextureRect2")
@onready var song_cover_panel = get_node("SongListPreview/VBoxContainer/SongCoverPanel")
const DEFAULT_IMAGE_PATH = "res://graphics/no_preview.png"
var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")
var current_song: HBSong
var currently_displayed_song: HBSong
@onready var list_tween := Threen.new()
signal song_assets_loaded(song, assets: SongAssetLoader.AssetLoadToken)
func _ready():
	super._ready()
	is_ready = true
	connect("resized", Callable(self, "_on_resized"))
	hide()
	add_child(list_tween)
	_on_resized()
	
const ANIMATION_DURATION = 0.25
	
var startup_song_assets
	
var is_ready = false

func _notification(what):
	if (what == NOTIFICATION_POST_ENTER_TREE and is_ready) or what == NOTIFICATION_READY:
		if currently_displayed_song != current_song:
			do_asset_load()
		else:
			animate_cover_art()
	
func animate_cover_art():
	list_tween.remove_all()
	cover_art_texture.pivot_offset = cover_art_texture.size / 2.0
	cover_art_texture2.position = Vector2(20, 20)
	var x_target = song_cover_panel.get_theme_constant("offset_left")
	cover_art_texture.modulate.a = 0.0
	list_tween.interpolate_property(cover_art_texture, "position:x", 500, x_target, ANIMATION_DURATION, Threen.TRANS_QUAD, Threen.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "position:y", 0, 0, ANIMATION_DURATION, Threen.TRANS_QUAD, Threen.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "modulate:a", 0.0, 1.0, ANIMATION_DURATION, Threen.TRANS_LINEAR, Threen.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "rotation", deg_to_rad(20), deg_to_rad(-4), ANIMATION_DURATION, Threen.TRANS_QUAD, Threen.EASE_OUT)
	list_tween.start()
func _on_song_assets_loaded(token: SongAssetLoader.AssetLoadToken):
	if token.song != current_song:
		return
	var circle_image := token.get_asset(SongAssetLoader.ASSET_TYPES.CIRCLE_IMAGE)
	if circle_image:
		author_info.hide()
		circle_texture_rect.texture = circle_image
		circle_panel.show()
	else:
		circle_panel.hide()
		author_info.show()
	var preview_image := token.get_asset(SongAssetLoader.ASSET_TYPES.PREVIEW)
	if preview_image:
		cover_art_texture.texture = preview_image
	else:
		cover_art_texture.texture = DEFAULT_IMAGE_TEXTURE
	cover_art_texture2.texture = cover_art_texture.texture
	
	cover_art_texture.material = null
	cover_art_texture2.material = null
	
	if cover_art_texture.texture is DIVASpriteSet.DIVASprite:
		cover_art_texture.material = cover_art_texture.texture.get_material()
		cover_art_texture2.material = cover_art_texture.texture.get_material()
	
	circle_texture_rect.material = null
	if circle_texture_rect.texture is DIVASpriteSet.DIVASprite:
		circle_texture_rect.material = circle_texture_rect.texture.get_material()
	
	animate_cover_art()
	currently_displayed_song = current_song
	emit_signal("song_assets_loaded", token)
	
func do_asset_load():
	var task = SongAssetLoader.request_asset_load(
		current_song,
		[
			SongAssetLoader.ASSET_TYPES.CIRCLE_IMAGE,
			SongAssetLoader.ASSET_TYPES.PREVIEW,
			SongAssetLoader.ASSET_TYPES.BACKGROUND,
			SongAssetLoader.ASSET_TYPES.CIRCLE_LOGO
		]
	)
	task.assets_loaded.connect(_on_song_assets_loaded)
func select_song(song: HBSong):
	current_song = song
	show()
	if is_inside_tree():
		do_asset_load()
	
	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/BPMLabel.text = "%s BPM" % song.bpm_string
	
	var song_meta = song.get_meta_string()
	
	$SongListPreview/VBoxContainer/Control/Panel2/VBoxContainer/SongMetaLabel.text = '\n'.join(PackedStringArray(song_meta))
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
	
func _on_resized():
	song_cover_panel.custom_minimum_size.y = size.x
