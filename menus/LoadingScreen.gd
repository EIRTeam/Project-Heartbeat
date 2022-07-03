extends Control

var current_diff
var game_info: HBGameInfo
var is_loading_practice_mode = false
onready var title_label = get_node("LoadingScreenElements/Panel2/Panel3/MarginContainer/HBoxContainer/VBoxContainer/TitleLabel")
onready var meta_label = get_node("LoadingScreenElements/Panel2/Panel3/MarginContainer/HBoxContainer/VBoxContainer/MetaLabel")
onready var loadingu_label = get_node("LoadingScreenElements/Panel2/Panel3/MarginContainer/HBoxContainer/LoadinguLabel")
onready var album_cover = get_node("LoadingScreenElements/Panel2/Panel3/MarginContainer/HBoxContainer/TextureRect")
onready var loading_panel = get_node("LoadingScreenElements/Panel2")
onready var appear_tween := Tween.new()
onready var disappear_tween = Tween.new()
onready var epilepsy_warning = get_node("LoadingScreenElements/EpilepsyWarning")
onready var epilepsy_warning_tween := Tween.new()
onready var chart_features_display = get_node("LoadingScreenElements/FeaturesDisplay")
onready var fade_out_color_rect = get_node("LoadingScreenElements/ColorRect")
onready var loading_screen_elements = get_node("LoadingScreenElements")
var base_assets
var current_assets
const DEFAULT_PREVIEW_TEXTURE = preload("res://graphics/no_preview_texture.png")
const DEFAULT_BG = preload("res://graphics/predarkenedbg.png")
onready var min_load_time_timer := Timer.new()
var skin_downloading_item := 0
var ugc_skin_to_use: HBUISkin

func _ready():
	add_child(appear_tween)
	add_child(min_load_time_timer)
	add_child(disappear_tween)
	appear_tween.interpolate_property(loading_panel, "rect_scale", Vector2(0.9, 0.9), Vector2.ONE, 0.5, Tween.TRANS_CUBIC)
	appear_tween.interpolate_property(loading_panel, "modulate:a", 0.0, 1.0, 0.5, Tween.TRANS_CUBIC)
	appear_tween.start()
	add_child(epilepsy_warning_tween)
	epilepsy_warning.hide()
	chart_features_display.hide()
	disappear_tween.connect("tween_all_completed", self, "load_into_game")
func show_epilepsy_warning():
	epilepsy_warning.show()
	epilepsy_warning_tween.interpolate_property(epilepsy_warning, "rect_scale:y", 0.2, 1.0, 0.5, Tween.TRANS_BOUNCE, Tween.EASE_OUT)
	epilepsy_warning_tween.interpolate_property(epilepsy_warning, "modulate:a", 0.0, 1.0, 0.5, Tween.TRANS_LINEAR)
	epilepsy_warning_tween.start()
	
func load_song(new_game_info: HBGameInfo, practice: bool, assets):
	base_assets = assets
	game_info = new_game_info
	current_diff = game_info.difficulty
	var song: HBSong = new_game_info.get_song()
	if song.show_epilepsy_warning:
		min_load_time_timer.start(3)
		show_epilepsy_warning()
	
	is_loading_practice_mode = practice

	
	if "background" in assets:
		$TextureRect.texture = assets.background
	else:
		$TextureRect.texture = DEFAULT_BG
	if "preview" in assets:
		album_cover.texture = assets.preview
	else:
		album_cover.texture = DEFAULT_PREVIEW_TEXTURE
	title_label.text = song.get_visible_title(new_game_info.variant)
	meta_label.text = PoolStringArray(song.get_meta_string()).join('\n')
	
	var start_now := true
	var skin_ugc_enabled := true
	
	if UserSettings.user_settings.per_song_settings.has(song.id):
		skin_ugc_enabled = (UserSettings.user_settings.per_song_settings[song.id] as HBPerSongSettings).use_song_skin
	
	if song.skin_ugc_id != 0 and skin_ugc_enabled:
		if PlatformService.service_provider.implements_ugc:
			var ugc_service: SteamUGCService = PlatformService.service_provider.ugc_provider
			if ugc_service:
				var item_state := Steam.getItemState(song.skin_ugc_id)
				print("FLAGFS!!!", item_state)
				if not item_state & Steam.ITEM_STATE_INSTALLED or item_state & Steam.ITEM_STATE_NEEDS_UPDATE:
					if Steam.downloadItem(song.skin_ugc_id, true):
						loadingu_label.text = tr("Downloadingu UI Skin...")
						skin_downloading_item = song.skin_ugc_id
						Steam.connect("item_downloaded", self, "_on_item_downloaded")
						start_now = false
					elif item_state & Steam.ITEM_STATE_INSTALLED:
						_load_ugc_skin(song.skin_ugc_id)
				else:
					_load_ugc_skin(song.skin_ugc_id)
	if start_now:
		start_asset_load()
func _load_ugc_skin(file_id: int):
	var item_state := Steam.getItemState(file_id)
	if item_state & Steam.ITEM_STATE_INSTALLED:
		var install_info := Steam.getItemInstallInfo(file_id)
		if install_info.ret:
			var res_pack: HBResourcePack = HBResourcePack.load_from_directory(install_info.folder)
			if res_pack:
				if res_pack.is_skin():
					ugc_skin_to_use = res_pack.get_skin()

func _on_item_downloaded(_result: int, file_id: int, _app_id: int):
	if skin_downloading_item == file_id:
		_load_ugc_skin(file_id)
		start_asset_load()
func start_asset_load():
	loadingu_label.text = tr("Loadingu...")
	var song: HBSong = game_info.get_song()
	var assets_to_get = ["audio", "voice"]
	if not song.has_audio_loudness:
		if not SongDataCache.is_song_audio_loudness_cached(song):
			assets_to_get.append("audio_loudness")
	var asset_task = SongAssetLoadAsyncTask.new(assets_to_get, song, game_info.variant)
	asset_task.connect("assets_loaded", self, "_on_song_assets_loaded")
	AsyncTaskQueueLight.queue_task(asset_task)
func _on_song_assets_loaded(assets):
	if not min_load_time_timer.is_stopped():
		yield(min_load_time_timer, "timeout")
	current_assets = assets
	if UserSettings.user_settings.show_note_types_before_playing:
		var song: HBSong = game_info.get_song()
		var chart := song.get_chart_for_difficulty(game_info.difficulty)
		chart_features_display.set_chart(chart)
		chart_features_display.animate_controls()
		chart_features_display.show()
		loading_panel.hide()
		epilepsy_warning.hide()
	else:
		animate_fade_out()
	
func load_into_game():
	if UserSettings.user_settings.enable_streamer_mode:
		var preview_image: Image = album_cover.texture.get_data()
		var bg_image: Image = $TextureRect.texture.get_data()
		
		var song_artist = ""
		
		var song := game_info.get_song() as HBSong
		
		if song.artist_alias != "":
			song_artist = song.artist_alias
		else:
			song_artist = song.artist
		
		var current_song_text = "%s\n%s" % [song.get_visible_title(), song_artist]
		var f := File.new()
		f.open(HBGame.STREAMER_MODE_CURRENT_SONG_TITLE_PATH, File.WRITE)
		f.store_string(current_song_text)
		f.close()
		
		preview_image.save_png(HBGame.STREAMER_MODE_CURRENT_SONG_PREVIEW_PATH)
		bg_image.save_png(HBGame.STREAMER_MODE_CURRENT_SONG_BG_PATH)
	var new_scene
	if not is_loading_practice_mode:
		new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
	else:
		new_scene = preload("res://rythm_game/practice_mode.tscn")
	game_info.time = OS.get_unix_time()
	var song := game_info.get_song() as HBSong
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	if not "audio_loudness" in current_assets:
		current_assets["audio_loudness"] = 0.0
		if SongDataCache.is_song_audio_loudness_cached(SongLoader.songs[game_info.song_id]):
			current_assets["audio_loudness"] = SongDataCache.audio_normalization_cache[game_info.song_id].loudness
		elif song.has_audio_loudness:
			current_assets["audio_loudness"] = song.audio_loudness
	scene.skin_override = ugc_skin_to_use
	scene.start_session(game_info, HBUtils.merge_dict(base_assets, current_assets))
	
var visible_chars := 0.0
	
func _process(delta):
	visible_chars += delta * 7.0
	loadingu_label.visible_characters = fmod(visible_chars, loadingu_label.text.length() + 1)

func animate_fade_out():
	if not disappear_tween.is_active():
		if current_assets:
			disappear_tween.interpolate_property(fade_out_color_rect, "color:a", 0.0, 1.0, 0.20)
			disappear_tween.start()

func _input(event):
	if event.is_action_pressed("gui_accept") or event.is_action_pressed("pause"):
		get_tree().set_input_as_handled()
		animate_fade_out()
