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
