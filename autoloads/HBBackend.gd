extends Node

var login_http_request := HTTPRequest.new()

const SERVICE_ENVIRONMENTS = {
	"live": "http://localhost:8000",
	"dev": "http://localhost:8000"
}

var service_url = SERVICE_ENVIRONMENTS.dev
var jwt_token = ""
var connected = false

enum REQUEST_TYPE {
	LOGIN
}

var request_type_methods = {
	REQUEST_TYPE.LOGIN: "_on_logged_in"
}

func _ready():
	login_http_request.connect("request_completed", self, "_on_request_completed")

func _on_request_completed(result, response_code, headers, body, request_type, requester):
	requester.queue_free()
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8()).result
		call(request_type_methods[request_type], json)
		
func _on_logged_in(json):
	jwt_token = json.token
	connected = true
	
func make_request(url: String, payload: Dictionary, method, type, no_auth=false):
	var requester = HTTPRequest.new()
	requester.connect("request_completed", self, "_on_request_completed", [type, requester])
	add_child(requester)
	var headers = ["Content-Type: application/json"]
	requester.request(service_url + url,  headers, false, method, JSON.print(payload))
func login_steam(ticket: PoolByteArray):
	var payload = {
		"steam_ticket": ticket.hex_encode()
	}
	make_request("/api/users/steam-login", payload, HTTPClient.METHOD_POST, REQUEST_TYPE.LOGIN, true)
