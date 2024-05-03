extends Node2D

const API_PUBLIC_DOMAIN = "https://api.zalance.net/api:Kp9D5gmw"
const API_PRICES_GET = API_PUBLIC_DOMAIN + '/price/{project_uuid}'
const API_SESSION_CREATE = API_PUBLIC_DOMAIN + '/session'
const API_SESSION_STATUS = API_PUBLIC_DOMAIN + '/session/status'
var project_id = ""
var return_url = ""
var account_id = "1120456E26F41EFC"
var livemode = false
var automatic_tax = true
var json_result
var json
var _session_id = null
var _prices = []
var _prices_next_page = null
var _prices_prev_page = null
const API_ZALANCE_HELP_MSG = " Check your project Id in the Zalance panel is correct. If you continue to have problems, contact supporet@zalance.net"
const API_PRICE_FAIL_MSG = "Error retrieving prices."
const API_CREATE_CHECKOUT_MSG = "Error creating checkout."
const API_CHECKOUT_STATUS_MSG = "Error getting checkout status."
const API_IMAGE_MSG = "Error retrieving image"

const ZAL_MSGS = {
	"not_found": "The resource was not found.",
	"account_not_found": "Account not found. Make sure you have completed the account onboarding process in your account settings."
}

class ZalanceResponse:
	var message: String = ""
	var error: bool = false
	var result = 0
	var response_code = 0
	var data = {}
	
	func _init(_result, _response_code):
		result = _result
		response_code = _response_code

func _ready():
	load_data()

func load_data() -> void:
	var fileExists = FileAccess.file_exists(ZalanceData.save_path)
	if fileExists:
		var data:ZalanceData = load(ZalanceData.save_path)
		project_id = data.project_id
		return_url = data.return_url
		livemode = data.livemode

func set_account_id(id: String):
	account_id = id

func get_prices(callback: Callable, count: int = 50, page: int = 1, locale: String = "en-US"):	
	var body = JSON.stringify({
		"count": count,
		"page": page,
		"livemode": livemode,
		"locale": locale
	})
	
	var url = API_PRICES_GET.format({"project_uuid": project_id})
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var err := http_request.request(url, [], HTTPClient.METHOD_POST, body)
	if err:
		remove_child(http_request)
		return err
	
	http_request.request_completed.connect(_on_prices_completed.bind(callback, http_request))
	return err

func _on_prices_completed(result, response_code, headers, body, callback: Callable, http_request):
	remove_child(http_request)
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(API_PRICE_FAIL_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_PRICE_FAIL_MSG
		callback.call(response)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		var msg = "Could not retrieve prices. " + json.message
		push_error("Zalance: " + msg)
		response.error = true
		response.message = get_translated_msg(json.message)
		callback.call(response)
	else:
		response.data = {
			"items": json.items,
			"next_page": json.nextPage,
			"prev_page": json.prevPage
		}
		callback.call(response)

func create_checkout_session(price_id: String, quantity: int, callback: Callable) -> int:
	var url = API_SESSION_CREATE
	var headers = ["Content-Type: application/json"]
	var lineItems = [{
		"price": price_id,
		"quantity": quantity
	}]
	var body = JSON.stringify({
		"project_uuid": project_id,
		"account_id": account_id,
		"return_url": return_url,
		"success_url": "https://zalance.net",
		"line_items": lineItems,
		"automatic_tax": automatic_tax,
		"livemode": livemode,
		"ui_mode": "hosted"
	})
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var err := http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err:
		remove_child(http_request)
		return err
	
	http_request.request_completed.connect(_on_create_checkout_session_completed.bind(callback, http_request))
	return err

func _on_create_checkout_session_completed(result, response_code, headers, body, callback: Callable, http_request):
	remove_child(http_request)
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(API_CREATE_CHECKOUT_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_CREATE_CHECKOUT_MSG
		callback.call(response)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		var msg = API_CREATE_CHECKOUT_MSG + " " + json.message
		push_error(API_CREATE_CHECKOUT_MSG)
		response.error = true
		response.message = get_translated_msg(json.message)
		callback.call(response)
	else:
		_session_id = json.id
		_create_checkout_browser(json.url)
		response.data = {
			"session_id": json.id
		}
		callback.call(response)

func _create_checkout_browser(url):
	print(url)
	OS.shell_open(url)

func get_checkout_session_status(callback: Callable) -> int:
	var body = JSON.stringify({
		"project_uuid": project_id,
		"session_id": _session_id
	})
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var err := http_request.request(
		API_SESSION_STATUS, 
		["Content-Type: application/json"], 
		HTTPClient.METHOD_POST, 
		body)
	
	if err:
		remove_child(http_request)
		return err
	
	http_request.request_completed.connect(_on_get_session_status_completed.bind(callback, http_request))
	return err

func _on_get_session_status_completed(result, response_code, headers, body, callback: Callable, http_request):
	remove_child(http_request)
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(API_CHECKOUT_STATUS_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_CHECKOUT_STATUS_MSG
		callback.call(response)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		var msg = API_CREATE_CHECKOUT_MSG + " " + json.message
		push_error(API_CREATE_CHECKOUT_MSG)
		response.error = true
		response.message = get_translated_msg(json.message)
		callback.call(response)
	else:
		response.data = json
		callback.call(response)

func get_image(image_url: String, callback: Callable):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var err = http_request.request(image_url)
	if err:
		push_error(API_IMAGE_MSG + " image: " + image_url)
		remove_child(http_request)
		return err
	
	http_request.request_completed.connect(_on_image_request_complete.bind(callback, http_request) )
	return err

# Called when the Image request is completed.
func _on_image_request_complete(result, response_code, headers, body, callback, http_request):
	remove_child(http_request)
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(API_IMAGE_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_IMAGE_MSG
		callback.call(response)
		return
	
	# Handle redirect
	if response_code >= 300 and response_code < 400:
		var url = body.get_string_from_utf8()
		if url != null and url.length() > 0:
			get_image(url, callback)
			return
	
	if response_code != HTTPClient.RESPONSE_OK:
		var msg = API_CREATE_CHECKOUT_MSG + " " + json.message
		push_error(API_CREATE_CHECKOUT_MSG)
		response.error = true
		response.message = get_translated_msg(json.message)
		callback.call(response)
	else:
		var image = Image.new()
		var headersArray = Array(headers)
		var error = null
		var is_png = headersArray.any(is_header_png)
		if is_png:
			error = image.load_png_from_buffer(body)
		else:
			error = image.load_jpg_from_buffer(body)
		if error != OK:
			push_error("Couldn't load the image.")
		
		#var texture = ImageTexture.create_from_image(image)
		response.data = {
			"image": image
		}
		callback.call(response)

func is_header_png(value):
	return value.begins_with("Content-Type") and value.ends_with("image/png")

func get_translated_msg(key) -> String:
	var value = ZAL_MSGS.get(key)
	if value != null:
		return value
	return key
