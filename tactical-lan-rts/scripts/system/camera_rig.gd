extends Node3D

@export var move_speed: float = 15.0
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 8.0
@export var max_zoom: float = 35.0

@onready var camera: Camera3D = $Camera3D

func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		# Alinea el movimiento WASD con la rotación isométrica de 45 grados
		var forward := Vector3(-1, 0, -1).normalized()
		var right := Vector3(1, 0, -1).normalized()
		var direction := (forward * -input_dir.y) + (right * input_dir.x)
		global_position += direction * move_speed * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.size = clamp(camera.size - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = clamp(camera.size + zoom_speed, min_zoom, max_zoom)
