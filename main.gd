extends Node

@onready var zalance_store = $ZalanceStore

func _ready():
	# Set to a test account Id
	Zalance.set_account_id("1120456E26F41EFC")
	Zalance.set_locale("en-US")
	zalance_store.fetch_items()
	
	print("Zalance test account Id: " + Zalance.account_id)
	print("Zalance locale: " + Zalance.locale)


#func _process(delta):
	#pass

