# game version class
extends Node

class_name HBVersion

const MAJOR = 0
const MINOR = 7
const PATCH = 2

const status = "Early Access"
const ver_name = "Project Heartbeat: Lovely Gothic Girl Rehab"

static func get_version_string():
	var result = "{ver_name} - {status} ({video_driver}, {os_name}) - {version} (build {commit}, {build_date} {build_time}) - ({user_id}, {friendly_username})"
	var sha = ProjectSettings.get("application/config/build_commit").substr(0, 7)
	var datetime = OS.get_datetime_from_unix_time(ProjectSettings.get("application/config/build_time")) 
	var date = "%02d/%02d/%02d" % [datetime.day, datetime.month, datetime.year]
	var time = " %02d:%02d:%d" % [datetime.hour, datetime.minute, datetime.second]
	var video_driver = OS.get_video_driver_name(OS.get_current_video_driver())
	
	var version = "%d.%d.%d" % [MAJOR, MINOR, PATCH]
	
	var demo_string = ""
	
	if HBGame.demo_mode:
		demo_string = " [DEMO]"
	
	result = result.format({
		"ver_name": ver_name + demo_string,
		"status": status,
		"video_driver": video_driver,
		"os_name": OS.get_name(),
		"version": version,
		"commit": sha,
		"build_date": date,
		"build_time": time,
		"user_id": str(PlatformService.service_provider.user_id),
		"friendly_username": PlatformService.service_provider.friendly_username
	})
	return result
