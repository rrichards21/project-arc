class_name Ball
extends RigidBody3D

func _ready() -> void:
    # Ensure continuous collision detection for fast moving objects
    continuous_cd = true
    contact_monitor = true
    max_contacts_reported = 3

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
    # Custom gravity or damping if needed
    pass
