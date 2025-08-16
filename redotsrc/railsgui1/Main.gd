extends Control

@onready var models_container = $VBoxContainer/ModelsContainer
@onready var controllers_container = $VBoxContainer/ControllersContainer
@onready var views_container = $VBoxContainer/ViewsContainer
@onready var settings_container = $VBoxContainer/SettingsContainer
@onready var line_edit_new_type = $VBoxContainer/ModelsContainer/Sidebar/VBoxContainer/NewDataTypeForm/LineEditNewType
@onready var model_list = $VBoxContainer/ModelsContainer/Sidebar/VBoxContainer/ModelList
@onready var line_edit_project_path = $VBoxContainer/SettingsContainer/VBoxContainer/HBoxContainer/LineEditProjectPath

var rails_project_path = ""
var settings_file = "user://settings.cfg"

func _ready():
	models_container.show()
	controllers_container.hide()
	views_container.hide()
	settings_container.hide()
	_load_settings()
	_load_models()


func _load_settings():
	var config = ConfigFile.new()
	var err = config.load(settings_file)
	if err == OK:
		rails_project_path = config.get_value("paths", "rails_project", "")
		line_edit_project_path.text = rails_project_path

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("paths", "rails_project", rails_project_path)
	config.save(settings_file)


func _load_models():
	model_list.clear()
	
	if rails_project_path.is_empty():
		return

	var output = []
	var command = "cd " + rails_project_path + " && ls app/models/*.rb"
	var exit_code = OS.execute("bash", ["-l", "-c", command], output, true)
	
	if exit_code == 0:
		if !output.is_empty():
			var all_lines = output[0].split("\n")
			for line in all_lines:
				if !line.is_empty():
					var file_path = line.strip_edges()
					var file_name = file_path.get_file()
					var model_name = file_name.get_basename()
					if model_name != "application_record":
						model_list.add_item(model_name.capitalize())
	else:
		print("Error loading models: " + str(exit_code))
		for line in output:
			print(line)


func _on_ModelsButton_pressed():
	models_container.show()
	controllers_container.hide()
	views_container.hide()
	settings_container.hide()


func _on_ControllersButton_pressed():
	models_container.hide()
	controllers_container.show()
	views_container.hide()
	settings_container.hide()


func _on_ViewsButton_pressed():
	models_container.hide()
	controllers_container.hide()
	views_container.show()
	settings_container.hide()


func _on_SettingsButton_pressed():
	models_container.hide()
	controllers_container.hide()
	views_container.hide()
	settings_container.show()


func _on_ButtonSaveSettings_pressed():
	rails_project_path = line_edit_project_path.text
	_save_settings()
	_load_models()


func _on_ButtonSaveNewType_pressed():
	var type_name = line_edit_new_type.text
	if type_name.is_empty():
		return

	var command = "cd " + rails_project_path + " && rails generate scaffold " + type_name + ""
	
	var output = []
	var exit_code = OS.execute("bash", ["-l", "-c", command], output, true)
	if exit_code == 0:
		line_edit_new_type.text = ""
		_load_models()
	else:
		print("Error creating scaffold: " + str(exit_code))
		for line in output:
			print(line)
