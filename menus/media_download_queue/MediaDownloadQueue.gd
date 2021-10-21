extends HBMenu

onready var vbox_container: VBoxContainer = get_node("VBoxContainer/HBUniversalScrollList/VBoxContainer")
onready var no_song_label: Label = get_node("Label")
onready var QUEUE_BUTTON = preload("res://menus/media_download_queue/MediaDownloadQueueButton.tscn")
onready var scroll_list = get_node("VBoxContainer/HBUniversalScrollList")
onready var queue_song_count: Label = get_node("VBoxContainer/HBoxContainer2/Label")

var song_map = {}

func _ready():
	YoutubeDL.connect("song_cached", self, "_on_song_cached")
	YoutubeDL.connect("song_queued", self, "_on_song_queued")
	YoutubeDL.connect("song_download_start", self, "_on_song_download_start")
	
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	
	populate()
	
func populate():
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
		
	for song in YoutubeDL.caching_queue:
		add_download_item(song)
	update_count_label()
	no_song_label.visible = YoutubeDL.caching_queue.size() <= 0
	
	scroll_list.grab_focus()
	
	if YoutubeDL.caching_queue.size() > 0:
		scroll_list.select_item(clamp(scroll_list.current_selected_item-1, 0, vbox_container.get_child_count()))
	
func update_count_label():
	queue_song_count.text = "%d songs queued" % [YoutubeDL.caching_queue.size()]
	
func _on_song_cached(song: HBSong):
	populate()

func add_download_item(song: HBSong):
	var button = QUEUE_BUTTON.instance()
	vbox_container.add_child(button)
	song_map[song] = button
	button.connect("pressed", self, "_on_button_pressed", [song])
	button.set_song(song)

func _on_button_pressed(song: HBSong):
	var video_id = YoutubeDL.get_video_id(song.youtube_url)
	if not video_id in YoutubeDL.songs_being_cached:
		var item = song_map[song]
		song_map.erase(song)
		vbox_container.remove_child(item)
		no_song_label.visible = YoutubeDL.caching_queue.size() <= 0
		if vbox_container.get_child_count() > 0:
			scroll_list.select_item(clamp(scroll_list.current_selected_item-1, 0, vbox_container.get_child_count()))
		YoutubeDL.songs_being_cached.erase(video_id)

func _on_song_queued(song: HBSong):
	no_song_label.visible = false

func _on_song_download_start(song: HBSong):
	if song in song_map:
		song_map[song].set_downloading(true)

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		change_to_menu("main_menu")
