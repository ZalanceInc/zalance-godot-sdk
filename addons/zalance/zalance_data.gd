@tool
extends Resource
class_name ZalanceData

static var save_path = "user://zalance_data.tres"
@export var project_id: String = ""
@export var livemode: bool = false
@export var return_url: String = ""
@export var columns: int = 0
@export var item_width: int = 0
@export var item_height: int = 0
