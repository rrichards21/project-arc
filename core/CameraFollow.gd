class_name CameraFollow
extends Camera3D

@export var smoothing_speed: float = 5.0
@export var offset: Vector3 = Vector3(0, 10, 10)

var target: Node3D = null

func _ready() -> void:
	# If offset is not set manually, take the current relative position
	# But here we enforce the specific Isometric-ish offset we want
	pass

func _process(delta: float) -> void:
	if target:
		var target_pos = target.global_position + offset
		global_position = global_position.lerp(target_pos, smoothing_speed * delta)
