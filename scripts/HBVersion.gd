extends Node

class_name HBVersion

static func get_version_string():
	var result = "Project Heartbeat - %s (build %s, %s %s)"
	var version = ProjectSettings.get("application/config/version")
	var sha = ProjectSettings.get("application/config/build_commit")
	var datetime = OS.get_datetime_from_unix_time(ProjectSettings.get("application/config/build_time")) 
	var date = "%02d/%02d/%02d" % [datetime.day, datetime.month, datetime.year]
	var time = " %02d:%02d:%d" % [datetime.hour, datetime.minute, datetime.second]
	result = result % [version, sha, date, time]
	return result
