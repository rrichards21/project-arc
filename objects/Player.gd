class_name Player
extends CharacterBody3D

# Dependencies
# Uses GameConfigs for speed constants

var push_force: float = 20.0
var max_health: int = 100
var current_health: int = 100

var is_dead: bool = false
var team_id: int = 0 # 0=None, 1=Blue, 2=Red

func _update_dead_visuals() -> void:
	# Enforce state
	visible = !is_dead
	$CollisionShape3D.disabled = is_dead
	if has_node("HealthBar"):
		$HealthBar.visible = !is_dead

func update_color() -> void:
	var mesh: MeshInstance3D = $MeshInstance3D
	# Optimization: check if material color matches team_id to avoid new allocation every frame?
	# For prototype, creating new material every frame is bad perf but guaranteed correct.
	# Better: Use material_override property.
	
	var desired_color = Color.WHITE
	if team_id == 1:
		desired_color = Color.BLUE
	elif team_id == 2:
		desired_color = Color.RED
		
	if mesh.material_override:
		if mesh.material_override.albedo_color != desired_color:
			mesh.material_override.albedo_color = desired_color
	else:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = desired_color
		mesh.material_override = mat

# _ready removed (no longer needed for dynamic loading)


# _ready removed (no longer needed for dynamic loading)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())
	# Critical: ServerSynchronizer must always be owned by Server (1)
	if has_node("ServerSynchronizer"):
		$ServerSynchronizer.set_multiplayer_authority(1)

func _physics_process(delta: float) -> void:
	if is_dead: return
	
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
	_handle_attack()

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

func _handle_attack() -> void:
	# Local check (predictions)
	if is_dead: return
	
	if Input.is_action_just_pressed("attack"):
		rpc_id(1, "request_attack")

@rpc("any_peer", "call_local")
func request_attack() -> void:
	if not multiplayer.is_server(): return
	
	# SERVER SIDES CHECK: Am I dead? (Anti-Zombie)
	if is_dead: return 
	
	# Server validates hit
	if $RayCast3D.is_colliding():
		var collider = $RayCast3D.get_collider()
		if collider is Player and collider != self:
			if not collider.is_dead:
				collider.take_damage(25) # 4 hits to kill
				print("Hit player: " + collider.name)

func take_damage(amount: int) -> void:
	# Server only logic for state
	if not multiplayer.is_server(): return
	
	# Direct assignment matches ServerSync authority
	current_health -= amount
	
	print(name + " took damage. Health: " + str(current_health))
	
	if current_health <= 0:
		die()

# @rpc("call_local") func update_health... REMOVED (Handled by ServerSynchronizer)
# func update_health_bar... MOVED to setter logic in _process or property setter

func die() -> void:
	# Server authority changes the variable
	is_dead = true
	# Sync handled by MultiplayerSynchronizer
	
	# Start Respawn Timer
	await get_tree().create_timer(5.0).timeout
	respawn()

func respawn() -> void:
	if not multiplayer.is_server(): return
	
	current_health = max_health
	is_dead = false
	position = Vector3(0, 5, 0)
	
	# Force position sync?
	rpc("force_teleport", position)

@rpc("call_local")
func force_teleport(pos: Vector3) -> void:
	position = pos

# Update loop to check health changes (simple approach since sync happens)
func _process(_delta: float) -> void:
	update_health_bar()
	# FORCE VISUAL SYNC LOOP (Fixes setter bypass issues)
	_update_dead_visuals()
	update_color()

func update_health_bar() -> void:
	if $HealthBar:
		var percent = float(current_health) / float(max_health)
		# Scale the sprite horizontally
		$HealthBar.scale.x = clamp(percent, 0.0, 1.0)
		
		# Optional: Change color based on health?
		# For now just size.
