class_name HBHTTPRangeDownloader

signal download_finished

enum STATE {
	STATE_READY,
	STATE_BUSY
}

var download_url := ""
var download_path := ""
var chunk_size = 1024
var headers = []

var state: int = STATE.STATE_READY

var has_error := false setget ,has_error
var error_string := "" setget ,get_error_string
var error_i := 0 setget ,get_error_i

var range_start := 0
var range_end := 0
var total_downloaded_bytes := 0
var file := File.new()
var file_size := -1

var mutex := Mutex.new()

var http := HTTPClient.new()

var url_regex: RegEx

var thread: Thread = null

func _init():
	url_regex = RegEx.new()
	url_regex.compile("^((http[s]?|ftp):\\/)?\\/?([^:\\/\\s]+)((\\/\\w+)*\\/)([\\w\\-\\.]+[^#?\\s]+)(.*)?(#[\\w\\-]+)?$")
	assert(url_regex.get_group_count() == 8)

func download(_download_url: String, _download_path: String, _chunk_size: int, _headers := []):
	if state != STATE.STATE_READY:
		propagate_error(ERR_BUSY, "RangeDownloader is busy")
		return
	download_url = _download_url
	download_path = _download_path
	chunk_size = _chunk_size
	state = STATE.STATE_BUSY
	headers = _headers
	range_start = 0
	range_end = 0
	file_size = -1
	total_downloaded_bytes = 0
	has_error = false
	error_string = ""
	error_i = 0
	http.read_chunk_size = chunk_size
	
	thread = Thread.new()
	thread.start(self, "thread_func")
	
func lock():
	mutex.lock()
func unlock():
	mutex.unlock()
	
func _get_hostname_from_url(url: String) -> String:
	var r_match := url_regex.search(url)
	return r_match.strings[3]
	
func _client_status_to_string(client_status: int):
	match client_status:
		HTTPClient.STATUS_DISCONNECTED:
			return "Disconnected from the server"
		HTTPClient.STATUS_RESOLVING:
			return "Currently resolving the hostname for the given URL into an IP"
		HTTPClient.STATUS_CANT_RESOLVE:
			return "DNS failure: Can't resolve the hostname for the given URL"
		HTTPClient.STATUS_CONNECTING:
			return "Currently connecting to server"
		HTTPClient.STATUS_CANT_CONNECT:
			return "Can't connect to the server"
		HTTPClient.STATUS_CONNECTED:
			return "Connection established"
		HTTPClient.STATUS_REQUESTING:
			return "Currently sending request"
		HTTPClient.STATUS_BODY:
			return "HTTP body received"
		HTTPClient.STATUS_CONNECTION_ERROR:
			return "Error in HTTP connection"
		HTTPClient.STATUS_SSL_HANDSHAKE_ERROR:
			return "Error in SSL handshake"
		
func _establish_connection():
	var hostname := _get_hostname_from_url(download_url)
	var err := http.connect_to_host(hostname, 443, true, true)
	
	if err != OK:
		propagate_error(err, "Error %d when opening connection to host %s" % [err, hostname])
		return
	
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		
	if http.get_status() != HTTPClient.STATUS_CONNECTED:
		propagate_error(http.get_status(), _client_status_to_string(http.get_status()))
		return
	headers.append("")
	
	range_start = 0
	range_end = range_start + chunk_size
	
func _process_download() -> bool:
	headers[-1] = "Range: bytes=%d-%d" % [range_start, range_end]
	
	var err := http.request(HTTPClient.METHOD_GET, download_url, headers)
	
	if err != OK:
		propagate_error(err, "Error %d when starting request" % [err])
		return false
		
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		
	var response_headers := http.get_response_headers_as_dictionary()

	# Youtube will randomly give us a 302 redirect for no really good reason
	# probably to throw off third-party downloaders like us...
	# so we will just follow it and pray.
	if http.get_response_code() == 302:
		var redirect_url := response_headers.get("Location", "") as String
		if redirect_url:
			download_url = redirect_url
			# We first need to establish a connection to the server again...
			http.close()
			_establish_connection()
			# We need to remove the final Range header that we have
			headers = headers.slice(0, headers.size()-2)
			return false
		else:
			propagate_error(http.get_response_code(), "Invalid redirect did not contain Location header")

	if response_headers.has("Content-Range"):
		file_size = response_headers["Content-Range"].split("/")[1].to_int()
		
		
	if http.get_response_code() < 200 or http.get_response_code() >= 400:
		propagate_error(http.get_response_code(), "Error %d when requesting data" % [http.get_response_code()])
		
	while http.get_status() == HTTPClient.STATUS_BODY:
		http.poll()
		
		var chunk := http.read_response_body_chunk()
		if chunk.size() > 0:
			total_downloaded_bytes += chunk.size()
			file.store_buffer(chunk)
	range_start = range_end+1
	if file_size != -1:
		range_end = min(range_start + http.read_chunk_size, file_size)
	 
	return total_downloaded_bytes >= file_size
func propagate_error(_error_i: int, _error_string: String):
	lock()
	has_error = true
	error_i = _error_i
	error_string = _error_string
	push_error("RangeDownloader error: %s" % [_error_string])
	unlock()
	
func has_error() -> bool:
	lock()
	var h := has_error
	unlock()
	return h
	
func get_error_i() -> int:
	lock()
	var h := error_i
	unlock()
	return h
	
func get_downloaded_bytes() -> int:
	return total_downloaded_bytes
	
func get_download_size() -> int:
	return max(file_size, 0) as int
	
func get_error_string() -> String:
	lock()
	var h := error_string
	unlock()
	return h
	
func thread_func():
	_establish_connection()
	
	var err :=  file.open(download_path, File.WRITE)
	if err != OK:
		propagate_error(error_i, "Error opening file %s for writing (error %d)" % [download_path, err])
	
	var download_finished_ok := false
	
	while not has_error:
		if _process_download():
			break
	
	file.flush()
	file.close()
	http.close()

	call_deferred("kill_thread")
	call_deferred("emit_signal", "download_finished")

func kill_thread():
	if thread.is_active():
		thread.wait_to_finish()
		state = STATE.STATE_READY

func cancel_download():
	kill_thread()
	
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if thread:
			if thread.is_active():
				thread.wait_to_finish()
	
