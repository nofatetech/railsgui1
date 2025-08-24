extends Control

@onready var models_container = $VBoxContainer/ModelsContainer
@onready var controllers_container = $VBoxContainer/ControllersContainer
@onready var views_container = $VBoxContainer/ViewsContainer
@onready var settings_container = $VBoxContainer/SettingsContainer
@onready var line_edit_new_type = $VBoxContainer/ModelsContainer/Sidebar/VBoxContainer/NewDataTypeForm/LineEditNewType
@onready var model_list = $VBoxContainer/ModelsContainer/Sidebar/VBoxContainer/ModelList
@onready var line_edit_project_path = $VBoxContainer/SettingsContainer/VBoxContainer/HBoxContainer/LineEditProjectPath
@onready var selected_model_label = $VBoxContainer/ModelsContainer/Editor/VBoxContainer/SelectedModelLabel
@onready var fields_grid_container = $VBoxContainer/ModelsContainer/Editor/VBoxContainer/FieldsGridContainer
@onready var line_edit_new_field_name = $VBoxContainer/ModelsContainer/Editor/VBoxContainer/AddFieldHBoxContainer/LineEditNewFieldName
@onready var option_button_new_field_type = $VBoxContainer/ModelsContainer/Editor/VBoxContainer/AddFieldHBoxContainer/OptionButtonNewFieldType
@onready var option_button_new_field_reference = $VBoxContainer/ModelsContainer/Editor/VBoxContainer/AddFieldHBoxContainer/OptionButtonNewFieldReference

var rails_project_path = ""
var settings_file = "user://settings.cfg"
var models_data = []

func _ready():
	models_container.show()
	controllers_container.hide()
	views_container.hide()
	settings_container.hide()
	_load_settings()
	
	option_button_new_field_type.add_item("string")
	option_button_new_field_type.add_item("text")
	option_button_new_field_type.add_item("integer")
	option_button_new_field_type.add_item("float")
	option_button_new_field_type.add_item("boolean")
	option_button_new_field_type.add_item("date")
	option_button_new_field_type.add_item("datetime")
	option_button_new_field_type.add_item("references")
	option_button_new_field_type.add_item("has_many")
	option_button_new_field_type.connect("item_selected", _on_NewFieldType_item_selected)

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
	print("-- LOAD MODELS")
	model_list.clear()
	option_button_new_field_reference.clear()
	models_data.clear()

	if rails_project_path.is_empty():
		return

	var output = []
	var command = "cp ../../railsfiles/bin/xgui_*.rb " + rails_project_path + "/bin/"
	var exit_code = OS.execute("bash", ["-l", "-c", command], output, true)

	output = []
	command = "cd " + rails_project_path + " && bundle exec bin/xgui_analyze_models.rb"
	exit_code = OS.execute("bash", ["-l", "-c", command], output, true)

	if exit_code == 0:
		if !output.is_empty():
			var json_string = output[0]
			var json = JSON.new()
			var error = json.parse(json_string)
			if error == OK:
				var models = json.get_data()
				if models is Array:
					models_data = models
					for model in models:
						if model is Dictionary and model.has("model_name"):
							var model_name = model["model_name"]
							model_list.add_item(model_name)
							option_button_new_field_reference.add_item(model_name)
			else:
				print("Error parsing JSON: " + json.get_error_message() + " in " + json_string)
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


func _clear_fields():
	for child in fields_grid_container.get_children():
		child.queue_free()


func _on_ModelList_item_selected(index):
	var model_name = model_list.get_item_text(index)
	selected_model_label.text = model_name
	_clear_fields()

	var selected_model_data = null
	for model in models_data:
		if model is Dictionary and model.has("model_name") and model["model_name"] == model_name:
			selected_model_data = model
			break

	if selected_model_data and selected_model_data.has("attributes"):
		var attributes = selected_model_data["attributes"]
		if attributes is Array:
			for attribute in attributes:
				if attribute is Dictionary and attribute.has("name") and attribute.has("type"):
					var field_label = Label.new()
					field_label.text = attribute["name"]
					fields_grid_container.add_child(field_label)
					var type_label = Label.new()
					type_label.text = attribute["type"]
					fields_grid_container.add_child(type_label)

	if selected_model_data and selected_model_data.has("associations"):
		var associations = selected_model_data["associations"]
		if associations is Array:
			for association in associations:
				if association is Dictionary and association.has("macro") and association.has("name"):
					var association_label = Label.new()
					association_label.text = association["macro"] + ": " + association["name"]
					fields_grid_container.add_child(association_label)
					var empty_label = Label.new()
					empty_label.text = ""
					fields_grid_container.add_child(empty_label)


func _on_ButtonSaveNewType_pressed():
	var type_name = line_edit_new_type.text
	if type_name.is_empty():
		return

	var command = "cd " + rails_project_path + " && rails generate scaffold " + type_name + " " + " && rails db:migrate"
	
	var output = []
	var exit_code = OS.execute("bash", ["-l", "-c", command], output, true)
	if exit_code == 0:
		line_edit_new_type.text = ""
		_load_models()
	else:
		print("Error creating scaffold: " + str(exit_code))
		for line in output:
			print(line)


func _on_NewFieldType_item_selected(index):
	print("_on_NewFieldType_item_selected")
	var type = option_button_new_field_type.get_item_text(index)
	if type == "references" or type == "has_many":
		option_button_new_field_reference.show()
	else:
		option_button_new_field_reference.hide()


func _on_ButtonAddNewField_pressed():
	print("_on_ButtonAddNewField_pressed")
	var selected_index = model_list.get_selected_items()[0]
	var model_a_name = model_list.get_item_text(selected_index)
	
	var field_name = line_edit_new_field_name.text
	#print("_on_ButtonAddNewField_pressed 002 ", field_name)
	if field_name.is_empty():
		return

	var field_type = option_button_new_field_type.get_item_text(option_button_new_field_type.selected)
	
	if field_type == "has_many":
		var model_b_name = option_button_new_field_reference.get_item_text(option_button_new_field_reference.selected)
		
		# 1. Migration
		var migration_command = "cd " + rails_project_path + " && rails generate migration Add" + model_a_name + "To" + model_b_name + " " + model_a_name.to_lower() + ":references"
		var output = []
		var exit_code = OS.execute("bash", ["-l", "-c", migration_command], output, true)
		if exit_code != 0:
			print("Error creating migration: " + str(exit_code))
			for line in output:
				print(line)
			return

		# 2. Modify ModelA
		var model_a_path = rails_project_path + "/app/models/" + model_a_name.to_lower() + ".rb"


		#var model_a_file = File.new()
		#model_a_file.open(model_a_path, File.READ_WRITE)

		var model_a_file = FileAccess.open(model_a_path, FileAccess.READ_WRITE)
		if model_a_file != null:
			# File opened successfully, perform operations
			print("File opened successfully")
		else:
			print("Failed to open file")

		var model_a_content = model_a_file.get_as_text()
		var new_model_a_content = model_a_content.replace("class " + model_a_name + " < ApplicationRecord", "class " + model_a_name + " < ApplicationRecord\n  has_many :" + field_name)
		model_a_file.seek(0)
		model_a_file.store_string(new_model_a_content)
		model_a_file.close()

		# 3. Modify ModelB
		var model_b_path = rails_project_path + "/app/models/" + model_b_name.to_lower() + ".rb"

		#var model_b_file = File.new()
		#model_b_file.open(model_b_path, File.READ_WRITE)


		var model_b_file = FileAccess.open(model_a_path, FileAccess.READ_WRITE)
		if model_b_file != null:
			# File opened successfully, perform operations
			print("File opened successfully")
		else:
			print("Failed to open file")


		var model_b_content = model_b_file.get_as_text()
		var new_model_b_content = model_b_content.replace("class " + model_b_name + " < ApplicationRecord", "class " + model_b_name + " < ApplicationRecord\n  belongs_to :" + model_a_name.to_lower())
		model_b_file.seek(0)
		model_b_file.store_string(new_model_b_content)
		model_b_file.close()

		line_edit_new_field_name.text = ""
		_on_ModelList_item_selected(selected_index)

	else:
		var full_field_type = field_type
		if field_type == "references":
			var referenced_model = option_button_new_field_reference.get_item_text(option_button_new_field_reference.selected)
			full_field_type = referenced_model.to_lower() + ":references"

		#var command = "cd " + rails_project_path + " && rails generate migration Add" + field_name.capitalize() + "To" + model_a_name + " " + field_name + ":" + full_field_type
		var command = "cd " + rails_project_path + " && rails generate migration Add" + field_name.capitalize().replace(" ", "") + "To" + model_a_name + " " + field_name + ":" + full_field_type + " && rails db:migrate"
		print("_on_ButtonAddNewField_pressed command: ", command)
		
		var output = []
		var exit_code = OS.execute("bash", ["-l", "-c", command], output, true)
		if exit_code == 0:
			line_edit_new_field_name.text = ""
			_on_ModelList_item_selected(selected_index)
		else:
			print("Error adding field: " + str(exit_code))
			for line in output:
				print(line)

	_load_models()
	
