extends RigidBody3D

const ARM_MASS = 0.08
const ARM_LINEAR_DAMP = 0.35
const ARM_ANGULAR_DAMP = 4.5


func _ready() -> void:
	mass = ARM_MASS
	linear_damp = ARM_LINEAR_DAMP
	angular_damp = ARM_ANGULAR_DAMP
	gravity_scale = 1.0
	can_sleep = false
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
