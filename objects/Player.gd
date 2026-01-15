class_name Player
extends CharacterBody3D

# Dependencies
# Uses GameConfigs for speed constants

var push_force: float = 20.0
var max_health: int = 100
var current_health: int = 100

var is_dead: bool = false
var team_id: int = 0 # 0=None, 1=Blue, 2=Red
var dash_cooldown: bool = false

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
	
	# Mobile Input Integration
	if GameManager.mobile_movement != Vector2.ZERO:
		input_dir = GameManager.mobile_movement
		
	# Input relative to global world coordinates
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
	
	if (Input.is_action_just_pressed("dash") or (GameManager.mobile_dash and not dash_cooldown)) and direction:
		velocity += direction * GameConfigs.DASH_FORCE
		dash_cooldown = true
		await get_tree().create_timer(1.0).timeout
		dash_cooldown = false

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

	if Input.is_action_just_released("grab") or (GameManager.mobile_action == false and grabbing_mobile_active):
		# Request Server to stop grab
		print("Sending request_release RPC")
		rpc_id(1, "request_release")
		grabbing_mobile_active = false

	# Logic for Mobile Action (Contextual)
	if GameManager.mobile_action and not grabbing_mobile_active:
		# Check context only on JUST press? 
		# We need a 'just_pressed' tracker for mobile bool, or just check if not holding.
		# Simple state machine:
		if $RayCast3D.is_colliding():
			var collider = $RayCast3D.get_collider()
			if collider is RigidBody3D:
				# Context: GRAB
				grabbing_mobile_active = true
				print("Mobile Grab Start")
				rpc_id(1, "request_grab", collider.get_path())
			elif collider is Player:
				# Context: ATTACK (Handled in _handle_attack, but mobile needs trigger)
				# Let's handle generic attack trigger here if not grabbing?
				pass
		else:
			# Context: ATTACK (Air swing)
			pass

var grabbing_mobile_active: bool = false

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

func server_force_release() -> void:
	if not multiplayer.is_server(): return
	
	# 1. Restore authority of held object if any
	if $Generic6DOFJoint3D.node_b:
		var node = get_node_or_null($Generic6DOFJoint3D.node_b)
		if node and node.has_method("set_owner_id"):
			node.set_owner_id(1)
			node.rpc("set_owner_id", 1)
			
	# 2. Unlink everywhere
	rpc("execute_release")
	grabbing_mobile_active = false

func _handle_attack() -> void:
	# Local check (predictions)
	if is_dead: return
	
	var is_attacking = Input.is_action_just_pressed("attack")
	
	# Mobile Attack Logic: If pressed and NOT grabbing anything
	if GameManager.mobile_action and not grabbing_mobile_active:
		# Debounce: Ensure we only fire once per press (like just_pressed)
		if not _mobile_attack_fired:
			_mobile_attack_fired = true
			is_attacking = true
	else:
		_mobile_attack_fired = false
	
	if is_attacking:
		print("Attempting Attack RPC...")
		rpc_id(1, "request_attack")

var _mobile_attack_fired: bool = false

@rpc("any_peer", "call_local")
func request_attack() -> void:
	if not multiplayer.is_server(): return
	
	# SERVER SIDES CHECK: Am I dead? (Anti-Zombie)
	if is_dead: return 
	
	# Server validates hit
	if $RayCast3D.is_colliding():
		var collider = $RayCast3D.get_collider()
		print("[Server] Attack Ray Hit: ", collider.name) 
		if collider is Player and collider != self:
			if not collider.is_dead:
				collider.take_damage(25) # 4 hits to kill
				print("[Server] Valid Hit on Player: " + collider.name)
		else:
			print("[Server] Hit ignored (Not a player or self)")
	else:
		print("[Server] Attack Ray Missed (Is enabled? Length OK?)")

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
func force_teleport(pos: Vector3, look_pos: Vector3 = Vector3.ZERO) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	if look_pos != Vector3.ZERO:
		look_at(look_pos, Vector3.UP)
		rotation.x = 0
		rotation.z = 0

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
