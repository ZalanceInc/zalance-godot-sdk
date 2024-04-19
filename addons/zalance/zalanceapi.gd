class_name Zalance
extends HTTPRequest

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
var _request_completed : bool = false
var _prices = []
var _prices_next_page = null
var _prices_prev_page = null
var _get_prices_callable: Callable = func(): pass
var _checkout_created_callable: Callable = func(): pass
var _checkout_status_callable: Callable = func(): pass
const API_ZALANCE_HELP_MSG = " Check your project Id in the Zalance panel is correct. If you continue to have problems, contact supporet@zalance.net"
const API_PRICE_FAIL_MSG = "Error retrieving prices."
const API_CREATE_CHECKOUT_MSG = "Error creating checkout."
const API_CHECKOUT_STATUS_MSG = "Error getting checkout status."

class ZalanceResponse:
	var message: String = ""
	var error: bool = false
	var result = 0
	var response_code = 0
	var data = {}
	
	func _init(_result, _response_code):
		result = _result
		response_code = _response_code

signal prices_received(response: ZalanceResponse)
signal checkout_created(id)
signal checkout_status(json)

func _ready():
	load_data()

func load_data() -> void:
	var data:ZalanceData = load(ZalanceData.save_path)
	project_id = data.project_id
	return_url = data.return_url
	livemode = data.livemode

func get_prices(count: int, page: int, callback: Callable):	
	var url = API_PRICES_GET.format({"project_uuid": project_id})
	var err := request(url, [], HTTPClient.METHOD_POST)
	if err:
		return err
	
	_get_prices_callable = callback
	request_completed.connect(_on_prices_completed)
	return err

func _on_prices_completed(result, response_code, headers, body):
	var response = ZalanceResponse.new(result, response_code)
	request_completed.disconnect(_on_prices_completed)
	if result != RESULT_SUCCESS:
		push_error(API_PRICE_FAIL_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_PRICE_FAIL_MSG
		_signal_prices_received(response)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		var msg = "Could not retrieve prices. " + json.message
		push_error("Zalance: " + msg)
		response.error = true
		response.message = msg
		_signal_prices_received(response)
	else:
		_prices = json.items
		_prices_next_page = json.nextPage
		_prices_prev_page = json.prevPage
		response.data = {
			"items": json.items,
			"next_page": json.nextPage,
			"prev_page": json.prevPage
		}
		_signal_prices_received(response)

func get_last_prices():
	return _prices;

func create_checkout_session(price_id, quantity, callback: Callable) -> int:
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
	var err := request(url, headers, HTTPClient.METHOD_POST, body)
	if err:
		return err
	
	_checkout_created_callable = callback
	request_completed.connect(_on_create_checkout_session_completed)
	return err

func _on_create_checkout_session_completed(result, response_code, headers, body):
	request_completed.disconnect(_on_create_checkout_session_completed)
	var response = ZalanceResponse.new(result, response_code)
	if result != RESULT_SUCCESS:
		push_error(API_CREATE_CHECKOUT_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_CREATE_CHECKOUT_MSG
		_signal_checkout_created(response)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		var msg = API_CREATE_CHECKOUT_MSG + " " + json.message
		push_error(API_CREATE_CHECKOUT_MSG)
		response.error = true
		response.message = msg
		_signal_checkout_created(response)
	else:
		_session_id = json.id
		_create_checkout_browser(json.url)
		response.data = {
			"session_id": json.id
		}
		_signal_checkout_created(response)

func _create_checkout_browser(url):
	print(url)
	OS.shell_open(url)

func get_checkout_session_status(callback: Callable):
	var body = JSON.stringify({
		"project_uuid": project_id,
		"session_id": _session_id
	})
	var err := request(
		API_SESSION_STATUS, 
		["Content-Type: application/json"], 
		HTTPClient.METHOD_POST, 
		body)
	
	if err:
		return err
	
	_checkout_status_callable = callback
	request_completed.connect(_on_get_session_status_completed)
	return 0

func _on_get_session_status_completed(result, response_code, headers, body):
	request_completed.disconnect(_on_get_session_status_completed)
	var response = ZalanceResponse.new(result, response_code)
	if result != RESULT_SUCCESS:
		push_error(API_CHECKOUT_STATUS_MSG + API_ZALANCE_HELP_MSG)
		response.error = true
		response.message = API_CHECKOUT_STATUS_MSG
		_signal_checkout_status(response)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		var msg = API_CREATE_CHECKOUT_MSG + " " + json.message
		push_error(API_CREATE_CHECKOUT_MSG)
		response.error = true
		response.message = msg
		_signal_checkout_status(response)
	else:
		response.data = json
		_signal_checkout_status(response)

func _signal_prices_received(response: ZalanceResponse):
	prices_received.connect(_get_prices_callable)
	prices_received.emit(response)
	prices_received.disconnect(_get_prices_callable)
	_get_prices_callable = func(): pass

func _signal_checkout_created(value):
	checkout_created.connect(_checkout_created_callable)
	checkout_created.emit(value)
	checkout_created.disconnect(_checkout_created_callable)
	_checkout_created_callable = func(): pass

func _signal_checkout_status(value):
	checkout_status.connect(_checkout_status_callable)
	checkout_status.emit(value)
	checkout_status.disconnect(_checkout_status_callable)
	_checkout_status_callable = func(): pass
