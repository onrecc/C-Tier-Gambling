extends Node2D

func _on_button_pressed() -> void:
	State.emit_signal("coins_changed", 1000)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
