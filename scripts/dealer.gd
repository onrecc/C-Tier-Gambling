extends Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_meta("Direction") == "down":
		anim_sprite.play("down")
	elif get_meta("Direction") == "up":
		anim_sprite.play("up")
	elif get_meta("Direction") == "left":
		anim_sprite.play("side")
	elif get_meta("Direction") == "right":
		anim_sprite.play("side")
		anim_sprite.flip_h = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
