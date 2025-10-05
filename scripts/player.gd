extends CharacterBody2D

const SPEED = 100.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: Vector2 = Vector2.DOWN  # default facing down

func _physics_process(delta: float) -> void:
	var horizontal := Input.get_axis("left", "right")
	var vertical := Input.get_axis("up", "down")
	
	# X axis movement
	if horizontal != 0:
		velocity.x = horizontal * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Y axis movement
	if vertical != 0:
		velocity.y = vertical * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	move_and_slide()
	
	# Handle animations
	_play_animation(horizontal, vertical)

func _play_animation(horizontal: float, vertical: float) -> void:
	if horizontal == 0 and vertical == 0:
		# Idle animation based on last direction
		if abs(last_direction.x) > abs(last_direction.y):
			anim_sprite.play("side")
			anim_sprite.flip_h = last_direction.x > 0
		elif last_direction.y < 0:
			anim_sprite.play("up")
		else:
			anim_sprite.play("down")
	else:
		# Walking animations
		if abs(horizontal) > abs(vertical):
			anim_sprite.play("walk_side")
			anim_sprite.flip_h = horizontal > 0
			last_direction = Vector2(horizontal, 0)
		elif vertical < 0:
			anim_sprite.play("walk_up")
			last_direction = Vector2(0, -1)
		else:
			anim_sprite.play("walk_down")
			last_direction = Vector2(0, 1)
