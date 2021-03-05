class_name HBError

var error_type: int
var error_message: String
var caller_data
enum OWN_ERRORS {
	CUSTOM_ERROR = ERR_PRINTER_ON_FIRE+1
}

const ERR2STR = {
	OK: "Ok",
	FAILED: "Generic error",
	ERR_UNAVAILABLE: "Unavailable",
	ERR_UNCONFIGURED: "Unconfigured",
	ERR_UNAUTHORIZED: "Unauthorized",
	ERR_PARAMETER_RANGE_ERROR: "Parameter out of range",
	ERR_OUT_OF_MEMORY: "Out of memory",
	ERR_FILE_NOT_FOUND: "File not found",
	ERR_FILE_BAD_DRIVE: "Bad drive",
	ERR_FILE_BAD_PATH: "Bad path",
	ERR_FILE_NO_PERMISSION: "Permission denied",
	ERR_FILE_ALREADY_IN_USE: "File already in use",
	ERR_FILE_CANT_OPEN: "Can't open file",
	ERR_FILE_CANT_WRITE: "Can't write file",
	ERR_FILE_CANT_READ: "Can't read file",
	ERR_FILE_UNRECOGNIZED: "File unrecognized",
	ERR_FILE_CORRUPT: "File corrupt",
	ERR_FILE_MISSING_DEPENDENCIES: "Missing dependencies",
	ERR_FILE_EOF: "End of file",
	ERR_CANT_OPEN: "Can't open",
	ERR_CANT_CREATE: "Can't create",
	ERR_QUERY_FAILED: "Query failed",
	ERR_ALREADY_IN_USE: "Already in use",
	ERR_LOCKED: "Locked",
	ERR_TIMEOUT: "Operation timed out",
	ERR_CANT_CONNECT: "Can't connect",
	ERR_CANT_RESOLVE: "Can't resolve",
	ERR_CONNECTION_ERROR: "Connection error",
	ERR_CANT_ACQUIRE_RESOURCE: "Can't acquire resource",
	ERR_CANT_FORK: "Can't fork process",
	ERR_INVALID_DATA: "Invalid data",
	ERR_INVALID_PARAMETER: "Invalid parameter",
	ERR_ALREADY_EXISTS: "Already exists",
	ERR_DOES_NOT_EXIST: "Does not exist",
	ERR_DATABASE_CANT_READ: "Database read error",
	ERR_DATABASE_CANT_WRITE: "Database write error",
	ERR_COMPILATION_FAILED: "Compilation failed",
	ERR_METHOD_NOT_FOUND: "Method not found",
	ERR_LINK_FAILED: "Linking failed",
	ERR_SCRIPT_FAILED: "Script failed",
	ERR_CYCLIC_LINK: "Cycling link",
	ERR_INVALID_DECLARATION: "Invalid declaration",
	ERR_DUPLICATE_SYMBOL: "Duplicate symbol",
	ERR_PARSE_ERROR: "Parse error",
	ERR_BUSY: "Busy",
	ERR_SKIP: "Skip",
	ERR_HELP: "Help",
	ERR_BUG: "Bug",
	ERR_PRINTER_ON_FIRE: "Printer on fire",
	OWN_ERRORS.CUSTOM_ERROR: "Error"
}

func _init(et, em, stack_origin):
	self.error_type = et
	self.error_message = em
	self.caller_data = stack_origin

func _to_string() -> String:
	var err = "ERROR: "

	if caller_data:
		err += "%s: " % [caller_data.function]

	if error_type == OWN_ERRORS.CUSTOM_ERROR:
		err += "%s" % [error_message]
	else:
		err += "%d (%s)" % [error_type, ERR2STR[error_type]]
		if error_message:
			err += " (%s)" % [error_message]
	
	if caller_data:
		err += "\n"
		err += "    At: %s:%d" % [caller_data.source, caller_data.line]
	return err
