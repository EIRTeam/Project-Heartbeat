# game version class
extends Node

class_name HBVersion

const MAJOR = 1
const MINOR = 0
const PATCH = 0

const status = "Release Candidate 3"
const ver_name = "Project Heartbeat: Marina's Legacy"
const VERSION_FILE_PATH := "res://version.json"

static func get_version_string(with_line_breaks := false):
	var sha = ProjectSettings.get("application/config/build_commit").substr(0, 7)
	
	var version = "%d.%d.%d" % [MAJOR, MINOR, PATCH]
	
	var demo_string = ""
	
	if HBGame.demo_mode:
		demo_string = " [DEMO]"
	
	var os_name = OS.get_name()
	
	if HBGame.is_on_steam_deck():
		os_name += " on Steam Deck"
	var format_info := {
		"ver_name": ver_name + demo_string,
		"status": status,
		"audio_driver": Shinobu.get_current_backend_name(),
		"video_driver": PHNative.get_rendering_api_name(),
		"api_version": RenderingServer.get_video_adapter_api_version(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"os_name": os_name,
		"version": version,
		"commit": "",
		"build_date": "",
		"build_time": "",
	}

	var has_date_info := false
	
	if FileAccess.file_exists(VERSION_FILE_PATH):
		var f := FileAccess.open(VERSION_FILE_PATH, FileAccess.READ)
		var json := JSON.parse_string(f.get_as_text()) as Dictionary
		has_date_info = json and json.has("build_time") and json.has("is_dirty") and json.has("commit_hash")
		if has_date_info:
			var datetime = Time.get_datetime_dict_from_unix_time(json.build_time + Time.get_time_zone_from_system().bias * 60)
			var date = "%02d/%02d/%02d" % [datetime.day, datetime.month, datetime.year]
			var time = " %02d:%02d:%d" % [datetime.hour, datetime.minute, datetime.second]
			has_date_info = true
			format_info["build_time"] = time
			format_info["commit"] = json.commit_hash
			format_info["dirty"] = "-dirty" if json.is_dirty else ""
		
	var result = "{ver_name} - {status} - ({video_driver} {api_version}, {audio_driver}, {os_name}) - {version} (build {commit}{dirty}, {build_date} {build_time}) - {video_adapter}"
	if not has_date_info:
		result = "{ver_name} - {status} - ({video_driver} {api_version}, {audio_driver}, {os_name}) - {version} - {video_adapter}"
		
	result = result.format(format_info)
	if with_line_breaks:
		result = result.replace(" - ", "\n")
	return result
