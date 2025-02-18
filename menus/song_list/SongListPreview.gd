extends HBMenu

@onready var author_info: Control = get_node("%AuthorInfoContainer")
@onready var cover_art_texture_shadow: TextureRect = get_node("%CoverTextureRectShadow")
@onready var cover_art_texture: TextureRect = get_node("%CoverTextureRect")
@onready var circle_panel: Control = get_node("%CircleImagePanel")
@onready var circle_texture_rect: TextureRect = get_node("%CircleTextureRect")
@onready var song_cover_panel: Control = get_node("%SongCoverPanel")
@onready var meta_container: Control = get_node("%MetaContainer")

@onready var bpm_label: Label = get_node("%BPMLabel")
@onready var title_label: Label = get_node("%TitleLabel")
@onready var original_title_label: Label = get_node("%OriginalTitleLabel")
@onready var song_meta_label: Label = get_node("%SongMetaLabel")
@onready var author_label: Label = get_node("%AuthorLabel")
@onready var container: Control = get_node("SongListPreview")

enum QueuedType {
	NORMAL,
	UGC
}

class SelectedSongData:
	var song_ugc_id: int
	var song: HBSong
	var queued_type: QueuedType
	var queued_call: Callable
	var queue_valid := true
	
func _replace_song_data(song_data: SelectedSongData):
	if selected_song_data:
		selected_song_data.queue_valid = false
	selected_song_data = song_data
	

const DEFAULT_IMAGE_PATH = "res://graphics/no_preview.png"

var DEFAULT_IMAGE_TEXTURE = preload("res://graphics/no_preview_texture.png")

var update_queued := false
var selected_song_data: SelectedSongData

@onready var list_tween := Threen.new()

signal song_assets_loaded(song, assets: SongAssetLoader.AssetLoadToken)
	
const ANIMATION_DURATION := 0.25

func _queue_update():
	if not update_queued:
		update_queued = true
		_update.call_deferred()

func _update():
	if update_queued:
		if is_inside_tree() and selected_song_data and selected_song_data.queue_valid:
			update_queued = false
			selected_song_data.queued_call.call()
		# Not in tree, defer to when we are next visible

func _ready():
	super._ready()
	connect("resized", Callable(self, "_on_resized"))
	hide()
	add_child(list_tween)
	_on_resized()
	container.hide()

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE:
			_update()
	
func animate_cover_art():
	list_tween.remove_all()
	cover_art_texture.pivot_offset = cover_art_texture.size / 2.0
	cover_art_texture_shadow.position = Vector2(20, 20)
	var x_target = song_cover_panel.get_theme_constant("offset_left")
	cover_art_texture.modulate.a = 0.0
	list_tween.interpolate_property(cover_art_texture, "position:x", 500, x_target, ANIMATION_DURATION, Threen.TRANS_QUAD, Threen.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "position:y", 0, 0, ANIMATION_DURATION, Threen.TRANS_QUAD, Threen.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "modulate:a", 0.0, 1.0, ANIMATION_DURATION, Threen.TRANS_LINEAR, Threen.EASE_OUT)
	list_tween.interpolate_property(cover_art_texture, "rotation", deg_to_rad(20), deg_to_rad(-4), ANIMATION_DURATION, Threen.TRANS_QUAD, Threen.EASE_OUT)
	list_tween.start()

func _on_song_assets_loaded(token: SongAssetLoader.AssetLoadToken):
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
	cover_art_texture_shadow.texture = cover_art_texture.texture
	
	cover_art_texture.material = null
	cover_art_texture_shadow.material = null
	
	if cover_art_texture.texture is DIVASpriteSet.DIVASprite:
		cover_art_texture.texture.notify_visible()
		cover_art_texture.material = cover_art_texture.texture.get_fallback_material()
		cover_art_texture_shadow.material = cover_art_texture.texture.get_fallback_material()
	
	circle_texture_rect.material = null
	if circle_texture_rect.texture is DIVASpriteSet.DIVASprite:
		circle_texture_rect.texture.notify_visible()
		circle_texture_rect.material = circle_texture_rect.texture.get_fallback_material()
	
	animate_cover_art()
	emit_signal("song_assets_loaded", token)
	
func do_asset_load(song: HBSong) -> SongAssetLoader.AssetLoadToken:
	var task = SongAssetLoader.request_asset_load(
		song,
		[
			SongAssetLoader.ASSET_TYPES.CIRCLE_IMAGE,
			SongAssetLoader.ASSET_TYPES.PREVIEW,
			SongAssetLoader.ASSET_TYPES.BACKGROUND,
			SongAssetLoader.ASSET_TYPES.CIRCLE_LOGO
		]
	)
	return await task.assets_loaded

func select_song(song: HBSong):
	if selected_song_data and selected_song_data.queued_type == QueuedType.NORMAL:
		if selected_song_data.song == song:
			return
	var song_data := SelectedSongData.new()
	song_data.song = song
	song_data.queued_type = QueuedType.NORMAL
	song_data.queued_call = self._show_normal_song
	_replace_song_data(song_data)
	_queue_update()
	
func _show_normal_song():
	var song_data := selected_song_data
	var song := selected_song_data.song
	bpm_label.text = tr("{beats_per_minute} BPM").format({
		"beats_per_minute": int(song.bpm_string)
	})
	
	var song_meta = song.get_meta_string()
	
	song_meta_label.text = '\n'.join(PackedStringArray(song_meta))
	meta_container.show()
	title_label.text = song.get_visible_title()
	var auth = ""
	if song.artist_alias:
		auth = song.artist_alias
	else:
		auth = song.artist

	if song.original_title:
		original_title_label.show()
		original_title_label.text = song.original_title
	else:
		original_title_label.hide()
		
	author_label.text = auth
	var assets := await do_asset_load(selected_song_data.song)
	if not song_data.queue_valid:
		return
	_on_song_assets_loaded(assets)
	container.show()
	song_data.queue_valid = false
## Lets you select songs from UGC without having local information, use sparingly.
func select_ugc_song(ugc_id: int):
	if selected_song_data and selected_song_data.queued_type == QueuedType.UGC:
		if selected_song_data.song_ugc_id == ugc_id:
			return
	var song_data := SelectedSongData.new()
	song_data.song_ugc_id = ugc_id
	song_data.queued_type = QueuedType.UGC
	song_data.queued_call = self._show_ugc_song
	_replace_song_data(song_data)
	_queue_update()

func _show_ugc_song():
	var song_data := selected_song_data
	var query := HBSteamUGCQuery.create_query(SteamworksConstants.UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE) \
		.with_file_ids([selected_song_data.song_ugc_id])
	query.request_page(0)
	var query_result: HBSteamUGCQueryPageResult = await query.query_completed
	if query_result.results.size() > 0:
		if not song_data.queue_valid:
			return
		# We don't have that much info here...
		original_title_label.hide()
		meta_container.hide()
		circle_panel.hide()
		author_info.hide()
		
		var info := query_result.results[0]
		title_label.text = info.title
		var album_art := await HBUtils.request_image_url(query_result.results[0].preview_image_url)
		if not song_data.queue_valid:
			return
		if album_art.texture:
			cover_art_texture.texture = album_art.texture
			cover_art_texture_shadow.texture = album_art.texture
		else:
			cover_art_texture_shadow.texture = DEFAULT_IMAGE_TEXTURE
		animate_cover_art()
func _on_resized():
	song_cover_panel.custom_minimum_size.y = size.x
