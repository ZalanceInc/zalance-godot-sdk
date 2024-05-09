class_name ZalanceItem
extends Control

var _item_data = null
var _image_url = null
@onready var _orig_size: Vector2 = get_size()
@onready var _orig_scale: Vector2 = get_scale()

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
	%ItemPrice.text = item_data.display_amount


func update_size(x, y):
	var v = Vector2(x, y)
	set_size(v)
	_orig_size = v

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


func _on_pressed():
	ZalanceSignals.item_clicked.emit(_item_data)


func _on_mouse_entered():
	var v = Vector2(_orig_size.x + 10, _orig_size.y + 10)
	var s = get_scale() * 1.01
	set_scale(s)
	#var styleBox := StyleBoxFlat.new()
	#styleBox.shadow_size = 5
	#styleBox.shadow_color = Color(1, 1, 1, 0.6)
	#add_theme_stylebox_override("normal", styleBox)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited():
	set_scale(_orig_scale)
	#var stylebox_flat := StyleBoxFlat.new()
	#stylebox_flat.shadow_size = 0
	#add_theme_stylebox_override("normal", stylebox_flat)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

