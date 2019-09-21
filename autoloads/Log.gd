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

func log(caller: Object, message: String, log_level = LogLevel.INFO) -> void:
	var caller_name = caller.get_class()
	if caller.LOG_NAME:
		caller_name = caller.LOG_NAME
	print("[%s] %s: %s" % [LogLevel2String[log_level], caller_name, message])

func _process(delta):
	OS.set_window_title("Project Heartbeat - %.2f" % Engine.get_frames_per_second())
