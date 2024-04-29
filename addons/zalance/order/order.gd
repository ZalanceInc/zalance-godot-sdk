class_name ZalanceOrder
extends Control

var _item_data = null
var _image_url = null
var _quantity = 1
var checkout_timer: Timer = Timer.new()
const CHECKOUT_WAIT_TIME = 4.0

# Called when the node enters the scene tree for the first time.
func _ready():
	checkout_timer.one_shot = true;
	checkout_timer.autostart = false;
	checkout_timer.wait_time = CHECKOUT_WAIT_TIME;
	checkout_timer.timeout.connect(_on_checkout_timer_complete)
	add_child(checkout_timer)
	
	ZalanceSignals.checkout_complete.connect(self._on_checkout_complete)
	ZalanceSignals.item_buy_now.connect(self._on_item_buy_now)
	#ZalanceEvents.connect("item_clicked", self._on_item_clicked)
	#ZalanceEvents.connect("item_add_to_cart", self._on_item_add_to_cart)
	#ZalanceEvents.connect("order_back_press", self._on_order_back_press)
	
	_show_error(null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func set_data(item_data):
	_item_data = item_data
	%ItemTitle.text = item_data.name
	%ItemDesc.text = item_data.description
	set_image(item_data.image.url)
	%ItemPrice.text = item_data.display_amount
	_show_buy_now()
	
func set_image(url: String):
	_image_url = url
	if _image_url != null and _image_url.length() > 0:
		Zalance.get_image(_image_url, _on_image_request_complete)

# Called when the Image request is completed.
func _on_image_request_complete(response):
	if response.error:
		push_error("Couldn't load the image: " + _image_url)
		return
	
	var image = response.data.image
	var texture = ImageTexture.create_from_image(image)

	# Display the image in a TextureRect node.
	%ItemImage.texture = texture
	
func is_header_png(value):
	return value.begins_with("Content-Type") and value.ends_with("image/png")

func _on_add_to_cart_btn_pressed():
	ZalanceSignals.item_add_to_cart.emit(_item_data)

func _on_buy_now_btn_pressed():
	ZalanceSignals.item_buy_now.emit(_item_data.price_id, _quantity)
	_show_purchasing_button()

func _on_back_button_pressed():
	ZalanceSignals.order_back_press.emit()

func _show_purchasing_button():
	%BuyNowBtn.text = "Processing..."
	%BuyNowBtn.disabled = true

func _show_buy_now():
	%BuyNowBtn.text = "Buy Now"
	%BuyNowBtn.disabled = false

func _show_order_complete():
	%BuyNowBtn.text = "Order Complete!"
	%BuyNowBtn.disabled = true

func _on_checkout_complete(_session):
	_show_order_complete()

func _on_item_buy_now(price_id, quantity):
	_show_error(null)
	var err = Zalance.create_checkout_session(price_id, quantity, _on_checkout_created)
	if err:
		var msg = "There was an error while creating checkout. Error: " + String(err)
		_show_error(msg)

func _on_checkout_created(response):
	if response.error:
		_show_error(response.message)
		_show_buy_now()
	else:
		checkout_timer.start(CHECKOUT_WAIT_TIME)

func _on_checkout_timer_complete():
	var err = Zalance.get_checkout_session_status(_on_checkout_status)
	if err:
		var msg = "There was an error updating the checkout status. Error: " + String(err)
		_show_error(msg)

func _on_checkout_status(response):
	if response.error:
		_show_error(response.message)
	if response.data == null:
		pass
	elif response.data.status == "expired":
		pass
	elif response.data.status == "complete":
		ZalanceSignals.checkout_complete.emit(response.data)
	elif response.data.status == "":
		_on_checkout_created(response)

func _show_error(msg):
	if msg == null:
		%ErrorMsg.text = "";
		%ErrorMsg.visible = false;
	else:
		%ErrorMsg.text = msg;
		%ErrorMsg.visible = true;
		push_error(msg)
