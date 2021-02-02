extends Node

const MAX_CONCURRENT_REQUESTS = 4

var queue = []
var current_requests = []
func add_request(url: String) -> HTTPRequest:
	var req = HTTPRequest.new()
	req.set_meta("url", url)
	queue.append(req)
	req.connect("request_completed", self, "_on_request_completed", [req])
	add_child(req)
	update_queue()
	return req
	
func update_queue():
	while current_requests.size() < MAX_CONCURRENT_REQUESTS and queue.size() > 0:
		var req = queue.pop_front()
		req.request(req.get_meta("url"))
		current_requests.append(req)

func _on_request_completed(result, response_code, headers, body, request: HTTPRequest):
	current_requests.erase(request)
	update_queue()
	request.queue_free()
