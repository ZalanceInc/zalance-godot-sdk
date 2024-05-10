extends Node

var account_id = "":
	set = set_account_id

var locale = "en-US":
	set = set_locale

var livemode = false:
	set = set_livemode

const API_PUBLIC_DOMAIN = "https://api.zalance.net/api:Kp9D5gmw"
const API_PRICES_GET = API_PUBLIC_DOMAIN + '/price/{project_uuid}'
const API_SESSION_CREATE = API_PUBLIC_DOMAIN + '/session'
const API_SESSION_STATUS = API_PUBLIC_DOMAIN + '/session/status'
var project_id = ZalanceData.TEST_PROJECT_ID
var return_url = ZalanceData.TEST_RETURN_URL

var automatic_tax = true
var json_result
var _session_id = null
var _prices = []
var _prices_next_page = null
var _prices_prev_page = null
var http_request_prices: HTTPRequest = null
const API_ZALANCE_HELP_MSG = " Check your project Id in the Zalance panel is correct. If you continue to have problems, contact supporet@zalance.net"
const API_PRICE_FAIL_MSG = "Error retrieving prices."
const API_CREATE_CHECKOUT_MSG = "Error creating checkout."
const API_CHECKOUT_STATUS_MSG = "Error getting checkout status."


const ZAL_MSGS = {
	"not_found": "The resource was not found.",
	"account_not_found": "Account not found. Make sure you have completed the account onboarding process in your account settings.",
	"image_not_found": "Error retrieving image",
	"image_format_unknown": "Unknown image format. Image must be either PNG or JPG format",
	"image_error": "Error retrieving image",
	"invalid_project_id": "Invalid project Id. Check your project Id in the Zalance panel is correct.",
	"invalid_account_id": "Invalid account Id.",
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
		
		if project_id == ZalanceData.TEST_PROJECT_ID:
			push_warning("Zalance test project Id loaded. This is for demonstration purposes only. Switch this with your project Id in Zalance editor panel.")
		if return_url == ZalanceData.TEST_RETURN_URL:
			push_warning("Zalance test return URL loaded. This is for demonstration purposes only. Switch this with your project Id in Zalance editor panel.")


func set_account_id(id: String) -> void:
	account_id = id


func set_locale(_locale: String) -> void:
	locale = _locale


func set_livemode(_livemode: bool) -> void:
	livemode = _livemode


func get_prices(callback: Callable, count: int = 50, page: int = 1) -> Error:
	var err := _check_project_id()
	if err:
		return err
	
	if http_request_prices != null:
		http_request_prices.cancel_request()
		remove_child(http_request_prices)
		http_request_prices.queue_free()
		http_request_prices = null
	
	var body = JSON.stringify({
		"count": count,
		"page": page,
		"livemode": livemode,
		"locale": locale
	})
	
	var url = API_PRICES_GET.format({"project_uuid": project_id})
	http_request_prices = HTTPRequest.new()
	add_child(http_request_prices)
	err = http_request_prices.request(url, [], HTTPClient.METHOD_POST, body)
	if err:
		remove_child(http_request_prices)
		http_request_prices.queue_free()
		http_request_prices = null
		return err
	
	http_request_prices.request_completed.connect(_on_prices_completed.bind(callback, http_request_prices))
	return err


func _on_prices_completed(result, response_code, headers, body, callback: Callable, http_request) -> void:
	remove_child(http_request_prices)
	http_request_prices.queue_free()
	http_request_prices = null
	
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(API_PRICE_FAIL_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_PRICE_FAIL_MSG
		callback.call(response)
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8());
	
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
	var err := _check_project_id()
	if err:
		return err
		
	err = _check_account_id()
	if err:
		return err	
	
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
	err = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if err:
		remove_child(http_request)
		http_request.queue_free()
		return err
	
	http_request.request_completed.connect(_on_create_checkout_session_completed.bind(callback, http_request))
	return err


func _on_create_checkout_session_completed(result, response_code, headers, body, callback: Callable, http_request):
	remove_child(http_request)
	http_request.queue_free()
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(API_CREATE_CHECKOUT_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_CREATE_CHECKOUT_MSG
		callback.call(response)
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8());
	
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
	var err := _check_project_id()
	if err:
		return err
	
	var body = JSON.stringify({
		"project_uuid": project_id,
		"session_id": _session_id
	})
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	err = http_request.request(
		API_SESSION_STATUS, 
		["Content-Type: application/json"], 
		HTTPClient.METHOD_POST, 
		body)
	
	if err:
		remove_child(http_request)
		http_request.queue_free()
		return err
	
	http_request.request_completed.connect(_on_get_session_status_completed.bind(callback, http_request))
	return err


func _on_get_session_status_completed(result, response_code, headers, body, callback: Callable, http_request):
	remove_child(http_request)
	http_request.queue_free()
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error(API_CHECKOUT_STATUS_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_CHECKOUT_STATUS_MSG
		callback.call(response)
		return
	
	var json = JSON.parse_string(body.get_string_from_utf8());
	
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
		var errMsg = get_translated_msg("image_not_found")
		push_error(errMsg + " - " + image_url)
		remove_child(http_request)
		http_request.queue_free()
		return err
	
	http_request.request_completed.connect(_on_image_request_complete.bind(callback, http_request) )
	return err


# Called when the Image request is completed.
func _on_image_request_complete(result, response_code, headers, body, callback, http_request):
	remove_child(http_request)
	http_request.queue_free()
	var response = ZalanceResponse.new(result, response_code)
	if result != HTTPRequest.RESULT_SUCCESS:
		var errMsg = get_translated_msg("image_not_found")
		response.error = true
		response.message = errMsg
		callback.call(response)
		return
	
	# Handle redirect
	if response_code >= 300 and response_code < 400:
		var url = body.get_string_from_utf8()
		if url != null and url.length() > 0:
			get_image(url, callback)
			return


	if response_code != HTTPClient.RESPONSE_OK:
		var errMsg = get_translated_msg("image_not_found")
		push_error(errMsg)
		response.error = true
		response.message = errMsg
		callback.call(response)
	else:
		var image = null
		var headersArray = Array(headers)
		var error = null
		var is_png = headersArray.any(is_header_png)
		var is_jpeg = headersArray.any(is_header_jpeg)
		if is_png:
			image = Image.new()
			error = image.load_png_from_buffer(body)
		elif is_jpeg:
			image = Image.new()
			error = image.load_jpg_from_buffer(body)
		else:
			var errMsg = get_translated_msg("image_format_unknown")
			push_error(errMsg)	
		
		if error != OK:
			var errMsg = get_translated_msg("image_error")
			push_error(errMsg)
		
		#var texture = ImageTexture.create_from_image(image)
		response.data = {
			"image": image
		}
		callback.call(response)


func is_header_png(value: String):
	return value.begins_with("Content-Type") and value.to_lower().ends_with("image/png")


func is_header_jpeg(value: String):
	return value.begins_with("Content-Type") and value.to_lower().ends_with("image/jpeg")


func _check_project_id() -> Error:
	if project_id == null or project_id.length() == 0:
		var errMsg = get_translated_msg("invalid_project_id")
		push_error(errMsg)
		return ERR_INVALID_PARAMETER
	return OK


func _check_account_id() -> Error:
	if account_id == null or account_id.length() == 0:
		var errMsg = get_translated_msg("invalid_account_id")
		push_error(errMsg)
		return ERR_INVALID_PARAMETER
	elif account_id == Zalance.TEST_ACCOUNT_ID:
		push_warning("Zalance test account Id detected. This account Id is for testing only. Please update this with a call to Zalance.set_account_id.")
	return OK


func get_translated_msg(key) -> String:
	var value = ZAL_MSGS.get(key)
	if value != null:
		return value
	return key
