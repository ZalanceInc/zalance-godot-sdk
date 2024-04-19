@tool
extends Control

var projectId = ""
var return_url = ""
var livemode = false

# Called when the node enters the scene tree for the first time.
func _ready():
	#livemode = $LivemodeCheckBox.button_pressed
	#projectId = $ProjectId.text
	load_data()
	print("projectId: " + projectId + ", livemode: " + str(livemode))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_project_id_text_changed():
	projectId = $ProjectId.text
	#print("projectId: " + projectId)
	save()

func _on_return_url_text_changed():
	return_url = $ReturnUrl.text
	print("return_url: " + return_url)
	save()

func _on_livemode_check_box_pressed():
	livemode = $LivemodeCheckBox.button_pressed
	print("livemode: " + str(livemode))
	save()

func _on_button_pressed():
	print("getting zalance prices")
	var result = Zalance.new().get_prices(50, 1, _get_prices_completed)

func _get_prices_completed(items):
	pass

func save() -> void:
	#print('saving data')
	var data := ZalanceData.new()
	data.project_id = projectId
	data.return_url = return_url
	data.livemode = livemode

	var error := ResourceSaver.save(data, ZalanceData.save_path)
	if error:
		print("An error happened while saving data: ", error)
	else:
		print("Zalance data saved.")

func load_data() -> void:
	var data:ZalanceData = load(ZalanceData.save_path)
	projectId = data.project_id
	$ProjectId.text = projectId
	return_url = data.return_url
	$ReturnUrl.text = return_url
	livemode = data.livemode
	$LivemodeCheckBox.button_pressed = livemode
	
