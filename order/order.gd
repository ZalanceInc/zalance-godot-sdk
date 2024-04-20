class_name Order
extends Control

var _item_data = null
var _image_url = null
var _quantity = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	Events.connect("checkout_complete", self._on_checkout_complete)
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
		ZalanceSDK.get_image(_image_url, _on_image_request_complete)

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

func _on_checkout_complete(_session):
	_show_order_complete()

func _show_error(msg):
	if msg == null:
		%ErrorMsg.text = "";
		%ErrorMsg.visible = false;
	else:
		%ErrorMsg.text = msg;
		%ErrorMsg.visible = true;
		push_error(msg)
