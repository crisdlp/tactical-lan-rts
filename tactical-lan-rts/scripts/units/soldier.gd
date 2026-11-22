extends CharacterBody3D

@export var move_speed: float = 6.0
@export var rotation_speed: float = 10.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var selection_ring: MeshInstance3D = $SelectionRing

var is_selected: bool = false

func _ready() -> void:
	selection_ring.visible = false

func set_selected(value: bool) -> void:
	is_selected = value
	selection_ring.visible = value

func set_move_target(target_pos: Vector3) -> void:
	nav_agent.target_position = target_pos

func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_path_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_path_pos - global_position)
	direction.y = 0
	direction = direction.normalized()

	velocity = direction * move_speed
	move_and_slide()

	# Rotar suavemente hacia la dirección de movimiento
	if direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
