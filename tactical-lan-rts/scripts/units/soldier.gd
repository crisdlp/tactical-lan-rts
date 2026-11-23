extends CharacterBody3D

@export var move_speed: float = 6.0
@export var rotation_speed: float = 10.0
@export var owner_id: int = 1:
	set(value):
		owner_id = value
		if is_node_ready():
			_apply_team_color()

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var selection_ring: MeshInstance3D = $SelectionRing
@onready var body_mesh: MeshInstance3D = $MeshInstance3D

var is_selected: bool = false

func _ready() -> void:
	selection_ring.visible = false
	_apply_team_color()

func _apply_team_color() -> void:
	var mat := StandardMaterial3D.new()
	# Host (ID 1) = Azul | Cliente = Rojo
	mat.albedo_color = Color(0.2, 0.4, 0.9) if owner_id == 1 else Color(0.9, 0.2, 0.2)
	body_mesh.material_override = mat

func set_selected(value: bool) -> void:
	is_selected = value
	selection_ring.visible = value

# El cliente pide moverse al Host; el Host valida que sea el dueño y ejecuta el movimiento
@rpc("any_peer", "call_local", "reliable")
func request_move(target_pos: Vector3) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == owner_id:
		nav_agent.target_position = target_pos

func _physics_process(delta: float) -> void:
	# Solo el Host calcula la navegación; el Cliente recibe position/rotation por red
	if not multiplayer.is_server():
		return
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_path_pos: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_path_pos - global_position)
	direction.y = 0
	direction = direction.normalized()

	velocity = direction * move_speed
	move_and_slide()

	if direction.length() > 0.1:
		var target_angle := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
