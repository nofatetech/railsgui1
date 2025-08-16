extends Control

@onready var models_container = $VBoxContainer/ModelsContainer
@onready var controllers_container = $VBoxContainer/ControllersContainer
@onready var views_container = $VBoxContainer/ViewsContainer

func _ready():
    models_container.show()
    controllers_container.hide()
    views_container.hide()

func _on_ModelsButton_pressed():
    models_container.show()
    controllers_container.hide()
    views_container.hide()

func _on_ControllersButton_pressed():
    models_container.hide()
    controllers_container.show()
    views_container.hide()

func _on_ViewsButton_pressed():
    models_container.hide()
    controllers_container.hide()
    views_container.show()
