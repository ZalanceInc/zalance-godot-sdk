extends Node
class_name ZalanceStore

var _next_page = 1
var _prev_page = null
@onready var _vscrollbar: VScrollBar = %GridScroll.get_v_scroll_bar()
const GET_PRICES_COUNT = 20

func _ready():
	ZalanceSignals.item_clicked.connect(self._on_item_clicked)
	ZalanceSignals.item_add_to_cart.connect(self._on_item_add_to_cart)
	ZalanceSignals.order_back_press.connect(self._on_order_back_press)
	%StoreMessage.text = ""
	
	_vscrollbar.value_changed.connect(self._on_vscroll_changed)
	_get_next_items()


func _process(_delta):
	pass


func _exit_tree():
	pass


func set_grid_visible(isVisible: bool):
	%GridScroll.visible = isVisible


func fetch_items():
	_next_page = 1
	_prev_page = null
	%ZalanceItemGrid.set_items([])
	_get_next_items()


func _on_vscroll_changed(value: float):
	var item_size = %ZalanceItemGrid.get_item_size()
	var scrollbar_size = _vscrollbar.get_rect().size
	# print("max_value: " + str(_vscrollbar.max_value) + ", scroll_vertical: " + str(%GridScroll.scroll_vertical) + ", item_size.y: " + str(item_size.y))
	var scroll_pos = %GridScroll.scroll_vertical + scrollbar_size.y + item_size.y
	if scroll_pos > _vscrollbar.max_value:
		_get_next_items()


func _get_next_items():
	if _next_page == null:
		return
	
	var err = Zalance.get_prices(_on_prices_received, GET_PRICES_COUNT, _next_page)
	if err:
		%StoreMessage.text = "There was an error while retrieving store items. Error: " + str(err)
	# Prevent querying the same page multiple times
	_next_page = null


func _on_prices_received(response):
	if response.error:
		%StoreMessage.text = response.message
	else:
		%ZalanceItemGrid.append_items(response.data.items)
		_next_page = response.data.next_page
		_prev_page = response.data.prev_page


func _on_item_clicked(item):
	set_grid_visible(false)


func _on_order_back_press():
	set_grid_visible(true)


func _on_item_add_to_cart(item):
	print("Item add to cart was clicked!")

