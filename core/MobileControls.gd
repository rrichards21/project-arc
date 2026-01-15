extends CanvasLayer

# Plugin Joystick Integration
@onready var joystick_node = $Joystick
# Note: The 'knob' node inside the plugin has the 'posVector' property.
# Based on plugin structure: Joystick (Control) -> knob (MeshInstance2D with script)
# We need to access that script.
var joystick_knob_script: Node2D

func _ready() -> void:
	# Only show on Android or if emulating
	if OS.get_name() != "Android" and not OS.has_feature("mobile"):
		# Optional: remove checks to test on PC easily
		pass 
	
	# Find the knob in the instanced scene
	if joystick_node.has_node("knob"):
		joystick_knob_script = joystick_node.get_node("knob")
	else:
		print("Error: Joystick plugin structure unknown. Cannot find 'knob'.")
		
	# Apply Custom Layout if exists
	_apply_custom_layout()

func _apply_custom_layout() -> void:
	var data = GameConfigs.load_mobile_layout()
	if data.is_empty(): return
	
	if data.has("joystick"):
		# We need to set ANCHORS overrides or simply positions.
		# Since we use anchors, we should be careful. 
		# For simplicity in this reliable system: We'll assume the saved POS is the offset modification 
		# OR we assume the save system saves strict Global Position/Canvas Position.
		
		# Let's trust the Config Scene stores OFFSETS relative to anchors 
		# OR simpler: stores the actual Position property if we change layout mode.
		
		# Strategy: Logic will be consistent between Config Scene and here.
		# Config Scene will save the result of get_position() and get_scale().
		
		# However, they are anchored.
		# If we change position, we modify offsets automatically in Godot Control.
		joystick_node.position = data.joystick.pos
		joystick_node.scale = data.joystick.scale
		
	if data.has("buttons"):
		var btns = $Buttons
		btns.position = data.buttons.pos
		btns.scale = data.buttons.scale

func _process(_delta: float) -> void:
	if joystick_knob_script:
		# 'posVector' is the property we added to knob.gd
		if "posVector" in joystick_knob_script:
			GameManager.mobile_movement = joystick_knob_script.posVector
		else:
			# Fallback if property missing (shouldn't happen if edit worked)
			pass

# Old logic removed.

func _on_btn_dash_pressed() -> void:
	print("Mobile Dash Pressed")
	GameManager.mobile_dash = true

func _on_btn_dash_released() -> void:
	GameManager.mobile_dash = false

func _on_btn_action_pressed() -> void:
	print("Mobile Action Pressed")
	GameManager.mobile_action = true

func _on_btn_action_released() -> void:
	GameManager.mobile_action = false
