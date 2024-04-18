class_name Order
extends Control

var _item_data = null
var _image_url = null
var _quantity = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("checkout_complete", self._on_checkout_complete)

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
		_loadImage(_image_url)

func _loadImage(url):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._on_image_request_complete)
	
	var error = http_request.request(url)		#_image_url	#"https://via.placeholder.com/64"
	if error != OK:
		push_error("An error occurred in the HTTP request.")

# Called when the Image request is completed.
func _on_image_request_complete(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Image couldn't be downloaded. Try a different image.")
	
	# Handle redirect
	if response_code >= 300 and response_code < 400:
		var url = body.get_string_from_utf8()
		if url != null and url.length() > 0:
			_loadImage(url)
		return
	
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("Couldn't load the image.")

	var texture = ImageTexture.create_from_image(image)

	# Display the image in a TextureRect node.
	%ItemImage.texture = texture

func _on_add_to_cart_btn_pressed():
	Events.emit_signal("item_add_to_cart", _item_data)

func _on_buy_now_btn_pressed():
	Events.emit_signal("item_buy_now", _item_data.price_id, _quantity)
	_show_purchasing_button()

func _on_back_button_pressed():
	Events.emit_signal("order_back_press")
	
func _show_purchasing_button():
	%BuyNowBtn.text = "Processing..."
	%BuyNowBtn.disabled = true

func _show_buy_now():
	%BuyNowBtn.text = "Buy Now"
	%BuyNowBtn.disabled = false
	
func _show_order_complete():
	%BuyNowBtn.text = "Order Complete!"
	%BuyNowBtn.disabled = true
	
func _on_checkout_complete(session):
	_show_order_complete()
