class_name Ball
extends RigidBody3D

func _ready() -> void:
    # Ensure continuous collision detection for fast moving objects
    continuous_cd = true
    contact_monitor = true
    max_contacts_reported = 3

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    if position.length() > 50.0:
        state.transform.origin = Vector3(0, 2, 0)
        state.linear_velocity = Vector3.ZERO
        state.angular_velocity = Vector3.ZERO
