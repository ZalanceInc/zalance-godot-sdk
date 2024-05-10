extends FlowContainer
class_name ZalanceItemGrid

var ZalanceItemClass = preload("./item.tscn")
var items: PackedByteArray = []
var item_size_x = 200	
var item_size_y = 250


# Called when the node enters the scene tree for the first time.
func _ready():
	load_data()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass


func load_data() -> void:
	_remove_children()
	var fileExists = FileAccess.file_exists(ZalanceData.save_path)
	if fileExists:
		var data:ZalanceData = load(ZalanceData.save_path)
		set_array_item_size(data.item_width, data.item_height)


func _remove_children():
	for n in get_children():
		remove_child(n)
		n.queue_free()


func set_items(items):
	_remove_children()
	append_items(items)


func append_items(items):
	for item in items:
		_add_item(item)


func _add_item(item_data):
	var item_class = ZalanceItemClass.instantiate()
	set_item_size(item_class, item_size_x, item_size_y)
	add_child(item_class)
	item_class.set_data(item_data)


func set_array_item_size(x: int, y: int):
	item_size_x = x
	item_size_y = y
	
	for n in get_children():
		var size = Vector2(x, y)
		set_item_size(n, x, y)


func set_item_size(item, x: int, y: int):
	if x < ZalanceData.MIN_ITEM_WIDTH:
		x = ZalanceData.MIN_ITEM_WIDTH
	if y < ZalanceData.MIN_ITEM_HEIGHT:
		y = ZalanceData.MIN_ITEM_HEIGHT
	
	var size = Vector2(x, y)
	item.set_custom_minimum_size(size)


func get_item_size():
	return Vector2(item_size_x, item_size_y)


func expand_item_size(item, grid_width, y):
	pass

