extends Node

const CHECKOUT_WAIT_TIME = 4.0
var checkout_timer: Timer = Timer.new()
var next_page = null
var prev_page = null

func _ready():
	checkout_timer.one_shot = true;
	checkout_timer.autostart = false;
	checkout_timer.wait_time = CHECKOUT_WAIT_TIME;
	checkout_timer.timeout.connect(_on_checkout_timer_complete)
	add_child(checkout_timer)
	
	Events.connect("item_clicked", self._on_item_clicked)
	Events.connect("item_add_to_cart", self._on_item_add_to_cart)
	Events.connect("item_buy_now", self._on_item_buy_now)
	Events.connect("order_back_press", self._on_order_back_press)
	
	%StoreMessage.text = ""
	var err = Zalance.get_prices(50, 1, _on_prices_received)
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
		%ItemGrid.append_items(response.data.items)
		next_page = response.data.next_page
		prev_page = response.data.prev_page

func _on_item_clicked(item):
	%Order.visible = true
	%GridScroll.visible = false
	%Order.set_data(item)

func _on_order_back_press():
	%Order.visible = false
	%GridScroll.visible = true

func _on_item_add_to_cart(item):
	print("Item add to cart was clicked!")

func _on_item_buy_now(price_id, quantity):
	var err = Zalance.create_checkout_session(price_id, quantity, _on_checkout_created)
	if err:
		%StoreMessage.text = "There was an error while creating checkout. Error: " + String(err)

func _on_checkout_created(response):
	if response.error:
		%StoreMessage.text = response.message
	else:
		checkout_timer.start(CHECKOUT_WAIT_TIME)

func _on_checkout_timer_complete():
	var err = Zalance.get_checkout_session_status(_on_checkout_status)
	if err:
		%StoreMessage.text = "There was an error updating the checkout status. Error: " + String(err)

func _on_checkout_status(response):
	if response.error:
		%StoreMessage.text = response.message
	if response.data == null:
		pass
	elif response.data.status == "expired":
		pass
	elif response.data.status == "complete":
		Events.checkout_complete.emit(response.data)
	elif response.data.status == "":
		_on_checkout_created(response)
