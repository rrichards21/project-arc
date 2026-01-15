extends Node

# --- Constants ---
# Physics
const GRAVITY: float = 9.8
const FRICTION: float = 0.1
const PLAYER_SPEED: float = 10.0
const PLAYER_ACCEL: float = 20.0
const DASH_FORCE: float = 25.0

# Layers (Collision masks)
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_BALL: int = 4
const LAYER_GOAL: int = 8

# Gameplay
const MATCH_DURATION: int = 180 # seconds

# --- Persistence ---
var config_path = "user://layout.cfg"

func save_mobile_layout(data: Dictionary) -> void:
	var config = ConfigFile.new()
	# data format: { "joystick": {pos: Vector2, scale: Vector2}, "buttons": {pos: Vector2, scale: Vector2} }
	
	if data.has("joystick"):
		config.set_value("joystick", "pos_x", data.joystick.pos.x)
		config.set_value("joystick", "pos_y", data.joystick.pos.y)
		config.set_value("joystick", "scale_x", data.joystick.scale.x)
		config.set_value("joystick", "scale_y", data.joystick.scale.y)
		
	if data.has("buttons"):
		config.set_value("buttons", "pos_x", data.buttons.pos.x)
		config.set_value("buttons", "pos_y", data.buttons.pos.y)
		config.set_value("buttons", "scale_x", data.buttons.scale.x)
		config.set_value("buttons", "scale_y", data.buttons.scale.y)
		
	config.save(config_path)
	print("Mobile layout saved.")

func load_mobile_layout() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(config_path)
	
	if err != OK:
		print("No custom layout found. Using defaults.")
		return {}
		
	var data = {}
	
	# Joystick Data
	if config.has_section("joystick"):
		var pos = Vector2(
			config.get_value("joystick", "pos_x", 0),
			config.get_value("joystick", "pos_y", 0)
		)
		var scale = Vector2(
			config.get_value("joystick", "scale_x", 1),
			config.get_value("joystick", "scale_y", 1)
		)
		data["joystick"] = {"pos": pos, "scale": scale}
		
	# Buttons Data
	if config.has_section("buttons"):
		var pos = Vector2(
			config.get_value("buttons", "pos_x", 0),
			config.get_value("buttons", "pos_y", 0)
		)
		var scale = Vector2(
			config.get_value("buttons", "scale_x", 1),
			config.get_value("buttons", "scale_y", 1)
		)
		data["buttons"] = {"pos": pos, "scale": scale}
		
	return data
