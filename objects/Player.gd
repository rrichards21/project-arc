class_name Player
extends CharacterBody3D

# Dependencies
# Uses GameConfigs for speed constants

var push_force: float = 20.0


# _ready removed (no longer needed for dynamic loading)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta: float) -> void:
	# Only control if I am the authority
	if not is_multiplayer_authority():
		return # Sync handles position, no local physics needed for puppets

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
	if Input.is_action_just_pressed("grab"):
		if $RayCast3D.is_colliding():
			var collider = $RayCast3D.get_collider()
			print("Grab attempt: Collided with " + collider.name)
			if collider is RigidBody3D:
				# Request Server to start grab
				print("Sending request_grab RPC for " + collider.name)
				rpc_id(1, "request_grab", collider.get_path())
		else:
			print("Grab attempt: RayCast hit nothing.")

	if Input.is_action_just_released("grab"):
		# Request Server to stop grab
		print("Sending request_release RPC")
		rpc_id(1, "request_release")

@rpc("any_peer", "call_local")
func request_grab(path: NodePath) -> void:
	if not multiplayer.is_server(): return
	
	# 1. Transfer Authority FIRST (Server does this authoritative change)
	var grabber_id = multiplayer.get_remote_sender_id()
	var node = get_node_or_null(path)
	if node and node.has_method("set_owner_id"):
		node.set_owner_id(grabber_id)
		node.rpc("set_owner_id", grabber_id)
		
	# 2. Tell everyone to link the joint
	rpc("execute_grab", path)

@rpc("any_peer", "call_local")
func request_release() -> void:
	if not multiplayer.is_server(): return
	
	# 1. Tell everyone to unlink
	rpc("execute_release")
	
	# 2. Restore Authority to Server (delayed slightly ensuring physics didn't explode?) 
	# Actually, usually fine to do immediately.
	# We need to find WHAT was connected. We can infer it from the joint or track it.
	# But execute_release clears node_b.
	# We need to know the object to reset its authority. 
	# Since node_b is still set on server when this runs:
	if $Generic6DOFJoint3D.node_b:
		var node = get_node_or_null($Generic6DOFJoint3D.node_b)
		if node and node.has_method("set_owner_id"):
			node.set_owner_id(1)
			node.rpc("set_owner_id", 1)

@rpc("any_peer", "call_local")
func execute_grab(path: NodePath) -> void:
	$Generic6DOFJoint3D.node_b = path

@rpc("any_peer", "call_local")
func execute_release() -> void:
	$Generic6DOFJoint3D.node_b = NodePath("")
