# Logging module
extends Node

signal message_logged(caller_name, message, log_level)

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
	if not Diagnostics.logging_enabled:
		return
	var caller_name = caller.get_class()
	if "LOG_NAME" in caller:
		caller_name = caller.LOG_NAME
	print("[%s] %s: %s" % [HBUtils.find_key(LogLevel, log_level), caller_name, message])
	emit_signal.call_deferred("message_logged", caller.LOG_NAME, message, log_level)
