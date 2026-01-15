extends MeshInstance2D

var dragging = false

var out_of_bounds = false

var direction

var velocity

@onready var position_var = $"../joystick_range".global_position

@onready var parent = get_parent()

var finger_index: int = -1

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			# Strict isolation: Only accept touches on the LEFT side of the screen
			var viewport_width = get_viewport_rect().size.x
			if event.position.x > viewport_width / 2:
				return
				
			var circle = mesh as SphereMesh
			if circle:
				if global_position.distance_to(event.position) <= 125:
					dragging = true
					finger_index = event.index
		else:
			if dragging and event.index == finger_index:
				dragging = false
				out_of_bounds = false
				finger_index = -1
	elif event is InputEventScreenDrag and dragging:
		if position_var.distance_to(event.position) <= 125:
			global_position = event.position
			out_of_bounds = false
			#print("false")
		else:
			out_of_bounds = true
			#print("true")

func _process(delta):
	# Update target position dynamically in case the parent moves
	position_var = $"../joystick_range".global_position

	if !dragging:
		# Safety fallback: Use local speed if parent property missing
		var speed = 10.0
		if "move_back_speed" in parent:
			speed = parent.move_back_speed
			
		global_position = lerp(global_position, position_var, speed * delta)
	if out_of_bounds:
		var angle = $"../joystick_range".global_position.angle_to_point(get_global_mouse_position())
		global_position.x = $"../joystick_range".global_position.x + cos(angle) * 125
		global_position.y = $"../joystick_range".global_position.y + sin(angle) * 125
	if dragging:
		# Calculate normalized vector (0 to 1 magnitude)
		# Max distance is 125 as defined in input check
		var diff = global_position - position_var
		posVector = diff / 125.0
		# Clamp just in case
		if posVector.length() > 1.0:
			posVector = posVector.normalized()
	else:
		posVector = Vector2.ZERO

# Public property for reading input
var posVector: Vector2 = Vector2.ZERO
