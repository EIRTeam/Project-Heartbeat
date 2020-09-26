extends Control

var background_song_assets_loader = HBBackgroundSongAssetsLoader.new()
var current_diff
var game_info: HBGameInfo
var is_loading_practice_mode = false
onready var title_label = get_node("Panel2/Panel3/MarginContainer/HBoxContainer/VBoxContainer/TitleLabel")
onready var meta_label = get_node("Panel2/Panel3/MarginContainer/HBoxContainer/VBoxContainer/MetaLabel")
onready var loadingu_label = get_node("Panel2/Panel3/MarginContainer/HBoxContainer/LoadinguLabel")
onready var album_cover = get_node("Panel2/Panel3/MarginContainer/HBoxContainer/TextureRect")
var appear_tween := Tween.new()
var base_assets
func _ready():
	background_song_assets_loader.connect("song_assets_loaded", self, "_on_song_assets_loaded")
	add_child(appear_tween)
	appear_tween.interpolate_property($Panel2, "rect_scale", Vector2(0.9, 0.9), Vector2.ONE, 0.5, Tween.TRANS_CUBIC)
	appear_tween.interpolate_property($Panel2, "modulate:a", 0.0, 1.0, 0.5, Tween.TRANS_CUBIC)
	appear_tween.start()
func load_song(new_game_info: HBGameInfo, practice: bool, assets):
	base_assets = assets
	game_info = new_game_info
	current_diff = game_info.difficulty
	var song: HBSong = new_game_info.get_song()
	is_loading_practice_mode = practice
	background_song_assets_loader.load_song_assets(song, ["audio", "audio_loudness"])
	$TextureRect.texture = assets.background
	album_cover.texture = assets.preview
	title_label.text = song.title
	meta_label.text = PoolStringArray(song.get_meta_string()).join('\n')
func _on_song_assets_loaded(song, assets):
	var new_scene
	if not is_loading_practice_mode:
		new_scene = preload("res://rythm_game/rhythm_game_controller.tscn")
	else:
		new_scene = preload("res://rythm_game/practice_mode.tscn")
	game_info.time = OS.get_unix_time()
	var scene = new_scene.instance()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	scene.start_session(game_info, HBUtils.merge_dict(base_assets, assets))
	
var visible_chars := 0.0
	
func _process(delta):
	visible_chars += delta * 7.0
	loadingu_label.visible_characters = fmod(visible_chars, loadingu_label.text.length() + 1)
