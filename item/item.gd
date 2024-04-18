class_name Item
extends Control

var _item_data = null
var _image_url = null

# Called when the node enters the scene tree for the first time.
#func _ready():
	#pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_data(item_data):
	_item_data = item_data
	%ItemTitle.text = item_data.name
	set_image(item_data.image.url)
	%ItemButton.text = item_data.display_amount

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

func _on_item_button_pressed():
	Events.emit_signal("item_clicked", _item_data)
	pass # Replace with function body.
