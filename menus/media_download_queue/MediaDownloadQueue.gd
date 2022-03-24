extends HBMenu

onready var vbox_container: VBoxContainer = get_node("VBoxContainer/HBUniversalScrollList/VBoxContainer")
onready var no_song_label: Label = get_node("Label")
onready var QUEUE_BUTTON = preload("res://menus/media_download_queue/MediaDownloadQueueButton.tscn")
onready var scroll_list = get_node("VBoxContainer/HBUniversalScrollList")
onready var queue_song_count: Label = get_node("VBoxContainer/HBoxContainer2/Label")

var song_map = {}

	
func _on_menu_enter(force_hard_transition=false, args = {}):
	._on_menu_enter(force_hard_transition, args)
	
	YoutubeDL.connect("song_cached", self, "_on_song_cached")
	YoutubeDL.connect("song_queued", self, "_on_song_queued")
	YoutubeDL.connect("song_download_start", self, "_on_song_download_start")
	
	populate()
	
func _on_menu_exit(force_hard_transition = false):
	._on_menu_exit(force_hard_transition)
	YoutubeDL.disconnect("song_cached", self, "_on_song_cached")
	YoutubeDL.disconnect("song_queued", self, "_on_song_queued")
	YoutubeDL.disconnect("song_download_start", self, "_on_song_download_start")
	
func populate():
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
		
	for entry in YoutubeDL.caching_queue:
		add_download_item(entry)
	update_count_label()
	no_song_label.visible = YoutubeDL.caching_queue.size() <= 0
	
	scroll_list.grab_focus()
	
	if YoutubeDL.caching_queue.size() > 0:
		scroll_list.select_item(clamp(scroll_list.current_selected_item-1, 0, vbox_container.get_child_count()))
	
func update_count_label():
	queue_song_count.text = "%d songs queued" % [YoutubeDL.caching_queue.size()]
	
func _on_song_cached(entry: YoutubeDL.CachingQueueEntry):
	populate()

func add_download_item(entry: YoutubeDL.CachingQueueEntry):
	var button = QUEUE_BUTTON.instance()
	vbox_container.add_child(button)
	song_map[entry] = button
	button.connect("pressed", self, "_on_button_pressed", [entry])
	button.set_entry(entry)

func _on_button_pressed(entry: YoutubeDL.CachingQueueEntry):
	var video_id = YoutubeDL.get_video_id(entry.song.get_variant_data(entry.variant).variant_url)
	if not video_id in YoutubeDL.songs_being_cached:
		var item = song_map[entry]
		song_map.erase(entry)
		vbox_container.remove_child(item)
		no_song_label.visible = YoutubeDL.caching_queue.size() <= 0
		if vbox_container.get_child_count() > 0:
			scroll_list.select_item(clamp(scroll_list.current_selected_item-1, 0, vbox_container.get_child_count()))
		YoutubeDL.songs_being_cached.erase(video_id)
		YoutubeDL.caching_queue.erase(entry)

func _on_song_queued(song: HBSong):
	no_song_label.visible = false
	populate()

func _on_song_download_start(song: HBSong):
	if song in song_map:
		song_map[song].set_downloading(true)

func _unhandled_input(event):
	if event.is_action_pressed("gui_cancel"):
		ShinobuGodot.fire_and_forget_sound(HBGame.MENU_BACK_SFX, "sfx")
		change_to_menu("main_menu")
