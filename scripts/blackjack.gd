extends Area2D

@export_file("*.tscn") var target_scene_path: String = "res://scenes/blackjack.tscn"
@export var player_group: StringName = &"player"

var _player_inside := false
var _player_ref: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group(player_group):
		_player_inside = true
		_player_ref = body as Node2D

func _on_body_exited(body: Node) -> void:
	if body == _player_ref:
		_player_inside = false
		_player_ref = null

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		_enter_game()

func _enter_game() -> void:
	if _player_ref == null:
		_player_ref = get_tree().get_first_node_in_group(String(player_group)) as Node2D

	if _player_ref and is_instance_valid(_player_ref):
		State.set_casino_return(_player_ref.global_position)

	var err := get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("Failed to change scene to: " + target_scene_path)
