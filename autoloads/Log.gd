# Logging module
extends Node

signal message_logged(caller_name, message, log_level, caller_data)

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
	var caller_data = get_stack()[1]
	var caller_name = caller.get_class()
	if caller.LOG_NAME:
		caller_name = caller.LOG_NAME
	print("[%s] %s:%d: %s" % [HBUtils.find_key(LogLevel, log_level), caller_data.source.get_file(), caller_data.line, message])
	emit_signal("message_logged", caller.LOG_NAME, message, log_level, caller_data)
