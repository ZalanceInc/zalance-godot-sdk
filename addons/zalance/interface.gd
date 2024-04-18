@tool
extends Control

var livemode = false
var projectId = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	livemode = $LivemodeCheckBox.button_pressed
	projectId = $ProjectId.text
	print("projectId: " + projectId + ", livemode: " + str(livemode))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_project_id_text_changed():
	projectId = $ProjectId.text
	print("projectId: " + projectId)

func _on_livemode_check_box_pressed():
	livemode = $LivemodeCheckBox.button_pressed
	print("livemode: " + str(livemode))

func _on_button_pressed():
	print("getting zalance prices")
	var result = Zalance.new().get_prices(50, 1)
