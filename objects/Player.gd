class_name Player
extends CharacterBody3D

# Dependencies
# Uses GameConfigs for speed constants

var push_force: float = 20.0


# _ready removed (no longer needed for dynamic loading)

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Input relative to global world coordinates
	# We do NOT use transform.basis here because we want WASD to always mean Global North/South/East/West
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	if direction:
		velocity.x = direction.x * GameConfigs.PLAYER_SPEED
		velocity.z = direction.z * GameConfigs.PLAYER_SPEED
		
		# Smooth Rotation
		# ONLY rotate if NOT grabbing something. If grabbing, we strafe/backpedal.
		if not $Generic6DOFJoint3D.node_b:
			var target_angle = atan2(-velocity.x, -velocity.z)
			rotation.y = lerp_angle(rotation.y, target_angle, 15.0 * delta)
		
	else:
		velocity.x = move_toward(velocity.x, 0, GameConfigs.PLAYER_SPEED)
		velocity.z = move_toward(velocity.z, 0, GameConfigs.PLAYER_SPEED)
	
	if Input.is_action_just_pressed("dash") and direction:
		velocity += direction * GameConfigs.DASH_FORCE

	# Gravity
	if not is_on_floor():
		velocity.y -= GameConfigs.GRAVITY * delta

	move_and_slide()
	
	_handle_grabbing()

	# RigidBody Interaction (Pushing)
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force * delta)

func _handle_grabbing() -> void:
	if Input.is_action_pressed("grab"):
		if $Generic6DOFJoint3D.node_b:
			return # Already grabbing

		if $RayCast3D.is_colliding():
			var collider = $RayCast3D.get_collider()
			if collider is RigidBody3D:
				$Generic6DOFJoint3D.node_b = collider.get_path()
	else:
		if $Generic6DOFJoint3D.node_b:
			$Generic6DOFJoint3D.node_b = NodePath("")
