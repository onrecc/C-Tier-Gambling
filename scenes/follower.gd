extends PathFollow2D

@export var speed: float = 60.0  # pixels per second
@export var loop_path: bool = true
@export var rotate_with_path: bool = true

func _ready() -> void:
	loop = loop_path
	rotates = rotate_with_path

func _process(delta: float) -> void:
	# progress is measured in pixels along the baked curve
	progress += speed * delta
