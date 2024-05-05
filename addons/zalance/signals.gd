extends Node
class_name ZalanceSignals

# We can also define a helper static method:
static func make_signal(p_obj, p_signal_name: StringName) -> Signal:
	# We use GDScript's duck typing to avoid having to cast p_obj.
	p_obj.add_user_signal(p_signal_name)
	return Signal(p_obj, p_signal_name)


static var store_item_clicked: Signal = make_signal(ZalanceSignals, "store_item_clicked")
static var item_clicked: Signal = make_signal(ZalanceSignals, "item_clicked")
static var item_buy_now: Signal = make_signal(ZalanceSignals, "item_buy_now")
static var item_add_to_cart: Signal = make_signal(ZalanceSignals, "item_add_to_cart")
static var order_back_press: Signal = make_signal(ZalanceSignals, "order_back_press")
static var checkout_complete: Signal = make_signal(ZalanceSignals, "checkout_complete")

#signal item_clicked(item)
#signal item_buy_now(price_id, quantity)
#signal item_add_to_cart(item)
#signal order_back_press()
#signal checkout_complete(item)
