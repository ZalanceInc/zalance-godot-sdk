@tool
extends Resource
class_name ZalanceData

static var save_path = "user://zalance_data.tres"
static var MIN_ITEM_WIDTH = 100
static var MIN_ITEM_HEIGHT = 100
static var TEST_PROJECT_ID = "bb632f31-9e6b-439f-8f9a-1d019085a391"
static var TEST_ACCOUNT_ID = "1120456E26F41EFC"
static var TEST_RETURN_URL = "https://zalance.net/"
@export var project_id: String = ""
@export var livemode: bool = false
@export var return_url: String = ""
@export var item_width: int = 0
@export var item_height: int = 0
