class_name Zalance
extends HTTPRequest

const API_PUBLIC_DOMAIN = "https://api.zalance.net/api:Kp9D5gmw"
const API_PRICES_GET = API_PUBLIC_DOMAIN + '/price/{project_uuid}'
const API_SESSION_CREATE = API_PUBLIC_DOMAIN + '/session'
const API_SESSION_STATUS = API_PUBLIC_DOMAIN + '/session/status'
var project_id = "bb632f31-9e6b-439f-8f9a-1d019085a391"
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

signal prices_received
signal checkout_created(id)
signal checkout_status(json)

func _ready():
	print("zalance is ready!")
	pass

func get_prices(count: int, page: int, callback: Callable):
	var url = API_PRICES_GET.format({"project_uuid": project_id})
	var err := request(url, [], HTTPClient.METHOD_POST)
	if err:
		return err
	
	_get_prices_callable = callback
	request_completed.connect(_on_prices_completed)

func _on_prices_completed(result, response_code, headers, body):
	request_completed.disconnect(_on_prices_completed)
	if result != RESULT_SUCCESS:
		push_error("Prices couldn't be fetched. Check your project Id is correct and try again. If you continue to have problems, contact support@zalance.net")
		_signal_prices_received(null)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		push_error("Zalance: failed to get prices. " + json.message)
		_signal_prices_received(null)
	else:
		_prices = json.items
		_prices_next_page = json.nextPage
		_prices_prev_page = json.prevPage
		_signal_prices_received(_prices)

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
		"return_url": "https://zalance.net",
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
	return 0

func _on_create_checkout_session_completed(result, response_code, headers, body):
	request_completed.disconnect(_on_create_checkout_session_completed)
	if result != RESULT_SUCCESS:
		push_error("Checkout session couldn't be created. Check your project Id is correct and try again. If you continue to have problems, contact support@zalance.net")
		_signal_checkout_created(null)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		push_error("Zalance: Error in create checkout session. " + json.message)
		_signal_checkout_created(null)
	else:
		_session_id = json.id
		_create_checkout_browser(json.url)
		_signal_checkout_created(_session_id)

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
	if result != RESULT_SUCCESS:
		push_error("Prices couldn't be fetched. Check your project Id is correct and try again. If you continue to have problems, contact support@zalance.net")
		_signal_checkout_status(null)
		return
	
	json = JSON.parse_string(body.get_string_from_utf8());
	
	if response_code != HTTPClient.RESPONSE_OK:
		push_error("Zalance: Error in get session status. " + json.message)
		_signal_checkout_status(null)
	else:
		_signal_checkout_status(json)

func _signal_prices_received(value):
	prices_received.connect(_get_prices_callable)
	prices_received.emit(value)
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
