extends Area2D

@onready var label = $Label 
var player_in_area: bool = false

func _ready():
	label.hide()

func _on_body_entered(body):
	if body is CharacterBody2D:
		player_in_area = true
		label.show() 

func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_area = false
		label.hide()

func _process(delta):
	if player_in_area and Input.is_action_just_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/bathroom.tscn")
