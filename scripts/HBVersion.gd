# game version class
extends Node

class_name HBVersion

const MAJOR = 0
const MINOR = 18
const PATCH = 0

const status = "Early Access"
const ver_name = "Project Heartbeat: Goth Girl Racing Department"

static func get_version_string(with_line_breaks := false):
	var result = "{ver_name} - {status} ({video_driver}, {audio_driver}, {os_name}) - {version} (build {commit}, {build_date} {build_time})"
	if with_line_breaks:
		result = result.replace(" - ", "\n")
	var sha = ProjectSettings.get("application/config/build_commit").substr(0, 7)
	var datetime = Time.get_datetime_dict_from_unix_time(ProjectSettings.get("application/config/build_time")) 
	var date = "%02d/%02d/%02d" % [datetime.day, datetime.month, datetime.year]
	var time = " %02d:%02d:%d" % [datetime.hour, datetime.minute, datetime.second]
	
	var version = "%d.%d.%d" % [MAJOR, MINOR, PATCH]
	
	var demo_string = ""
	
	if HBGame.demo_mode:
		demo_string = " [DEMO]"
	
	var os_name = OS.get_name()
	
	if HBGame.is_on_steam_deck():
		os_name += " on Steam Deck"
	
	result = result.format({
		"ver_name": ver_name + demo_string,
		"status": status,
		"audio_driver": Shinobu.get_current_backend_name(),
		"os_name": os_name,
		"version": version,
		"commit": sha,
		"build_date": date,
		"build_time": time,
	})
	return result
