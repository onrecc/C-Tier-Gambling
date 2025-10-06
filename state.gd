extends Node

var coins: int = 1000:
	set(value):
		coins = value
		emit_signal("score_changed", coins)
		if coins <= 0:
			_on_broke()

var inventory: Array[String] = []

signal score_changed(new_score)

var casino_return_pos: Vector2 = Vector2.INF

func set_casino_return(pos: Vector2) -> void:
	casino_return_pos = pos

func take_casino_return() -> Vector2:
	var p := casino_return_pos
	casino_return_pos = Vector2.INF
	return p

func _on_broke() -> void:
	get_tree().change_scene_to_file("res://scenes/brokeahh.tscn")
