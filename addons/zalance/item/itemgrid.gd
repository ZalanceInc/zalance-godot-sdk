extends GridContainer
class_name ZalanceItemGrid

var ZalanceItemClass = preload("./item.tscn")
var items: PackedByteArray = []
var item_size_x = 200
var item_size_y = 250

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

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
	var size = Vector2(x, y)
	item.set_custom_minimum_size(size)

func expand_item_size(item, grid_width, y):
	var c = columns if columns > 0 else 1
	var x = grid_width / (columns if columns > 0 else 1)
	var size = Vector2(x, y)
	item.set_custom_minimum_size(size)
