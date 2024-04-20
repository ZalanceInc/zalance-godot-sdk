extends GridContainer

var ItemClass = preload("res://item/item.tscn")
var items: PackedByteArray = [] 

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
	var item_class = ItemClass.instantiate()
	add_child(item_class)
	item_class.set_data(item_data)
