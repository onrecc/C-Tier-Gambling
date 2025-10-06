extends Node2D

@export var label_path: NodePath = NodePath("CanvasLayer/Label")

@onready var label: Label = get_node_or_null(label_path)

func _ready() -> void:
	if not label:
		push_error("CoinDisplay.gd: No label found at path " + str(label_path))
		return

	# Set initial value
	_update_label()

	if "coins_changed" in State:
		State.coins_changed.connect(_on_coins_changed)
	else:
		set_process(true)
		
	_restore_player_pos_if_any()

func _process(_delta: float) -> void:
	if not ("coins_changed" in State):
		_update_label()

func _on_coins_changed(new_amount: int) -> void:
	_update_label(new_amount)

func _update_label(amount: int = -1) -> void:
	var coins = amount if amount >= 0 else State.coins
	label.text = "Coins: " + str(coins)
	
func _restore_player_pos_if_any() -> void:
	var pos := State.take_casino_return()
	if pos.is_finite():
		await get_tree().process_frame  # let nodes finish ready()
		$Player.global_position = pos
		# If you have a Camera2D that follows the player:
		if $Camera2D:
			$Camera2D.reset_smoothing() # optional, avoids lerp from old spot
