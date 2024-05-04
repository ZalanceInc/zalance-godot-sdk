extends Node

var next_page = null
var prev_page = null

func _ready():
	ZalanceSignals.item_clicked.connect(self._on_item_clicked)
	ZalanceSignals.item_add_to_cart.connect(self._on_item_add_to_cart)
	ZalanceSignals.order_back_press.connect(self._on_order_back_press)
	%StoreMessage.text = ""
	
	var err = Zalance.get_prices(_on_prices_received, 50, 1)
	if err:
		%StoreMessage.text = "There was an error while retrieving store items. Error: " + String(err)

func _process(_delta):
	pass

func _exit_tree():
	pass

func _on_prices_received(response):
	if response.error:
		%StoreMessage.text = response.message
	else:
		%ZalanceItemGrid.append_items(response.data.items)
		next_page = response.data.next_page
		prev_page = response.data.prev_page

func _on_item_clicked(item):
	#%ZalanceOrder.visible = true
	%GridScroll.visible = false
	#%ZalanceOrder.set_data(item)

func _on_order_back_press():
	#%ZalanceOrder.visible = false
	%GridScroll.visible = true

func _on_item_add_to_cart(item):
	print("Item add to cart was clicked!")
