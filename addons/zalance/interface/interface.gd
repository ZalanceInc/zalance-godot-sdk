@tool
extends Control

var project_id = ZalanceData.TEST_PROJECT_ID
var return_url = ZalanceData.TEST_RETURN_URL
var livemode = false
var item_width: int = 200
var item_height: int = 250
var regex = RegEx.new()
const ZalanceAPI = preload("../zalanceapi.gd")
var zalance: ZalanceAPI = null


# Called when the node enters the scene tree for the first time.
func _ready():
	regex.compile("^[0-9]*$")
	zalance = ZalanceAPI.new()
	add_child(zalance)
	load_data()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_project_id_text_changed():
	project_id = %ProjectId.text
	#print("project_id: " + project_id)
	save()


func _on_return_url_text_changed():
	return_url = %ReturnUrl.text
	#print("return_url: " + return_url)
	save()


func _on_livemode_check_box_pressed():
	livemode = %LivemodeCheckBox.button_pressed
	print("_on_livemode_check_box_pressed: " + str(livemode))
	save()
	zalance.set_livemode(livemode)


func _on_item_width_text_changed():
	if regex.search(%ItemWidth.text):
		item_width = int(%ItemWidth.text)
		save()
	else:
		%ItemWidth.text = str(item_width)
	%ItemWidth.set_caret_column(%ItemWidth.text.length())


func _on_item_height_text_changed():
	if regex.search(%ItemHeight.text):
		item_height = int(%ItemHeight.text)
		save()
	else:
		%ItemHeight.text = str(item_height)
	%ItemHeight.set_caret_column(%ItemHeight.text.length())


func _on_button_pressed():
	%Output.text = "Testing Zalance connection to project..."
	var err = zalance.get_prices(_on_prices_received, 50, 1)
	if err:
		%Output.text += "\nError retrieving price items. \nError: " + str(err)

func _on_prices_received(response):
	#$Output.text = "test: " + response.message + ", error: " + str(response.error)
	if response.error:
		%Output.text += '\nError: ' + response.message
	else:
		%Output.text += '\nSuccess!'
		%Output.text += '\n' + "Item count: " + str(response.data.items.size())


func _on_tab_bar_tab_selected(tab):
	print(str(tab))


func save() -> void:
	var data := ZalanceData.new()
	data.project_id = project_id
	data.return_url = return_url
	data.livemode = livemode
	data.item_width = item_width
	data.item_height = item_height
	#print("data: ", data.project_id, " ", data.return_url, " ", data.livemode)

	var error := ResourceSaver.save(data, ZalanceData.save_path)
	if error:
		print("An error happened while saving data: ", error)
	else:
		print("Zalance data saved.")
	
	%LivemodeCheckBox.button_pressed = livemode


func load_data() -> void:
	var fileExists = FileAccess.file_exists(ZalanceData.save_path)
	if fileExists:
		var data:ZalanceData = load(ZalanceData.save_path)
		project_id = data.project_id
		return_url = data.return_url
		livemode = data.livemode
		item_width = data.item_width
		item_height = data.item_height
	
	update_form()


func update_form() -> void:
	%ProjectId.text = project_id
	%ReturnUrl.text = return_url
	%LivemodeCheckBox.button_pressed = livemode
	%ItemWidth.text = str(item_width)
	%ItemHeight.text = str(item_height)
