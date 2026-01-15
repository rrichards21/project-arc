class_name Goal
extends RigidBody3D

signal goal_scored(team_id_scored_against: int)

@export var team_id: int = 1 # 1: Team A's Goal (defended by A), 2: Team B's Goal

func _ready() -> void:
	# Heavy but movable
	mass = 50.0
	
	if physics_material_override == null:
		physics_material_override = PhysicsMaterial.new()
	
	physics_material_override.friction = 0.8
	linear_damp = 1.0
	angular_damp = 1.0

	$GoalDetector.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	# Check if it's the ball (could check class or group)
	if body is RigidBody3D and body.name.to_lower().contains("ball"):
		goal_scored.emit(team_id)

var _reset_pending: bool = false
var _reset_pos: Vector3
var _reset_rot: Vector3

func force_reset(pos: Vector3, rot_deg: Vector3) -> void:
	_reset_pos = pos
	_reset_rot = rot_deg
	_reset_pending = true

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _reset_pending:
		state.transform.origin = _reset_pos
		state.transform.basis = Basis.from_euler(_reset_rot * (PI / 180.0))
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		_reset_pending = false
