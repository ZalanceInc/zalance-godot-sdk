@tool
extends EditorPlugin

const ZALANCE_AUTOLOAD_NAME = "Zalance"
const ZALANCE_AUTOLOAD_SOURCE = "./zalanceapi.gd"
#const EVENTS_AUTOLOAD_NAME = "ZalanceEvents"
#const EVENTS_AUTOLOAD_SOURCE = "./events.gd"
var interface = preload("./interface/interface.tscn").instantiate()


func _enter_tree():
	add_custom_type("ZalanceAPI", "Node2D", preload("zalanceapi.gd"), preload("zalance.svg"))
	add_autoload_singleton(ZALANCE_AUTOLOAD_NAME, ZALANCE_AUTOLOAD_SOURCE)
	#add_autoload_singleton(EVENTS_AUTOLOAD_NAME, EVENTS_AUTOLOAD_SOURCE)
	add_control_to_bottom_panel(interface, "Zalance")


func _exit_tree():
	remove_custom_type("ZalanceAPI")
	remove_autoload_singleton(ZALANCE_AUTOLOAD_NAME)
	#remove_autoload_singleton(EVENTS_AUTOLOAD_NAME)
	remove_control_from_bottom_panel(interface)
	interface.free()

