# game version class
extends Node

class_name HBVersion

static func get_version_string():
	var result = "Project Heartbeat (%s, %s) - %s (build %s, %s %s) (%s, %s)"
	var version = ProjectSettings.get("application/config/version")
	var sha = ProjectSettings.get("application/config/build_commit").substr(0, 7)
	var datetime = OS.get_datetime_from_unix_time(ProjectSettings.get("application/config/build_time")) 
	var date = "%02d/%02d/%02d" % [datetime.day, datetime.month, datetime.year]
	var time = " %02d:%02d:%d" % [datetime.hour, datetime.minute, datetime.second]
	var video_driver = OS.get_video_driver_name(OS.get_current_video_driver())
	
	
	result = result % [video_driver, OS.get_name(), version, sha, date, time, str(PlatformService.service_provider.user_id), PlatformService.service_provider.friendly_username]
	return result
