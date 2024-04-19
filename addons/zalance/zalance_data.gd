@tool
extends Resource
class_name ZalanceData

static var save_path = "user://zalance_data.tres"
@export var project_id: String = ""
@export var livemode: bool = false
@export var return_url: String = ""
