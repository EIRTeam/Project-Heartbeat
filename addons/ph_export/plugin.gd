@tool
extends EditorPlugin

class PHExportPlugin:
	extends EditorExportPlugin
	
	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		# copy extra third party stuff
		if features.has("demo") or features.has("no_youtube_dl"):
			return
		var target_dir := path.get_base_dir()
		
		var copy_map := [
			["res://third_party/ffmpeg/ffmpeg.exe", "bin/ffmpeg/ffmpeg.exe"],
			["res://third_party/ffmpeg/ffprobe.exe", "bin/ffmpeg/ffprobe.exe"],
			["res://third_party/ffmpeg/ffmpeg", "bin/ffmpeg/ffmpeg"],
			["res://third_party/ffmpeg/ffprobe", "bin/ffmpeg/ffprobe"],
			["res://third_party/deno/deno.exe", "bin/deno/deno.exe"],
			["res://third_party/deno/deno", "bin/deno/deno"]
		]
		
		for file_src_dst in copy_map:
			var dst_file := target_dir.path_join((file_src_dst[1] as String))
			var file_dir := dst_file.get_base_dir()
			if not DirAccess.dir_exists_absolute(file_dir):
				DirAccess.make_dir_recursive_absolute(file_dir)
			
			var err := DirAccess.copy_absolute(file_src_dst[0], dst_file)
			if err != OK:
				print("Error copying file from %s to %s!" % [file_src_dst[0], dst_file])
		

var phexport: PHExportPlugin

func _enter_tree() -> void:
	phexport = PHExportPlugin.new()
	add_export_plugin(phexport)

func _exit_tree() -> void:
	if phexport:
		remove_export_plugin(phexport)
		phexport = null
