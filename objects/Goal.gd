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

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Example: Lock Y axis translation/rotation to keep it on the ground if needed
	pass
