class_name ZalanceItem
extends Control

var _item_data = null
var _image_url = null

# Called when the node enters the scene tree for the first time.
#func _ready():
	#pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func set_data(item_data):
	_item_data = item_data
	%ItemTitle.text = item_data.name
	set_image(item_data.image.url)
	%ItemButton.text = item_data.display_amount
	
func update_size(x, y):
	set_size(x, y)
	
func set_image(url: String):
	_image_url = url
	if _image_url != null and _image_url.length() > 0:
		Zalance.get_image(url, _on_image_request_complete)

# Called when the Image request is completed.
func _on_image_request_complete(response):
	if response.error:
		push_error("Couldn't load the image: " + _image_url)
		return
	
	var image = response.data.image
	var texture = ImageTexture.create_from_image(image)
	
	# Display the image in a TextureRect node.
	%ItemImage.texture = texture

func _on_item_button_pressed():
	ZalanceSignals.item_clicked.emit(_item_data)
	pass # Replace with function body.
