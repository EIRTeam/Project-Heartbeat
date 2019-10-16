# Login and statistics module

extends Node

enum LogLevel {
	INFO,
	WARN,
	ERROR
}

const LogLevel2String = {
	LogLevel.INFO: "INFO",
	LogLevel.WARN: "WARN",
	LogLevel.ERROR: "ERROR",
}

func _ready():
	print("Project Heartbeat ")

func log(caller: Object, message: String, log_level = LogLevel.INFO) -> void:
	var caller_name = caller.get_class()
	if caller.LOG_NAME:
		caller_name = caller.LOG_NAME
	print("[%s] %s: %s" % [LogLevel2String[log_level], caller_name, message])
