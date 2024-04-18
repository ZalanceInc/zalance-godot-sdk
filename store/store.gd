extends Node

const CHECKOUT_WAIT_TIME = 2.0
var checkout_timer: Timer = Timer.new()

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
	
	ZalanceSDK.get_prices(50, 1, _on_prices_received)

func _process(_delta):
	pass

func _exit_tree():
	pass

func _on_prices_received(prices):
	if prices != null:
		%ItemGrid.set_items(prices)

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
	ZalanceSDK.create_checkout_session(price_id, quantity, _on_checkout_created)

func _on_checkout_created(id):
	if id != null:
		checkout_timer.start(CHECKOUT_WAIT_TIME)

func _on_checkout_timer_complete():
	ZalanceSDK.get_checkout_session_status(_on_checkout_status)
	
func _on_checkout_status(session):
	if session == null:
		pass
	elif session.status == "expired":
		pass
	elif session.status == "complete":
		Events.checkout_complete.emit(session)
	elif session.status == "":
		_on_checkout_created(session.session_id)
