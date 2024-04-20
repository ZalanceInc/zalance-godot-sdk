@tool
extends EditorPlugin

const AUTOLOAD_NAME = "Zalance"
const AUTOLOAD_SOURCE = "res://addons/zalance/zalanceapi.gd"
var interface = preload("res://addons/zalance/interface.tscn").instantiate()

func _enter_tree():
	#add_custom_type("Zalance", "HTTPRequest", preload("zalanceapi.gd"), preload("zalance.svg"))
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_SOURCE)
	add_control_to_bottom_panel(interface, "Zalance")

func _exit_tree():
	#remove_custom_type("Zalance")
	remove_autoload_singleton(AUTOLOAD_NAME)
	remove_control_from_bottom_panel(interface)
	interface.free()
