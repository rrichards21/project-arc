extends Control

var mobile_controls_scene = preload("res://core/MobileControls.tscn")
var mobile_controls_instance
var selected_node: Control = null

@onready var edit_panel = $UI/EditPanel
@onready var scale_slider = $UI/EditPanel/VBox/HSliderScale
@onready var hud = $HUD

func _ready() -> void:
	# Load Mobile Controls
	mobile_controls_instance = mobile_controls_scene.instantiate()
	hud.add_child(mobile_controls_instance)
	
	# Hijack Inputs for Editing
	# We need to find Joystick and Buttons
	var joystick = mobile_controls_instance.get_node("Joystick") # Instanced scene or node
	var buttons = mobile_controls_instance.get_node("Buttons")
	
	# Connect signals for our custom drag logic
	# Since they consume input, we might need a transparent overlay or 
	# just check inputs globally relative to their rects.
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.position)
		else:
			_handle_touch_up()
			
	if event is InputEventScreenDrag and selected_node:
		_handle_drag(event)

func _handle_touch_down(pos: Vector2) -> void:
	# Check collision with Joystick or Buttons
	var joystick = mobile_controls_instance.get_node("Joystick")
	var buttons = mobile_controls_instance.get_node("Buttons")
	
	if _is_pos_inside(joystick, pos):
		_select_node(joystick)
	elif _is_pos_inside(buttons, pos):
		_select_node(buttons)
	elif edit_panel.visible and edit_panel.get_global_rect().has_point(pos):
		# Touched the UI panel, do not deselect
		pass
	else:
		_deselect()

func _handle_touch_up() -> void:
	pass

func _handle_drag(event: InputEventScreenDrag) -> void:
	if selected_node:
		selected_node.global_position += event.relative

func _is_pos_inside(node: Control, pos: Vector2) -> bool:
	return node.get_global_rect().has_point(pos)

func _select_node(node: Control) -> void:
	selected_node = node
	edit_panel.visible = true
	scale_slider.value = node.scale.x # Assuming uniform scale
	print("Selected: " + node.name)

func _deselect() -> void:
	selected_node = null
	edit_panel.visible = false

func _on_scale_changed(value: float) -> void:
	if selected_node:
		selected_node.scale = Vector2(value, value)

func _on_btn_save_pressed() -> void:
	var joystick = mobile_controls_instance.get_node("Joystick")
	var buttons = mobile_controls_instance.get_node("Buttons")
	
	var data = {
		"joystick": {
			"pos": joystick.position,
			"scale": joystick.scale
		},
		"buttons": {
			"pos": buttons.position,
			"scale": buttons.scale
		}
	}
	
	GameConfigs.save_mobile_layout(data)
	get_tree().change_scene_to_file("res://core/Menu.tscn")

func _on_btn_reset_pressed() -> void:
	# Reload scene to reset
	get_tree().reload_current_scene()
