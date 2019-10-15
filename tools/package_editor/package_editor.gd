extends Control

onready var package_list = get_node("HSplitContainer/VBoxContainer/PackageList")
onready var package_editor = get_node("HSplitContainer/PackageEditor")
onready var song_meta_editor = get_node("HSplitContainer/SongMetaEditor")
onready var create_package_popup = get_node("CreatePackageDialog")
onready var create_song_popup = get_node("CreateSongDialog")
const LOG_NAME = "PackageEditor"

var dev_packages = {}

const EXPORT_PRESETS_BASE = """
[preset.0]

name=\"Mod\"
platform=\"Linux/X11\"
runnable=false
custom_features=""
export_filter=\"all_resources\"
include_filter=\"*.json\"
exclude_filter=""
export_path=""
patch_list=PoolStringArray(  )
script_export_mode=1
script_encryption_key=""

[preset.0.options]

texture_format/bptc=false
texture_format/s3tc=true
texture_format/etc=false
texture_format/etc2=false
texture_format/no_bptc_fallbacks=true
binary_format/64_bits=true
binary_format/embed_pck=false
custom_template/release=""
custom_template/debug=""
"""

func _ready():
	print(OS.get_executable_path())
	update_dev_package_list()
	song_meta_editor.hide()
	package_editor.hide()
	print(OS.get_cmdline_args())
	

func load_dev_package(folder_name: String):
	var file := File.new()
	var package_meta_path = HBPackageMeta.get_dev_package_meta_path(folder_name)
	var err = file.open(package_meta_path, File.READ)
	if err == OK:
		var package_json := JSON.parse(file.get_as_text())
		if package_json.error == OK:
			dev_packages[folder_name] = HBSerializable.deserialize(package_json.result)
			package_list.add_package(folder_name, dev_packages[folder_name])
		else:
			Log.log(self, "Error loading package %s config file on line %d: %s" % [folder_name, package_json.error_line, package_json.error_string], Log.LogLevel.ERROR)
	else:
		Log.log(self, "Error loading meta file for package %s with error %d, file may be missing?" % [folder_name, err], Log.LogLevel.ERROR)

func update_dev_package_list():
	var dir := Directory.new()
	if not dir.dir_exists(HBPackageMeta.DEV_PACKAGE_DIR):
		dir.make_dir(HBPackageMeta.DEV_PACKAGE_DIR)
	if dir.open(HBPackageMeta.DEV_PACKAGE_DIR) == OK:
		dir.list_dir_begin()
		var dir_name = dir.get_next()
		
		while dir_name != "":
			if dir.current_is_dir() and not dir_name.begins_with("."):
				load_dev_package(dir_name)
			dir_name = dir.get_next()


func _on_PackageList_package_selected(package_folder_name):
	package_editor.package_meta = dev_packages[package_folder_name]
	song_meta_editor.hide()
	package_editor.show()
func _on_PackageList_song_selected(song: HBSong, song_id, package_name):
	song_meta_editor.show()
	package_editor.hide()
	song_meta_editor.song_meta = song
	song_meta_editor.package_meta = dev_packages[package_name]
	song_meta_editor.package_name = package_name
	package_list.get_selected().set_text(0, song.title)
	

func _on_SongMetaEditor_song_meta_saved():
	var song = package_list.get_selected_song() as HBSong
	var song_id = package_list.get_selected_song_id()
	var song_package_name = package_list.get_selected_song_package_name()
	song.save_to_file(HBPackageMeta.get_dev_package_song_meta_path(song_package_name, song_id))
	package_list.get_selected().set_text(0, song.title)
	
func _on_PackageEditor_package_meta_saved():
	var package_name = package_list.get_selected_package_name()
	var file := File.new()
	var package_meta := dev_packages[package_name] as HBPackageMeta
	package_meta.save_to_file(HBPackageMeta.get_dev_package_meta_path(package_name))
		
	# Update selected package item name
	package_list.get_selected().set_text(0, package_meta.name)


func _on_CreatePackageDialog_confirmed():
	if $CreatePackageDialog/LineEdit.text != "":
		var package_name = $CreatePackageDialog/LineEdit.text
		var package_folder_name = HBUtils.get_valid_filename(package_name)
		if package_folder_name != "":
			var dir := Directory.new()
			var err = dir.make_dir_recursive(HBPackageMeta.get_dev_package_path(package_folder_name))
			if err == OK:
				var package_meta = HBPackageMeta.new()
				package_meta.name = package_name
				package_meta.save_to_file(HBPackageMeta.get_dev_package_meta_path(package_folder_name))
				load_dev_package(package_folder_name)
			else:
				Log.log(self, "Error creating package folder for package %s error: %d" % [package_folder_name, err])

func _on_CreateSongDialog_confirmed():
	if $CreateSongDialog/LineEdit.text != "":
		var song_name = HBUtils.get_valid_filename($CreateSongDialog/LineEdit.text)
		var package_name = package_list.get_selected_package_name()
		var package_folder_name = HBUtils.get_valid_filename(package_name)
		if song_name != "":
			var dir := Directory.new()
			var song_path = HBPackageMeta.get_dev_package_song_path(package_name, song_name)
			var err = dir.make_dir_recursive(song_path)
			if err == OK:
				var song_meta = HBSong.new()
				song_meta.title = $CreateSongDialog/LineEdit.text
				song_meta.id = song_name
				song_meta.save_to_file(HBPackageMeta.get_dev_package_song_meta_path(package_name, song_name))
				package_list.add_song(package_list.get_selected(), song_meta, song_name, package_name)
			else:
				Log.log(self, "Error creating song folder for song %s error: %d" % [song_name, err])


func _on_AddButton_pressed():
	if package_list.is_selected_a_package():
		create_song_popup.popup_centered_ratio(0.25)
	else:
		create_package_popup.popup_centered_ratio(0.25)






func _on_CloseButton_pressed():
	package_list.get_selected().deselect(0)
	package_editor.hide()
	song_meta_editor.hide()


func _on_ExportPackageFileDialog_file_selected(path):
	var package_name = package_list.get_selected_package_name()
	var package_path = HBPackageMeta.get_dev_package_path(package_name)
	var ep_path = HBPackageMeta.get_dev_package_path(package_name).plus_file("export_presets.cfg")
	
	# Check if the package already has a export presets file, if not we create it
	
	var file := File.new()
	if not file.file_exists(ep_path):
		if file.open(ep_path, File.WRITE) == OK:
			file.store_string(EXPORT_PRESETS_BASE)
			
	var arguments = PoolStringArray()
	arguments.append("--no-window")
	arguments.append("--path")
	arguments.append(ProjectSettings.globalize_path(package_path))
	arguments.append("--export")
	arguments.append("\"Mod\"")
	arguments.append(ProjectSettings.globalize_path(path))
	Log.log(self, "Running godot: " + OS.get_executable_path() + " " + arguments.join(" "), Log.LogLevel.INFO)
	var output = []
	OS.execute(OS.get_executable_path(), arguments, true, output)
